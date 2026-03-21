// translation_service.dart
// MyMemory 무료 번역 API를 사용하여 상품명/설명 자동번역
// API 제한: 비인증 시 하루 1000단어 (이메일 등록 시 10000단어)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TranslationService {
  static const _baseUrl = 'https://api.mymemory.translated.net/get';

  // 지원 언어 코드 (MyMemory 형식)
  static const Map<String, String> _langCodes = {
    'en': 'ko|en',
    'ja': 'ko|ja',
    'zh': 'ko|zh',
    'mn': 'ko|mn',
  };

  // 번역 캐시 (중복 요청 방지)
  static final Map<String, Map<String, String>> _cache = {};

  /// 한국어 텍스트를 4개 언어로 일괄 번역
  /// 반환: {'en': '...', 'ja': '...', 'zh': '...', 'mn': '...'}
  static Future<Map<String, String>> translateText(String koreanText) async {
    if (koreanText.trim().isEmpty) return {};

    final results = <String, String>{};
    final futures = _langCodes.entries.map((entry) async {
      try {
        final translated = await _translate(koreanText, entry.value);
        if (translated != null && translated.isNotEmpty) {
          results[entry.key] = translated;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('번역 실패(${entry.key}): $e');
      }
    });

    await Future.wait(futures);
    return results;
  }

  /// [deprecated] translateText 사용 권장
  static Future<Map<String, String>> translateProductName(String koreanName) =>
      translateText(koreanName);

  /// 캐시된 번역 확인 후 없으면 번역 (중복 요청 방지)
  static Future<Map<String, String>> translateWithCache(String koreanText) async {
    final key = koreanText.trim();
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    final result = await translateText(key);
    if (result.isNotEmpty) {
      _cache[key] = result;
    }
    return result;
  }

  /// 긴 텍스트 번역 (설명 등, 500자씩 분할 처리)
  static Future<Map<String, String>> translateLongText(String koreanText) async {
    if (koreanText.trim().isEmpty) return {};

    // 500자 이하면 그냥 번역
    if (koreanText.length <= 500) {
      return translateWithCache(koreanText);
    }

    // 긴 텍스트는 단락으로 분할해서 번역 후 합치기
    final paragraphs = koreanText.split('\n');
    final resultsByLang = <String, List<String>>{
      'en': [], 'ja': [], 'zh': [], 'mn': [],
    };

    for (final para in paragraphs) {
      if (para.trim().isEmpty) {
        for (final lang in resultsByLang.keys) {
          resultsByLang[lang]!.add('');
        }
        continue;
      }
      // 단락도 500자 초과 시 잘라서 번역
      final chunk = para.length > 500 ? para.substring(0, 500) : para;
      final translated = await translateWithCache(chunk);
      for (final lang in resultsByLang.keys) {
        resultsByLang[lang]!.add(translated[lang] ?? para);
      }
    }

    return {
      'en': resultsByLang['en']!.join('\n'),
      'ja': resultsByLang['ja']!.join('\n'),
      'zh': resultsByLang['zh']!.join('\n'),
      'mn': resultsByLang['mn']!.join('\n'),
    };
  }

  /// 상품명 + 설명 동시 번역 반환
  /// 반환: {'name': {'en':..., 'ja':..., 'zh':..., 'mn':...}, 'description': {...}}
  static Future<Map<String, Map<String, String>>> translateProduct({
    required String name,
    required String description,
  }) async {
    final nameResult = await translateWithCache(name);
    final descResult = await translateLongText(description);
    return {
      'name': nameResult,
      'description': descResult,
    };
  }

  /// 단일 번역 요청 (내부 사용)
  static Future<String?> _translate(String text, String langPair) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': text,
        'langpair': langPair,
        'de': 'fitfashionshop@app.com', // API 식별용 이메일 (할당량 증가)
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>?;
        final translated = responseData?['translatedText'] as String?;

        // 번역 품질 확인
        final match = responseData?['match'];
        if (translated != null && translated.isNotEmpty && match != 0) {
          return translated;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_translate 오류: $e');
    }
    return null;
  }

  /// 캐시 초기화
  static void clearCache() => _cache.clear();
}
