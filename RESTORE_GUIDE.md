# 2FIT Mall – 복원 가이드

## 백업 정보
- **프로젝트명**: 2fit-mall (2FIT 스포츠웨어 쇼핑몰)
- **배포 URL**: https://2fit-mall.co.kr
- **GitHub**: https://github.com/chw243527-ux/2fit-mall
- **기술 스택**: Flutter 3.35.4 / Dart 3.9.2 / Firebase (Firestore, Storage, Auth)
- **패키지명**: com.fitfashionshop.shop
- **백업 일시**: 2025년 3월 21일

---

## 전체 복원 절차

### 1. tar.gz 압축 해제
```bash
tar -xzf 2fit_mall_full_backup.tar.gz -C /home/user/
```
→ `/home/user/flutter_app/` 디렉토리가 생성됩니다.

### 2. Flutter 환경 확인
```bash
flutter --version   # 3.35.4 이상
dart --version      # 3.9.2 이상
```

### 3. 의존성 설치
```bash
cd /home/user/flutter_app
flutter pub get
```

### 4. Firebase 설정 파일 확인
다음 파일이 올바른지 확인하세요:
- `android/app/google-services.json` – Android Firebase 설정
- `lib/firebase_options.dart` – 멀티플랫폼 Firebase 옵션 (Web/Android)

### 5. 웹 빌드 & 실행
```bash
cd /home/user/flutter_app
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```
→ http://localhost:5060 에서 확인

### 6. GitHub Pages 배포
```bash
cd /home/user/flutter_app
flutter build web --release
echo "2fit-mall.co.kr" > build/web/CNAME

# gh-pages 브랜치로 배포
cd /tmp && mkdir ghpages && cd ghpages
git init && git checkout -b gh-pages
cp -r /home/user/flutter_app/build/web/. .
git config user.email "deploy@fitfashion.com"
git config user.name "Deploy Bot"
git add -A
git commit -m "deploy: $(date '+%Y-%m-%d %H:%M')"
git remote add origin https://[TOKEN]@github.com/chw243527-ux/2fit-mall.git
git push -f origin gh-pages
```

---

## 프로젝트 구조

```
flutter_app/
├── lib/
│   ├── main.dart                          # 앱 진입점, Firebase 초기화
│   ├── firebase_options.dart              # Firebase 멀티플랫폼 설정
│   ├── models/
│   │   └── models.dart                   # ProductModel, OrderModel, UserModel 등
│   ├── providers/
│   │   └── providers.dart                # ProductProvider, UserProvider, CartProvider 등
│   ├── services/
│   │   ├── product_service.dart          # 상품 CRUD (Firestore + 로컬캐시)
│   │   ├── order_service.dart            # 주문 관리
│   │   ├── auth_service.dart             # 인증 (이메일/구글)
│   │   ├── storage_service.dart          # Firebase Storage 이미지 업로드
│   │   ├── translation_service.dart      # 다국어 자동 번역
│   │   └── ...
│   ├── screens/
│   │   ├── admin/
│   │   │   ├── admin_screen.dart         # 관리자 대시보드 (12탭)
│   │   │   └── admin_extra_tabs.dart     # 매출통계, 재고, 직원관리
│   │   ├── home/
│   │   │   ├── home_screen.dart          # 홈 화면
│   │   │   └── splash_screen.dart        # 스플래시
│   │   ├── products/
│   │   │   ├── product_detail_screen.dart # 상품 상세 (디자인이미지 섹션 포함)
│   │   │   ├── product_list_screen.dart   # 상품 목록
│   │   │   └── category_detail_screen.dart
│   │   ├── orders/
│   │   │   ├── group_custom_order_screen.dart # 단체 커스텀 주문
│   │   │   ├── group_order_only_screen.dart   # 단체전용 상품 목록
│   │   │   ├── group_order_form_screen.dart   # 단체 주문 폼
│   │   │   └── group_order_guide_screen.dart  # 단체 주문 안내
│   │   └── ...
│   ├── widgets/
│   │   ├── app_drawer.dart               # 사이드바 (ORDERS: 단체전용상품만)
│   │   ├── pc_layout.dart                # PC 레이아웃 래퍼
│   │   └── product_card.dart             # 상품 카드
│   └── utils/
│       ├── app_localizations.dart        # 다국어 (한/영/중/몽골/러시아)
│       ├── constants.dart                # 앱 상수
│       └── theme.dart                    # 앱 테마
├── android/
│   └── app/
│       ├── build.gradle.kts              # applicationId: com.fitfashionshop.shop
│       ├── google-services.json          # Firebase Android 설정
│       └── src/main/kotlin/com/fitfashionshop/shop/MainActivity.kt
├── web/
│   └── index.html                        # 웹 진입점
├── assets/
│   ├── images/                           # 로고, 이미지
│   └── icon/app_icon.png                 # 앱 아이콘
└── pubspec.yaml                          # 의존성 정의
```

