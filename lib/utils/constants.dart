class AppConstants {
  // App Info
  static const String appName = '2FIT MALL';
  static const String appVersion = '1.0.2';
  static const String companyName = '2FIT Korea Co., Ltd.'; // ✏️ 사업자 등록 후 실제 상호로 교체
  static const String copyright = '© 2024 2FIT Korea. All rights reserved.';
  
  // Contact
  static const String customerServicePhone = '010-7227-6914';
  static const String eliteAthletePhone = '010-7227-6914';
  static const String customerServiceEmail = 'chw243527@gmail.com';
  static const String kakaoTalkId = '@2fitkorea';
  static const String customerServiceHours =
      '평일 10:00 - 18:00 (점심 12:00 - 14:00)\n토요일 · 일요일 · 공휴일 휴무';
  
  // Order Rules
  static const int groupOrderMinCount = 5;
  static const int additionalOrderDays = 7;
  static const String cancellationPolicy = '결제 후 1시간 이내 취소/변경 가능';
  
  // Shipping
  static const String freeShippingText = '무료배송';
  static const String standardShippingText = '일반배송';
  static const double freeShippingThreshold = 300000; // 30만원 이상 무료배송
  static const double standardShippingFee = 3000;     // 기본 배송비 3,000원
  
  // Categories
  static const List<String> categories = [
    '전체',
    '상의',
    '하의',
    '세트',
    '아우터',
    '스킨슈트',
    '악세사리',
    '이벤트',
  ];
  
  // Sort Options
  static const List<String> sortOptions = [
    '최신순',
    '가격 낮은 순',
    '가격 높은 순',
    '인기순',
  ];
  
  // Size Options
  // 성인 사이즈: S~XL (기본 범위, 요구사항: S부터 XL까지)
  static const List<String> adultSizes = ['S', 'M', 'L', 'XL'];
  // 주니어 사이즈: S~XL (요구사항: 주니어 s부터 xl까지)
  static const List<String> juniorSizes = ['S', 'M', 'L', 'XL'];
  
  // Color Options
  static const Map<String, int> colorOptions = {
    'Black': 0xFF1A1A1A,
    'White': 0xFFF5F5F5,
    'Gray': 0xFF9E9E9E,
    'Navy': 0xFF1A237E,
    'Red': 0xFFE53935,
    'Blue': 0xFF1E88E5,
    'Green': 0xFF43A047,
    'Pink': 0xFFE91E63,
    'Yellow': 0xFFFFD600,
    'Purple': 0xFF7B1FA2,
    'Orange': 0xFFFF6B35,
    'Brown': 0xFF795548,
  };
  
  // Payment Methods
  static const List<String> paymentMethods = [
    '카카오페이',
    '신용/체크카드',
    '무통장입금',
    '네이버페이',
    '토스페이',
  ];
  
  // Waistband Options
  static const List<Map<String, dynamic>> waistbandOptions = [
    {'name': '기본 허리밴드', 'price': 0},
    {'name': '로고 허리밴드', 'price': 3000},
    {'name': '와이드 허리밴드', 'price': 5000},
    {'name': '커스텀 허리밴드', 'price': 8000},
  ];

  // Product Nylon/Spandex Material
  static const String defaultMaterial = '78% Nylon, 22% Spandex / 4-way Stretch';

  // ── 2FIT 등록 색상 팔레트 (사진 기반) ──
  static const List<Map<String, dynamic>> twoFitColors = [
    {'name': '블랙',       'nameEn': 'Black',      'hex': 0xFF1A1A1A},
    {'name': '화이트',     'nameEn': 'White',      'hex': 0xFFF5F5F5},
    {'name': '챠콜',       'nameEn': 'Charcoal',   'hex': 0xFF3C3C3C},
    {'name': '라이트그레이','nameEn': 'Lt.Gray',    'hex': 0xFFBDBDBD},
    {'name': '네이비',     'nameEn': 'Navy',       'hex': 0xFF0D1B4F},
    {'name': '로얄블루',   'nameEn': 'Royal Blue', 'hex': 0xFF1245A8},
    {'name': '스카이블루', 'nameEn': 'Sky Blue',   'hex': 0xFF3FA9F5},
    {'name': '민트',       'nameEn': 'Mint',       'hex': 0xFF26C9A0},
    {'name': '다크그린',   'nameEn': 'D.Green',    'hex': 0xFF1B4332},
    {'name': '그린',       'nameEn': 'Green',      'hex': 0xFF43A047},
    {'name': '레드',       'nameEn': 'Red',        'hex': 0xFFCC0000},
    {'name': '버건디',     'nameEn': 'Burgundy',   'hex': 0xFF6D0E19},
    {'name': '핑크',       'nameEn': 'Pink',       'hex': 0xFFEE82A2},
    {'name': '라이트핑크', 'nameEn': 'Lt.Pink',    'hex': 0xFFF8BBD0},
    {'name': '퍼플',       'nameEn': 'Purple',     'hex': 0xFF7B1FA2},
    {'name': '오렌지',     'nameEn': 'Orange',     'hex': 0xFFFF6B35},
    {'name': '옐로우',     'nameEn': 'Yellow',     'hex': 0xFFFFD600},
    {'name': '골드',       'nameEn': 'Gold',       'hex': 0xFFD4AF37},
    {'name': '카키',       'nameEn': 'Khaki',      'hex': 0xFF7D7C48},
    {'name': '브라운',     'nameEn': 'Brown',      'hex': 0xFF795548},
    {'name': '베이지',     'nameEn': 'Beige',      'hex': 0xFFF5E6C8},
    {'name': '아이보리',   'nameEn': 'Ivory',      'hex': 0xFFFFFBEA},
    {'name': '실버',       'nameEn': 'Silver',     'hex': 0xFFC0C0C0},
    {'name': '형광그린',   'nameEn': 'Neon Green', 'hex': 0xFF39FF14},
    {'name': '형광핑크',   'nameEn': 'Neon Pink',  'hex': 0xFFFF1493},
    {'name': '형광옐로우', 'nameEn': 'Neon Yellow','hex': 0xFFFFFF00},
    {'name': '네온오렌지', 'nameEn': 'Neon Orange','hex': 0xFFFF5F00},
    {'name': '코발트',     'nameEn': 'Cobalt',     'hex': 0xFF0047AB},
    {'name': '라벤더',     'nameEn': 'Lavender',   'hex': 0xFFE6CCFF},
    {'name': '피치',       'nameEn': 'Peach',      'hex': 0xFFFFCBA4},
  ];

  // ── 성인 사이즈 조건표 ──
  static const List<Map<String, String>> adultSizeChart = [
    {'size': 'XS(85)',  'height': '154~159', 'weight': '44~51',  'chest': '85',  'waist': '26~28'},
    {'size': 'S(90)',   'height': '160~165', 'weight': '52~60',  'chest': '90',  'waist': '28~30'},
    {'size': 'M(95)',   'height': '166~172', 'weight': '61~71',  'chest': '95',  'waist': '30~32'},
    {'size': 'L(100)',  'height': '172~177', 'weight': '72~78',  'chest': '100', 'waist': '32~34'},
    {'size': 'XL(105)', 'height': '177~182', 'weight': '79~85',  'chest': '105', 'waist': '34~36'},
    {'size': '2XL(110)','height': '182~187', 'weight': '86~91',  'chest': '110', 'waist': '36~38'},
    {'size': '3XL(115)','height': '187~191', 'weight': '91~96',  'chest': '115', 'waist': '38~40'},
  ];

  // ── 주니어 사이즈 조건표 ──
  static const List<Map<String, String>> juniorSizeChart = [
    {'size': 'J-S(60)',  'height': '112~117', 'weight': '19~21', 'age': '6~7세'},
    {'size': 'J-M(65)',  'height': '118~122', 'weight': '22~24', 'age': '7~8세'},
    {'size': 'J-L(70)',  'height': '123~133', 'weight': '25~28', 'age': '8~9세'},
    {'size': 'J-XL(75)', 'height': '130~139', 'weight': '26~34', 'age': '10~11세'},
    {'size': 'J-2XL(80)','height': '140~153', 'weight': '35~43', 'age': ''},
  ];

  // ── 하의 길이 옵션 ──
  static const List<Map<String, String>> bottomLengths = [
    {'label': '9부',   'desc': '~95cm', 'eng': '9/10 length'},
    {'label': '5부',   'desc': '~55cm', 'eng': '5/10 length'},
    {'label': '4부',   'desc': '~47cm', 'eng': '4/10 length'},
    {'label': '3부',   'desc': '~37cm', 'eng': '3/10 length'},
    {'label': '2.5부', 'desc': '~30cm', 'eng': 'Short'},
    {'label': '숏쇼츠','desc': '~23cm', 'eng': 'Short Shorts'},
  ];

  // ── 단체 맞춤 할인 정책 ──
  static const Map<int, int> groupDiscounts = {30: 5, 50: 10};
  static const int groupMinFreeShipping = 5;
  static const int groupAdditionalShippingFee = 4000;
  static const int waistbandExtraPrice = 60000; // 구버전 호환용 (미사용)

  // ── 허리밴드 변경 옵션 (3가지) ──
  static const int waistbandNamePrice    = 50000; // 단체명 변경만
  static const int waistbandColorPrice   = 50000; // 색상 변경만
  static const int waistbandBothPrice    = 70000; // 단체명 + 색상 변경

  // ── 하의 길이별 추가 비용 ──
  // 9부(기본)는 추가 비용 없음, 그 외 길이는 추가 비용 발생
  static const Map<String, int> bottomLengthPrices = {
    '9부':    0,
    '5부':    0,
    '4부':    0,
    '3부':    0,
    '2.5부':  0,
    '숏쇼츠':  0,
  };

  // ── 원단 소재 (심리스/일반) 선택 옵션 ──
  // 단체커스텀: 심리스(무봉제) / 일반(봉제) 선택 가능
  // 기성품: 일반(봉제)만 가능
  static const List<String> fabricTypes = [
    '일반 (봉제)',
    '심리스 (무봉제)',
  ];

  // ── 무게 선택 옵션 ──
  static const List<String> fabricWeights = ['80g', '90g'];
  static const String defaultFabricWeight = '80g';

  // ── 원단 타입별 추가 비용 ──
  static const Map<String, int> fabricTypePrices = {
    '일반 (봉제)':      0,
    '심리스 (무봉제)': 10000,
  };

  // ── 메인 카테고리 목록 ──
  static const List<String> mainCategories = [
    '상의', '하의', '세트', '아우터', '스킨슈트', '악세사리', '이벤트',
  ];

  // ── 카테고리별 서브카테고리 맵 ──
  static const Map<String, List<String>> subCategoryMap = {
    '상의': [
      '싱글렛 A타입', '싱글렛 B타입', '라운드 반팔티', '크롭탑',
      '롱 슬리브', '맨투맨', '후드집업', '카라티',
    ],
    '하의': ['타이즈', '트레이닝바지', '반바지'],
    '세트': ['싱글렛 A타입세트', '트레이닝세트'],
    '아우터': ['바람막이', '트레이닝집업', '다운패딩', '다운조끼패딩', '롱패딩'],
    '스킨슈트': ['스킨슈트'],
    '악세사리': ['모자', '백팩'],
    '이벤트': ['이벤트'],
  };

  // ── 타이즈 하위 카테고리 (하의 길이별) ──
  static const List<String> tightsSubCategories = [
    '9부', '5부', '4부', '3부', '2.5부', '숏쇼츠',
  ];

  // ── 커스텀 주문 가능 상품 카테고리 ──
  static const List<String> customOrderCategories = [
    '상의', '하의', '세트', '아우터', '스킨슈트',
  ];

  // ── 기성품 구매 가능 카테고리 (모든 카테고리) ──
  static const List<String> readyMadeCategories = [
    '상의', '하의', '세트', '아우터', '스킨슈트', '악세사리', '이벤트',
  ];

  // ── 허리밴드 팀명 인쇄 가능 여부 ──
  // 단체주문 시 허리밴드에 팀명 인쇄 가능 (추가 비용)
  static const int waistbandTeamNamePrice = 6000; // 1인당

  // ── 하의 길이 선택 제약 ──
  // 싱글렛세트는 성별로 자동고정
  static const List<String> bottomLengthCategories = ['싱글렛 A타입', '싱글렛 B타입']; // 상의>싱글렛 타입

  // 타이즈는 선택한 하위카테고리(길이)를 그대로 사용
  static const Map<String, List<String>> productLengthRestrictions = {
    '타이즈': ['9부', '5부', '4부', '3부', '2.5부', '숏쇼츠'],
  };

  // ── 기성품 색상 K/PP 기본 색상 (추가비용 없음) ──
  static const List<String> freeColors = ['K (블랙)', 'PP (퍼플네이비)']; // K/PP 기본 색상 (추가비용 없음)
  static const int extraColorPrice = 20000; // K/PP 외 색상 추가비용

  // ── 단체 커스텀 주문 디자인 확정 기한 ──
  // 주문 후 2-3일 이내 수정요청 없으면 디자인 확정 → 제작 시작
  static const int customOrderDesignConfirmDays = 3;
  static const int customOrderModifyDays = 7; // 주문 후 7일(1주)

  // ── 단체 커스텀 주문 자동 확정 기한 ──
  static const int customOrderAutoConfirmDays = 14; // 주문 후 14일 자동 확정
}
