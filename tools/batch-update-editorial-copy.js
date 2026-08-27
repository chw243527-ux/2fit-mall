#!/usr/bin/env node
/*
 * 기성품 에디토리얼 카피 일괄 갱신 스크립트
 *
 * 기본값은 미리보기(dry run)입니다. Firestore에 실제 저장하려면 --apply를 명시해야 합니다.
 *
 * 사용 예시
 *   GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/service-account.json \
 *     node scripts/batch-update-editorial-copy.js
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/service-account.json \
 *     node scripts/batch-update-editorial-copy.js --apply
 *
 * 옵션
 *   --apply             Firestore products 컬렉션에 실제 반영
 *   --force             editorialLocked=true 상품도 갱신
 *   --include-inactive  비활성 상품도 포함
 *   --project <id>      기본값: fit-mall
 */

'use strict';

const path = require('path');

function loadFirebaseAdmin() {
  try {
    return require('firebase-admin');
  } catch (_) {
    try {
      return require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
    } catch (error) {
      console.error('\n[오류] firebase-admin 패키지를 찾을 수 없습니다.');
      console.error('먼저 프로젝트 루트에서 다음을 실행해 주세요:');
      console.error('  cd functions && npm ci\n');
      throw error;
    }
  }
}

const admin = loadFirebaseAdmin();

const args = new Set(process.argv.slice(2));
const getOption = (name, fallback) => {
  const index = process.argv.indexOf(name);
  return index >= 0 && process.argv[index + 1] ? process.argv[index + 1] : fallback;
};
const applyChanges = args.has('--apply');
const force = args.has('--force');
const includeInactive = args.has('--include-inactive');
const projectId = getOption('--project', process.env.FIREBASE_PROJECT || 'fit-mall');

if (args.has('--help') || args.has('-h')) {
  console.log('사용법: node scripts/batch-update-editorial-copy.js [--apply] [--force] [--include-inactive] [--project fit-mall]');
  process.exit(0);
}

function normalize(value) {
  return String(value || '').toLowerCase().replace(/\s+/g, ' ').trim();
}

function includesAny(value, terms) {
  return terms.some((term) => value.includes(term));
}

function colorProfile(colors) {
  const source = normalize(Array.isArray(colors) ? colors.join(' ') : colors);
  if (source.includes('오렌지')) return { key: 'orange', label: 'ORANGE', adjective: '선명한 오렌지' };
  if (source.includes('틸블루') || source.includes('틸 블루')) return { key: 'teal', label: 'TEAL', adjective: '산뜻한 틸블루' };
  if (source.includes('블루') || source.includes('스카이블루') || source.includes('스카이 블루')) return { key: 'blue', label: 'BLUE', adjective: '시원한 블루' };
  if (source.includes('그린')) return { key: 'green', label: 'GREEN', adjective: '정돈된 그린' };
  if (source.includes('화이트') || source.includes('white')) return { key: 'white', label: 'WHITE', adjective: '밝고 선명한 화이트' };
  if (source.includes('핑크')) return { key: 'pink', label: 'PINK', adjective: '경쾌한 핑크' };
  if (source.includes('퍼플')) return { key: 'purple', label: 'PURPLE', adjective: '깊이감 있는 퍼플' };
  if (source.includes('블랙') || source.includes('검정') || source.includes('black')) return { key: 'black', label: 'BLACK', adjective: '기본에 충실한 블랙' };
  return { key: 'signature', label: 'SIGNATURE', adjective: '2FIT 시그니처' };
}

function materialProfile(product) {
  const source = normalize([
    product.category,
    product.subCategory,
    product.name,
    product.material,
  ].join(' '));
  const isSingletSet = product.category === '세트' || includesAny(source, ['싱글렛세트', '싱글렛 세트']);

  if (!isSingletSet && includesAny(source, ['싱글렛', '라운드티', '라운드 티'])) {
    return {
      key: 'polyester-lycra',
      material: '폴리에스터 92% / 라이크라 8%',
      label: source.includes('라운드') ? 'PERFORMANCE ROUND TEE' : 'RUNNING SINGLET',
      title: 'RUN LIGHT.\nSTAY READY.',
      accent: 'POLYESTER 92% · LYCRA 8%',
      subtitle: '폴리에스터 92%와 라이크라 8%의 균형으로 가볍게 움직이고 편안하게 페이스를 이어갑니다.',
    };
  }

  if (includesAny(source, ['골지타이즈', '골지 타이즈']) ||
      (product.category === '하의' && source.includes('골지'))) {
    return {
      key: 'nylon-lycra',
      material: '나일론 75% / 라이크라 25%',
      label: 'RIB TIGHTS',
      title: 'STRETCH WITH\nPURPOSE.',
      accent: 'NYLON 75% · LYCRA 25%',
      subtitle: '나일론 75%와 라이크라 25%의 유연한 밸런스로, 움직임에 맞춰 안정적인 핏을 제안합니다.',
    };
  }

  if (source.includes('에어로브라이트')) {
    return {
      key: 'aero-bright',
      material: '에어로브라이트 원단(펄원단) / 폴리에스터 78% / 크레오라 22%',
      label: 'AERO BRIGHT PERFORMANCE',
      title: 'MOVE WITH\nA LIGHT EDGE.',
      accent: 'POLYESTER 78% · CREORA 22%',
      subtitle: '에어로브라이트 펄원단의 폴리에스터 78%와 크레오라 22%가 가볍고 유연한 움직임을 완성합니다.',
    };
  }

  if (includesAny(source, ['크롭탑', '크롭 탑', '삼각', '원피스', '브라이트'])) {
    return {
      key: 'bright',
      material: '브라이트 원단(펄원단) / 폴리에스터 80% / 크레오라 20%',
      label: 'BRIGHT PEARL PERFORMANCE',
      title: 'CATCH LIGHT.\nKEEP MOVING.',
      accent: 'POLYESTER 80% · CREORA 20%',
      subtitle: '브라이트 펄원단의 폴리에스터 80%와 크레오라 20%를 사용해, 움직임에 빛나는 유연함을 더했습니다.',
    };
  }

  const material = String(product.material || '').trim() || '상품별 소재 정보 확인';
  return {
    key: 'general',
    material,
    label: '2FIT PERFORMANCE WEAR',
    title: 'MADE TO\nKEEP MOVING.',
    accent: 'DESIGNED FOR MOTION.',
    subtitle: '움직임에 집중할 수 있도록 설계한 2FIT 스포츠웨어입니다. 상품별 소재와 옵션을 확인해 주세요.',
  };
}