---

## 핵심 의존성 (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: 3.6.0
  cloud_firestore: 5.4.3
  firebase_storage: 12.3.2
  firebase_auth: 5.3.3
  provider: 6.1.5+1
  image_picker: 1.1.2
  shared_preferences: 2.5.3
  hive: 2.2.3
  hive_flutter: 1.1.0
  http: 1.5.0
  google_mobile_ads: 5.3.1
  webview_flutter: 4.13.0
  # ... (pubspec.yaml 전체 참조)
```

---

## Firebase 프로젝트 정보

- **Project ID**: fit-mall (firebase_options.dart 참조)
- **Storage Bucket**: fit-mall.firebasestorage.app
- **Firestore Collections**:
  - `products` – 상품 (isActive, isGroupOnly, sectionImages 등)
  - `orders` – 주문
  - `users` – 회원
  - `reviews` – 리뷰
  - `coupons` – 쿠폰
  - `points` – 포인트
  - `notices` – 공지사항
  - `banners` – 홈 배너

---

## 주요 수정 이력 (최신순)

### 2025-03-21
1. **상품삭제 hard delete** – soft delete(isActive=false) → Firestore `.delete()` 완전 삭제
2. **상품삭제 즉시 UI반영** – `_adminProducts.removeWhere()` + `notifyListeners()` 즉시 호출
3. **product_service.dart 클래스 구조 버그 수정** – `}` 중복으로 메서드들이 클래스 밖으로 밀려난 문제 수정
4. **상품관리 비활성 상품 표시** – `adminProducts` 분리 (isActive 필터 없음), `loadAdminProducts()` 추가
5. **상품수정 이미지 업로드 개선** – 진행상태/에러 메시지 다이얼로그 내 표시

### 2025-03-21 (이전)
6. **상품상세 디자인이미지 섹션** – 카테고리 위에 디자인이미지 업로드/표시 (라이트박스 확대)
7. **단체커스텀 디자인이미지** – GroupCustomOrderScreen에 선택 상품의 디자인이미지 표시
8. **사이드바 개편** – ORDERS 섹션: 단체주문서식 제거, 단체전용상품(GroupOrderOnlyScreen)만 유지
9. **GroupOrderOnlyScreen 개편** – 탭 제거, isGroupOnly=true 상품 목록만 표시
10. **단체주문 사이즈 직접입력** – 성별 무관 사이즈 입력 허용, 10인 이상만 이름 표시

---

## 관리자 계정 설정

`lib/utils/constants.dart` 또는 `lib/services/auth_service.dart`에서 관리자 이메일 목록 확인:
```dart
static const List<String> adminEmails = [
  // 실제 관리자 이메일 목록 (constants.dart 참조)
];
```

---

## 배포 자동화 스크립트

```bash
# deploy.sh – 빌드 + gh-pages 배포 자동화
chmod +x deploy.sh
./deploy.sh
```

---

## 주의사항

1. `android/app/google-services.json` – Firebase Android 설정 (민감정보, Git 주의)
2. `lib/firebase_options.dart` – API 키 포함 (민감정보, Git 주의)
3. `pubspec.lock` – 의존성 고정 버전 (함께 복원해야 동일 빌드 보장)
4. Flutter 버전은 반드시 3.35.4 사용 (`.metadata` 파일 참조)
