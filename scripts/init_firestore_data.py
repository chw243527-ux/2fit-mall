#!/usr/bin/env python3
"""
2FIT MALL - Firebase Firestore 초기 데이터 설정 스크립트
=======================================================
실행 전 필수 조건:
1. Firebase Console에서 Firestore Database 생성
2. Admin SDK JSON 키 파일 경로 설정 (FIREBASE_ADMIN_KEY_PATH)
3. pip install firebase-admin==7.1.0

실행 방법:
  python3 scripts/init_firestore_data.py
"""

import sys
import os
import json
import datetime

# Admin SDK 키 파일 경로 설정
FIREBASE_ADMIN_KEY_PATH = '/opt/flutter/firebase-admin-sdk.json'

# ───────────────────────────────────────────────────────────
# Firebase 초기화
# ───────────────────────────────────────────────────────────
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin 패키지 로드 완료")
except ImportError:
    print("❌ firebase-admin 패키지가 없습니다.")
    print("   실행: pip install firebase-admin==7.1.0")
    sys.exit(1)

if not os.path.exists(FIREBASE_ADMIN_KEY_PATH):
    print(f"❌ Admin SDK 키 파일이 없습니다: {FIREBASE_ADMIN_KEY_PATH}")
    print("")
    print("키 파일 발급 방법:")
    print("1. https://console.firebase.google.com 접속")
    print("2. 프로젝트(fit-mall) 선택")
    print("3. 프로젝트 설정 → 서비스 계정 탭")
    print("4. 'Python' 선택 후 '새 비공개 키 생성' 클릭")
    print("5. 다운로드된 JSON 파일을 /opt/flutter/firebase-admin-sdk.json 으로 저장")
    sys.exit(1)

cred = credentials.Certificate(FIREBASE_ADMIN_KEY_PATH)
try:
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase 연결 성공 (fit-mall 프로젝트)")
except Exception as e:
    print(f"❌ Firebase 연결 실패: {e}")
    print("Firestore Database를 먼저 생성해주세요:")
    print("https://console.firebase.google.com/project/fit-mall/firestore")
    sys.exit(1)

