#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
2FIT MALL — Firebase Firestore 초기 데이터 생성 스크립트
==========================================================
사용법:
  1. Firebase Admin SDK JSON 키 파일 준비
     Firebase Console → 프로젝트 설정 → 서비스 계정 → 새 비공개 키 생성
  2. 아래 KEY_FILE 경로를 실제 경로로 변경
  3. pip install firebase-admin
  4. python3 setup_firebase_data.py
"""

import sys
import json
from datetime import datetime, timedelta

KEY_FILE = "./firebase-adminsdk.json"   # ← 실제 키 파일 경로로 변경

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("❌ firebase-admin 설치 필요: pip install firebase-admin==7.1.0")
    sys.exit(1)

# ── 초기화 ──────────────────────────────────────────────────
try:
    cred = credentials.Certificate(KEY_FILE)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase 연결 성공")
except Exception as e:
    print(f"❌ Firebase 연결 실패: {e}")
    print("   KEY_FILE 경로를 확인하세요.")
    sys.exit(1)

# ── 상품 데이터 ──────────────────────────────────────────────
PRODUCTS = [
    {
        "id": "prod_001",
        "name": "2FIT 크롭탑 세트",
        "category": "세트",
        "subCategory": "크롭탑 세트",
        "price": 170000,
        "originalPrice": 200000,
        "description": "2FIT 시그니처 크롭탑 세트. 고품질 78% Nylon + 22% Spandex 소재. 4-way 스트레치로 최상의 활동성을 제공합니다.",
        "images": [
            "https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=600&auto=format",
            "https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "W (화이트)", "NV (네이비)", "PP (퍼플네이비)"],
        "material": "78% Nylon, 22% Spandex / 4-way Stretch",
        "isNew": True,
        "isSale": True,
        "isFreeShipping": True,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.9,
        "reviewCount": 287,
        "stockCount": 100,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Crop Top Set",
            "ja": "2FIT クロップトップセット",
            "zh": "2FIT 短款上衣套装",
            "mn": "2FIT Кроп топ иж бүрдэл",
        },
    },
    {
        "id": "prod_002",
        "name": "2FT 원피스 (One-piece)",
        "category": "스킨슈트",
        "subCategory": "원피스",
        "price": 200000,
        "originalPrice": 200000,
        "description": "ONLY YOU 디자인. 맞춤 제작 스포츠웨어. 단독구매 상품으로 5명 미만도 주문 가능합니다.",
        "images": [
            "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&auto=format",
            "https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "W (화이트)", "PP (퍼플네이비)", "RD (레드)"],
        "material": "78% Nylon, 22% Spandex / 4-way Stretch",
        "isNew": True,
        "isSale": False,
        "isFreeShipping": True,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.8,
        "reviewCount": 156,
        "stockCount": 80,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT One-piece",
            "ja": "2FIT ワンピース",
            "zh": "2FIT 连体服",
            "mn": "2FIT Нэг хэсэгт хувцас",
        },
    },
    {
        "id": "prod_003",
        "name": "2FIT 반팔T",
        "category": "상의",
        "subCategory": "반팔티셔츠",
        "price": 40000,
        "originalPrice": 45000,
        "description": "ONLY YOU 디자인. 퍼포먼스와 팀 아이덴티티를 완성하는 2FIT 반팔 티셔츠.",
        "images": [
            "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&auto=format",
            "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "W (화이트)", "NV (네이비)", "GR (그레이)"],
        "material": "78% Nylon, 22% Spandex / 4-way Stretch",
        "isNew": False,
        "isSale": True,
        "isFreeShipping": False,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.7,
        "reviewCount": 423,
        "stockCount": 200,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Short-sleeve T-shirt",
            "ja": "2FIT 半袖Tシャツ",
            "zh": "2FIT 短袖T恤",
            "mn": "2FIT Богино ханцуйт цамц",
        },
    },
    {
        "id": "prod_004",
        "name": "2FIT 카라T",
        "category": "상의",
        "subCategory": "카라티셔츠",
        "price": 45000,
        "originalPrice": 50000,
        "description": "ONLY YOU 디자인. 카라 넥라인으로 세련된 스타일을 완성하세요.",
        "images": [
            "https://images.unsplash.com/photo-1534258936925-c58bed479fcb?w=600&auto=format",
            "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "W (화이트)", "NV (네이비)"],
        "material": "78% Nylon, 22% Spandex / 4-way Stretch",
        "isNew": False,
        "isSale": False,
        "isFreeShipping": False,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.6,
        "reviewCount": 198,
        "stockCount": 150,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Collar T-shirt",
            "ja": "2FIT カラーTシャツ",
            "zh": "2FIT 翻领T恤",
            "mn": "2FIT Захтай цамц",
        },
    },
    {
        "id": "prod_005",
        "name": "2FIT 레깅스",
        "category": "하의",
        "subCategory": "레깅스",
        "price": 60000,
        "originalPrice": 70000,
        "description": "ONLY YOU 디자인. 팀 퍼포먼스를 완성하는 2FIT 레깅스. 심리스 기술 적용.",
        "images": [
            "https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600&auto=format",
            "https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "NV (네이비)", "PP (퍼플네이비)"],
        "material": "78% Nylon, 22% Spandex / 4-way Stretch",
        "isNew": True,
        "isSale": False,
        "isFreeShipping": False,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.8,
        "reviewCount": 312,
        "stockCount": 120,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Leggings",
            "ja": "2FIT レギンス",
            "zh": "2FIT 紧身裤",
            "mn": "2FIT Легинс",
        },
    },
    {
        "id": "prod_006",
        "name": "2FIT PANTS",
        "category": "하의",
        "subCategory": "팬츠",
        "price": 80000,
        "originalPrice": 90000,
        "description": "ONLY YOU 디자인. 3부/4부/5부 80,000원, 9부 90,000원. 다양한 기장으로 선택하세요.",
        "images": [
            "https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&auto=format",
            "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "NV (네이비)", "GR (그레이)"],
        "material": "78% Nylon, 22% Spandex / 4-way Stretch",
        "isNew": False,
        "isSale": False,
        "isFreeShipping": False,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.5,
        "reviewCount": 145,
        "stockCount": 90,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Pants",
            "ja": "2FIT パンツ",
            "zh": "2FIT 运动裤",
            "mn": "2FIT Өмд",
        },
    },
    {
        "id": "prod_007",
        "name": "2FIT 싱글렛 세트",
        "category": "세트",
        "subCategory": "싱글렛 세트",
        "price": 130000,
        "originalPrice": 150000,
        "description": "ONLY YOU 디자인. 퍼포먼스와 팀 아이덴티티를 완성하는 싱글렛 세트.",
        "images": [
            "https://images.unsplash.com/photo-1534258936925-c58bed479fcb?w=600&auto=format",
            "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "W (화이트)", "RD (레드)", "BL (블루)"],
        "material": "78% Nylon, 22% Spandex / 4-way Stretch",
        "isNew": True,
        "isSale": False,
        "isFreeShipping": True,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.9,
        "reviewCount": 267,
        "stockCount": 60,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Singlet Set",
            "ja": "2FIT シングレットセット",
            "zh": "2FIT 背心套装",
            "mn": "2FIT Сингл малгайт иж бүрдэл",
        },
    },
    {
        "id": "prod_008",
        "name": "2FIT 단체 커스텀 유니폼",
        "category": "세트",
        "subCategory": "단체주문",
        "price": 150000,
        "originalPrice": 180000,
        "description": "5명 이상 단체주문 전용. 팀 로고/이름 커스텀 인쇄 포함. 30명 이상 5% 할인, 50명 이상 10% 할인.",
        "images": [
            "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&auto=format",
            "https://images.unsplash.com/photo-1513689125086-6c432170e843?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "W (화이트)", "NV (네이비)", "RD (레드)", "BL (블루)"],
        "material": "78% Nylon, 22% Spandex / 4-way Stretch",
        "isNew": False,
        "isSale": False,
        "isFreeShipping": True,
        "isGroupOnly": True,
        "isActive": True,
        "rating": 4.9,
        "reviewCount": 534,
        "stockCount": 999,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Group Custom Uniform",
            "ja": "2FIT グループカスタムユニフォーム",
            "zh": "2FIT 团体定制制服",
            "mn": "2FIT Багийн захиалгат дүрэмт хувцас",
        },
    },
    {
        "id": "prod_009",
        "name": "남성 5부 골지 레깅스",
        "category": "하의",
        "subCategory": "레깅스",
        "price": 60000,
        "originalPrice": 60000,
        "description": "2.5부/5부 골지 원단으로 새롭게 출시. 포근하고 신축성 좋은 소재.",
        "images": [
            "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&auto=format",
            "https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&auto=format",
        ],
        "sizes": ["S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "NV (네이비)", "GR (그레이)"],
        "material": "골지 원단",
        "isNew": True,
        "isSale": False,
        "isFreeShipping": False,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.7,
        "reviewCount": 89,
        "stockCount": 75,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "Men's 5-part Ribbed Leggings",
            "ja": "メンズ5分丈リブレギンス",
            "zh": "男士5分罗纹紧身裤",
            "mn": "Эрэгтэй 5 хэсэгтэй хавирганцар легинс",
        },
    },
    {
        "id": "prod_010",
        "name": "여성 2.5부 골지 레깅스",
        "category": "하의",
        "subCategory": "레깅스",
        "price": 60000,
        "originalPrice": 60000,
        "description": "2.5부 골지 원단으로 새롭게 출시. 포근한 원단으로 완성된 여성용 레깅스.",
        "images": [
            "https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600&auto=format",
            "https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL"],
        "colors": ["K (블랙)", "W (화이트)", "PP (퍼플네이비)"],
        "material": "골지 원단",
        "isNew": True,
        "isSale": False,
        "isFreeShipping": False,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.8,
        "reviewCount": 102,
        "stockCount": 85,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "Women's 2.5-part Ribbed Leggings",
            "ja": "レディース2.5分丈リブレギンス",
            "zh": "女士2.5分罗纹紧身裤",
            "mn": "Эмэгтэй 2.5 хэсэгтэй хавирганцар легинс",
        },
    },
    {
        "id": "prod_011",
        "name": "2FIT 아우터 재킷",
        "category": "아우터",
        "subCategory": "재킷",
        "price": 120000,
        "originalPrice": 140000,
        "description": "방풍/방수 기능성 아우터. 러닝, 사이클링 등 야외 스포츠에 최적.",
        "images": [
            "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&auto=format",
            "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "NV (네이비)", "GR (그레이)"],
        "material": "폴리에스터 100% / 방풍·방수",
        "isNew": False,
        "isSale": True,
        "isFreeShipping": True,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 4.6,
        "reviewCount": 178,
        "stockCount": 55,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Outer Jacket",
            "ja": "2FIT アウタージャケット",
            "zh": "2FIT 外套夹克",
            "mn": "2FIT Гадуур куртка",
        },
    },
    {
        "id": "prod_012",
        "name": "2FIT 스킨슈트",
        "category": "스킨슈트",
        "subCategory": "스킨슈트",
        "price": 250000,
        "originalPrice": 280000,
        "description": "엘리트 선수용 스킨슈트. 대한민국 엘리트 선수의 50~60%가 착용하는 경기복.",
        "images": [
            "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&auto=format",
            "https://images.unsplash.com/photo-1534258936925-c58bed479fcb?w=600&auto=format",
        ],
        "sizes": ["XS", "S", "M", "L", "XL", "XXL"],
        "colors": ["K (블랙)", "W (화이트)", "RD (레드)", "BL (블루)"],
        "material": "78% Nylon, 22% Spandex / 심리스 4-way Stretch",
        "isNew": True,
        "isSale": False,
        "isFreeShipping": True,
        "isGroupOnly": False,
        "isActive": True,
        "rating": 5.0,
        "reviewCount": 67,
        "stockCount": 40,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "nameTranslations": {
            "en": "2FIT Skinsuit",
            "ja": "2FIT スキンスーツ",
            "zh": "2FIT 连体紧身服",
            "mn": "2FIT Скинсьют",
        },
    },
]

# ── 쿠폰 데이터 ──────────────────────────────────────────────
COUPONS = [
    {
        "id": "coupon_welcome",
        "code": "WELCOME2FIT",
        "name": "신규 회원 할인 쿠폰",
        "type": "percent",
        "value": 10,
        "minOrderAmount": 50000,
        "maxDiscountAmount": 20000,
        "expiresAt": (datetime.now() + timedelta(days=365)).isoformat(),
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "id": "coupon_summer",
        "code": "SUMMER2025",
        "name": "2025 여름 시즌 쿠폰",
        "type": "percent",
        "value": 15,
        "minOrderAmount": 100000,
        "maxDiscountAmount": 30000,
        "expiresAt": (datetime.now() + timedelta(days=90)).isoformat(),
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
    {
        "id": "coupon_shipping",
        "code": "FREESHIP",
        "name": "무료배송 쿠폰",
        "type": "fixed",
        "value": 3000,
        "minOrderAmount": 30000,
        "maxDiscountAmount": 3000,
        "expiresAt": (datetime.now() + timedelta(days=180)).isoformat(),
        "isActive": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    },
]

# ── 공지사항 데이터 ──────────────────────────────────────────
NOTICES = [
    {
        "id": "notice_001",
        "title": "2025 S/S 신상품 출시 안내",
        "content": "2025 봄/여름 시즌 신상품이 출시되었습니다.\n크롭탑 세트, 원피스, 싱글렛 세트 등 다양한 신제품을 확인해보세요!\n\n주요 출시 상품:\n- 2FIT 크롭탑 세트 (신규)\n- 2FIT 원피스 풀 커스텀 (신규)\n- 남성/여성 골지 레깅스 (신규)",
        "isActive": True,
        "priority": 1,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "titleTranslations": {
            "en": "2025 S/S New Product Launch",
            "ja": "2025 S/S 新商品発売のお知らせ",
            "zh": "2025 春夏新品上市公告",
            "mn": "2025 зун/хавар шинэ бүтээгдэхүүн гарлаа",
        },
    },
    {
        "id": "notice_002",
        "title": "단체주문 할인 이벤트",
        "content": "단체주문 할인 혜택 안내:\n\n✅ 30명 이상: 5% 할인\n✅ 50명 이상: 10% 할인\n\n단체주문 문의: 카카오톡 @2fitkorea\n전화: 010-4386-3331",
        "isActive": True,
        "priority": 2,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "titleTranslations": {
            "en": "Group Order Discount Event",
            "ja": "団体注文割引イベント",
            "zh": "团体订单折扣活动",
            "mn": "Багийн захиалгын хямдрал",
        },
    },
]

# ── 데이터 업로드 함수 ────────────────────────────────────────
def upload_products():
    print("\n📦 상품 데이터 업로드 중...")
    batch = db.batch()
    for p in PRODUCTS:
        pid = p.pop("id")
        ref = db.collection("products").document(pid)
        batch.set(ref, p)
    batch.commit()
    print(f"   ✅ 상품 {len(PRODUCTS)}개 업로드 완료")

def upload_coupons():
    print("\n🎫 쿠폰 데이터 업로드 중...")
    batch = db.batch()
    for c in COUPONS:
        cid = c.pop("id")
        ref = db.collection("coupons").document(cid)
        batch.set(ref, c)
    batch.commit()
    print(f"   ✅ 쿠폰 {len(COUPONS)}개 업로드 완료")

def upload_notices():
    print("\n📢 공지사항 업로드 중...")
    batch = db.batch()
    for n in NOTICES:
        nid = n.pop("id")
        ref = db.collection("notices").document(nid)
        batch.set(ref, n)
    batch.commit()
    print(f"   ✅ 공지사항 {len(NOTICES)}개 업로드 완료")

def create_admin_user():
    """관리자 계정 Firestore 문서 생성 (Firebase Auth에서 계정 생성 후 UID 입력)"""
    print("\n👤 관리자 설정 안내:")
    print("   Firebase Auth에서 아래 계정으로 가입 후 Firestore에 자동 등록됩니다:")
    print("   - admin@2fitkorea.com")
    print("   - cs@2fitkorea.com")
    print("   - manager@2fit.co.kr")
    print("   앱에서 해당 이메일로 로그인하면 자동으로 관리자 권한이 부여됩니다.")

if __name__ == "__main__":
    print("=" * 60)
    print("  2FIT MALL — Firebase 초기 데이터 설정")
    print("=" * 60)

    try:
        upload_products()
        upload_coupons()
        upload_notices()
        create_admin_user()

        print("\n" + "=" * 60)
        print("  ✅ 모든 초기 데이터 업로드 완료!")
        print("=" * 60)
        print("\n다음 단계:")
        print("  1. Firebase Console → Authentication → 이메일/비밀번호 활성화")
        print("  2. Firebase Console → Firestore → 보안 규칙 업데이트")
        print("     (firestore.rules 파일 내용 복사 붙여넣기)")
        print("  3. Firebase Console → Storage → 보안 규칙 설정")
        print("  4. 앱 실행 후 회원가입/로그인 테스트")

    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
