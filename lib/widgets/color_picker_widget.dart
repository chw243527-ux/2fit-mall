import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';
import '../utils/app_localizations.dart';

// ══════════════════════════════════════════════════════════════
// 골지(Rib) 텍스처 페인터
// 실제 골지 원단 사진 기반: 두꺼운 세로 리브 + 강한 3D 입체감
// 각 리브 = 왼쪽 밝은면(하이라이트) + 오른쪽 어두운면(그림자)
// 주기: ~9px (하이라이트 4px + 그림자 3px + 틈새 2px)
// ══════════════════════════════════════════════════════════════
class RibTexturePainter extends CustomPainter {
  final Color baseColor;
  const RibTexturePainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final lum = baseColor.computeLuminance();

    // ─── 리브 파라미터 (사진 분석 기반) ───
    // 실제 사진: 굵은 리브 1개 = 약 9px 주기
    // 리브 왼쪽 = 밝은 면(평탄+반사), 오른쪽 = 어두운 면(그림자)
    const ribPeriod  = 9.0;  // 전체 주기
    const brightW    = 4.0;  // 밝은 면 너비
    const darkW      = 3.0;  // 어두운 면 너비
    // 틈 = 9 - 4 - 3 = 2px (베이스 색상 그대로 보임)

    // 밝기에 따른 하이라이트/그림자 강도 조정
    final highlightAlpha = lum > 0.6
        ? 0.55   // 밝은 색: 하이라이트 강함
        : lum > 0.3
            ? 0.45   // 중간 색
            : 0.35;  // 어두운 색: 하이라이트 상대적 약함

    final shadowAlpha = lum > 0.6
        ? 0.22   // 밝은 색: 그림자 약하게 (너무 진하면 이상)
        : lum > 0.3
            ? 0.38   // 중간 색
            : 0.55;  // 어두운 색: 그림자 강하게 (입체감)

    // ─── 그라디언트 방식으로 각 리브 그리기 ───
    double x = 0;
    while (x < size.width) {
      // ① 밝은 면: LinearGradient (왼쪽 끝 매우 밝음 → 오른쪽으로 페이드)
      final brightRect = Rect.fromLTWH(x, 0, brightW, size.height);
      final brightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: highlightAlpha),
            Colors.white.withValues(alpha: highlightAlpha * 0.15),
          ],
        ).createShader(brightRect);
      canvas.drawRect(brightRect, brightPaint);

      // ② 어두운 면: LinearGradient (왼쪽 진함 → 오른쪽 페이드)
      final darkX = x + brightW;
      if (darkX < size.width) {
        final darkRect = Rect.fromLTWH(
            darkX, 0, math.min(darkW, size.width - darkX), size.height);
        final darkPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: shadowAlpha),
              Colors.black.withValues(alpha: shadowAlpha * 0.1),
            ],
          ).createShader(darkRect);
        canvas.drawRect(darkRect, darkPaint);
      }

      x += ribPeriod;
    }

    // ─── 전체 상단 광택 오버레이 ───
    // 직물 표면의 전반적인 광택감 (상단 밝음, 하단 약간 어두움)
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: lum > 0.5 ? 0.18 : 0.10),
          Colors.transparent,
          Colors.black.withValues(alpha: lum > 0.5 ? 0.06 : 0.14),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), glossPaint);
  }

  @override
  bool shouldRepaint(covariant RibTexturePainter old) =>
      old.baseColor != baseColor;
}

// ══════════════════════════════════════════════════════════════
// RibColorSwatch - 골지 텍스처 사각 스와치 (공개 위젯)
// ══════════════════════════════════════════════════════════════
class RibColorSwatch extends StatelessWidget {
  final Color color;
  final double size;
  final bool isSelected;
  final Color accentColor;
  final bool isLight;
  final Widget? child;
  final double? height;
  final double? borderRadius;

