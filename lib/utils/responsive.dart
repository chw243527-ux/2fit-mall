// responsive.dart — 2FIT Mall 전역 반응형 유틸리티
//
// 사용법:
//   final r = Responsive.of(context);
//   r.w(360)    → 화면 너비 비례 픽셀
//   r.h(100)    → 화면 높이 비례 픽셀
//   r.sp(14)    → 화면 크기 비례 폰트 크기
//   r.isMobile  → true (< 600)
//   r.isTablet  → true (600 ~ 899)
//   r.isPc      → true (≥ 900)
//
// 설계 기준(baseWidth):
//   모바일: 390px (iPhone 15 Pro)
//   태블릿: 768px (iPad)
//   PC    : 1280px

import 'package:flutter/material.dart';

// ── 브레이크포인트 상수 ──────────────────────────
// 320px: iPhone SE(1세대) 계열, 360px: Galaxy S 계열의 일반적인 최소 CSS 폭
const double kNarrowMobileBreakpoint = 360;
const double kMobileBreakpoint = 600;
const double kTabletBreakpoint = 900;   // = kPcBreakpoint 와 동일
const double kPcMaxWidth       = 1280;  // PC 콘텐츠 최대 너비

// ── 폰트 스케일 상한/하한 ────────────────────────
const double kMinFontScale = 0.85;  // 아주 작은 기기에서 너무 작아지지 않게
const double kMaxFontScale = 1.15;  // PC/4K 모니터에서 텍스트 과도하게 커지지 않게

class Responsive {
  final double screenWidth;
  final double screenHeight;
  final double devicePixelRatio;

  const Responsive._({
    required this.screenWidth,
    required this.screenHeight,
    required this.devicePixelRatio,
  });

  factory Responsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Responsive._(
      screenWidth:      mq.size.width,
      screenHeight:     mq.size.height,
      devicePixelRatio: mq.devicePixelRatio,
    );
  }

  // ── 기기 구분 ────────────────────────────────
  bool get isMobile => screenWidth < kMobileBreakpoint;
  bool get isNarrowMobile => screenWidth <= kNarrowMobileBreakpoint;
  bool get isTablet => screenWidth >= kMobileBreakpoint && screenWidth < kTabletBreakpoint;
  bool get isPc     => screenWidth >= kTabletBreakpoint;

  /// 모바일 본문 공통 좌우 여백. 320~360px에서는 12px로 줄여 콘텐츠 폭을 확보합니다.
  double get contentGutter {
    if (isNarrowMobile) return 12.0;
    if (isMobile) return 16.0;
    if (isTablet) return 24.0;
    return 32.0;
  }

  /// 가로 버튼·칩·카드에 사용할 최소 터치 영역입니다.
  double get minTouchTarget => isNarrowMobile ? 44.0 : 48.0;

  // ── 기준 너비 (기기별) ─────────────────────────
  double get _baseWidth {
    if (isPc)     return 1280.0;
    if (isTablet) return 768.0;
    return 390.0;   // 모바일 기준
  }

  double get _baseHeight {
    if (isPc)     return 800.0;
    if (isTablet) return 1024.0;
    return 844.0;   // 모바일 기준 (iPhone 15 Pro)
  }

  // ── 스케일 팩터 ──────────────────────────────
  double get scaleW => screenWidth  / _baseWidth;
  double get scaleH => screenHeight / _baseHeight;

  /// 폰트 스케일: 너비+높이 평균으로 산출, 상하한 클램프
  double get fontScale =>
      ((scaleW + scaleH) / 2).clamp(kMinFontScale, kMaxFontScale);

  // ── 변환 메서드 ──────────────────────────────
  /// 너비 비례 픽셀 (디자인 기준 너비 → 실제 너비)
  double w(double designPx) => designPx * scaleW;

  /// 높이 비례 픽셀
  double h(double designPx) => designPx * scaleH;

  /// 폰트 크기 (화면 크기 비례, 클램프 적용)
  double sp(double designFontSize) => designFontSize * fontScale;

  /// 소형 화면에서만 값이 너무 커지는 것을 막기 위한 컴팩트 값 선택기입니다.
  T compact<T>({required T normal, T? narrow}) =>
      isNarrowMobile ? (narrow ?? normal) : normal;

  /// 패딩/마진 — 너비 비례
  EdgeInsets padding({
    double left   = 0,
    double top    = 0,
    double right  = 0,
    double bottom = 0,
  }) => EdgeInsets.fromLTRB(
    w(left), h(top), w(right), h(bottom),
  );

  EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: w(h), vertical: this.h(v));

  /// 반응형 값 선택 (mobile / tablet / pc)
  T value<T>({required T mobile, T? tablet, T? pc}) {
    if (isPc)     return pc     ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }
}

// ── 편의 extension ──────────────────────────────
extension ResponsiveContext on BuildContext {
  Responsive get r => Responsive.of(this);
}

// ── 전역 textScaler 계산 ────────────────────────
/// main.dart builder에서 사용: 시스템 폰트 크기를 제한된 범위로 클램프
TextScaler clampedTextScaler(BuildContext context) {
  final mq = MediaQuery.of(context);
  final sysFactor = mq.textScaler.scale(1.0);
  // 시스템 접근성 설정 최대 1.2배까지만 반영
  final clamped = sysFactor.clamp(0.9, 1.2);
  return TextScaler.linear(clamped);
}
