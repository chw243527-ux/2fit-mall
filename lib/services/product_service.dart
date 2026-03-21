// product_service.dart — Firestore 기반 상품 서비스 (로컬 캐시 병행)
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ProductService {
  // ─────────────────────────────────────────────────────────────
  // 로컬 더미 상품 데이터
  // ─────────────────────────────────────────────────────────────
  static final List<ProductModel> _products = [
    ProductModel(
      id: 'p001',
      name: '2FIT 라운드넥 티셔츠',
      category: '상의',
      price: 35000,
      originalPrice: 45000,
      description: '고품질 나일론/스판덱스 소재의 라운드넥 티셔츠. 4-way 스트레치로 최상의 활동성.',
      images: [
        'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600',
        'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'White', 'Navy', 'Gray'],
      isNew: true,
      isSale: true,
      isFreeShipping: true,
      rating: 4.8,
      reviewCount: 124,
      stockCount: 50,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      nameTranslations: {
        'en': '2FIT Round Neck T-Shirt',
        'ja': '2FIT ラウンドネックTシャツ',
        'zh': '2FIT 圆领T恤',
        'mn': '2FIT Тойрог захтай цамц',
      },
      descriptionTranslations: {
        'en': 'Round neck T-shirt made from high-quality nylon/spandex fabric. 4-way stretch for maximum mobility.',
        'ja': '高品質ナイロン/スパンデックス素材のラウンドネックTシャツ。4ウェイストレッチで最高の動きやすさ。',
        'zh': '采用高品质尼龙/氨纶面料的圆领T恤。4向弹力设计，提供最佳活动性。',
        'mn': 'Өндөр чанарын нейлон/спандекс даавуугаар хийсэн тойрог захтай цамц. 4 чиглэлтэй сунах чадвартай, хөдөлгөөний чөлөө хамгийн дээд.',
      },
    ),
    ProductModel(
      id: 'p002',
      name: '2FIT 크롭 탑',
      category: '상의',
      price: 28000,
      description: '슬림핏 크롭 탑. 러닝, 요가, 헬스 등 다양한 운동에 최적.',
      images: [
        'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=600',
        'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      colors: ['Black', 'White', 'Pink', 'Navy'],
      isNew: true,
      isFreeShipping: false,
      rating: 4.6,
      reviewCount: 87,
      stockCount: 35,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      nameTranslations: {
        'en': '2FIT Crop Top',
        'ja': '2FIT クロップトップ',
        'zh': '2FIT 运动短上衣',
        'mn': '2FIT Кроп топ',
      },
      descriptionTranslations: {
        'en': 'Slim-fit crop top. Perfect for running, yoga, fitness and various activities.',
        'ja': 'スリムフィットクロップトップ。ランニング、ヨガ、フィットネスなど様々な運動に最適。',
        'zh': '修身短款上衣。非常适合跑步、瑜伽、健身等各种运动。',
        'mn': 'Нарийн тохиромжтой кроп топ. Гүйлт, йога, фитнесс болон бусад дасгалд тохиромжтой.',
      },
    ),
    ProductModel(
      id: 'p003',
      name: '2FIT 후드 집업',
      category: '상의',
      price: 65000,
      originalPrice: 80000,
      description: '따뜻한 후드 집업. 운동 전후 착용에 최적화된 디자인.',
      images: [
        'https://images.unsplash.com/photo-1556821840-3a63f15732ce?w=600',
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
      ],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Gray', 'Navy'],
      isSale: true,
      isFreeShipping: true,
      rating: 4.7,
      reviewCount: 56,
      stockCount: 20,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      nameTranslations: {
        'en': '2FIT Hoodie Zip-Up',
        'ja': '2FIT フードジップアップ',
        'zh': '2FIT 连帽拉链衫',
        'mn': '2FIT Худдтай зипп хувцас',
      },
      descriptionTranslations: {
        'en': 'Warm hoodie zip-up. Design optimized for before and after workout.',
        'ja': '温かいフードジップアップ。運動前後の着用に最適化されたデザイン。',
        'zh': '温暖的连帽拉链衫。专为运动前后穿着而优化设计。',
        'mn': 'Дулаан худдтай зипп хувцас. Дасгалын өмнө болон дараа өмсөхөд тохируулан дизайнлагдсан.',
      },
    ),
    ProductModel(
      id: 'p004',
      name: '2FIT 긴소매 티셔츠',
      category: '상의',
      price: 42000,
      description: '자외선 차단 기능이 있는 긴소매 스포츠 티셔츠.',
      images: [
        'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'White', 'Blue', 'Red'],
      rating: 4.5,
      reviewCount: 43,
      stockCount: 60,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      nameTranslations: {
        'en': '2FIT Long Sleeve T-Shirt',
        'ja': '2FIT 長袖Tシャツ',
        'zh': '2FIT 长袖T恤',
        'mn': '2FIT Урт ханцуйт цамц',
      },
      descriptionTranslations: {
        'en': 'Long sleeve sports T-shirt with UV protection.',
        'ja': '紫外線カット機能付き長袖スポーツTシャツ。',
        'zh': '具有紫外线防护功能的长袖运动T恤。',
        'mn': 'Хэт ягаан туяанаас хамгаалах урт ханцуйт спортын цамц.',
      },
    ),
    ProductModel(
      id: 'p005',
      name: '2FIT 싱글렛 A타입',
      category: '상의',
      price: 22000,
      description: '통기성 극대화 싱글렛. 마라톤, 트라이애슬론에 최적.',
      images: [
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      colors: ['Black', 'White', 'Red', 'Blue'],
      isNew: true,
      rating: 4.9,
      reviewCount: 210,
      stockCount: 80,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      nameTranslations: {
        'en': '2FIT Singlet Type-A',
        'ja': '2FIT シングレット Aタイプ',
        'zh': '2FIT 背心A型',
        'mn': '2FIT Сингулет А загвар',
      },
      descriptionTranslations: {
        'en': 'Maximum breathability singlet. Ideal for marathons and triathlons.',
        'ja': '通気性を最大化したシングレット。マラソン・トライアスロンに最適。',
        'zh': '透气性最大化背心。适合马拉松、铁人三项。',
        'mn': 'Агаар нэвтрэх чадварыг дээд зэргээр нэмэгдүүлсэн. Марафон, триатлонд тохиромжтой.',
      },
    ),
    ProductModel(
      id: 'p006',
      name: '2FIT 카라 티셔츠',
      category: '상의',
      price: 38000,
      description: '세련된 카라 디자인의 스포츠 티셔츠. 골프, 테니스에 추천.',
      images: [
        'https://images.unsplash.com/photo-1503341455253-b2e723bb3dbb?w=600',
      ],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['White', 'Black', 'Navy', 'Gray'],
      rating: 4.4,
      reviewCount: 31,
      stockCount: 45,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      nameTranslations: {
        'en': '2FIT Polo Shirt',
        'ja': '2FIT ポロシャツ',
        'zh': '2FIT POLO衫',
        'mn': '2FIT Захтай цамц',
      },
      descriptionTranslations: {
        'en': 'Stylish collar design sports shirt. Recommended for golf and tennis.',
        'ja': 'スタイリッシュなカラーデザインのスポーツシャツ。ゴルフ・テニスにおすすめ。',
        'zh': '时尚领型设计运动衬衫。推荐用于高尔夫和网球。',
        'mn': 'Загварлаг захтай спортын цамц. Гольф, теннист тохиромжтой.',
      },
    ),
    // ── 하의 ──────────────────────────────────────────────────
    ProductModel(
      id: 'p007',
      name: '2FIT 트레이닝 팬츠',
      category: '하의',
      price: 52000,
      description: '편안한 착용감의 트레이닝 팬츠. 실내외 운동 모두 적합.',
      images: [
        'https://images.unsplash.com/photo-1547496502-affa22d38842?w=600',
        'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Gray', 'Navy'],
      isFreeShipping: true,
      rating: 4.7,
      reviewCount: 98,
      stockCount: 40,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      nameTranslations: {
        'en': '2FIT Training Pants',
        'ja': '2FIT トレーニングパンツ',
        'zh': '2FIT 训练裤',
        'mn': '2FIT Дасгалын өмд',
      },
      descriptionTranslations: {
        'en': 'Comfortable training pants. Suitable for both indoor and outdoor sports.',
        'ja': '快適な着心地のトレーニングパンツ。室内外どちらの運動にも適しています。',
        'zh': '穿着舒适的训练裤。适合室内外运动。',
        'mn': 'Тав тухтай дасгалын өмд. Дотор, гадаа хоёулаа тохиромжтой.',
      },
    ),
    ProductModel(
      id: 'p008',
      name: '2FIT 반바지',
      category: '하의',
      price: 32000,
      description: '가볍고 시원한 스포츠 반바지. 러닝, 축구에 최적화.',
      images: [
        'https://images.unsplash.com/photo-1591195853828-11db59a44f43?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'White', 'Navy', 'Red'],
      isNew: true,
      rating: 4.6,
      reviewCount: 75,
      stockCount: 55,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      nameTranslations: {
        'en': '2FIT Shorts',
        'ja': '2FIT ショートパンツ',
        'zh': '2FIT 短裤',
        'mn': '2FIT Шорт',
      },
      descriptionTranslations: {
        'en': 'Lightweight and cool sports shorts. Optimized for running and football.',
        'ja': '軽くて涼しいスポーツショートパンツ。ランニング・サッカーに最適。',
        'zh': '轻盈凉爽的运动短裤。专为跑步和足球优化。',
        'mn': 'Хөнгөн, сэрүүн спортын шорт. Гүйлт, хөлбөмбөгт оновчтой.',
      },
    ),
    ProductModel(
      id: 'p009',
      name: '2FIT 롱 레깅스',
      category: '하의',
      price: 45000,
      description: '발목까지 오는 풀 레깅스. 압박감과 신축성의 완벽한 밸런스.',
      images: [
        'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600',
        'https://images.unsplash.com/photo-1518459031867-a89b944bffe4?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      colors: ['Black', 'Navy', 'Gray', 'Purple'],
      isNew: true,
      isFreeShipping: true,
      rating: 4.9,
      reviewCount: 187,
      stockCount: 70,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      nameTranslations: {
        'en': '2FIT Long Leggings',
        'ja': '2FIT ロングレギンス',
        'zh': '2FIT 长款紧身裤',
        'mn': '2FIT Урт легинс',
      },
      descriptionTranslations: {
        'en': 'Full-length ankle leggings. Perfect balance of compression and elasticity.',
        'ja': '足首までのフルレギンス。圧迫感と伸縮性の完璧なバランス。',
        'zh': '全长及踝紧身裤。压缩感与弹性的完美平衡。',
        'mn': 'Бүтэн урт шагайны легинс. Даралт ба уян хатан чанарын төгс тэнцвэр.',
      },
    ),
    ProductModel(
      id: 'p010',
      name: '2FIT 숏 레깅스',
      category: '하의',
      price: 38000,
      description: '무릎 위까지 오는 숏 레깅스. 자전거, 트레일 러닝에 최적.',
      images: [
        'https://images.unsplash.com/photo-1548690312-e3b507d8c110?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      colors: ['Black', 'Navy', 'Pink'],
      rating: 4.7,
      reviewCount: 63,
      stockCount: 48,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      nameTranslations: {
        'en': '2FIT Short Leggings',
        'ja': '2FIT ショートレギンス',
        'zh': '2FIT 短款紧身裤',
        'mn': '2FIT Богино легинс',
      },
      descriptionTranslations: {
        'en': 'Short leggings above the knee. Ideal for cycling and trail running.',
        'ja': '膝上までのショートレギンス。自転車・トレイルランニングに最適。',
        'zh': '膝上短紧身裤。适合骑行和越野跑。',
        'mn': 'Өвдөгний дээр хүрэх богино легинс. Дугуй унах, уулын гүйлтэд тохиромжтой.',
      },
    ),
    ProductModel(
      id: 'p011',
      name: '2FIT 사이클 숏츠',
      category: '하의',
      price: 55000,
      description: '패딩이 내장된 사이클링 전용 숏츠. 장거리 라이딩에 최적.',
      images: [
        'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Navy'],
      isFreeShipping: true,
      rating: 4.8,
      reviewCount: 44,
      stockCount: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      nameTranslations: {
        'en': '2FIT Cycling Shorts',
        'ja': '2FIT サイクルショーツ',
        'zh': '2FIT 骑行短裤',
        'mn': '2FIT Дугуй унах шорт',
      },
      descriptionTranslations: {
        'en': 'Cycling shorts with built-in padding. Optimized for long-distance riding.',
        'ja': 'パッド内蔵サイクリング専用ショーツ。長距離ライディングに最適。',
        'zh': '内置垫片骑行专用短裤。适合长途骑行。',
        'mn': 'Дотор доторлогоотой дугуй унах шорт. Урт замын унаанд оновчтой.',
      },
    ),
    // ── 세트 ──────────────────────────────────────────────────
    ProductModel(
      id: 'p012',
      name: '2FIT 크롭탑+숏레깅스 세트',
      category: '세트',
      price: 58000,
      originalPrice: 70000,
      description: '크롭탑과 숏 레깅스의 매칭 세트. 요가, 필라테스 최적.',
      images: [
        'https://images.unsplash.com/photo-1518459031867-a89b944bffe4?w=600',
        'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      colors: ['Black', 'Navy', 'Pink'],
      isNew: true,
      isSale: true,
      isFreeShipping: true,
      rating: 4.8,
      reviewCount: 92,
      stockCount: 35,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      nameTranslations: {
        'en': '2FIT Crop Top + Short Leggings Set',
        'ja': '2FIT クロップトップ＋ショートレギンスセット',
        'zh': '2FIT 短款上衣+短紧身裤套装',
        'mn': '2FIT Богиносгосон топ + богино легинс иж бүрдэл',
      },
      descriptionTranslations: {
        'en': 'Matching set of crop top and short leggings. Ideal for yoga and Pilates.',
        'ja': 'クロップトップとショートレギンスのマッチングセット。ヨガ・ピラティスに最適。',
        'zh': '短款上衣和短紧身裤的配套套装。适合瑜伽和普拉提。',
        'mn': 'Богиносгосон топ болон богино легинсийн иж бүрдэл. Йога, Пилатест тохиромжтой.',
      },
    ),
    ProductModel(
      id: 'p013',
      name: '2FIT 티셔츠+롱레깅스 세트',
      category: '세트',
      price: 72000,
      originalPrice: 85000,
      description: '라운드넥 티셔츠와 롱 레깅스 매칭 세트.',
      images: [
        'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      colors: ['Black', 'Gray', 'Navy'],
      isSale: true,
      isFreeShipping: true,
      rating: 4.6,
      reviewCount: 58,
      stockCount: 25,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      nameTranslations: {
        'en': '2FIT T-Shirt + Long Leggings Set',
        'ja': '2FIT Tシャツ＋ロングレギンスセット',
        'zh': '2FIT T恤+长紧身裤套装',
        'mn': '2FIT Цамц + урт легинс иж бүрдэл',
      },
      descriptionTranslations: {
        'en': 'Matching set of round neck T-shirt and long leggings.',
        'ja': 'ラウンドネックTシャツとロングレギンスのマッチングセット。',
        'zh': '圆领T恤和长紧身裤的配套套装。',
        'mn': 'Тойрог захтай цамц болон урт легинсийн иж бүрдэл.',
      },
    ),
    ProductModel(
      id: 'p014',
      name: '2FIT 후드+트레이닝 세트',
      category: '세트',
      price: 110000,
      originalPrice: 130000,
      description: '후드 집업과 트레이닝 팬츠 풀세트.',
      images: [
        'https://images.unsplash.com/photo-1556821840-3a63f15732ce?w=600',
      ],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Gray', 'Navy'],
      isSale: true,
      isFreeShipping: true,
      rating: 4.7,
      reviewCount: 41,
      stockCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      nameTranslations: {
        'en': '2FIT Hoodie + Training Set',
        'ja': '2FIT フード＋トレーニングセット',
        'zh': '2FIT 连帽衫+训练套装',
        'mn': '2FIT Малгайтай + дасгалын иж бүрдэл',
      },
      descriptionTranslations: {
        'en': 'Full set of hoodie zip-up and training pants.',
        'ja': 'フードジップアップとトレーニングパンツのフルセット。',
        'zh': '连帽拉链上衣和训练裤的完整套装。',
        'mn': 'Зипэн малгайтай болон дасгалын өмдний бүрэн иж бүрдэл.',
      },
    ),
    // ── 아우터 ─────────────────────────────────────────────────
    ProductModel(
      id: 'p015',
      name: '2FIT 바람막이 자켓',
      category: '아우터',
      price: 89000,
      description: '방풍·방수 기능의 경량 바람막이. 러닝, 하이킹에 최적.',
      images: [
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
      ],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Navy', 'Red'],
      isFreeShipping: true,
      rating: 4.8,
      reviewCount: 67,
      stockCount: 20,
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
      nameTranslations: {
        'en': '2FIT Windbreaker Jacket',
        'ja': '2FIT ウィンドブレーカー',
        'zh': '2FIT 防风夹克',
        'mn': '2FIT Салхи тэсвэрлэх куртка',
      },
      descriptionTranslations: {
        'en': 'Lightweight windbreaker with windproof and waterproof features. Ideal for running and hiking.',
        'ja': '防風・防水機能の軽量ウィンドブレーカー。ランニング・ハイキングに最適。',
        'zh': '具有防风防水功能的轻量防风夹克。适合跑步和徒步。',
        'mn': 'Салхи ба усны тэсвэртэй хөнгөн куртка. Гүйлт, явган аялалд тохиромжтой.',
      },
    ),
    ProductModel(
      id: 'p016',
      name: '2FIT 다운 패딩',
      category: '아우터',
      price: 145000,
      originalPrice: 180000,
      description: '가볍고 따뜻한 다운 패딩. 겨울 아웃도어 스포츠용.',
      images: [
        'https://images.unsplash.com/photo-1559181567-c3190100191d?w=600',
      ],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Navy', 'Gray'],
      isSale: true,
      isFreeShipping: true,
      rating: 4.9,
      reviewCount: 33,
      stockCount: 12,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      nameTranslations: {
        'en': '2FIT Down Jacket',
        'ja': '2FIT ダウンジャケット',
        'zh': '2FIT 羽绒服',
        'mn': '2FIT Пухан цув',
      },
      descriptionTranslations: {
        'en': 'Lightweight and warm down jacket. For winter outdoor sports.',
        'ja': '軽くて暖かいダウンジャケット。冬のアウトドアスポーツ用。',
        'zh': '轻便保暖羽绒服。适合冬季户外运动。',
        'mn': 'Хөнгөн, дулаан пухан цув. Өвлийн гадаа спортод зориулсан.',
      },
    ),
    // ── 액세서리 ───────────────────────────────────────────────
    ProductModel(
      id: 'p017',
      name: '2FIT 스포츠 백팩',
      category: '액세서리',
      price: 68000,
      description: '20L 용량의 스포츠 전용 백팩. 노트북 수납 가능.',
      images: [
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600',
      ],
      sizes: ['FREE'],
      colors: ['Black', 'Gray', 'Navy'],
      isFreeShipping: true,
      rating: 4.7,
      reviewCount: 89,
      stockCount: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      nameTranslations: {
        'en': '2FIT Sports Backpack',
        'ja': '2FIT スポーツバックパック',
        'zh': '2FIT 运动背包',
        'mn': '2FIT Спортын нуруувч',
      },
      descriptionTranslations: {
        'en': '20L capacity sports backpack. Laptop compatible.',
        'ja': '20L容量のスポーツ専用バックパック。ノートPC収納可能。',
        'zh': '20L容量运动专用背包。可放置笔记本电脑。',
        'mn': '20Л багтаамжтай спортын нуруувч. Зөөврийн компьютер хийж болно.',
      },
    ),
    ProductModel(
      id: 'p018',
      name: '2FIT 스포츠 양말 (3켤레)',
      category: '액세서리',
      price: 15000,
      description: '땀 흡수·속건성 스포츠 양말 3켤레 세트.',
      images: [
        'https://images.unsplash.com/photo-1586350977771-b3b0abd50c82?w=600',
      ],
      sizes: ['M(250~265)', 'L(270~285)'],
      colors: ['White', 'Black', 'Gray'],
      isNew: true,
      rating: 4.5,
      reviewCount: 156,
      stockCount: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      nameTranslations: {
        'en': '2FIT Sports Socks (3 pairs)',
        'ja': '2FIT スポーツソックス（3足）',
        'zh': '2FIT 运动袜（3双）',
        'mn': '2FIT Спортын оймс (3 хос)',
      },
      descriptionTranslations: {
        'en': 'Sweat-absorbing quick-dry sports socks set of 3 pairs.',
        'ja': '汗吸収・速乾スポーツソックス3足セット。',
        'zh': '吸汗速干运动袜3双套装。',
        'mn': 'Хөлс шингээх, хурдан хатдаг спортын оймс 3 хос иж бүрдэл.',
      },
    ),
    ProductModel(
      id: 'p019',
      name: '2FIT 헤어밴드',
      category: '액세서리',
      price: 8000,
      description: '넌슬립 코팅 스포츠 헤어밴드. 러닝, 테니스 전용.',
      images: [
        'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=600',
      ],
      sizes: ['FREE'],
      colors: ['Black', 'White', 'Pink', 'Navy'],
      rating: 4.4,
      reviewCount: 72,
      stockCount: 150,
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      nameTranslations: {
        'en': '2FIT Sports Headband',
        'ja': '2FIT スポーツヘアバンド',
        'zh': '2FIT 运动发带',
        'mn': '2FIT Спортын үс оогуур',
      },
      descriptionTranslations: {
        'en': 'Non-slip coated sports headband. Dedicated for running and tennis.',
        'ja': 'ノンスリップコーティングスポーツヘアバンド。ランニング・テニス専用。',
        'zh': '防滑涂层运动发带。专为跑步和网球设计。',
        'mn': 'Гулгахгүй бүрлэгтэй спортын үс оогуур. Гүйлт, теннист зориулсан.',
      },
    ),
    ProductModel(
      id: 'p020',
      name: '2FIT 물병 750ml',
      category: '액세서리',
      price: 22000,
      description: '트라이탄 소재 친환경 물병. BPA FREE.',
      images: [
        'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=600',
      ],
      sizes: ['750ml'],
      colors: ['Black', 'White', 'Blue'],
      isNew: true,
      rating: 4.6,
      reviewCount: 45,
      stockCount: 80,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      nameTranslations: {
        'en': '2FIT Water Bottle 750ml',
        'ja': '2FIT ウォーターボトル 750ml',
        'zh': '2FIT 水壶 750ml',
        'mn': '2FIT Усны лонх 750мл',
      },
      descriptionTranslations: {
        'en': 'Eco-friendly Tritan water bottle. BPA FREE.',
        'ja': 'トライタン素材のエコフレンドリーウォーターボトル。BPA FREE。',
        'zh': '三酚素材环保水壶。无BPA。',
        'mn': 'Трайтан материалын экологийн цэвэр усны лонх. BPA агуулаагүй.',
      },
    ),
    // ── 단체주문 전용 상품 (싱글렛 A타입세트 + 하의 타이즈만) ──────────
    ProductModel(
      id: 'group_singlet_set',
      name: '2FIT 싱글렛 A타입 세트 (단체)',
      category: '단체주문',
      subCategory: '싱글렛 A타입세트',
      price: 58000,
      originalPrice: 75000,
      description: '싱글렛 A타입 + 하의 세트. 마라톤·트라이애슬론 팀 단체 제작 전용. 5명 이상 주문 가능.',
      images: [
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Navy', 'Red', 'White', 'Purple', 'Sky Blue'],
      material: '82% Polyester, 18% Spandex',
      isNew: true,
      isSale: true,
      isGroupOnly: true,
      isFreeShipping: true,
      rating: 4.9,
      reviewCount: 156,
      stockCount: 500,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      nameTranslations: {
        'en': '2FIT Singlet Type-A Set (Group)',
        'ja': '2FIT シングレット Aタイプセット（団体）',
        'zh': '2FIT 背心A型套装（团体）',
        'mn': '2FIT Сингулет А загвар иж бүрдэл (Бүлэг)',
      },
      descriptionTranslations: {
        'en': 'Singlet Type-A + Bottom Set. Exclusively for marathon/triathlon team group orders. Minimum 5 people.',
        'ja': 'シングレット Aタイプ＋ボトムセット。マラソン・トライアスロンチームの団体製作専用。5名以上から注文可能。',
        'zh': '背心A型+下装套装。专为马拉松·铁人三项团体定制。最少5人起订。',
        'mn': 'Сингулет А загвар + Доод хэсгийн иж бүрдэл. Марафон·триатлоны баг бүлгийн захиалга. 5-аас дээш хүн захиалах боломжтой.',
      },
    ),
    ProductModel(
      id: 'group_tights',
      name: '2FIT 타이즈 (단체)',
      category: '단체주문',
      subCategory: '타이즈',
      price: 45000,
      originalPrice: 58000,
      description: '고탄성 4-way 스트레치 타이즈. 압박감과 신축성의 완벽한 밸런스. 단체 제작 전용.',
      images: [
        'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600',
        'https://images.unsplash.com/photo-1518459031867-a89b944bffe4?w=600',
      ],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Navy', 'Red', 'White', 'Purple', 'Gray'],
      material: '80% Nylon, 20% Spandex',
      isNew: false,
      isSale: true,
      isGroupOnly: true,
      isFreeShipping: true,
      rating: 4.8,
      reviewCount: 203,
      stockCount: 500,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      nameTranslations: {
        'en': '2FIT Tights (Group)',
        'ja': '2FIT タイツ（団体）',
        'zh': '2FIT 紧身裤（团体）',
        'mn': '2FIT Таайтс (Бүлэг)',
      },
      descriptionTranslations: {
        'en': 'High-elasticity 4-way stretch tights. Perfect balance of compression and elasticity. For group orders only.',
        'ja': '高弾性4ウェイストレッチタイツ。圧迫感と伸縮性の完璧なバランス。団体製作専用。',
        'zh': '高弹4向拉伸紧身裤。压缩感与弹性的完美平衡。仅限团体定制。',
        'mn': 'Өндөр уян хатан 4 чиглэлтэй стретч таайтс. Даралт ба уян хатан чанарын төгс тэнцвэр. Зөвхөн бүлгийн захиалгад.',
      },
    ),
  ];

  // ── Firestore ──────────────────────────────────────────────
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── 캐시 ──────────────────────────────────────────────────────
  static List<ProductModel> _cache = [];
  static bool _loaded = false;
  static const String _prefKey = 'products_v4'; // v4: Firestore 연동

  static void _ensureCache() {
    if (_cache.isEmpty) _cache = List.from(_products);
  }

  static void updateCache(List<ProductModel> products) {
    _cache = products;
  }

  // ── Firestore에서 상품 로드 ────────────────────────────────────
  static Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await _db
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 8));

      if (snapshot.docs.isNotEmpty) {
        final firestoreProducts = snapshot.docs.map((doc) {
          final data = doc.data();
          // Firestore Timestamp → String 변환
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp)
                .toDate()
                .toIso8601String();
          }
          return ProductModel.fromJson(data);
        }).toList();

        _products.clear();
        _products.addAll(firestoreProducts);
        _cache = List.from(_products);
        _loaded = true;
        if (kDebugMode) debugPrint('✅ Firestore 상품 ${firestoreProducts.length}개 로드');

        // 로컬 캐시에도 저장 (오프라인 대비)
        await _persistToLocal();
        return;
      } else {
        // Firestore에 데이터가 없으면 더미 사용
        if (kDebugMode) debugPrint('⚠️ Firestore 상품 0개 → 더미 데이터 사용');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 상품 로드 실패, 로컬 폴백: $e');
    }
    // Firestore 실패 또는 데이터 없음 → 로컬 캐시 → 더미 데이터 순서로 폴백
    await _loadFromLocal();
  }

  // ── 로컬 캐시 저장 ────────────────────────────────────────────
  static Future<void> _persistToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _products.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_prefKey, jsonList);
    } catch (_) {}
  }

  // ── 로컬 캐시 로드 (오프라인 폴백) ───────────────────────────
  static Future<void> _loadFromLocal() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey);
      if (saved != null && saved.isNotEmpty) {
        final loaded = saved
            .map((s) => ProductModel.fromJson(
                jsonDecode(s) as Map<String, dynamic>))
            .toList();
        _products.clear();
        _products.addAll(loaded);
        _cache = List.from(_products);
        if (kDebugMode) debugPrint('📦 로컬 캐시에서 ${loaded.length}개 상품 로드');
        return;
      }
    } catch (_) {}
    // 로컬 캐시도 없으면 내장 더미 데이터 사용 (_products는 이미 더미로 초기화됨)
    _cache = List.from(_products);
    if (kDebugMode) debugPrint('🧪 내장 더미 데이터 ${_products.length}개 사용');
  }

  // ── 레거시 호환 (기존 코드에서 _persist 호출 시) ──────────────
  static Future<void> _persist() async => _persistToLocal();

  // ── 조회 ──────────────────────────────────────────────────────

  static Future<List<ProductModel>> getAllProducts() async {
    if (!_loaded) await _loadFromFirestore();
    return _products.where((p) => p.isActive).toList();
  }

  /// 관리자 전용: isActive 필터 없이 모든 상품 반환
  static Future<List<ProductModel>> getAllProductsForAdmin() async {
    await _loadFromFirestoreAll();
    return List.from(_allProducts);
  }

  static final List<ProductModel> _allProducts = [];

  static Future<void> _loadFromFirestoreAll() async {
    try {
      final snapshot = await _db
          .collection('products')
          .get()
          .timeout(const Duration(seconds: 12));

      // 상품이 0개여도 정상 처리 (모두 삭제된 경우)
      final all = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return ProductModel.fromJson(data);
      }).toList();

      _allProducts.clear();
      _allProducts.addAll(all);
      // 활성 상품은 일반 캐시도 갱신
      final active = all.where((p) => p.isActive).toList();
      _products.clear();
      _products.addAll(active);
      _cache = List.from(active);
      _loaded = true;
      if (kDebugMode) debugPrint('✅ 관리자 전체 상품 ${all.length}개 로드 (활성: ${active.length})');
      await _persistToLocal();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 관리자 상품 로드 실패: $e');
      if (!_loaded) await _loadFromLocal();
      _allProducts.clear();
      _allProducts.addAll(_products);
    }
  }

  static Future<List<ProductModel>> getProductsByCategory(String category) async {
    if (!_loaded) await _loadFromFirestore();
    if (category == '전체') return _products.where((p) => p.isActive).toList();
    if (category == '신상품') {
      return _products.where((p) => p.isNew && p.isActive).toList();
    }
    if (category == '세일') {
      return _products.where((p) => p.isSale && p.isActive).toList();
    }
    return _products
        .where((p) => p.category == category && p.isActive)
        .toList();
  }

  static Future<ProductModel?> getProductById(String id) async {
    if (!_loaded) await _loadFromFirestore();
    // 1) 캐시에서 먼저 탐색
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {}
    // 2) Firestore 직접 조회
    try {
      final doc = await _db.collection('products').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return ProductModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<ProductModel>> searchProducts(String query) async {
    if (query.isEmpty) return getAllProducts();
    final q = query.toLowerCase();
    return _products
        .where((p) =>
            p.isActive &&
            (p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q)))
        .toList();
  }

  static Future<List<ProductModel>> getNewArrivals() async {
    return _products.where((p) => p.isNew && p.isActive).toList();
  }

  static Future<List<ProductModel>> getSaleProducts() async {
    return _products.where((p) => p.isSale && p.isActive).toList();
  }

  static Future<List<ProductModel>> getPopularProducts() async {
    final sorted = List<ProductModel>.from(
        _products.where((p) => p.isActive))
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return sorted.take(8).toList();
  }

  // ── 실시간 스트림 (로컬 Stream 에뮬레이션) ──────────────────────

  static Stream<List<ProductModel>> productsStream() async* {
    yield await getAllProducts();
  }

  static Stream<List<ProductModel>> categoryStream(String category) async* {
    yield await getProductsByCategory(category);
  }

  // ── 관리자 CRUD ───────────────────────────────────────────────

  static Future<void> addProduct(ProductModel product) async {
    if (!_loaded) await _loadFromFirestore();
    _products.add(product);
    _cache = List.from(_products);
    await _persistToLocal();
    // Firestore에도 저장
    try {
      await _db.collection('products').doc(product.id).set(product.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 상품 저장 실패: $e');
    }
  }

  static Future<bool> updateProduct(ProductModel updated) async {
    if (!_loaded) await _loadFromFirestore();
    final idx = _products.indexWhere((p) => p.id == updated.id);
    if (idx < 0) return false;
    _products[idx] = updated;
    _cache = List.from(_products);
    await _persistToLocal();
    // Firestore 업데이트
    try {
      await _db.collection('products').doc(updated.id).set(updated.toJson(), SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 상품 업데이트 실패: $e');
    }
    return true;
  }

  static Future<bool> deleteProduct(String productId) async {
    if (!_loaded) await _loadFromFirestore();
    // 메모리 캐시에서 즉시 제거
    _products.removeWhere((p) => p.id == productId);
    _allProducts.removeWhere((p) => p.id == productId);
    _cache = List.from(_products);
    await _persistToLocal();
    // Firestore 완전 삭제 (hard delete)
    try {
      await _db.collection('products').doc(productId).delete();
      if (kDebugMode) debugPrint('✅ Firestore 상품 완전 삭제: $productId');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 상품 삭제 실패: $e');
      return false;
    }
    return true;
  }

  static Future<bool> updateStock(String productId, int newStock) async {
    if (!_loaded) await _loadFromFirestore();
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0) return false;
    final p = _products[idx];
    _products[idx] = ProductModel(
      id: p.id, name: p.name, category: p.category,
      price: p.price, originalPrice: p.originalPrice,
      description: p.description, images: p.images,
      sizes: p.sizes, colors: p.colors, material: p.material,
      isNew: p.isNew, isSale: p.isSale, isFreeShipping: p.isFreeShipping,
      isActive: p.isActive,
      rating: p.rating, reviewCount: p.reviewCount,
      stockCount: newStock,
      createdAt: p.createdAt, sectionImages: p.sectionImages,
    );
    _cache = List.from(_products);
    await _persist();
    // Firestore 재고 업데이트
    try {
      await _db.collection('products').doc(productId).update({'stockCount': newStock});
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 재고 업데이트 실패: $e');
    }
    return true;
  }

  static Future<bool> updateSectionImages(
      String productId, String sectionKey, List<String> urls) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0) return false;
    final p = _products[idx];
    final newMap = Map<String, List<String>>.from(p.sectionImages);
    if (urls.isEmpty) {
      newMap.remove(sectionKey);
    } else {
      newMap[sectionKey] = List<String>.from(urls);
    }
    _products[idx] = ProductModel(
      id: p.id, name: p.name, category: p.category,
      price: p.price, originalPrice: p.originalPrice,
      description: p.description, images: p.images,
      sizes: p.sizes, colors: p.colors, material: p.material,
      isNew: p.isNew, isSale: p.isSale, isFreeShipping: p.isFreeShipping,
      isActive: p.isActive,
      rating: p.rating, reviewCount: p.reviewCount, stockCount: p.stockCount,
      createdAt: p.createdAt, sectionImages: newMap,
    );
    _cache = List.from(_products);
    await _persist();
    // Firestore 섹션 이미지 업데이트
    try {
      await _db.collection('products').doc(productId).update({'sectionImages': newMap});
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 섹션이미지 업데이트 실패: $e');
    }
    return true;
  }

  static Future<bool> updateMainImages(
      String productId, List<String> urls) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0) return false;
    final p = _products[idx];
    _products[idx] = ProductModel(
      id: p.id, name: p.name, category: p.category,
      price: p.price, originalPrice: p.originalPrice,
      description: p.description, images: urls,
      sizes: p.sizes, colors: p.colors, material: p.material,
      isNew: p.isNew, isSale: p.isSale, isFreeShipping: p.isFreeShipping,
      isActive: p.isActive,
      rating: p.rating, reviewCount: p.reviewCount, stockCount: p.stockCount,
      createdAt: p.createdAt, sectionImages: p.sectionImages,
    );
    _cache = List.from(_products);
    await _persist();
    // Firestore 메인 이미지 업데이트
    try {
      await _db.collection('products').doc(productId).update({'images': urls});
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 메인이미지 업데이트 실패: $e');
    }
    return true;
  }

  // ── 동기 접근 (캐시 기반) ──────────────────────────────────────

  static List<ProductModel> getAllProductsSync() {
    _ensureCache();
    return _cache;
  }

  static List<ProductModel> getProductsByCategorySync(String category) {
    _ensureCache();
    if (category == '전체') return _cache;
    if (category == '신상품') return _cache.where((p) => p.isNew).toList();
    if (category == '세일') return _cache.where((p) => p.isSale).toList();
    return _cache.where((p) => p.category == category).toList();
  }

  static ProductModel? getProductByIdSync(String id) {
    _ensureCache();
    try {
      return _cache.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 번역 필드만 Firestore에 업데이트 (가볍게)
  static Future<void> updateTranslations({
    required String productId,
    Map<String, String>? nameTranslations,
    Map<String, String>? descriptionTranslations,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nameTranslations != null && nameTranslations.isNotEmpty) {
        data['nameTranslations'] = nameTranslations;
      }
      if (descriptionTranslations != null && descriptionTranslations.isNotEmpty) {
        data['descriptionTranslations'] = descriptionTranslations;
      }
      if (data.isEmpty) return;

      await _db.collection('products').doc(productId).set(
        data,
        SetOptions(merge: true),
      );
      // 로컬 캐시도 업데이트
      final idx = _products.indexWhere((p) => p.id == productId);
      if (idx >= 0) {
        final p = _products[idx];
        _products[idx] = p.copyWithTranslations(
          nameTranslations: nameTranslations ?? p.nameTranslations,
          descriptionTranslations: descriptionTranslations ?? p.descriptionTranslations,
        );
        _cache = List.from(_products);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 번역 업데이트 실패 ($productId): $e');
    }
  }
}