  const RibColorSwatch({
    super.key,
    required this.color,
    required this.size,
    this.isSelected = false,
    this.accentColor = AppColors.accent,
    required this.isLight,
    this.child,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? size;
    final r = borderRadius ?? (size * 0.26);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: isSelected
              ? accentColor
              : isLight
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.20),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isSelected ? 0.55 : 0.30),
            blurRadius: isSelected ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 골지 텍스처
            CustomPaint(painter: RibTexturePainter(baseColor: color)),
            // 체크 아이콘
            if (child != null) Center(child: child!),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 골지 원단칼라 팔레트 (19가지 공식 색상)
// ══════════════════════════════════════════════════════════════
class AppColorPalette {
  static const List<Map<String, dynamic>> registeredColors = [
    {'name': 'K (블랙)',       'nameEn': 'K-Black',       'code': 'K',  'hex': 0xFF1A1A1A},
    {'name': 'PP (퍼플네이비)', 'nameEn': 'PP-PurpleNavy', 'code': 'PP', 'hex': 0xFF1A1A3A},
    {'name': 'N (네이비)',      'nameEn': 'N-Navy',        'code': 'N',  'hex': 0xFF0D1B3E},
    {'name': 'W (화이트)',      'nameEn': 'W-White',       'code': 'W',  'hex': 0xFFF2F2F2},
    {'name': 'G (그레이)',      'nameEn': 'G-Gray',        'code': 'G',  'hex': 0xFFAAAAAA},
    {'name': 'DG (다크그레이)', 'nameEn': 'DG-DarkGray',   'code': 'DG', 'hex': 0xFF454545},
    {'name': 'SB (스카이블루)', 'nameEn': 'SB-SkyBlue',    'code': 'SB', 'hex': 0xFFADD8E6},
    {'name': 'B (블루)',        'nameEn': 'B-Blue',        'code': 'B',  'hex': 0xFF2A52BE},
    {'name': 'DB (다크블루)',   'nameEn': 'DB-DarkBlue',   'code': 'DB', 'hex': 0xFF3A5068},
    {'name': 'SP (스모크핑크)', 'nameEn': 'SP-SmokePink',  'code': 'SP', 'hex': 0xFFD4A5A0},
    {'name': 'LP (라이트핑크)', 'nameEn': 'LP-LightPink',  'code': 'LP', 'hex': 0xFFE8B4BC},
    {'name': 'IO (아이보리)',   'nameEn': 'IO-Ivory',      'code': 'IO', 'hex': 0xFFD6D0C4},
    {'name': 'LG (라이트그레이)','nameEn': 'LG-LightGray', 'code': 'LG', 'hex': 0xFFBDBDBD},
    {'name': 'R (레드)',        'nameEn': 'R-Red',         'code': 'R',  'hex': 0xFFCC1111},
    {'name': 'ND (뉴다크)',     'nameEn': 'ND-NewDark',    'code': 'ND', 'hex': 0xFF4A5040},
    {'name': 'BB (틸블루)',     'nameEn': 'BB-TealBlue',   'code': 'BB', 'hex': 0xFF006B6B},
    {'name': 'FP (형광핑크)',   'nameEn': 'FP-FluoPink',   'code': 'FP', 'hex': 0xFFFF0090},
    {'name': 'FO (형광오렌지)', 'nameEn': 'FO-FluoOrange', 'code': 'FO', 'hex': 0xFFFF5500},
    {'name': 'FG (형광그린)',   'nameEn': 'FG-FluoGreen',  'code': 'FG', 'hex': 0xFF99FF00},
  ];

  static List<Map<String, dynamic>> get fullPalette => registeredColors;

