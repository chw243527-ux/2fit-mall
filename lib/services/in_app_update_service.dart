import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Google Play 인앱 업데이트 처리 서비스입니다.
///
/// Google Play에서 설치된 Android 앱에서만 동작합니다.
/// 웹·iOS·직접 설치 APK에서는 조용히 종료하며 앱의 일반 실행을 막지 않습니다.
enum ManualUpdateResult {
  started,
  noUpdate,
  storeOpened,
  unavailable,
  failed,
}

class InAppUpdateService {
  InAppUpdateService._();

  static bool _checkedThisSession = false;
  static bool _updateInProgress = false;

  /// 앱 시작 시 한 번 호출합니다.
  ///
  /// [force]가 true이면 즉시 업데이트를 우선합니다. 결제·보안 등
  /// 긴급 수정이 아닌 일반 배포에서는 false를 사용해 Flexible 업데이트를 씁니다.
  static Future<void> checkAndPrompt(
    BuildContext context, {
    bool force = false,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_checkedThisSession || _updateInProgress) return;
    _checkedThisSession = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (!context.mounted) return;

      if (force && info.immediateUpdateAllowed) {
        _updateInProgress = true;
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        _updateInProgress = true;
        await InAppUpdate.startFlexibleUpdate();
        if (!context.mounted) return;

        await InAppUpdate.completeFlexibleUpdate();
        await _promptRestart(context);
        return;
      }

      // Play 정책이나 테스트 트랙 상태에 따라 업데이트 방식이 허용되지
      // 않을 수 있으므로, 이 경우에는 앱을 계속 사용할 수 있게 둡니다.
      if (kDebugMode) {
        debugPrint('ℹ️ Google Play 업데이트가 제공되었지만 허용된 방식이 없습니다.');
      }
    } catch (e) {
      // 업데이트 확인 실패는 로그인·주문·결제 흐름을 막지 않아야 합니다.
      if (kDebugMode) {
        debugPrint('ℹ️ Google Play 인앱 업데이트 확인 건너뜀: $e');
      }
    } finally {
      _updateInProgress = false;
    }
  }

  /// 사용자가 버튼을 눌러 직접 업데이트를 확인합니다.
  /// 앱 시작 시 자동 확인과 달리 세션 중복 제한을 적용하지 않습니다.
  static Future<ManualUpdateResult> checkManually(
    BuildContext context, {
    bool force = false,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return ManualUpdateResult.unavailable;
    }
    if (_updateInProgress) return ManualUpdateResult.failed;

    _updateInProgress = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        // Google Play API가 업데이트를 제공하지 않는 경우에는 최신이라고
        // 단정하지 않습니다. Play Store에서 테스트 트랙·계정을 확인할 수
        // 있도록 수동 확인 화면은 별도 안내를 표시합니다.
        return ManualUpdateResult.noUpdate;
      }
      if (!context.mounted) return ManualUpdateResult.failed;

      if (force && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return ManualUpdateResult.started;
      }
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        if (!context.mounted) return ManualUpdateResult.failed;
        await InAppUpdate.completeFlexibleUpdate();
        await _promptRestart(context);
        return ManualUpdateResult.started;
      }
      await openPlayStore();
      return ManualUpdateResult.storeOpened;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ℹ️ 수동 Google Play 업데이트 확인 건너뜀: $e');
      }
      final opened = await openPlayStore();
      return opened ? ManualUpdateResult.storeOpened : ManualUpdateResult.failed;
    } finally {
      _updateInProgress = false;
    }
  }

  static Future<bool> openPlayStore() async {
    const appId = 'com.twofit.twofit';
    final marketUri = Uri.parse('market://details?id=$appId');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$appId',
    );
    try {
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showReleaseNotes(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.new_releases_rounded),
            SizedBox(width: 8),
            Expanded(child: Text('새 버전 변경 사항')),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '이번 업데이트에 포함된 내용입니다.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 14),
              _ReleaseNoteItem('고객센터 연락처를 최신 사업자 정보로 통일했습니다.'),
              _ReleaseNoteItem('주문 상태 이메일에서 카카오채널 문의 링크를 제공합니다.'),
              _ReleaseNoteItem('웹·앱 푸터와 정책 링크를 정리했습니다.'),
              _ReleaseNoteItem('앱 안정성과 업데이트 안내 기능을 개선했습니다.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  static Future<void> _promptRestart(BuildContext context) async {
    if (!context.mounted) return;

    await _showReleaseNotes(context);
    if (!context.mounted) return;

    final restart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('업데이트가 완료되었습니다'),
        content: const Text(
          '새 버전을 적용하려면 앱을 다시 시작해야 합니다. 지금 앱을 다시 시작하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('지금 다시 시작'),
          ),
        ],
      ),
    );

    if (restart == true) {
      // Android에서는 현재 프로세스를 닫고 사용자가 다시 실행하도록 유도합니다.
      // Google Play가 설치한 업데이트는 다음 실행부터 적용됩니다.
      await SystemNavigator.pop();
    }
  }

  /// 다음 앱 실행에서 다시 확인할 수 있도록 세션 플래그를 초기화합니다.
  /// 테스트 코드나 로그아웃 후 재검증이 필요한 경우에만 사용합니다.
  static void resetSessionCheck() {
    _checkedThisSession = false;
    _updateInProgress = false;
  }
}

/// 업데이트 확인 전 사용자에게 표시할 수 있는 선택 안내 문구입니다.
/// 현재 기본 흐름은 Google Play 시스템 UI를 사용하며, 필요 시 앱 자체
/// 다이얼로그를 연결할 때 이 문구를 재사용합니다.
class _ReleaseNoteItem extends StatelessWidget {
  final String text;

  const _ReleaseNoteItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.check_circle_rounded, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class AppUpdateCopy {
  AppUpdateCopy._();

  static const title = '새 버전이 출시되었습니다';
  static const message = '더 안정적인 서비스 이용을 위해 최신 버전으로 업데이트해 주세요.';
  static const forceTitle = '업데이트가 필요합니다';
  static const forceMessage = '계속 이용하려면 최신 버전으로 업데이트해 주세요.';
}