function colorHeadline(profile, color) {
  const byColor = {
    orange: ['ENERGY\nIN MOTION.', 'ORANGE EDITION.'],
    teal: ['LIGHT STEP.\nCLEAR MIND.', 'TEAL EDITION.'],
    blue: ['COOL TONE.\nSTRONG MOVE.', 'BLUE EDITION.'],
    green: ['STAY SHARP.\nKEEP MOVING.', 'GREEN EDITION.'],
    white: ['CLEAN LINES.\nCLEAR PACE.', 'WHITE EDITION.'],
    pink: ['BRIGHT PACE.\nBOLD MOVE.', 'PINK EDITION.'],
    purple: ['FLOW\nIN MOTION.', 'PURPLE EDITION.'],
    black: ['STAY READY.\nSTAY MOVING.', 'BLACK EDITION.'],
  };
  return byColor[color.key] || [profile.title, profile.accent];
}

function buildEditorialCopy(product) {
  const material = materialProfile(product);
  const color = colorProfile(product.colors);
  const [title, accent] = colorHeadline(material, color);

  return {
    editorialLabel: `${material.label} / ${color.label}`,
    editorialTitle: title,
    editorialAccent: accent,
    editorialSubtitle: `${material.subtitle} ${color.adjective} 컬러로 2FIT의 움직임을 완성합니다.`,
    editorialMaterialKey: material.key,
    editorialMaterialText: material.material,
    editorialSource: 'material-copy-batch-v1',
  };
}

function sameCopy(existing, generated) {
  return [
    'editorialLabel',
    'editorialTitle',
    'editorialAccent',
    'editorialSubtitle',
    'editorialMaterialKey',
    'editorialMaterialText',
  ].every((key) => String(existing[key] || '') === String(generated[key] || ''));
}

function printPreview(product, copy, status) {
  console.log(`\n[${status}] ${product.id} — ${product.name}`);
  console.log(`  소재: ${copy.editorialMaterialText}`);
  console.log(`  라벨: ${copy.editorialLabel}`);
  console.log(`  타이틀: ${copy.editorialTitle.replace(/\n/g, ' / ')}`);
  console.log(`  서브: ${copy.editorialSubtitle}`);
}

async function main() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error('GOOGLE_APPLICATION_CREDENTIALS 환경변수에 Firebase 서비스 계정 JSON의 절대 경로를 지정해 주세요.');
  }

  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId });
  const db = admin.firestore();
  const snapshot = await db.collection('products').get();
  const readyMade = snapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((product) => product.isReadyMade === true && product.isGroupOnly !== true)
    .filter((product) => includeInactive || product.isActive !== false)
    .sort((a, b) => String(a.name || '').localeCompare(String(b.name || ''), 'ko'));

  if (readyMade.length === 0) {
    console.log('갱신 대상 기성품이 없습니다. isReadyMade=true 및 isGroupOnly=false 설정을 확인해 주세요.');
    return;
  }

  const targets = [];
  let locked = 0;
  let unchanged = 0;

  for (const product of readyMade) {
    const copy = buildEditorialCopy(product);
    if (product.editorialLocked === true && !force) {
      locked += 1;
      printPreview(product, copy, '잠김 — 건너뜀');
      continue;
    }
    if (sameCopy(product, copy)) {
      unchanged += 1;
      printPreview(product, copy, '변경 없음');
      continue;
    }
    targets.push({ product, copy });
    printPreview(product, copy, applyChanges ? '반영 예정' : '미리보기');
  }

  console.log('\n────────────────────────────────────────');
  console.log(`기성품 조회: ${readyMade.length}개`);
  console.log(`갱신 대상: ${targets.length}개`);
  console.log(`변경 없음: ${unchanged}개`);
  console.log(`잠김 처리: ${locked}개`);

  if (!applyChanges) {
    console.log('\n미리보기만 완료했습니다. 내용을 확인한 뒤 실제 저장하려면 --apply 옵션을 추가해 다시 실행해 주세요.');
    return;
  }

  for (let start = 0; start < targets.length; start += 400) {
    const batch = db.batch();
    for (const { product, copy } of targets.slice(start, start + 400)) {
      batch.update(db.collection('products').doc(product.id), {
        ...copy,
        editorialUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  console.log(`\n완료: ${targets.length}개 기성품의 에디토리얼 카피를 Firestore에 저장했습니다.`);
  console.log('참고: Firestore 문서에 editorialLocked=true를 저장한 상품은 이후 일괄 갱신에서 보호됩니다.');
}

main().catch((error) => {
  console.error(`\n[실패] ${error.message}`);
  process.exitCode = 1;
});