  // ── 세상 모든 색 팔레트 (HSV 전체 스펙트럼, 그리드 7열 맞춤) ──
  // 총 ~252색: 무채색(7) + 다크(77) + 순색(77) + 밝은색(77) + 파스텔(14)
  static List<Color> get extendedPalette {
    final colors = <Color>[];

    // ① 무채색 7단계 (검정→흰색)
    for (int i = 0; i < 7; i++) {
      final v = (i / 6 * 255).round();
      colors.add(Color.fromARGB(255, v, v, v));
    }

    // ② 다크 계열 (명도 0.25, 채도 1.0) — 각 hue 77개
    const hues = [
      0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0,
      55.0, 60.0, 65.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0,
      140.0, 150.0, 160.0, 170.0, 180.0, 190.0, 200.0, 210.0, 215.0,
      220.0, 225.0, 230.0, 235.0, 240.0, 245.0, 250.0, 255.0, 260.0,
      265.0, 270.0, 275.0, 280.0, 285.0, 290.0, 295.0, 300.0, 305.0,
      310.0, 315.0, 320.0, 325.0, 330.0, 335.0, 340.0, 345.0, 350.0,
      355.0,
      // 특수색: 스킨/누드/카멜/올리브/틸/코발트/마린/버건디 등
      14.0, 22.0, 36.0, 48.0, 72.0, 84.0, 96.0, 108.0, 132.0, 144.0,
      156.0, 168.0, 192.0, 204.0, 216.0, 228.0, 252.0,
    ];

    for (final h in hues) {
      colors.add(HSVColor.fromAHSV(1.0, h, 1.0, 0.28).toColor());
    }

    // ③ 순색 계열 (명도 0.75, 채도 1.0)
    for (final h in hues) {
      colors.add(HSVColor.fromAHSV(1.0, h, 1.0, 0.75).toColor());
    }

    // ④ 밝은 순색 (명도 1.0, 채도 1.0)
    for (final h in hues) {
      colors.add(HSVColor.fromAHSV(1.0, h, 1.0, 1.0).toColor());
    }

    // ⑤ 파스텔 계열 (채도 0.28, 명도 1.0) — 14색
    for (int i = 0; i < 14; i++) {
      final h = i / 14 * 360;
      colors.add(HSVColor.fromAHSV(1.0, h, 0.28, 1.0).toColor());
    }

    return colors;
  }
}

// ══════════════════════════════════════════════════════════════
// ColorPickerWidget - 모달 바텀시트 색상 선택기
// 탭1: 골지 19색 / 탭2: 전체 팔레트 / 탭3: HEX 직접 입력
// ══════════════════════════════════════════════════════════════
class ColorPickerWidget extends StatefulWidget {
  final String? selectedColorName;
  final Color? selectedColor;
  final Function(String colorName, Color color) onColorSelected;

