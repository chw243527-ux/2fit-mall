#!/usr/bin/env node
/**
 * 2FIT MALL mobile responsive audit
 *
 * 사용: node tools/mobile-responsive-audit.js
 * 역할: 주요 모바일 CSS 뷰포트에서 Responsive 유틸리티의 폰트·여백·터치 영역
 * 보호값을 계산하고, 핵심 화면에 고정 폭 위험 패턴이 있는지 점검합니다.
 * 이 스크립트는 소스 또는 Firestore 데이터를 변경하지 않습니다.
 */

const fs = require('fs');
const path = require('path');

const devices = [
  { name: 'iPhone SE (1세대) 기준', width: 320, height: 568 },
  { name: 'Galaxy S 소형 폭 기준', width: 360, height: 740 },
  { name: 'iPhone SE (2·3세대) 기준', width: 375, height: 667 },
  { name: 'iPhone 14·15 기준', width: 390, height: 844 },
  { name: 'Galaxy S 대형 폭 기준', width: 412, height: 915 },
];

const baseWidth = 390;
const baseHeight = 844;
const minFontScale = 0.85;
const maxFontScale = 1.15;

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
const round = (value) => Math.round(value * 100) / 100;

function deviceRow(device) {
  const scaleW = device.width / baseWidth;
  const scaleH = device.height / baseHeight;
  const fontScale = clamp((scaleW + scaleH) / 2, minFontScale, maxFontScale);
  const narrow = device.width <= 360;

  return {
    device: device.name,
    viewport: `${device.width} × ${device.height}`,
    fontScale: `${round(fontScale)}×`,
    heading32: `${round(32 * fontScale)}px`,
    body14: `${round(14 * fontScale)}px`,
    gutter: `${narrow ? 12 : 16}px`,
    minTouch: `${narrow ? 44 : 48}px`,
    bottomBarVertical: `${narrow ? 8 : round(10 * scaleH)}px`,
  };
}

function checkSource(relativePath, rules) {
  const absolutePath = path.join(process.cwd(), relativePath);
  const source = fs.readFileSync(absolutePath, 'utf8');
  const failures = rules.filter(({ test }) => !test(source)).map(({ label }) => label);
  return { relativePath, failures };
}

const checks = [
  checkSource('web/index.html', [
    { label: 'viewport 메타태그', test: (s) => s.includes('width=device-width') },
    { label: '작은 화면 PWA 배너 미디어쿼리', test: (s) => s.includes('@media (max-width: 360px)') },
    { label: 'iOS 안전 영역 처리', test: (s) => s.includes('safe-area-inset') },
    { label: '가로 오버플로 차단', test: (s) => s.includes('overflow-x: hidden') },
  ]),
  checkSource('lib/utils/responsive.dart', [
    { label: '360px 이하 소형 화면 분기', test: (s) => s.includes('kNarrowMobileBreakpoint = 360') },
    { label: '소형 화면 12px 여백', test: (s) => s.includes('return 12.0') },
    { label: '최소 44px 터치 영역', test: (s) => s.includes('isNarrowMobile ? 44.0') },
    { label: '폰트 스케일 하한', test: (s) => s.includes('kMinFontScale = 0.85') },
  ]),
  checkSource('lib/screens/products/product_detail_screen.dart', [
    { label: '하단 구매 바 SafeArea', test: (s) => s.includes('child: SafeArea(') },
    { label: '하단 구매 바 소형 화면 여백', test: (s) => s.includes('r.isMobile ? r.contentGutter') },
  ]),
  checkSource('lib/screens/admin/admin_screen.dart', [
    { label: '관리자 모바일 레이아웃 전환', test: (s) => s.includes('return _buildMobileLayout(user)') },
    { label: '관리자 모바일 Drawer', test: (s) => s.includes('drawer: Drawer(') },
  ]),
];

console.log('\n2FIT MALL — Mobile Responsive Audit\n');
console.table(devices.map(deviceRow));

const failed = checks.filter(({ failures }) => failures.length > 0);
console.log('\nSource safeguards');
for (const { relativePath, failures } of checks) {
  console.log(`${failures.length === 0 ? 'PASS' : 'FAIL'}  ${relativePath}`);
  for (const failure of failures) console.log(`      - ${failure}`);
}

if (failed.length > 0) {
  console.error(`\n${failed.length}개 파일에서 보호 규칙이 누락되었습니다.`);
  process.exit(1);
}

console.log('\nPASS — 주요 모바일 폭의 반응형 보호 규칙이 모두 확인되었습니다.');