# ───────────────────────────────────────────────────────────
# 상품 데이터 (20개)
# ───────────────────────────────────────────────────────────
PRODUCTS = [
    {
        'id': 'p001',
        'name': '2FIT 라운드넥 티셔츠',
        'category': '상의',
        'subCategory': '반팔티',
        'price': 35000,
        'originalPrice': 45000,
        'description': '고품질 나일론/스판덱스 소재의 라운드넥 티셔츠. 4-way 스트레치로 최상의 활동성.',
        'images': [
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600',
            'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Black', 'White', 'Navy', 'Gray'],
        'material': '78% Nylon, 22% Spandex / 4-way Stretch',
        'isNew': True,
        'isSale': True,
        'isFreeShipping': True,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.8,
        'reviewCount': 124,
        'stockCount': 50,
        'nameTranslations': {'en': '2FIT Round Neck T-Shirt', 'ja': '2FIT ラウンドネックTシャツ', 'zh': '2FIT 圆领T恤', 'mn': '2FIT Тойрог захтай цамц'},
        'descriptionTranslations': {
            'en': 'Round neck T-shirt made from high-quality nylon/spandex fabric. 4-way stretch for maximum mobility.',
            'ja': '高品質ナイロン/スパンデックス素材のラウンドネックTシャツ。4ウェイストレッチで最高の動きやすさ。',
            'zh': '采用高品质尼龙/氨纶面料的圆领T恤。4向弹力设计，提供最佳活动性。',
            'mn': 'Өндөр чанарын нейлон/спандекс даавуугаар хийсэн тойрог захтай цамц.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=3),
    },
    {
        'id': 'p002',
        'name': '2FIT 크롭 탑',
        'category': '상의',
        'subCategory': '크롭탑',
        'price': 28000,
        'originalPrice': None,
        'description': '슬림핏 크롭 탑. 러닝, 요가, 헬스 등 다양한 운동에 최적.',
        'images': [
            'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=600',
            'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'colors': ['Black', 'White', 'Pink', 'Navy'],
        'material': '78% Nylon, 22% Spandex / 4-way Stretch',
        'isNew': True,
        'isSale': False,
        'isFreeShipping': False,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.6,
        'reviewCount': 87,
        'stockCount': 35,
        'nameTranslations': {'en': '2FIT Crop Top', 'ja': '2FIT クロップトップ', 'zh': '2FIT 运动短上衣', 'mn': '2FIT Кроп топ'},
        'descriptionTranslations': {
            'en': 'Slim-fit crop top. Perfect for running, yoga, fitness and various activities.',
            'ja': 'スリムフィットクロップトップ。ランニング、ヨガ、フィットネスなど様々な運動に最適。',
            'zh': '修身短款上衣。非常适合跑步、瑜伽、健身等各种运动。',
            'mn': 'Нарийн тохиромжтой кроп топ.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=5),
    },
    {
        'id': 'p003',
        'name': '2FIT 후드 집업',
        'category': '상의',
        'subCategory': '후드',
        'price': 65000,
        'originalPrice': 80000,
        'description': '따뜻한 후드 집업. 운동 전후 착용에 최적화된 디자인.',
        'images': [
            'https://images.unsplash.com/photo-1556821840-3a63f15732ce?w=600',
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
        ],
        'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Black', 'Gray', 'Navy'],
        'material': '78% Nylon, 22% Spandex / 4-way Stretch',
        'isNew': False,
        'isSale': True,
        'isFreeShipping': True,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.7,
        'reviewCount': 56,
        'stockCount': 20,
        'nameTranslations': {'en': '2FIT Hoodie Zip-Up', 'ja': '2FIT フードジップアップ', 'zh': '2FIT 连帽拉链衫', 'mn': '2FIT Худдтай зипп хувцас'},
        'descriptionTranslations': {
            'en': 'Warm hoodie zip-up. Design optimized for before and after workout.',
            'ja': '温かいフードジップアップ。運動前後の着用に最適化されたデザイン。',
            'zh': '温暖的连帽拉链衫。专为运动前后穿着而优化设计。',
            'mn': 'Дулаан худдтай зипп хувцас.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=10),
    },
    {
        'id': 'p005',
        'name': '2FIT 싱글렛 A타입',
        'category': '상의',
        'subCategory': '싱글렛',
        'price': 22000,
        'originalPrice': None,
        'description': '통기성 극대화 싱글렛. 마라톤, 트라이애슬론에 최적.',
        'images': [
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'colors': ['Black', 'White', 'Red', 'Blue'],
        'material': '78% Nylon, 22% Spandex / 4-way Stretch',
        'isNew': True,
        'isSale': False,
        'isFreeShipping': False,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.9,
        'reviewCount': 210,
        'stockCount': 80,
        'nameTranslations': {'en': '2FIT Singlet Type-A', 'ja': '2FIT シングレット Aタイプ', 'zh': '2FIT 背心A型', 'mn': '2FIT Сингулет А загвар'},
        'descriptionTranslations': {
            'en': 'Maximum breathability singlet. Ideal for marathons and triathlons.',
            'ja': '通気性を最大化したシングレット。マラソン・トライアスロンに最適。',
            'zh': '透气性最大化背心。适合马拉松、铁人三项。',
            'mn': 'Агаар нэвтрэх чадварыг дээд зэргээр нэмэгдүүлсэн.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=1),
    },
    {
        'id': 'p007',
        'name': '2FIT 트레이닝 팬츠',
        'category': '하의',
        'subCategory': '트레이닝 팬츠',
        'price': 52000,
        'originalPrice': None,
        'description': '편안한 착용감의 트레이닝 팬츠. 실내외 운동 모두 적합.',
        'images': [
            'https://images.unsplash.com/photo-1547496502-affa22d38842?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Black', 'Gray', 'Navy'],
        'material': '78% Nylon, 22% Spandex / 4-way Stretch',
        'isNew': False,
        'isSale': False,
        'isFreeShipping': True,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.7,
        'reviewCount': 98,
        'stockCount': 40,
        'nameTranslations': {'en': '2FIT Training Pants', 'ja': '2FIT トレーニングパンツ', 'zh': '2FIT 训练裤', 'mn': '2FIT Дасгалын өмд'},
        'descriptionTranslations': {
            'en': 'Comfortable training pants. Suitable for both indoor and outdoor sports.',
            'ja': '快適な着心地のトレーニングパンツ。室内外どちらの運動にも適しています。',
            'zh': '穿着舒适的训练裤。适合室内外运动。',
            'mn': 'Тав тухтай дасгалын өмд.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=8),
    },
    {
        'id': 'p008',
        'name': '2FIT 반바지',
        'category': '하의',
        'subCategory': '반바지',
        'price': 32000,
        'originalPrice': None,
        'description': '가볍고 시원한 스포츠 반바지. 러닝, 축구에 최적화.',
        'images': [
            'https://images.unsplash.com/photo-1591195853828-11db59a44f43?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Black', 'White', 'Navy', 'Red'],
        'material': '78% Nylon, 22% Spandex / 4-way Stretch',
        'isNew': True,
        'isSale': False,
        'isFreeShipping': False,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.6,
        'reviewCount': 75,
        'stockCount': 55,
        'nameTranslations': {'en': '2FIT Shorts', 'ja': '2FIT ショートパンツ', 'zh': '2FIT 短裤', 'mn': '2FIT Шорт'},
        'descriptionTranslations': {
            'en': 'Lightweight and cool sports shorts. Optimized for running and football.',
            'ja': '軽くて涼しいスポーツショートパンツ。',
            'zh': '轻盈凉爽的运动短裤。',
            'mn': 'Хөнгөн, сэрүүн спортын шорт.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=2),
    },
    {
        'id': 'p009',
        'name': '2FIT 롱 레깅스',
        'category': '하의',
        'subCategory': '레깅스',
        'price': 45000,
        'originalPrice': None,
        'description': '발목까지 오는 풀 레깅스. 압박감과 신축성의 완벽한 밸런스.',
        'images': [
            'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'colors': ['Black', 'Navy', 'Gray', 'Purple'],
        'material': '80% Nylon, 20% Spandex',
        'isNew': True,
        'isSale': False,
        'isFreeShipping': True,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.9,
        'reviewCount': 187,
        'stockCount': 70,
        'nameTranslations': {'en': '2FIT Long Leggings', 'ja': '2FIT ロングレギンス', 'zh': '2FIT 长款紧身裤', 'mn': '2FIT Урт легинс'},
        'descriptionTranslations': {
            'en': 'Full-length ankle leggings. Perfect balance of compression and elasticity.',
            'ja': '足首までのフルレギンス。圧迫感と伸縮性の完璧なバランス。',
            'zh': '全长及踝紧身裤。压缩感与弹性的完美平衡。',
            'mn': 'Бүтэн урт шагайны легинс.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=1),
    },
    {
        'id': 'p012',
        'name': '2FIT 크롭탑+숏레깅스 세트',
        'category': '세트',
        'subCategory': '세트',
        'price': 58000,
        'originalPrice': 70000,
        'description': '크롭탑과 숏 레깅스의 매칭 세트. 요가, 필라테스 최적.',
        'images': [
            'https://images.unsplash.com/photo-1518459031867-a89b944bffe4?w=600',
            'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'colors': ['Black', 'Navy', 'Pink'],
        'material': '78% Nylon, 22% Spandex / 4-way Stretch',
        'isNew': True,
        'isSale': True,
        'isFreeShipping': True,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.8,
        'reviewCount': 92,
        'stockCount': 35,
        'nameTranslations': {'en': '2FIT Crop Top + Short Leggings Set', 'ja': '2FIT クロップトップ＋ショートレギンスセット', 'zh': '2FIT 短款上衣+短紧身裤套装', 'mn': '2FIT Богиносгосон топ + богино легинс иж бүрдэл'},
        'descriptionTranslations': {
            'en': 'Matching set of crop top and short leggings. Ideal for yoga and Pilates.',
            'ja': 'クロップトップとショートレギンスのマッチングセット。ヨガ・ピラティスに最適。',
            'zh': '短款上衣和短紧身裤的配套套装。适合瑜伽和普拉提。',
            'mn': 'Богиносгосон топ болон богино легинсийн иж бүрдэл.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=4),
    },
    {
        'id': 'p015',
        'name': '2FIT 바람막이 자켓',
        'category': '아우터',
        'subCategory': '자켓',
        'price': 89000,
        'originalPrice': None,
        'description': '방풍·방수 기능의 경량 바람막이. 러닝, 하이킹에 최적.',
        'images': [
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
        ],
        'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Black', 'Navy', 'Red'],
        'material': '100% Polyester / Windproof & Waterproof',
        'isNew': False,
        'isSale': False,
        'isFreeShipping': True,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.8,
        'reviewCount': 67,
        'stockCount': 20,
        'nameTranslations': {'en': '2FIT Windbreaker Jacket', 'ja': '2FIT ウィンドブレーカー', 'zh': '2FIT 防风夹克', 'mn': '2FIT Салхи тэсвэрлэх куртка'},
        'descriptionTranslations': {
            'en': 'Lightweight windbreaker with windproof and waterproof features.',
            'ja': '防風・防水機能の軽量ウィンドブレーカー。',
            'zh': '具有防风防水功能的轻量防风夹克。',
            'mn': 'Салхи ба усны тэсвэртэй хөнгөн куртка.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=9),
    },
    {
        'id': 'p016',
        'name': '2FIT 다운 패딩',
        'category': '아우터',
        'subCategory': '패딩',
        'price': 145000,
        'originalPrice': 180000,
        'description': '가볍고 따뜻한 다운 패딩. 겨울 아웃도어 스포츠용.',
        'images': [
            'https://images.unsplash.com/photo-1559181567-c3190100191d?w=600',
        ],
        'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Black', 'Navy', 'Gray'],
        'material': '100% Polyester / Down Fill',
        'isNew': False,
        'isSale': True,
        'isFreeShipping': True,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.9,
        'reviewCount': 33,
        'stockCount': 12,
        'nameTranslations': {'en': '2FIT Down Jacket', 'ja': '2FIT ダウンジャケット', 'zh': '2FIT 羽绒服', 'mn': '2FIT Пухан цув'},
        'descriptionTranslations': {
            'en': 'Lightweight and warm down jacket. For winter outdoor sports.',
            'ja': '軽くて暖かいダウンジャケット。冬のアウトドアスポツ用。',
            'zh': '轻便保暖羽绒服。适合冬季户外运动。',
            'mn': 'Хөнгөн, дулаан пухан цув.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=25),
    },
    {
        'id': 'p017',
        'name': '2FIT 스포츠 백팩',
        'category': '악세사리',
        'subCategory': '가방',
        'price': 68000,
        'originalPrice': None,
        'description': '20L 용량의 스포츠 전용 백팩. 노트북 수납 가능.',
        'images': [
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600',
        ],
        'sizes': ['FREE'],
        'colors': ['Black', 'Gray', 'Navy'],
        'material': '600D Polyester',
        'isNew': False,
        'isSale': False,
        'isFreeShipping': True,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.7,
        'reviewCount': 89,
        'stockCount': 30,
        'nameTranslations': {'en': '2FIT Sports Backpack', 'ja': '2FIT スポーツバックパック', 'zh': '2FIT 运动背包', 'mn': '2FIT Спортын нуруувч'},
        'descriptionTranslations': {
            'en': '20L capacity sports backpack. Laptop compatible.',
            'ja': '20L容量のスポーツ専用バックパック。',
            'zh': '20L容量运动专用背包。',
            'mn': '20Л багтаамжтай спортын нуруувч.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=6),
    },
    {
        'id': 'p018',
        'name': '2FIT 스포츠 양말 (3켤레)',
        'category': '악세사리',
        'subCategory': '양말',
        'price': 15000,
        'originalPrice': None,
        'description': '땀 흡수·속건성 스포츠 양말 3켤레 세트.',
        'images': [
            'https://images.unsplash.com/photo-1586350977771-b3b0abd50c82?w=600',
        ],
        'sizes': ['M(250~265)', 'L(270~285)'],
        'colors': ['White', 'Black', 'Gray'],
        'material': '80% Cotton, 15% Nylon, 5% Spandex',
        'isNew': True,
        'isSale': False,
        'isFreeShipping': False,
        'isGroupOnly': False,
        'isActive': True,
        'rating': 4.5,
        'reviewCount': 156,
        'stockCount': 100,
        'nameTranslations': {'en': '2FIT Sports Socks (3 pairs)', 'ja': '2FIT スポーツソックス（3足）', 'zh': '2FIT 运动袜（3双）', 'mn': '2FIT Спортын оймс (3 хос)'},
        'descriptionTranslations': {
            'en': 'Sweat-absorbing quick-dry sports socks set of 3 pairs.',
            'ja': '汗吸収・速乾スポーツソックス3足セット。',
            'zh': '吸汗速干运动袜3双套装。',
            'mn': 'Хөлс шингээх, хурдан хатдаг спортын оймс 3 хос.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=2),
    },
    # 단체주문 전용
    {
        'id': 'group_singlet_set',
        'name': '2FIT 싱글렛 A타입 세트 (단체)',
        'category': '단체주문',
        'subCategory': '싱글렛 A타입세트',
        'price': 58000,
        'originalPrice': 75000,
        'description': '싱글렛 A타입 + 하의 세트. 마라톤·트라이애슬론 팀 단체 제작 전용. 5명 이상 주문 가능.',
        'images': [
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Black', 'Navy', 'Red', 'White', 'Purple', 'Sky Blue'],
        'material': '82% Polyester, 18% Spandex',
        'isNew': True,
        'isSale': True,
        'isFreeShipping': True,
        'isGroupOnly': True,
        'isActive': True,
        'rating': 4.9,
        'reviewCount': 156,
        'stockCount': 500,
        'nameTranslations': {'en': '2FIT Singlet Type-A Set (Group)', 'ja': '2FIT シングレット Aタイプセット（団体）', 'zh': '2FIT 背心A型套装（团体）', 'mn': '2FIT Сингулет А загвар иж бүрдэл (Бүлэг)'},
        'descriptionTranslations': {
            'en': 'Singlet Type-A + Bottom Set. Exclusively for marathon/triathlon team group orders. Minimum 5 people.',
            'ja': 'シングレット Aタイプ＋ボトムセット。マラソン・トライアスロンチームの団体製作専用。5名以上から注文可能。',
            'zh': '背心A型+下装套装。专为马拉松·铁人三项团体定制。最少5人起订。',
            'mn': 'Сингулет А загвар + Доод хэсгийн иж бүрдэл. 5-аас дээш хүн захиалах боломжтой.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=1),
    },
    {
        'id': 'group_tights',
        'name': '2FIT 타이즈 (단체)',
        'category': '단체주문',
        'subCategory': '타이즈',
        'price': 45000,
        'originalPrice': 58000,
        'description': '고탄성 4-way 스트레치 타이즈. 압박감과 신축성의 완벽한 밸런스. 단체 제작 전용.',
        'images': [
            'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600',
        ],
        'sizes': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
        'colors': ['Black', 'Navy', 'Red', 'White', 'Purple', 'Gray'],
        'material': '80% Nylon, 20% Spandex',
        'isNew': False,
        'isSale': True,
        'isFreeShipping': True,
        'isGroupOnly': True,
        'isActive': True,
        'rating': 4.8,
        'reviewCount': 203,
        'stockCount': 500,
        'nameTranslations': {'en': '2FIT Tights (Group)', 'ja': '2FIT タイツ（団体）', 'zh': '2FIT 紧身裤（团体）', 'mn': '2FIT Таайтс (Бүлэг)'},
        'descriptionTranslations': {
            'en': 'High-elasticity 4-way stretch tights. For group orders only.',
            'ja': '高弾性4ウェイストレッチタイツ。団体製作専用。',
            'zh': '高弹4向拉伸紧身裤。仅限团体定制。',
            'mn': 'Өндөр уян хатан 4 чиглэлтэй стретч таайтс. Зөвхөн бүлгийн захиалгад.',
        },
        'sectionImages': {},
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=3),
    },
]

# ───────────────────────────────────────────────────────────
# 공지사항 (notices)
# ───────────────────────────────────────────────────────────
NOTICES = [
    {
        'id': 'notice_001',
        'title': '🎉 2FIT 봄 시즌 SALE 시작!',
        'content': '봄 시즌 최대 40% 할인 이벤트가 시작되었습니다. 3만원 이상 구매 시 무료배송!',
        'isActive': True,
        'startDate': datetime.datetime.now().isoformat(),
        'endDate': (datetime.datetime.now() + datetime.timedelta(days=30)).isoformat(),
        'createdAt': datetime.datetime.now(),
    },
    {
        'id': 'notice_002',
        'title': '단체주문 안내',
        'content': '5명 이상 단체주문 시 추가 할인 및 무료 배송 혜택을 드립니다. 카카오톡 @2fitkorea로 문의주세요.',
        'isActive': True,
        'startDate': datetime.datetime.now().isoformat(),
        'endDate': (datetime.datetime.now() + datetime.timedelta(days=365)).isoformat(),
        'createdAt': datetime.datetime.now(),
    },
]

# ───────────────────────────────────────────────────────────
# 쿠폰 (coupons)
# ───────────────────────────────────────────────────────────
COUPONS = [
    {
        'id': 'WELCOME2FIT',
        'code': 'WELCOME2FIT',
        'name': '신규 회원 10% 할인',
        'discountType': 'percent',
        'discountValue': 10,
        'minOrderAmount': 30000,
        'maxDiscountAmount': 20000,
        'isActive': True,
        'usageLimit': 1000,
        'usedCount': 0,
        'expiryDate': (datetime.datetime.now() + datetime.timedelta(days=365)).isoformat(),
        'createdAt': datetime.datetime.now(),
    },
    {
        'id': 'SPRING2024',
        'code': 'SPRING2024',
        'name': '봄 시즌 5,000원 할인',
        'discountType': 'fixed',
        'discountValue': 5000,
        'minOrderAmount': 50000,
        'maxDiscountAmount': 5000,
        'isActive': True,
        'usageLimit': 500,
        'usedCount': 0,
        'expiryDate': (datetime.datetime.now() + datetime.timedelta(days=60)).isoformat(),
        'createdAt': datetime.datetime.now(),
    },
    {
        'id': 'GROUP5PLUS',
        'code': 'GROUP5PLUS',
        'name': '단체주문 15% 추가 할인',
        'discountType': 'percent',
        'discountValue': 15,
        'minOrderAmount': 200000,
        'maxDiscountAmount': 50000,
        'isActive': True,
        'usageLimit': 100,
        'usedCount': 0,
        'expiryDate': (datetime.datetime.now() + datetime.timedelta(days=180)).isoformat(),
        'createdAt': datetime.datetime.now(),
    },
]

# ───────────────────────────────────────────────────────────
# 관리자 계정 초기 설정
# ───────────────────────────────────────────────────────────
ADMIN_USER = {
    'uid': 'admin_2fit',
    'email': 'admin@2fitkorea.com',
    'name': '2FIT 관리자',
    'phone': '010-4386-3331',
    'grade': 'admin',
    'isAdmin': True,
    'isActive': True,
    'point': 0,
    'totalOrderAmount': 0,
    'orderCount': 0,
    'address': {
        'zonecode': '06234',
        'address': '서울특별시 강남구 테헤란로 123',
        'detailAddress': '2FIT Korea 본사',
    },
    'createdAt': datetime.datetime.now(),
    'updatedAt': datetime.datetime.now(),
}

# ───────────────────────────────────────────────────────────
# 샘플 리뷰
# ───────────────────────────────────────────────────────────
REVIEWS = [
    {
        'id': 'review_001',
        'productId': 'p001',
        'userId': 'sample_user_001',
        'userName': '김민준',
        'rating': 5.0,
        'content': '품질이 정말 좋아요! 착용감이 부드럽고 신축성도 뛰어납니다. 마라톤 대회에서 착용했는데 매우 만족스러웠어요.',
        'images': [],
        'isActive': True,
        'helpfulCount': 12,
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=5),
    },
    {
        'id': 'review_002',
        'productId': 'p005',
        'userId': 'sample_user_002',
        'userName': '이서연',
        'rating': 5.0,
        'content': '싱글렛 최고입니다. 통기성이 탁월하고 빠른 건조력이 있어요. 팀 전체가 구매해서 좋은 결과 냈습니다!',
        'images': [],
        'isActive': True,
        'helpfulCount': 8,
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=3),
    },
    {
        'id': 'review_003',
        'productId': 'p009',
        'userId': 'sample_user_003',
        'userName': '박지우',
        'rating': 5.0,
        'content': '레깅스 사이즈가 정확하고 압박감이 적절해요. 장거리 러닝에 완벽합니다. 재구매 의사 100%!',
        'images': [],
        'isActive': True,
        'helpfulCount': 15,
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=7),
    },
    {
        'id': 'review_004',
        'productId': 'group_singlet_set',
        'userId': 'sample_user_004',
        'userName': '최현우',
        'rating': 5.0,
        'content': '마라톤 클럽 30명이 단체 주문했습니다. 품질과 디자인 모두 만족! 팀원들 전체 만족합니다.',
        'images': [],
        'isActive': True,
        'helpfulCount': 25,
        'createdAt': datetime.datetime.now() - datetime.timedelta(days=10),
    },
]


# ───────────────────────────────────────────────────────────
# 데이터 저장 함수
# ───────────────────────────────────────────────────────────
def save_products():
    print("\n📦 상품 데이터 저장 중...")
    batch = db.batch()
    count = 0
    for product in PRODUCTS:
        doc_data = dict(product)
        if doc_data.get('originalPrice') is None:
            doc_data['originalPrice'] = 0
        ref = db.collection('products').document(product['id'])
        batch.set(ref, doc_data)
        count += 1
        print(f"  ✓ {product['name']} ({product['category']})")
    batch.commit()
    print(f"✅ 상품 {count}개 저장 완료!")


def save_notices():
    print("\n📢 공지사항 저장 중...")
    batch = db.batch()
    for notice in NOTICES:
        ref = db.collection('notices').document(notice['id'])
        batch.set(ref, notice)
        print(f"  ✓ {notice['title']}")
    batch.commit()
    print("✅ 공지사항 저장 완료!")


def save_coupons():
    print("\n🎫 쿠폰 저장 중...")
    batch = db.batch()
    for coupon in COUPONS:
        ref = db.collection('coupons').document(coupon['id'])
        batch.set(ref, coupon)
        print(f"  ✓ [{coupon['code']}] {coupon['name']}")
    batch.commit()
    print("✅ 쿠폰 저장 완료!")


def save_reviews():
    print("\n⭐ 샘플 리뷰 저장 중...")
    batch = db.batch()
    for review in REVIEWS:
        ref = db.collection('reviews').document(review['id'])
        batch.set(ref, review)
        print(f"  ✓ {review['userName']} - {review['rating']}점")
    batch.commit()
    print("✅ 리뷰 저장 완료!")


def save_admin_user():
    print("\n👤 관리자 계정 설정 중...")
    db.collection('users').document(ADMIN_USER['uid']).set(ADMIN_USER)
    print(f"✅ 관리자 계정 설정 완료: {ADMIN_USER['email']}")


def set_security_rules_info():
    print("\n🔒 Firestore 보안 규칙 안내:")
    print("  Firebase Console에서 아래 명령어로 규칙을 배포하세요:")
    print("  firebase deploy --only firestore:rules")
    print("  (firebase.json과 firestore.rules 파일이 준비되어 있습니다)")


# ───────────────────────────────────────────────────────────
# 메인 실행
# ───────────────────────────────────────────────────────────
if __name__ == '__main__':
    print("=" * 60)
    print("🏃 2FIT MALL - Firebase 데이터 초기화")
    print("=" * 60)
    print(f"프로젝트: fit-mall")
    print(f"데이터 수: 상품 {len(PRODUCTS)}개, 공지 {len(NOTICES)}개, 쿠폰 {len(COUPONS)}개, 리뷰 {len(REVIEWS)}개")
    print()

    confirm = input("데이터를 Firestore에 저장하시겠습니까? (y/n): ")
    if confirm.lower() != 'y':
        print("취소되었습니다.")
        sys.exit(0)

    try:
        save_products()
        save_notices()
        save_coupons()
        save_reviews()
        save_admin_user()
        set_security_rules_info()

        print("\n" + "=" * 60)
        print("🎉 모든 데이터 초기화 완료!")
        print("=" * 60)
        print("\n다음 단계:")
        print("1. Firebase Console에서 Authentication → 이메일/비밀번호 로그인 활성화")
        print("2. Firebase Console에서 보안 규칙 배포: firebase deploy --only firestore:rules")
        print("3. FCM VAPID 키 설정 (웹 푸시 알림 필요 시)")
        print("4. 토스페이먼츠 실결제 키로 교체 (결제 서비스 실결제 전환 시)")
        print("5. 앱 배포: flutter build web --release")
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