  const ColorPickerWidget({
    super.key,
    this.selectedColorName,
    this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _hexCtrl = TextEditingController();
  Color _previewColor = const Color(0xFF1A1A1A);

  AppLocalizations get loc => context.read<LanguageProvider>().loc;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    if (widget.selectedColor != null) {
      _previewColor = widget.selectedColor!;
      _hexCtrl.text = _colorToHex(widget.selectedColor!);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    return c.toARGB32().toRadixString(16).substring(2).toUpperCase();
  }

  void _select(String name, Color color) {
    widget.onColorSelected(name, color);
  }

  void _applyHex() {
    final raw = _hexCtrl.text.trim().replaceAll('#', '');
    if (raw.length == 6) {
      try {
        final color = Color(int.parse('FF$raw', radix: 16));
        _select('커스텀 (#$raw)', color);
        Navigator.pop(context);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.colorPickerInvalidHex)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.colorPickerHexLength)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Text(loc.colorPickerTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                if (widget.selectedColorName != null) ...[
                  RibColorSwatch(
                    color: widget.selectedColor ?? Colors.transparent,
                    size: 20,
                    isLight: (widget.selectedColor ?? Colors.white)
                        .computeLuminance() > 0.5,
                  ),
                  const SizedBox(width: 6),
                  Text(widget.selectedColorName!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666))),
                ],
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // 탭 바
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF555555),
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: loc.colorPickerRib19),
                Tab(text: loc.colorPickerFullPalette),
                Tab(text: loc.colorPickerHexTab),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 탭 콘텐츠
          Flexible(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRibGrid(),
                _buildFullPalette(),
                _buildHexInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 탭1: 골지 19색 그리드 ──
  Widget _buildRibGrid() {
    const colors = AppColorPalette.registeredColors;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: colors.length,
      itemBuilder: (_, i) {
        final c = colors[i];
        final color = Color(c['hex'] as int);
        final isSel = widget.selectedColorName == c['name'];
        final isLight = color.computeLuminance() > 0.5;
        final code = c['code'] as String;
        return GestureDetector(
          onTap: () {
            _select(c['name'] as String, color);
            Navigator.pop(context);
          },
          child: Column(
            children: [
              RibColorSwatch(
                color: color,
                size: 52,
                isSelected: isSel,
                accentColor: AppColors.accent,
                isLight: isLight,
                child: isSel
                    ? Icon(Icons.check_rounded,
                        size: 20,
                        color: isLight ? Colors.black87 : Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(code,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSel
                        ? AppColors.accent
                        : const Color(0xFF222222),
                  ),
                  textAlign: TextAlign.center),
              Text(
                (c['name'] as String).split(' ').first,
                style: TextStyle(
                  fontSize: 8,
                  color: isSel
                      ? AppColors.accent
                      : const Color(0xFF888888),
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 탭2: 전체 컬러 팔레트 ──
  Widget _buildFullPalette() {
    final extended = AppColorPalette.extendedPalette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.colorPickerAll,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: extended.map((color) {
              final isLight = color.computeLuminance() > 0.5;
              final isSel = widget.selectedColor != null &&
                  widget.selectedColor!.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () {
                  final hex = _colorToHex(color);
                  _select('커스텀 (#$hex)', color);
                  Navigator.pop(context);
                },
                child: RibColorSwatch(
                  color: color,
                  size: 36,
                  isSelected: isSel,
                  accentColor: AppColors.accent,
                  isLight: isLight,
                  child: isSel
                      ? Icon(Icons.check_rounded,
                          size: 14,
                          color: isLight ? Colors.black87 : Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // 색조 슬라이더 팔레트
          Text(loc.colorPickerTone,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333))),
          const SizedBox(height: 8),
          _HueBar(
            onColorSelected: (color) {
              final hex = _colorToHex(color);
              _select('커스텀 (#$hex)', color);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ── 탭3: HEX 직접 입력 ──
  Widget _buildHexInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.colorPickerHexInput,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222))),
          const SizedBox(height: 4),
          Text(loc.colorPickerHexExample,
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF999999))),
          const SizedBox(height: 16),
          // 미리보기
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _previewColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: _previewColor),
                  CustomPaint(
                      painter:
                          RibTexturePainter(baseColor: _previewColor)),
                  Center(
                    child: Text(
                      '#${_colorToHex(_previewColor)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _previewColor.computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 입력 필드
          TextField(
            controller: _hexCtrl,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontFamily: 'monospace'),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9A-Fa-f#]')),
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: InputDecoration(
              hintText: '#FF0000',
              hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _previewColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 50),
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF1A1A1A), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
            onChanged: (v) {
              final raw = v.trim().replaceAll('#', '');
              if (raw.length == 6) {
                final hex = int.tryParse('FF$raw', radix: 16);
                if (hex != null) {
                  setState(() => _previewColor = Color(hex));
                }
              }
            },
            onSubmitted: (_) => _applyHex(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _applyHex,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(loc.colorPickerConfirm,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 20),
          // 19색 빠른 참조
          Text(loc.goljiRef,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppColorPalette.registeredColors.map((c) {
              final color = Color(c['hex'] as int);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _previewColor = color;
                    _hexCtrl.text = _colorToHex(color);
                  });
                },
                child: Tooltip(
                  message: '${c['code']} ${c['name']}',
                  child: RibColorSwatch(
                    color: color,
                    size: 28,
                    isLight: color.computeLuminance() > 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── 색조 바 위젯 ──
class _HueBar extends StatefulWidget {
  final Function(Color) onColorSelected;
  const _HueBar({required this.onColorSelected});
  @override
  State<_HueBar> createState() => _HueBarState();
}

class _HueBarState extends State<_HueBar> {
  double _hue = 0;
  double _sat = 1.0;
  double _val = 0.8;

  Color get _current =>
      HSVColor.fromAHSV(1.0, _hue, _sat, _val).toColor();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 미리보기
        GestureDetector(
          onTap: () => widget.onColorSelected(_current),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(color: _current),
                CustomPaint(
                    painter: RibTexturePainter(baseColor: _current)),
                Center(
                  child: Text(
                    '탭하여 이 색상 선택',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _current.computeLuminance() > 0.5
                          ? Colors.black54
                          : Colors.white70,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _slider('색조', _hue, 0, 360, (v) => setState(() => _hue = v),
            isHue: true),
        _slider('채도', _sat, 0, 1, (v) => setState(() => _sat = v)),
        _slider('명도', _val, 0, 1, (v) => setState(() => _val = v)),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool isHue = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF888888))),
        ),
        Expanded(
          child: isHue
              ? SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    activeColor: HSVColor.fromAHSV(
                            1.0, value, 1.0, 1.0)
                        .toColor(),
                    inactiveColor: const Color(0xFFE0E0E0),
                    onChanged: onChanged,
                  ),
                )
              : Slider(
                  value: value,
                  min: min,
                  max: max,
                  activeColor: _current,
                  inactiveColor: const Color(0xFFE0E0E0),
                  onChanged: onChanged,
                ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            isHue
                ? '${value.round()}°'
                : '${(value * 100).round()}%',
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF888888)),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ColorSelectButton - 폼에서 모달 팝업으로 색상 선택
// ══════════════════════════════════════════════════════════════
class ColorSelectButton extends StatelessWidget {
  final String label;
  final String? selectedColorName;
  final Color? selectedColor;
  final Function(String colorName, Color color) onColorSelected;
  final Color accentColor;

  const ColorSelectButton({
    super.key,
    required this.label,
    this.selectedColorName,
    this.selectedColor,
    required this.onColorSelected,
    this.accentColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selectedColorName != null
              ? selectedColor?.withValues(alpha: 0.08)
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedColorName != null
                ? (selectedColor ?? accentColor).withValues(alpha: 0.5)
                : const Color(0xFFE0E0E0),
            width: selectedColorName != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (selectedColor != null) ...[
              RibColorSwatch(
                color: selectedColor!,
                size: 24,
                isLight: selectedColor!.computeLuminance() > 0.5,
                accentColor: accentColor,
              ),
              const SizedBox(width: 10),
            ] else ...[
              const Icon(Icons.palette_outlined,
                  size: 20, color: Color(0xFF888888)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                selectedColorName ?? '$label 선택하기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selectedColorName != null
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: selectedColorName != null
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFF888888),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ColorPickerWidget(
        selectedColorName: selectedColorName,
        selectedColor: selectedColor,
        onColorSelected: (name, color) {
          onColorSelected(name, color);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// InlineColorChart - 인라인 색상 선택 차트 (팝업 없음)
// 탭1: 골지 19색 / 탭2: 전체 팔레트 / 탭3: HEX 입력
// ══════════════════════════════════════════════════════════════
class InlineColorChart extends StatefulWidget {
  final String label;
  final String? selectedColorName;
  final Color? selectedColor;
  final Function(String colorName, Color color) onColorSelected;
  final Color accentColor;
  final bool required;

  const InlineColorChart({
    super.key,
    required this.label,
    this.selectedColorName,
    this.selectedColor,
    required this.onColorSelected,
    this.accentColor = AppColors.accent,
    this.required = false,
  });

  @override
  State<InlineColorChart> createState() => _InlineColorChartState();
}

class _InlineColorChartState extends State<InlineColorChart>
    with SingleTickerProviderStateMixin {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  late TabController _tabCtrl;
  final _codeCtrl = TextEditingController();
  final _hexCtrl = TextEditingController();
  String? _codeError;
  Color _hexPreview = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    if (widget.selectedColor != null) {
      _hexPreview = widget.selectedColor!;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _codeCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();

  void _onCodeSubmit() {
    final code = _codeCtrl.text.trim().toUpperCase();
    final found = AppColorPalette.registeredColors
        .where((c) => (c['code'] as String).toUpperCase() == code);
    if (found.isNotEmpty) {
      final c = found.first;
      widget.onColorSelected(c['name'] as String, Color(c['hex'] as int));
      setState(() {
        _codeCtrl.clear();
        _codeError = null;
      });
    } else {
      setState(() => _codeError = '"$code" 코드를 찾을 수 없습니다');
    }
  }

  void _onHexSubmit() {
    final raw = _hexCtrl.text.trim().replaceAll('#', '');
    if (raw.length == 6) {
      final hex = int.tryParse('FF$raw', radix: 16);
      if (hex != null) {
        final color = Color(hex);
        widget.onColorSelected('커스텀 (#$raw)', color);
        setState(() => _hexPreview = color);
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('6자리 HEX 코드를 입력해주세요')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.selectedColorName != null
              ? widget.accentColor.withValues(alpha: 0.4)
              : const Color(0xFFE8E8E8),
          width: widget.selectedColorName != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Row(
            children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A))),
              if (widget.required) ...const [
                SizedBox(width: 4),
                Text('*',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
              const Spacer(),
              if (widget.selectedColorName != null) ...[
                RibColorSwatch(
                  color: widget.selectedColor ?? Colors.transparent,
                  size: 20,
                  isLight: (widget.selectedColor ?? Colors.white)
                      .computeLuminance() > 0.5,
                  accentColor: widget.accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.selectedColorName!,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // ── 탭 바 ──
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: widget.accentColor,
                borderRadius: BorderRadius.circular(6),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF666666),
              labelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: loc.colorPickerRib19),
                Tab(text: loc.colorPickerFullPalette),
                Tab(text: loc.colorPickerHexTab),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── 탭 콘텐츠 ──
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRib19(),
                _buildExtended(),
                _buildHex(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 탭1: 골지 19색
  Widget _buildRib19() {
    const colors = AppColorPalette.registeredColors;
    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: colors.map((c) {
              final name = c['name'] as String;
              final code = c['code'] as String;
              final color = Color(c['hex'] as int);
              final isSel = widget.selectedColorName == name;
              final isLight = color.computeLuminance() > 0.5;
              return GestureDetector(
                onTap: () => widget.onColorSelected(name, color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  width: 48,
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSel
                        ? color.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel
                          ? widget.accentColor
                          : Colors.transparent,
                      width: isSel ? 2 : 0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RibColorSwatch(
                        color: color,
                        size: 36,
                        isSelected: isSel,
                        accentColor: widget.accentColor,
                        isLight: isLight,
                        child: isSel
                            ? Icon(Icons.check_rounded,
                                size: 15,
                                color: isLight
                                    ? Colors.black87
                                    : Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 3),
                      Text(code,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSel
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isSel
                                ? widget.accentColor
                                : const Color(0xFF444444),
                          ),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // 코드 직접 입력
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '코드 입력 (예: K, N, FP)',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: Color(0xFFAAAAAA)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFFDDDDDD))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: widget.accentColor, width: 1.5)),
                    errorText: _codeError,
                    errorStyle: const TextStyle(fontSize: 10),
                  ),
                  onSubmitted: (_) => _onCodeSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onCodeSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(0, 38),
                  elevation: 0,
                ),
                child: Text(loc.selectBtn,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 탭2: 전체 팔레트 (세상 모든 색 — 7열 GridView)
  Widget _buildExtended() {
    final extended = AppColorPalette.extendedPalette;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: extended.length,
      itemBuilder: (_, i) {
        final color = extended[i];
        final isLight = color.computeLuminance() > 0.5;
        final isSel = widget.selectedColor != null &&
            widget.selectedColor!.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () {
            final hex = _colorToHex(color);
            widget.onColorSelected('커스텀 (#$hex)', color);
          },
          child: RibColorSwatch(
            color: color,
            size: 36,
            borderRadius: 8,
            isSelected: isSel,
            accentColor: widget.accentColor,
            isLight: isLight,
            child: isSel
                ? Icon(Icons.check_rounded,
                    size: 14,
                    color: isLight ? Colors.black87 : Colors.white)
                : null,
          ),
        );
      },
    );
  }

  // 탭3: HEX 입력
  Widget _buildHex() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 미리보기 바
        Container(
          height: 44,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: _hexPreview),
              CustomPaint(
                  painter: RibTexturePainter(baseColor: _hexPreview)),
              Center(
                child: Text(
                  '#${_colorToHex(_hexPreview)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: _hexPreview.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hexCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9A-Fa-f#]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
                decoration: InputDecoration(
                  hintText: '#FF0000',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: Color(0xFFCCCCCC)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFFDDDDDD))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: widget.accentColor, width: 1.5)),
                ),
                onChanged: (v) {
                  final raw = v.trim().replaceAll('#', '');
                  if (raw.length == 6) {
                    final hex = int.tryParse('FF$raw', radix: 16);
                    if (hex != null) {
                      setState(() => _hexPreview = Color(hex));
                    }
                  }
                },
                onSubmitted: (_) => _onHexSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _onHexSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 42),
                elevation: 0,
              ),
              child: Text(loc.applyBtn,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(loc.goljiQuickRef,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: AppColorPalette.registeredColors.map((c) {
            final color = Color(c['hex'] as int);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _hexPreview = color;
                  _hexCtrl.text =
                      '#${_colorToHex(color)}';
                });
              },
              child: Tooltip(
                message: c['code'] as String,
                child: RibColorSwatch(
                  color: color,
                  size: 22,
                  isLight: color.computeLuminance() > 0.5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
