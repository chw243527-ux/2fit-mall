// ─────────────────────────────────────────────────────────
// 다국어 번역 데이터 (영어 · 일본어 · 중국어 · 몽골어)
// ─────────────────────────────────────────────────────────

enum AppLanguage {
  korean,
  english,
  japanese,
  chinese,
  mongolian,
}

extension AppLanguageExt on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.korean:   return 'KO';
      case AppLanguage.english:  return 'EN';
      case AppLanguage.japanese: return 'JA';
      case AppLanguage.chinese:  return 'ZH';
      case AppLanguage.mongolian:return 'MN';
    }
  }

  String get nativeName {
    switch (this) {
      case AppLanguage.korean:   return '한국어';
      case AppLanguage.english:  return 'English';
      case AppLanguage.japanese: return '日本語';
      case AppLanguage.chinese:  return '中文';
      case AppLanguage.mongolian:return 'Монгол';
    }
  }

  String get flagEmoji {
    switch (this) {
      case AppLanguage.korean:   return '🇰🇷';
      case AppLanguage.english:  return '🇺🇸';
      case AppLanguage.japanese: return '🇯🇵';
      case AppLanguage.chinese:  return '🇨🇳';
      case AppLanguage.mongolian:return '🇲🇳';
    }
  }
}

class AppLocalizations {
  final AppLanguage language;
  const AppLocalizations(this.language);

  // ── 공통 ──
  String get appName {
    switch (language) {
      case AppLanguage.korean:   return '2FIT MALL';
      case AppLanguage.english:  return '2FIT MALL';
      case AppLanguage.japanese: return '2FIT MALL';
      case AppLanguage.chinese:  return '2FIT MALL';
      case AppLanguage.mongolian:return '2FIT MALL';
    }
  }

  // ── 내비게이션 ──
  String get navHome {
    switch (language) {
      case AppLanguage.korean:   return '홈';
      case AppLanguage.english:  return 'Home';
      case AppLanguage.japanese: return 'ホーム';
      case AppLanguage.chinese:  return '首页';
      case AppLanguage.mongolian:return 'Нүүр';
    }
  }

  String get navProducts {
    switch (language) {
      case AppLanguage.korean:   return '상품';
      case AppLanguage.english:  return 'Shop';
      case AppLanguage.japanese: return '商品';
      case AppLanguage.chinese:  return '商品';
      case AppLanguage.mongolian:return 'Бараа';
    }
  }

  String get navOrderGuide {
    switch (language) {
      case AppLanguage.korean:   return '주문안내';
      case AppLanguage.english:  return 'Orders';
      case AppLanguage.japanese: return '注文案内';
      case AppLanguage.chinese:  return '订单指南';
      case AppLanguage.mongolian:return 'Захиалга';
    }
  }

  String get navCart {
    switch (language) {
      case AppLanguage.korean:   return '장바구니';
      case AppLanguage.english:  return 'Cart';
      case AppLanguage.japanese: return 'カート';
      case AppLanguage.chinese:  return '购物车';
      case AppLanguage.mongolian:return 'Сагс';
    }
  }

  String get navMyPage {
    switch (language) {
      case AppLanguage.korean:   return '마이페이지';
      case AppLanguage.english:  return 'My Page';
      case AppLanguage.japanese: return 'マイページ';
      case AppLanguage.chinese:  return '我的';
      case AppLanguage.mongolian:return 'Миний';
    }
  }

  // ── 카테고리 ──
  String get catAll {
    switch (language) {
      case AppLanguage.korean:   return '전체';
      case AppLanguage.english:  return 'All';
      case AppLanguage.japanese: return '全て';
      case AppLanguage.chinese:  return '全部';
      case AppLanguage.mongolian:return 'Бүгд';
    }
  }

  String get catTop {
    switch (language) {
      case AppLanguage.korean:   return '상의';
      case AppLanguage.english:  return 'Tops';
      case AppLanguage.japanese: return 'トップス';
      case AppLanguage.chinese:  return '上衣';
      case AppLanguage.mongolian:return 'Дээд';
    }
  }

  String get catBottom {
    switch (language) {
      case AppLanguage.korean:   return '하의';
      case AppLanguage.english:  return 'Bottoms';
      case AppLanguage.japanese: return 'ボトムス';
      case AppLanguage.chinese:  return '下装';
      case AppLanguage.mongolian:return 'Доод';
    }
  }

  String get catSet {
    switch (language) {
      case AppLanguage.korean:   return '세트';
      case AppLanguage.english:  return 'Sets';
      case AppLanguage.japanese: return 'セット';
      case AppLanguage.chinese:  return '套装';
      case AppLanguage.mongolian:return 'Иж';
    }
  }

  String get catOuter {
    switch (language) {
      case AppLanguage.korean:   return '아우터';
      case AppLanguage.english:  return 'Outer';
      case AppLanguage.japanese: return 'アウター';
      case AppLanguage.chinese:  return '外套';
      case AppLanguage.mongolian:return 'Гадуур';
    }
  }

  String get catAccessory {
    switch (language) {
      case AppLanguage.korean:   return '액세서리';
      case AppLanguage.english:  return 'Acces.';
      case AppLanguage.japanese: return 'アクセ';
      case AppLanguage.chinese:  return '配件';
      case AppLanguage.mongolian:return 'Дагалд';
    }
  }

  String get catNew {
    switch (language) {
      case AppLanguage.korean:   return '신상품';
      case AppLanguage.english:  return 'New';
      case AppLanguage.japanese: return '新着';
      case AppLanguage.chinese:  return '新品';
      case AppLanguage.mongolian:return 'Шинэ';
    }
  }

  String get catSale {
    switch (language) {
      case AppLanguage.korean:   return '세일';
      case AppLanguage.english:  return 'Sale';
      case AppLanguage.japanese: return 'セール';
      case AppLanguage.chinese:  return '特卖';
      case AppLanguage.mongolian:return 'Хямд';
    }
  }

  // ── 홈 화면 ──
  String get sectionCategory {
    switch (language) {
      case AppLanguage.korean:   return '카테고리';
      case AppLanguage.english:  return 'CATEGORY';
      case AppLanguage.japanese: return 'カテゴリー';
      case AppLanguage.chinese:  return '分类';
      case AppLanguage.mongolian:return 'АНГИЛАЛ';
    }
  }

  String get sectionNewArrival {
    switch (language) {
      case AppLanguage.korean:   return '신상품';
      case AppLanguage.english:  return 'NEW ARRIVAL';
      case AppLanguage.japanese: return '新着商品';
      case AppLanguage.chinese:  return '新品上市';
      case AppLanguage.mongolian:return 'ШИНЭ БАРАА';
    }
  }

  String get sectionNewArrivalSub {
    switch (language) {
      case AppLanguage.korean:   return 'NEW ARRIVAL';
      case AppLanguage.english:  return 'New Arrivals';
      case AppLanguage.japanese: return 'NEW ARRIVAL';
      case AppLanguage.chinese:  return 'NEW ARRIVAL';
      case AppLanguage.mongolian:return 'NEW ARRIVAL';
    }
  }

  String get sectionBestSeller {
    switch (language) {
      case AppLanguage.korean:   return '베스트';
      case AppLanguage.english:  return 'BEST SELLER';
      case AppLanguage.japanese: return 'ベスト';
      case AppLanguage.chinese:  return '热销';
      case AppLanguage.mongolian:return 'ШИЛДЭГ';
    }
  }

  String get sectionBestSellerSub {
    switch (language) {
      case AppLanguage.korean:   return 'BEST SELLER';
      case AppLanguage.english:  return 'Best Sellers';
      case AppLanguage.japanese: return 'BEST SELLER';
      case AppLanguage.chinese:  return 'BEST SELLER';
      case AppLanguage.mongolian:return 'BEST SELLER';
    }
  }

  String get viewAll {
    switch (language) {
      case AppLanguage.korean:   return '전체보기';
      case AppLanguage.english:  return 'View All';
      case AppLanguage.japanese: return '全て見る';
      case AppLanguage.chinese:  return '查看全部';
      case AppLanguage.mongolian:return 'Бүгдийг';
    }
  }

  String get bannerSubtitle {
    switch (language) {
      case AppLanguage.korean:   return '러너를 위한';
      case AppLanguage.english:  return 'For Runners';
      case AppLanguage.japanese: return 'ランナーのために';
      case AppLanguage.chinese:  return '为跑者而生';
      case AppLanguage.mongolian:return 'Гүйгчдэд зориулсан';
    }
  }

  String get shopNow {
    switch (language) {
      case AppLanguage.korean:   return '쇼핑하기';
      case AppLanguage.english:  return 'Shop Now';
      case AppLanguage.japanese: return 'ショップ';
      case AppLanguage.chinese:  return '立即购买';
      case AppLanguage.mongolian:return 'Дэлгүүр';
    }
  }

  String get chatButton {
    switch (language) {
      case AppLanguage.korean:   return '실시간 채팅 상담';
      case AppLanguage.english:  return 'Live Chat';
      case AppLanguage.japanese: return 'ライブチャット';
      case AppLanguage.chinese:  return '在线客服';
      case AppLanguage.mongolian:return 'Чат дэмжлэг';
    }
  }

  String get online {
    switch (language) {
      case AppLanguage.korean:   return '온라인';
      case AppLanguage.english:  return 'Online';
      case AppLanguage.japanese: return 'オンライン';
      case AppLanguage.chinese:  return '在线';
      case AppLanguage.mongolian:return 'Онлайн';
    }
  }

  // ── 검색 ──
  String get search {
    switch (language) {
      case AppLanguage.korean:   return '검색';
      case AppLanguage.english:  return 'Search';
      case AppLanguage.japanese: return '検索';
      case AppLanguage.chinese:  return '搜索';
      case AppLanguage.mongolian:return 'Хайх';
    }
  }

  String get searchHint {
    switch (language) {
      case AppLanguage.korean:   return '상품명으로 검색...';
      case AppLanguage.english:  return 'Search products...';
      case AppLanguage.japanese: return '商品名で検索...';
      case AppLanguage.chinese:  return '搜索商品...';
      case AppLanguage.mongolian:return 'Бараа хайх...';
    }
  }

  // ── 알림 ──
  String get notifications {
    switch (language) {
      case AppLanguage.korean:   return '알림';
      case AppLanguage.english:  return 'Notifications';
      case AppLanguage.japanese: return '通知';
      case AppLanguage.chinese:  return '通知';
      case AppLanguage.mongolian:return 'Мэдэгдэл';
    }
  }

  String get noNotifications {
    switch (language) {
      case AppLanguage.korean:   return '새 알림이 없습니다';
      case AppLanguage.english:  return 'No new notifications';
      case AppLanguage.japanese: return '新しい通知はありません';
      case AppLanguage.chinese:  return '暂无新通知';
      case AppLanguage.mongolian:return 'Шинэ мэдэгдэл байхгүй';
    }
  }

  // ── 언어 선택 ──
  String get selectLanguage {
    switch (language) {
      case AppLanguage.korean:   return '언어 선택';
      case AppLanguage.english:  return 'Select Language';
      case AppLanguage.japanese: return '言語選択';
      case AppLanguage.chinese:  return '选择语言';
      case AppLanguage.mongolian:return 'Хэл сонгох';
    }
  }

  // ── 상품 ──
  String get addToCart {
    switch (language) {
      case AppLanguage.korean:   return '장바구니 담기';
      case AppLanguage.english:  return 'Add to Cart';
      case AppLanguage.japanese: return 'カートに追加';
      case AppLanguage.chinese:  return '加入购物车';
      case AppLanguage.mongolian:return 'Сагсанд нэмэх';
    }
  }

  String get buyNow {
    switch (language) {
      case AppLanguage.korean:   return '바로 구매';
      case AppLanguage.english:  return 'Buy Now';
      case AppLanguage.japanese: return '今すぐ購入';
      case AppLanguage.chinese:  return '立即购买';
      case AppLanguage.mongolian:return 'Шууд авах';
    }
  }

  String get customOrder {
    switch (language) {
      case AppLanguage.korean:   return '커스텀 주문';
      case AppLanguage.english:  return 'Custom Order';
      case AppLanguage.japanese: return 'カスタム注文';
      case AppLanguage.chinese:  return '定制订单';
      case AppLanguage.mongolian:return 'Тусгай захиалга';
    }
  }

  String get price {
    switch (language) {
      case AppLanguage.korean:   return '가격';
      case AppLanguage.english:  return 'Price';
      case AppLanguage.japanese: return '価格';
      case AppLanguage.chinese:  return '价格';
      case AppLanguage.mongolian:return 'Үнэ';
    }
  }

  String get free {
    switch (language) {
      case AppLanguage.korean:   return '무료';
      case AppLanguage.english:  return 'Free';
      case AppLanguage.japanese: return '無料';
      case AppLanguage.chinese:  return '免费';
      case AppLanguage.mongolian:return 'Үнэгүй';
    }
  }

  String get freeShipping {
    switch (language) {
      case AppLanguage.korean:   return '무료배송';
      case AppLanguage.english:  return 'Free Shipping';
      case AppLanguage.japanese: return '送料無料';
      case AppLanguage.chinese:  return '免费配送';
      case AppLanguage.mongolian:return 'Үнэгүй хүргэлт';
    }
  }

  // ── 공지사항 ──
  String get notice { switch (language) {
    case AppLanguage.korean:   return '공지사항';
    case AppLanguage.english:  return 'Notice';
    case AppLanguage.japanese: return 'お知らせ';
    case AppLanguage.chinese:  return '公告';
    case AppLanguage.mongolian:return 'Мэдэгдэл';
  }}
  String get noticeClose { switch (language) {
    case AppLanguage.korean:   return '닫기';
    case AppLanguage.english:  return 'Close';
    case AppLanguage.japanese: return '閉じる';
    case AppLanguage.chinese:  return '关闭';
    case AppLanguage.mongolian:return 'Хаах';
  }}
  String get noticeDoNotShow { switch (language) {
    case AppLanguage.korean:   return '오늘 하루 보지 않기';
    case AppLanguage.english:  return 'Don\'t show today';
    case AppLanguage.japanese: return '今日は表示しない';
    case AppLanguage.chinese:  return '今天不再显示';
    case AppLanguage.mongolian:return 'Өнөөдөр харуулахгүй';
  }}

  // ── 버튼 공통 ──
  String get confirm { switch (language) {
    case AppLanguage.korean:   return '확인';
    case AppLanguage.english:  return 'OK';
    case AppLanguage.japanese: return '確認';
    case AppLanguage.chinese:  return '确认';
    case AppLanguage.mongolian:return 'Тийм';
  }}
  String get cancel { switch (language) {
    case AppLanguage.korean:   return '취소';
    case AppLanguage.english:  return 'Cancel';
    case AppLanguage.japanese: return 'キャンセル';
    case AppLanguage.chinese:  return '取消';
    case AppLanguage.mongolian:return 'Болих';
  }}
  String get delete { switch (language) {
    case AppLanguage.korean:   return '삭제';
    case AppLanguage.english:  return 'Delete';
    case AppLanguage.japanese: return '削除';
    case AppLanguage.chinese:  return '删除';
    case AppLanguage.mongolian:return 'Устгах';
  }}
  String get edit { switch (language) {
    case AppLanguage.korean:   return '수정';
    case AppLanguage.english:  return 'Edit';
    case AppLanguage.japanese: return '編集';
    case AppLanguage.chinese:  return '编辑';
    case AppLanguage.mongolian:return 'Засах';
  }}
  String get save { switch (language) {
    case AppLanguage.korean:   return '저장';
    case AppLanguage.english:  return 'Save';
    case AppLanguage.japanese: return '保存';
    case AppLanguage.chinese:  return '保存';
    case AppLanguage.mongolian:return 'Хадгалах';
  }}
  String get selectAll { switch (language) {
    case AppLanguage.korean:   return '전체선택';
    case AppLanguage.english:  return 'Select All';
    case AppLanguage.japanese: return '全て選択';
    case AppLanguage.chinese:  return '全选';
    case AppLanguage.mongolian:return 'Бүгдийг сонгох';
  }}
  String get deleteSelected { switch (language) {
    case AppLanguage.korean:   return '선택삭제';
    case AppLanguage.english:  return 'Delete Selected';
    case AppLanguage.japanese: return '選択削除';
    case AppLanguage.chinese:  return '删除所选';
    case AppLanguage.mongolian:return 'Сонгосоныг устгах';
  }}
  String get share { switch (language) {
    case AppLanguage.korean:   return '공유';
    case AppLanguage.english:  return 'Share';
    case AppLanguage.japanese: return 'シェア';
    case AppLanguage.chinese:  return '分享';
    case AppLanguage.mongolian:return 'Хуваалцах';
  }}
  String get keepShopping { switch (language) {
    case AppLanguage.korean:   return '쇼핑 계속하기';
    case AppLanguage.english:  return 'Continue Shopping';
    case AppLanguage.japanese: return 'ショッピングを続ける';
    case AppLanguage.chinese:  return '继续购物';
    case AppLanguage.mongolian:return 'Дэлгүүрлэж үргэлжлүүлэх';
  }}
  String get findPassword { switch (language) {
    case AppLanguage.korean:   return '비밀번호 찾기';
    case AppLanguage.english:  return 'Forgot Password';
    case AppLanguage.japanese: return 'パスワードを忘れた';
    case AppLanguage.chinese:  return '忘记密码';
    case AppLanguage.mongolian:return 'Нууц үг мартсан';
  }}
  String get signUp { switch (language) {
    case AppLanguage.korean:   return '회원가입';
    case AppLanguage.english:  return 'Sign Up';
    case AppLanguage.japanese: return '会員登録';
    case AppLanguage.chinese:  return '注册';
    case AppLanguage.mongolian:return 'Бүртгүүлэх';
  }}
  String get noAccount { switch (language) {
    case AppLanguage.korean:   return '계정이 없으신가요?';
    case AppLanguage.english:  return 'Don\'t have an account?';
    case AppLanguage.japanese: return 'アカウントをお持ちでないですか？';
    case AppLanguage.chinese:  return '没有账号？';
    case AppLanguage.mongolian:return 'Бүртгэл байхгүй юу?';
  }}
  // ── 로그인 ──
  String get email { switch (language) {
    case AppLanguage.korean:   return '이메일';
    case AppLanguage.english:  return 'Email';
    case AppLanguage.japanese: return 'メール';
    case AppLanguage.chinese:  return '邮箱';
    case AppLanguage.mongolian:return 'И-мэйл';
  }}
  String get password { switch (language) {
    case AppLanguage.korean:   return '비밀번호';
    case AppLanguage.english:  return 'Password';
    case AppLanguage.japanese: return 'パスワード';
    case AppLanguage.chinese:  return '密码';
    case AppLanguage.mongolian:return 'Нууц үг';
  }}
  String get passwordHint { switch (language) {
    case AppLanguage.korean:   return '비밀번호를 입력해주세요';
    case AppLanguage.english:  return 'Enter your password';
    case AppLanguage.japanese: return 'パスワードを入力してください';
    case AppLanguage.chinese:  return '请输入密码';
    case AppLanguage.mongolian:return 'Нууц үгээ оруулна уу';
  }}
  String get rememberMe { switch (language) {
    case AppLanguage.korean:   return '로그인 상태 유지';
    case AppLanguage.english:  return 'Remember me';
    case AppLanguage.japanese: return 'ログイン状態を保持';
    case AppLanguage.chinese:  return '保持登录';
    case AppLanguage.mongolian:return 'Нэвтэрсэн хэвээр';
  }}
  String get orDivider { switch (language) {
    case AppLanguage.korean:   return '또는';
    case AppLanguage.english:  return 'or';
    case AppLanguage.japanese: return 'または';
    case AppLanguage.chinese:  return '或';
    case AppLanguage.mongolian:return 'эсвэл';
  }}
  String get kakaoLogin { switch (language) {
    case AppLanguage.korean:   return '카카오로 로그인';
    case AppLanguage.english:  return 'Login with Kakao';
    case AppLanguage.japanese: return 'カカオでログイン';
    case AppLanguage.chinese:  return 'Kakao账号登录';
    case AppLanguage.mongolian:return 'Kakao-р нэвтрэх';
  }}
  String get googleLogin { switch (language) {
    case AppLanguage.korean:   return 'Google로 로그인';
    case AppLanguage.english:  return 'Login with Google';
    case AppLanguage.japanese: return 'Googleでログイン';
    case AppLanguage.chinese:  return 'Google账号登录';
    case AppLanguage.mongolian:return 'Google-р нэвтрэх';
  }}
  String get signUpGuide { switch (language) {
    case AppLanguage.korean:   return '회원가입: support@2fit.co.kr로 문의해주세요';
    case AppLanguage.english:  return 'Sign up: Contact support@2fit.co.kr';
    case AppLanguage.japanese: return '会員登録: support@2fit.co.krへお問い合わせください';
    case AppLanguage.chinese:  return '注册: 请联系 support@2fit.co.kr';
    case AppLanguage.mongolian:return 'Бүртгэл: support@2fit.co.kr-д хандана уу';
  }}

  String get moreReviews { switch (language) {
    case AppLanguage.korean:   return '리뷰 더보기';
    case AppLanguage.english:  return 'More Reviews';
    case AppLanguage.japanese: return 'レビューをもっと見る';
    case AppLanguage.chinese:  return '查看更多评价';
    case AppLanguage.mongolian:return 'Дэлгэрэнгүй үнэлгээ';
  }}

  // ── 장바구니 ──
  String get cart { switch (language) {
    case AppLanguage.korean:   return '장바구니';
    case AppLanguage.english:  return 'Cart';
    case AppLanguage.japanese: return 'カート';
    case AppLanguage.chinese:  return '购物车';
    case AppLanguage.mongolian:return 'Сагс';
  }}
  String get subtotal { switch (language) {
    case AppLanguage.korean:   return '상품 금액';
    case AppLanguage.english:  return 'Subtotal';
    case AppLanguage.japanese: return '商品金額';
    case AppLanguage.chinese:  return '商品金额';
    case AppLanguage.mongolian:return 'Барааны үнэ';
  }}
  String get shippingFee { switch (language) {
    case AppLanguage.korean:   return '배송비';
    case AppLanguage.english:  return 'Shipping';
    case AppLanguage.japanese: return '送料';
    case AppLanguage.chinese:  return '运费';
    case AppLanguage.mongolian:return 'Хүргэлт';
  }}
  String get totalAmount { switch (language) {
    case AppLanguage.korean:   return '총 결제금액';
    case AppLanguage.english:  return 'Total';
    case AppLanguage.japanese: return '合計金額';
    case AppLanguage.chinese:  return '合计金额';
    case AppLanguage.mongolian:return 'Нийт дүн';
  }}
  String get cartEmpty { switch (language) {
    case AppLanguage.korean:   return '장바구니가 비었습니다';
    case AppLanguage.english:  return 'Your cart is empty';
    case AppLanguage.japanese: return 'カートが空です';
    case AppLanguage.chinese:  return '购物车是空的';
    case AppLanguage.mongolian:return 'Сагс хоосон байна';
  }}
  String get cartEmptySub { switch (language) {
    case AppLanguage.korean:   return '원하는 상품을 담아보세요';
    case AppLanguage.english:  return 'Add items you like';
    case AppLanguage.japanese: return 'お気に入りの商品を追加してください';
    case AppLanguage.chinese:  return '添加您喜欢的商品';
    case AppLanguage.mongolian:return 'Дуртай барааг нэмнэ үү';
  }}
  String get checkout { switch (language) {
    case AppLanguage.korean:   return '주문하기';
    case AppLanguage.english:  return 'Checkout';
    case AppLanguage.japanese: return '注文する';
    case AppLanguage.chinese:  return '结账';
    case AppLanguage.mongolian:return 'Захиалах';
  }}

  // ── 상품 상세 ──
  String get readyMade { switch (language) {
    case AppLanguage.korean:   return '기성품';
    case AppLanguage.english:  return 'Ready-Made';
    case AppLanguage.japanese: return '既製品';
    case AppLanguage.chinese:  return '成衣';
    case AppLanguage.mongolian:return 'Бэлэн бараа';
  }}
  String get groupCustom { switch (language) {
    case AppLanguage.korean:   return '단체 커스텀';
    case AppLanguage.english:  return 'Group Custom';
    case AppLanguage.japanese: return 'グループ注文';
    case AppLanguage.chinese:  return '团体定制';
    case AppLanguage.mongolian:return 'Багийн захиалга';
  }}
  String get personalCustom { switch (language) {
    case AppLanguage.korean:   return '개인 커스텀';
    case AppLanguage.english:  return 'Personal Custom';
    case AppLanguage.japanese: return '個人カスタム';
    case AppLanguage.chinese:  return '个人定制';
    case AppLanguage.mongolian:return 'Хувийн захиалга';
  }}
  String get purchaseMethod { switch (language) {
    case AppLanguage.korean:   return '구매 방식';
    case AppLanguage.english:  return 'Purchase Type';
    case AppLanguage.japanese: return '購入方法';
    case AppLanguage.chinese:  return '购买方式';
    case AppLanguage.mongolian:return 'Худалдан авалтын төрөл';
  }}
  String get bottomLength { switch (language) {
    case AppLanguage.korean:   return '하의 길이 선택';
    case AppLanguage.english:  return 'Select Length';
    case AppLanguage.japanese: return '丈の選択';
    case AppLanguage.chinese:  return '选择裤长';
    case AppLanguage.mongolian:return 'Урт сонгох';
  }}
  String get sizeSelect { switch (language) {
    case AppLanguage.korean:   return '사이즈 선택';
    case AppLanguage.english:  return 'Select Size';
    case AppLanguage.japanese: return 'サイズ選択';
    case AppLanguage.chinese:  return '选择尺码';
    case AppLanguage.mongolian:return 'Хэмжээ сонгох';
  }}
  String get quantity { switch (language) {
    case AppLanguage.korean:   return '수량';
    case AppLanguage.english:  return 'Qty';
    case AppLanguage.japanese: return '数量';
    case AppLanguage.chinese:  return '数量';
    case AppLanguage.mongolian:return 'Тоо';
  }}
  String get sizeChart { switch (language) {
    case AppLanguage.korean:   return '사이즈 차트';
    case AppLanguage.english:  return 'Size Chart';
    case AppLanguage.japanese: return 'サイズチャート';
    case AppLanguage.chinese:  return '尺码表';
    case AppLanguage.mongolian:return 'Хэмжээний хүснэгт';
  }}
  String get adultSize { switch (language) {
    case AppLanguage.korean:   return '성인 (Adult)';
    case AppLanguage.english:  return 'Adult';
    case AppLanguage.japanese: return '大人 (Adult)';
    case AppLanguage.chinese:  return '成人 (Adult)';
    case AppLanguage.mongolian:return 'Насанд хүрсэн';
  }}
  String get juniorSize { switch (language) {
    case AppLanguage.korean:   return '주니어 (Junior)';
    case AppLanguage.english:  return 'Junior';
    case AppLanguage.japanese: return 'ジュニア (Junior)';
    case AppLanguage.chinese:  return '青少年 (Junior)';
    case AppLanguage.mongolian:return 'Хүүхэд';
  }}

  // ── 마이페이지 ──
  String get myOrders { switch (language) {
    case AppLanguage.korean:   return '내 주문';
    case AppLanguage.english:  return 'My Orders';
    case AppLanguage.japanese: return '注文履歴';
    case AppLanguage.chinese:  return '我的订单';
    case AppLanguage.mongolian:return 'Миний захиалга';
  }}
  String get wishlist { switch (language) {
    case AppLanguage.korean:   return '찜 목록';
    case AppLanguage.english:  return 'Wishlist';
    case AppLanguage.japanese: return 'お気に入り';
    case AppLanguage.chinese:  return '收藏夹';
    case AppLanguage.mongolian:return 'Хадгалсан';
  }}
  String get myReviews { switch (language) {
    case AppLanguage.korean:   return '내 리뷰';
    case AppLanguage.english:  return 'My Reviews';
    case AppLanguage.japanese: return 'レビュー';
    case AppLanguage.chinese:  return '我的评价';
    case AppLanguage.mongolian:return 'Миний үнэлгээ';
  }}
  String get settings { switch (language) {
    case AppLanguage.korean:   return '설정';
    case AppLanguage.english:  return 'Settings';
    case AppLanguage.japanese: return '設定';
    case AppLanguage.chinese:  return '设置';
    case AppLanguage.mongolian:return 'Тохиргоо';
  }}
  String get logout { switch (language) {
    case AppLanguage.korean:   return '로그아웃';
    case AppLanguage.english:  return 'Logout';
    case AppLanguage.japanese: return 'ログアウト';
    case AppLanguage.chinese:  return '退出登录';
    case AppLanguage.mongolian:return 'Гарах';
  }}
  String get login { switch (language) {
    case AppLanguage.korean:   return '로그인';
    case AppLanguage.english:  return 'Login';
    case AppLanguage.japanese: return 'ログイン';
    case AppLanguage.chinese:  return '登录';
    case AppLanguage.mongolian:return 'Нэвтрэх';
  }}

  // ── 주문 안내 ──
  String get orderGuide { switch (language) {
    case AppLanguage.korean:   return '주문 안내';
    case AppLanguage.english:  return 'Order Guide';
    case AppLanguage.japanese: return '注文案内';
    case AppLanguage.chinese:  return '订购指南';
    case AppLanguage.mongolian:return 'Захиалгын гарын авлага';
  }}
  String get groupOrder { switch (language) {
    case AppLanguage.korean:   return '단체 주문';
    case AppLanguage.english:  return 'Group Order';
    case AppLanguage.japanese: return '団体注文';
    case AppLanguage.chinese:  return '团体订单';
    case AppLanguage.mongolian:return 'Багийн захиалга';
  }}
  String get personalOrder { switch (language) {
    case AppLanguage.korean:   return '개인 맞춤 제작';
    case AppLanguage.english:  return 'Personal Custom';
    case AppLanguage.japanese: return '個人カスタム制作';
    case AppLanguage.chinese:  return '个性化定制';
    case AppLanguage.mongolian:return 'Хувийн дизайн';
  }}
  String get placeOrder { switch (language) {
    case AppLanguage.korean:   return '주문하기';
    case AppLanguage.english:  return 'Place Order';
    case AppLanguage.japanese: return '注文する';
    case AppLanguage.chinese:  return '下单';
    case AppLanguage.mongolian:return 'Захиалах';
  }}

  // ── 상품 상세 ──
  String get productDetail { switch (language) {
    case AppLanguage.korean:   return '상품 상세';
    case AppLanguage.english:  return 'Product Detail';
    case AppLanguage.japanese: return '商品詳細';
    case AppLanguage.chinese:  return '商品详情';
    case AppLanguage.mongolian:return 'Бүтээгдэхүүний дэлгэрэнгүй';
  }}
  String get selectSize { switch (language) {
    case AppLanguage.korean:   return '사이즈 선택';
    case AppLanguage.english:  return 'Select Size';
    case AppLanguage.japanese: return 'サイズを選ぶ';
    case AppLanguage.chinese:  return '选择尺码';
    case AppLanguage.mongolian:return 'Хэмжээ сонгох';
  }}
  String get selectColor { switch (language) {
    case AppLanguage.korean:   return '컬러';
    case AppLanguage.english:  return 'Color';
    case AppLanguage.japanese: return 'カラー';
    case AppLanguage.chinese:  return '颜色';
    case AppLanguage.mongolian:return 'Өнгө';
  }}
  String get purchaseType { switch (language) {
    case AppLanguage.korean:   return '구매 방식';
    case AppLanguage.english:  return 'Purchase Type';
    case AppLanguage.japanese: return '購入方法';
    case AppLanguage.chinese:  return '购买方式';
    case AppLanguage.mongolian:return 'Худалдан авах арга';
  }}
  String get customMade { switch (language) {
    case AppLanguage.korean:   return '커스텀 제작';
    case AppLanguage.english:  return 'Custom Order';
    case AppLanguage.japanese: return 'カスタム制作';
    case AppLanguage.chinese:  return '定制生产';
    case AppLanguage.mongolian:return 'Захиалгат үйлдвэрлэл';
  }}
  String get adultTab { switch (language) {
    case AppLanguage.korean:   return '성인';
    case AppLanguage.english:  return 'Adult';
    case AppLanguage.japanese: return '大人';
    case AppLanguage.chinese:  return '成人';
    case AppLanguage.mongolian:return 'Насанд хүрсэн';
  }}
  String get juniorTab { switch (language) {
    case AppLanguage.korean:   return '주니어';
    case AppLanguage.english:  return 'Junior';
    case AppLanguage.japanese: return 'ジュニア';
    case AppLanguage.chinese:  return '青少年';
    case AppLanguage.mongolian:return 'Залуу';
  }}

  // ── 장바구니 ──
  String get continueShopping { switch (language) {
    case AppLanguage.korean:   return '쇼핑 계속하기';
    case AppLanguage.english:  return 'Continue Shopping';
    case AppLanguage.japanese: return 'ショッピングを続ける';
    case AppLanguage.chinese:  return '继续购物';
    case AppLanguage.mongolian:return 'Дэлгүүрлэлт үргэлжлүүлэх';
  }}
  String get orderTotal { switch (language) {
    case AppLanguage.korean:   return '주문 합계';
    case AppLanguage.english:  return 'Order Total';
    case AppLanguage.japanese: return '注文合計';
    case AppLanguage.chinese:  return '订单总额';
    case AppLanguage.mongolian:return 'Захиалгын нийт';
  }}

  // ── 로그인/회원가입 ──
  String get forgotPassword { switch (language) {
    case AppLanguage.korean:   return '비밀번호 찾기';
    case AppLanguage.english:  return 'Forgot Password';
    case AppLanguage.japanese: return 'パスワードを忘れた';
    case AppLanguage.chinese:  return '忘记密码';
    case AppLanguage.mongolian:return 'Нууц үг мартсан';
  }}
  String get emailAddress { switch (language) {
    case AppLanguage.korean:   return '이메일 주소';
    case AppLanguage.english:  return 'Email Address';
    case AppLanguage.japanese: return 'メールアドレス';
    case AppLanguage.chinese:  return '电子邮件地址';
    case AppLanguage.mongolian:return 'Имэйл хаяг';
  }}

  // ── 마이페이지 ──
  String get myPage { switch (language) {
    case AppLanguage.korean:   return '마이페이지';
    case AppLanguage.english:  return 'My Page';
    case AppLanguage.japanese: return 'マイページ';
    case AppLanguage.chinese:  return '我的页面';
    case AppLanguage.mongolian:return 'Миний хуудас';
  }}

  // ── 공통 UI ──
  String get close { switch (language) {
    case AppLanguage.korean:   return '닫기';
    case AppLanguage.english:  return 'Close';
    case AppLanguage.japanese: return '閉じる';
    case AppLanguage.chinese:  return '关闭';
    case AppLanguage.mongolian:return 'Хаах';
  }}
  String get loading { switch (language) {
    case AppLanguage.korean:   return '로딩 중...';
    case AppLanguage.english:  return 'Loading...';
    case AppLanguage.japanese: return '読み込み中...';
    case AppLanguage.chinese:  return '加载中...';
    case AppLanguage.mongolian:return 'Уншиж байна...';
  }}
  String get error { switch (language) {
    case AppLanguage.korean:   return '오류가 발생했습니다';
    case AppLanguage.english:  return 'An error occurred';
    case AppLanguage.japanese: return 'エラーが発生しました';
    case AppLanguage.chinese:  return '发生错误';
    case AppLanguage.mongolian:return 'Алдаа гарлаа';
  }}
  String get retry { switch (language) {
    case AppLanguage.korean:   return '다시 시도';
    case AppLanguage.english:  return 'Retry';
    case AppLanguage.japanese: return '再試行';
    case AppLanguage.chinese:  return '重试';
    case AppLanguage.mongolian:return 'Дахин оролдох';
  }}
  String get linkCopied { switch (language) {
    case AppLanguage.korean:   return '링크가 복사되었습니다';
    case AppLanguage.english:  return 'Link copied!';
    case AppLanguage.japanese: return 'リンクがコピーされました';
    case AppLanguage.chinese:  return '链接已复制';
    case AppLanguage.mongolian:return 'Холбоос хуулагдлаа';
  }}
  String get loginRequired { switch (language) {
    case AppLanguage.korean:   return '로그인이 필요합니다';
    case AppLanguage.english:  return 'Login required';
    case AppLanguage.japanese: return 'ログインが必要です';
    case AppLanguage.chinese:  return '需要登录';
    case AppLanguage.mongolian:return 'Нэвтрэх шаардлагатай';
  }}
  String get addedToCart { switch (language) {
    case AppLanguage.korean:   return '장바구니에 추가되었습니다';
    case AppLanguage.english:  return 'Added to cart';
    case AppLanguage.japanese: return 'カートに追加されました';
    case AppLanguage.chinese:  return '已加入购物车';
    case AppLanguage.mongolian:return 'Тэргэнд нэмэгдлээ';
  }}
  String get addedToWishlist { switch (language) {
    case AppLanguage.korean:   return '찜 목록에 추가되었습니다';
    case AppLanguage.english:  return 'Added to wishlist';
    case AppLanguage.japanese: return 'お気に入りに追加されました';
    case AppLanguage.chinese:  return '已添加到收藏夹';
    case AppLanguage.mongolian:return 'Хүслийн жагсаалтад нэмэгдлээ';
  }}
  String get removedFromWishlist { switch (language) {
    case AppLanguage.korean:   return '찜 목록에서 제거되었습니다';
    case AppLanguage.english:  return 'Removed from wishlist';
    case AppLanguage.japanese: return 'お気に入りから削除されました';
    case AppLanguage.chinese:  return '已从收藏夹删除';
    case AppLanguage.mongolian:return 'Хүслийн жагсаалтаас хасагдлаа';
  }}
  String get selectSizeFirst { switch (language) {
    case AppLanguage.korean:   return '사이즈를 선택해주세요';
    case AppLanguage.english:  return 'Please select a size';
    case AppLanguage.japanese: return 'サイズを選択してください';
    case AppLanguage.chinese:  return '请选择尺码';
    case AppLanguage.mongolian:return 'Хэмжээ сонгоно уу';
  }}
  String get selectColorFirst { switch (language) {
    case AppLanguage.korean:   return '컬러를 선택해주세요';
    case AppLanguage.english:  return 'Please select a color';
    case AppLanguage.japanese: return 'カラーを選択してください';
    case AppLanguage.chinese:  return '请选择颜色';
    case AppLanguage.mongolian:return 'Өнгө сонгоно уу';
  }}
  String get forgotPasswordGuide { switch (language) {
    case AppLanguage.korean:   return '비밀번호 재설정 링크가 이메일로 전송됩니다.\n고객센터: help@2fit.co.kr';
    case AppLanguage.english:  return 'Password reset link will be sent to your email.\nSupport: help@2fit.co.kr';
    case AppLanguage.japanese: return 'パスワードリセットリンクをメールに送ります。\nサポート: help@2fit.co.kr';
    case AppLanguage.chinese:  return '密码重置链接将发送到您的邮箱。\n客服: help@2fit.co.kr';
    case AppLanguage.mongolian:return 'Нууц үг шинэчлэх холбоосыг имэйлээр илгээх болно.\nДэмжлэг: help@2fit.co.kr';
  }}

  // ── 채팅 상담 ──
  String get chatTitle { switch (language) {
    case AppLanguage.korean:   return '2FIT 고객센터';
    case AppLanguage.english:  return '2FIT Support';
    case AppLanguage.japanese: return '2FIT サポート';
    case AppLanguage.chinese:  return '2FIT 客服';
    case AppLanguage.mongolian:return '2FIT Дэмжлэг';
  }}
  String get chatOnline { switch (language) {
    case AppLanguage.korean:   return '온라인';
    case AppLanguage.english:  return 'Online';
    case AppLanguage.japanese: return 'オンライン';
    case AppLanguage.chinese:  return '在线';
    case AppLanguage.mongolian:return 'Онлайн';
  }}
  String get chatWelcome { switch (language) {
    case AppLanguage.korean:   return '안녕하세요! 2FIT MALL 고객센터입니다 😊\n무엇을 도와드릴까요?';
    case AppLanguage.english:  return 'Hello! Welcome to 2FIT MALL Support 😊\nHow can we help you?';
    case AppLanguage.japanese: return 'こんにちは！2FIT MALLサポートへようこそ 😊\nご用件をお聞かせください。';
    case AppLanguage.chinese:  return '您好！欢迎来到2FIT MALL客服 😊\n请问有什么可以帮助您？';
    case AppLanguage.mongolian:return 'Сайн байна уу! 2FIT MALL тусламжид тавтай морилно уу 😊\nЯмар асуудал байна?';
  }}
  String get chatWelcome2 { switch (language) {
    case AppLanguage.korean:   return '주문 문의, 배송 조회, 사이즈 추천 등 궁금한 점을 말씀해주세요.';
    case AppLanguage.english:  return 'Feel free to ask about orders, shipping, size recommendations, and more.';
    case AppLanguage.japanese: return 'ご注文、配送、サイズ推薦などお気軽にどうぞ。';
    case AppLanguage.chinese:  return '欢迎询问订单、配送、尺码推荐等问题。';
    case AppLanguage.mongolian:return 'Захиалга, хүргэлт, хэмжээний зөвлөмж гэх мэт асуулт асуугаарай.';
  }}
  String get chatInputHint { switch (language) {
    case AppLanguage.korean:   return '메시지를 입력하세요...';
    case AppLanguage.english:  return 'Type a message...';
    case AppLanguage.japanese: return 'メッセージを入力...';
    case AppLanguage.chinese:  return '输入消息...';
    case AppLanguage.mongolian:return 'Мессеж бичнэ үү...';
  }}
  String get chatQuickTitle { switch (language) {
    case AppLanguage.korean:   return '자주 묻는 질문';
    case AppLanguage.english:  return 'Frequently Asked Questions';
    case AppLanguage.japanese: return 'よくある質問';
    case AppLanguage.chinese:  return '常见问题';
    case AppLanguage.mongolian:return 'Түгээмэл асуултууд';
  }}
  String get chatBackToFaq { switch (language) {
    case AppLanguage.korean:   return '자주 묻는 질문으로 돌아가기';
    case AppLanguage.english:  return 'Back to FAQ';
    case AppLanguage.japanese: return 'よくある質問に戻る';
    case AppLanguage.chinese:  return '返回常见问题';
    case AppLanguage.mongolian:return 'Асуултуудруу буцах';
  }}
  String get chatEliteTitle { switch (language) {
    case AppLanguage.korean:   return '엘리트 선수 전용 문의';
    case AppLanguage.english:  return 'Elite Athlete Inquiry';
    case AppLanguage.japanese: return 'エリートアスリート専用問い合わせ';
    case AppLanguage.chinese:  return '精英运动员专属咨询';
    case AppLanguage.mongolian:return 'Элит тамирчны лавлагаа';
  }}
  String get chatEliteDesc { switch (language) {
    case AppLanguage.korean:   return '엘리트 선수는 전담 상담사에게 직접 연결됩니다';
    case AppLanguage.english:  return 'Elite athletes are connected directly to a dedicated consultant';
    case AppLanguage.japanese: return 'エリート選手は専任コンサルタントに直接繋がります';
    case AppLanguage.chinese:  return '精英运动员将直接连接到专属顾问';
    case AppLanguage.mongolian:return 'Элит тамирчдыг тусгай зөвлөхтэй шууд холбоно';
  }}
  String get chatCallNow { switch (language) {
    case AppLanguage.korean:   return '지금 전화하기';
    case AppLanguage.english:  return 'Call Now';
    case AppLanguage.japanese: return '今すぐ電話する';
    case AppLanguage.chinese:  return '立即致电';
    case AppLanguage.mongolian:return 'Одоо залгах';
  }}
  String get chatPhoneInquiry { switch (language) {
    case AppLanguage.korean:   return '전화 문의';
    case AppLanguage.english:  return 'Phone Inquiry';
    case AppLanguage.japanese: return '電話で問い合わせ';
    case AppLanguage.chinese:  return '电话咨询';
    case AppLanguage.mongolian:return 'Утасны лавлагаа';
  }}
  String get chatWeekdayHours { switch (language) {
    case AppLanguage.korean:   return '평일 10:00 - 18:00 (점심 12:00-14:00)';
    case AppLanguage.english:  return 'Weekdays 10:00-18:00 (Lunch 12:00-14:00)';
    case AppLanguage.japanese: return '平日 10:00-18:00（昼休み 12:00-14:00）';
    case AppLanguage.chinese:  return '工作日 10:00-18:00（午休12:00-14:00）';
    case AppLanguage.mongolian:return 'Ажлын өдөр 10:00-18:00';
  }}
  String get chatTranslatedLabel { switch (language) {
    case AppLanguage.korean:   return '원문 보기';
    case AppLanguage.english:  return 'View original';
    case AppLanguage.japanese: return '原文を見る';
    case AppLanguage.chinese:  return '查看原文';
    case AppLanguage.mongolian:return 'Эх текст харах';
  }}

  // ── 채팅 FAQ 항목 (키) ──
  String get faqOrderStatus { switch (language) {
    case AppLanguage.korean:   return '주문 상태 확인';
    case AppLanguage.english:  return 'Order Status';
    case AppLanguage.japanese: return '注文状況確認';
    case AppLanguage.chinese:  return '订单状态查询';
    case AppLanguage.mongolian:return 'Захиалгын байдал';
  }}
  String get faqShipping { switch (language) {
    case AppLanguage.korean:   return '배송 조회';
    case AppLanguage.english:  return 'Shipping Tracking';
    case AppLanguage.japanese: return '配送照会';
    case AppLanguage.chinese:  return '物流查询';
    case AppLanguage.mongolian:return 'Хүргэлт хянах';
  }}
  String get faqSize { switch (language) {
    case AppLanguage.korean:   return '사이즈 추천';
    case AppLanguage.english:  return 'Size Recommendation';
    case AppLanguage.japanese: return 'サイズ推薦';
    case AppLanguage.chinese:  return '尺码推荐';
    case AppLanguage.mongolian:return 'Хэмжээний зөвлөмж';
  }}
  String get faqCustomOrder { switch (language) {
    case AppLanguage.korean:   return '커스텀 주문 문의';
    case AppLanguage.english:  return 'Custom Order';
    case AppLanguage.japanese: return 'カスタム注文問い合わせ';
    case AppLanguage.chinese:  return '定制订单咨询';
    case AppLanguage.mongolian:return 'Захиалгат захиалга';
  }}
  String get faqReturn { switch (language) {
    case AppLanguage.korean:   return '교환/환불 신청';
    case AppLanguage.english:  return 'Exchange/Refund';
    case AppLanguage.japanese: return '交換・返品申請';
    case AppLanguage.chinese:  return '换货/退款申请';
    case AppLanguage.mongolian:return 'Буцаалт/Буцаан олгох';
  }}
  String get faqGroupOrder { switch (language) {
    case AppLanguage.korean:   return '단체 주문 문의';
    case AppLanguage.english:  return 'Group Order';
    case AppLanguage.japanese: return '団体注文問い合わせ';
    case AppLanguage.chinese:  return '团体订单咨询';
    case AppLanguage.mongolian:return 'Бүлгийн захиалга';
  }}
  String get faqEliteAthlete { switch (language) {
    case AppLanguage.korean:   return '엘리트 선수 문의';
    case AppLanguage.english:  return 'Elite Athlete Inquiry';
    case AppLanguage.japanese: return 'エリート選手問い合わせ';
    case AppLanguage.chinese:  return '精英运动员咨询';
    case AppLanguage.mongolian:return 'Элит тамирчны асуулт';
  }}

  // ── 채팅 FAQ 답변 ──
  String get faqOrderStatusAns { switch (language) {
    case AppLanguage.korean:   return '주문 번호를 알려주시면 주문 상태를 확인해 드리겠습니다.\n마이페이지 > 주문내역에서도 확인 가능합니다.';
    case AppLanguage.english:  return 'Please provide your order number and we will check the status.\nYou can also check in My Page > Order History.';
    case AppLanguage.japanese: return 'ご注文番号をお知らせいただければ、注文状況を確認いたします。\nマイページ > 注文履歴からもご確認いただけます。';
    case AppLanguage.chinese:  return '请提供您的订单号，我们将为您查询订单状态。\n也可在我的页面 > 订单历史中查看。';
    case AppLanguage.mongolian:return 'Захиалгын дугаараа өгвөл захиалгын байдлыг шалгана.\nМиний хуудас > Захиалгын түүхээс ч шалгах боломжтой.';
  }}
  String get faqShippingAns { switch (language) {
    case AppLanguage.korean:   return '배송 조회는 마이페이지 > 주문내역에서 운송장 번호로 조회하실 수 있습니다.\nCJ대한통운 기준 2~3 영업일 소요됩니다.';
    case AppLanguage.english:  return 'You can track your shipment with the tracking number in My Page > Order History.\nTypically takes 2~3 business days via CJ Logistics.';
    case AppLanguage.japanese: return 'マイページ > 注文履歴で追跡番号から配送状況を確認できます。\nCJ大韓通運基準で2〜3営業日かかります。';
    case AppLanguage.chinese:  return '可在我的页面 > 订单历史中用运单号查询配送状态。\nCJ大韩通运标准需2~3个工作日。';
    case AppLanguage.mongolian:return 'Миний хуудас > Захиалгын түүхэд трекинг дугаараар хянана.\nCJ Logistics-ээр 2~3 ажлын өдөр болно.';
  }}
  String get faqSizeAns { switch (language) {
    case AppLanguage.korean:   return '사이즈 추천을 위해 키와 몸무게, 평소 사이즈를 알려주세요!\n상품 상세 페이지의 사이즈 가이드도 참고해 주세요 😊';
    case AppLanguage.english:  return 'Please tell us your height, weight, and usual size for a recommendation!\nAlso check the size guide on the product detail page 😊';
    case AppLanguage.japanese: return 'サイズ推薦のため、身長・体重・普段のサイズを教えてください！\n商品詳細ページのサイズガイドもご参考ください 😊';
    case AppLanguage.chinese:  return '请告诉我们您的身高、体重和平时的尺码，以便推荐！\n也请参考商品详情页的尺码指南 😊';
    case AppLanguage.mongolian:return 'Өндөр, жин, ердийн хэмжээгээ хэлнэ үү!\nБүтээгдэхүүний хэмжээний гарын авлагыг ч харна уу 😊';
  }}
  String get faqCustomOrderAns { switch (language) {
    case AppLanguage.korean:   return '커스텀 주문은 이름/번호 인쇄, 팀 로고 삽입이 가능합니다.\n주문서식 탭에서 주문서 양식을 확인하시고, 작성 후 문의해 주세요.';
    case AppLanguage.english:  return 'Custom orders support name/number printing and team logo insertion.\nPlease check the order form in the Order Guide tab and contact us.';
    case AppLanguage.japanese: return 'カスタム注文は名前/番号印刷、チームロゴ挿入が可能です。\n注文書式タブで注文書をご確認の上、お問い合わせください。';
    case AppLanguage.chinese:  return '定制订单支持名称/号码印刷、团队Logo插入。\n请在订单格式标签中查看订单表格后联系我们。';
    case AppLanguage.mongolian:return 'Захиалгат захиалгад нэр/дугаар хэвлэх, багийн лого оруулах боломжтой.\nЗахиалгын маягтыг Захиалгын гарын авлага таб-аас харна уу.';
  }}
  String get faqReturnAns { switch (language) {
    case AppLanguage.korean:   return '교환/환불은 수령 후 7일 이내 가능합니다.\n단, 커스텀 인쇄 상품은 교환/환불이 불가합니다.\n신청을 위해 주문번호와 사유를 알려주세요.';
    case AppLanguage.english:  return 'Exchange/refund is available within 7 days of receipt.\nHowever, custom printed items cannot be exchanged or refunded.\nPlease provide your order number and reason to apply.';
    case AppLanguage.japanese: return '交換・返品は受領後7日以内に可能です。\nただし、カスタム印刷商品は交換・返品不可です。\n申請のため、注文番号と理由をお知らせください。';
    case AppLanguage.chinese:  return '收货后7天内可申请换货/退款。\n但定制印刷商品不可换货/退款。\n请提供订单号和原因申请。';
    case AppLanguage.mongolian:return 'Хүлээн авсанаас хойш 7 хоногийн дотор солилт/буцаалт боломжтой.\nГэхдээ захиалгат хэвлэмэл бараанд хамаарахгүй.\nЗахиалгын дугаар болон шалтгааныг мэдэгдэнэ үү.';
  }}
  String get faqGroupOrderAns { switch (language) {
    case AppLanguage.korean:   return '단체 주문은 5인 이상부터 가능하며, 팀 할인 혜택이 적용됩니다.\n주문서식 > 단체 주문서를 작성하여 문의해 주세요!';
    case AppLanguage.english:  return 'Group orders are available for 5 or more people with team discounts.\nPlease fill out the Group Order Form in Order Guide and contact us!';
    case AppLanguage.japanese: return '団体注文は5人以上から可能で、チーム割引が適用されます。\n注文書式 > 団体注文書をご記入の上、お問い合わせください！';
    case AppLanguage.chinese:  return '5人及以上可申请团体订单，享受团队折扣优惠。\n请填写订单格式 > 团体订单表并联系我们！';
    case AppLanguage.mongolian:return 'Бүлгийн захиалга 5 ба түүнээс дээш хүнд боломжтой, багийн хөнгөлөлт байна.\nЗахиалгын гарын авлага > Бүлгийн захиалгын маягтыг бөглөнэ үү!';
  }}

  // ── 알림 시스템 ──
  String get adminNotifyTitle { switch (language) {
    case AppLanguage.korean:   return '새 문의 알림';
    case AppLanguage.english:  return 'New Inquiry Alert';
    case AppLanguage.japanese: return '新規問い合わせ通知';
    case AppLanguage.chinese:  return '新咨询通知';
    case AppLanguage.mongolian:return 'Шинэ лавлагааны мэдэгдэл';
  }}
  String get adminNotifyKakaoGuide { switch (language) {
    case AppLanguage.korean:   return '카카오/문자 알림을 받으려면 관리자 설정에서 전화번호를 등록하세요.';
    case AppLanguage.english:  return 'Register your phone number in admin settings to receive KakaoTalk/SMS alerts.';
    case AppLanguage.japanese: return '管理者設定で電話番号を登録してカカオ/SMSアラートを受け取ってください。';
    case AppLanguage.chinese:  return '在管理员设置中注册手机号以接收KakaoTalk/短信通知。';
    case AppLanguage.mongolian:return 'KakaoTalk/SMS мэдэгдэл авахын тулд утасны дугаараа бүртгүүлнэ үү.';
  }}

  // ── 상품 카테고리/섹션 공통 ──
  String get catSkinsuit { switch (language) {
    case AppLanguage.korean:   return '스킨슈트';
    case AppLanguage.english:  return 'Skinsuit';
    case AppLanguage.japanese: return 'スキンスーツ';
    case AppLanguage.chinese:  return '皮肤衣';
    case AppLanguage.mongolian:return 'Арьсны костюм';
  }}
  String get catEvent { switch (language) {
    case AppLanguage.korean:   return '이벤트';
    case AppLanguage.english:  return 'Event';
    case AppLanguage.japanese: return 'イベント';
    case AppLanguage.chinese:  return '活动';
    case AppLanguage.mongolian:return 'Үйл явдал';
  }}
  String get back { switch (language) {
    case AppLanguage.korean:   return '뒤로';
    case AppLanguage.english:  return 'Back';
    case AppLanguage.japanese: return '戻る';
    case AppLanguage.chinese:  return '返回';
    case AppLanguage.mongolian:return 'Буцах';
  }}
  String get reviews { switch (language) {
    case AppLanguage.korean:   return '리뷰';
    case AppLanguage.english:  return 'Reviews';
    case AppLanguage.japanese: return 'レビュー';
    case AppLanguage.chinese:  return '评价';
    case AppLanguage.mongolian:return 'Сэтгэгдлүүд';
  }}
  String get writeReview { switch (language) {
    case AppLanguage.korean:   return '리뷰 작성';
    case AppLanguage.english:  return 'Write a Review';
    case AppLanguage.japanese: return 'レビューを書く';
    case AppLanguage.chinese:  return '写评价';
    case AppLanguage.mongolian:return 'Сэтгэгдэл бичих';
  }}
  String get profile { switch (language) {
    case AppLanguage.korean:   return '프로필';
    case AppLanguage.english:  return 'Profile';
    case AppLanguage.japanese: return 'プロフィール';
    case AppLanguage.chinese:  return '个人资料';
    case AppLanguage.mongolian:return 'Профайл';
  }}
  String get orderHistory { switch (language) {
    case AppLanguage.korean:   return '주문내역';
    case AppLanguage.english:  return 'Order History';
    case AppLanguage.japanese: return '注文履歴';
    case AppLanguage.chinese:  return '订单历史';
    case AppLanguage.mongolian:return 'Захиалгын түүх';
  }}
  String get points { switch (language) {
    case AppLanguage.korean:   return '포인트';
    case AppLanguage.english:  return 'Points';
    case AppLanguage.japanese: return 'ポイント';
    case AppLanguage.chinese:  return '积分';
    case AppLanguage.mongolian:return 'Оноо';
  }}
  String get address { switch (language) {
    case AppLanguage.korean:   return '배송지';
    case AppLanguage.english:  return 'Address';
    case AppLanguage.japanese: return '配送先';
    case AppLanguage.chinese:  return '收货地址';
    case AppLanguage.mongolian:return 'Хүргэх хаяг';
  }}
  String get newArrival { switch (language) {
    case AppLanguage.korean:   return '신상품';
    case AppLanguage.english:  return 'New Arrival';
    case AppLanguage.japanese: return '新着';
    case AppLanguage.chinese:  return '新品';
    case AppLanguage.mongolian:return 'Шинэ бараа';
  }}
  String get bestSeller { switch (language) {
    case AppLanguage.korean:   return '베스트셀러';
    case AppLanguage.english:  return 'Best Seller';
    case AppLanguage.japanese: return 'ベストセラー';
    case AppLanguage.chinese:  return '热销';
    case AppLanguage.mongolian:return 'Хамгийн их зарагдсан';
  }}
  String get sale { switch (language) {
    case AppLanguage.korean:   return '세일';
    case AppLanguage.english:  return 'Sale';
    case AppLanguage.japanese: return 'セール';
    case AppLanguage.chinese:  return '特卖';
    case AppLanguage.mongolian:return 'Хямдрал';
  }}
  String get total { switch (language) {
    case AppLanguage.korean:   return '합계';
    case AppLanguage.english:  return 'Total';
    case AppLanguage.japanese: return '合計';
    case AppLanguage.chinese:  return '合计';
    case AppLanguage.mongolian:return 'Нийт';
  }}
  String get shipping { switch (language) {
    case AppLanguage.korean:   return '배송비';
    case AppLanguage.english:  return 'Shipping';
    case AppLanguage.japanese: return '送料';
    case AppLanguage.chinese:  return '运费';
    case AppLanguage.mongolian:return 'Хүргэлтийн төлбөр';
  }}
  String get color { switch (language) {
    case AppLanguage.korean:   return '컬러';
    case AppLanguage.english:  return 'Color';
    case AppLanguage.japanese: return 'カラー';
    case AppLanguage.chinese:  return '颜色';
    case AppLanguage.mongolian:return 'Өнгө';
  }}
  String get size { switch (language) {
    case AppLanguage.korean:   return '사이즈';
    case AppLanguage.english:  return 'Size';
    case AppLanguage.japanese: return 'サイズ';
    case AppLanguage.chinese:  return '尺码';
    case AppLanguage.mongolian:return 'Хэмжээ';
  }}
  String get material { switch (language) {
    case AppLanguage.korean:   return '소재';
    case AppLanguage.english:  return 'Material';
    case AppLanguage.japanese: return '素材';
    case AppLanguage.chinese:  return '材质';
    case AppLanguage.mongolian:return 'Материал';
  }}
  String get sizeGuide { switch (language) {
    case AppLanguage.korean:   return '사이즈 가이드';
    case AppLanguage.english:  return 'Size Guide';
    case AppLanguage.japanese: return 'サイズガイド';
    case AppLanguage.chinese:  return '尺码指南';
    case AppLanguage.mongolian:return 'Хэмжээний гарын авлага';
  }}
  String get gender { switch (language) {
    case AppLanguage.korean:   return '성별';
    case AppLanguage.english:  return 'Gender';
    case AppLanguage.japanese: return '性別';
    case AppLanguage.chinese:  return '性别';
    case AppLanguage.mongolian:return 'Хүйс';
  }}
  String get male { switch (language) {
    case AppLanguage.korean:   return '남성';
    case AppLanguage.english:  return 'Male';
    case AppLanguage.japanese: return '男性';
    case AppLanguage.chinese:  return '男';
    case AppLanguage.mongolian:return 'Эрэгтэй';
  }}
  String get female { switch (language) {
    case AppLanguage.korean:   return '여성';
    case AppLanguage.english:  return 'Female';
    case AppLanguage.japanese: return '女性';
    case AppLanguage.chinese:  return '女';
    case AppLanguage.mongolian:return 'Эмэгтэй';
  }}

  // ── 앱 드로어 / 공통 ──
  String get loginSignup { switch (language) {
    case AppLanguage.korean:   return '로그인 / 회원가입';
    case AppLanguage.english:  return 'Login / Sign Up';
    case AppLanguage.japanese: return 'ログイン / 新規登録';
    case AppLanguage.chinese:  return '登录 / 注册';
    case AppLanguage.mongolian:return 'Нэвтрэх / Бүртгүүлэх';
  }}
  String get brandInfo { switch (language) {
    case AppLanguage.korean:   return '브랜드 소개';
    case AppLanguage.english:  return 'About Us';
    case AppLanguage.japanese: return 'ブランド紹介';
    case AppLanguage.chinese:  return '品牌介绍';
    case AppLanguage.mongolian:return 'Брэндийн тухай';
  }}
  String get brandDescription { switch (language) {
    case AppLanguage.korean:   return '2FIT는 스포츠·피트니스 전문 의류 브랜드로,\n고품질 나일론·스판덱스 소재를 사용하여\n최상의 착용감과 기능성을 제공합니다.';
    case AppLanguage.english:  return '2FIT is a professional sports & fitness apparel brand,\noffering the best comfort and performance\nwith high-quality nylon & spandex materials.';
    case AppLanguage.japanese: return '2FITはスポーツ・フィットネス専門ウェアブランドで、\n高品質ナイロン・スパンデックス素材を使用し、\n最高の着用感と機能性を提供します。';
    case AppLanguage.chinese:  return '2FIT是专业运动健身服装品牌，\n采用高品质尼龙·氨纶面料，\n提供最佳穿着感和功能性。';
    case AppLanguage.mongolian:return '2FIT бол спорт, фитнессийн мэргэжлийн хувцасны брэнд,\nөндөр чанарын нейлон, спандекс даавуу ашиглан\nхамгийн сайн тав тух, ажиллагааг хангадаг.';
  }}
  String get adminDashboard { switch (language) {
    case AppLanguage.korean:   return '관리자 대시보드';
    case AppLanguage.english:  return 'Admin Dashboard';
    case AppLanguage.japanese: return '管理者ダッシュボード';
    case AppLanguage.chinese:  return '管理员控制台';
    case AppLanguage.mongolian:return 'Удирдагчийн самбар';
  }}
  String get adminManageDesc { switch (language) {
    case AppLanguage.korean:   return '주문 · 상품 · 회원 관리';
    case AppLanguage.english:  return 'Orders · Products · Members';
    case AppLanguage.japanese: return '注文 · 商品 · 会員管理';
    case AppLanguage.chinese:  return '订单 · 商品 · 会员管理';
    case AppLanguage.mongolian:return 'Захиалга · Бараа · Гишүүн';
  }}
  String get adminPanel { switch (language) {
    case AppLanguage.korean:   return '관리자 패널';
    case AppLanguage.english:  return 'Admin Panel';
    case AppLanguage.japanese: return '管理者パネル';
    case AppLanguage.chinese:  return '管理员面板';
    case AppLanguage.mongolian:return 'Удирдагчийн самбар';
  }}
  String get adminBadge { switch (language) {
    case AppLanguage.korean:   return '관리자';
    case AppLanguage.english:  return 'Admin';
    case AppLanguage.japanese: return '管理者';
    case AppLanguage.chinese:  return '管理员';
    case AppLanguage.mongolian:return 'Удирдагч';
  }}

  // ── 정렬/필터 ──
  String get sortLatest { switch (language) {
    case AppLanguage.korean:   return '최신순';
    case AppLanguage.english:  return 'Latest';
    case AppLanguage.japanese: return '新着順';
    case AppLanguage.chinese:  return '最新';
    case AppLanguage.mongolian:return 'Шинэ';
  }}
  String get sortPriceLow { switch (language) {
    case AppLanguage.korean:   return '가격 낮은 순';
    case AppLanguage.english:  return 'Price: Low';
    case AppLanguage.japanese: return '価格安い順';
    case AppLanguage.chinese:  return '价格低';
    case AppLanguage.mongolian:return 'Үнэ бага';
  }}
  String get sortPriceHigh { switch (language) {
    case AppLanguage.korean:   return '가격 높은 순';
    case AppLanguage.english:  return 'Price: High';
    case AppLanguage.japanese: return '価格高い順';
    case AppLanguage.chinese:  return '价格高';
    case AppLanguage.mongolian:return 'Үнэ өндөр';
  }}
  String get sortPopular { switch (language) {
    case AppLanguage.korean:   return '인기순';
    case AppLanguage.english:  return 'Popular';
    case AppLanguage.japanese: return '人気順';
    case AppLanguage.chinese:  return '热门';
    case AppLanguage.mongolian:return 'Алдартай';
  }}
  String get allProducts { switch (language) {
    case AppLanguage.korean:   return '전체 상품';
    case AppLanguage.english:  return 'All Products';
    case AppLanguage.japanese: return '全商品';
    case AppLanguage.chinese:  return '全部商品';
    case AppLanguage.mongolian:return 'Бүх бараа';
  }}
  String get viewAllProducts { switch (language) {
    case AppLanguage.korean:   return '전체 상품 보기';
    case AppLanguage.english:  return 'View All Products';
    case AppLanguage.japanese: return '全商品を見る';
    case AppLanguage.chinese:  return '查看全部商品';
    case AppLanguage.mongolian:return 'Бүх барааг харах';
  }}
  String get productCount { switch (language) {
    case AppLanguage.korean:   return '개 상품';
    case AppLanguage.english:  return ' items';
    case AppLanguage.japanese: return '点の商品';
    case AppLanguage.chinese:  return '件商品';
    case AppLanguage.mongolian:return ' бараа';
  }}

  // ── 마이페이지 ──
  String get orderManagement { switch (language) {
    case AppLanguage.korean:   return '주문 관리';
    case AppLanguage.english:  return 'Order Management';
    case AppLanguage.japanese: return '注文管理';
    case AppLanguage.chinese:  return '订单管理';
    case AppLanguage.mongolian:return 'Захиалгын удирдлага';
  }}
  String get logoutConfirm { switch (language) {
    case AppLanguage.korean:   return '로그아웃하시겠습니까?';
    case AppLanguage.english:  return 'Are you sure you want to logout?';
    case AppLanguage.japanese: return 'ログアウトしますか？';
    case AppLanguage.chinese:  return '确定要退出登录吗？';
    case AppLanguage.mongolian:return 'Гарахдаа итгэлтэй байна уу?';
  }}
  String get profileUpdated { switch (language) {
    case AppLanguage.korean:   return '프로필이 업데이트되었습니다.';
    case AppLanguage.english:  return 'Profile updated successfully.';
    case AppLanguage.japanese: return 'プロフィールが更新されました。';
    case AppLanguage.chinese:  return '个人资料已更新。';
    case AppLanguage.mongolian:return 'Профайл шинэчлэгдлээ.';
  }}
  String get notificationNew { switch (language) {
    case AppLanguage.korean:   return '새 알림';
    case AppLanguage.english:  return 'New Notification';
    case AppLanguage.japanese: return '新着通知';
    case AppLanguage.chinese:  return '新通知';
    case AppLanguage.mongolian:return 'Шинэ мэдэгдэл';
  }}
  String get newChatInquiry { switch (language) {
    case AppLanguage.korean:   return '새 채팅 문의';
    case AppLanguage.english:  return 'New Chat Inquiry';
    case AppLanguage.japanese: return '新着チャット問い合わせ';
    case AppLanguage.chinese:  return '新咨询';
    case AppLanguage.mongolian:return 'Шинэ чат лавлагаа';
  }}
  String get newOrderAlert { switch (language) {
    case AppLanguage.korean:   return '새 주문 알림';
    case AppLanguage.english:  return 'New Order Alert';
    case AppLanguage.japanese: return '新規注文通知';
    case AppLanguage.chinese:  return '新订单通知';
    case AppLanguage.mongolian:return 'Шинэ захиалгын мэдэгдэл';
  }}
  String get inquiryReceived { switch (language) {
    case AppLanguage.korean:   return '고객 문의가 접수되었습니다';
    case AppLanguage.english:  return 'Customer inquiry received';
    case AppLanguage.japanese: return 'お客様のお問い合わせを受け付けました';
    case AppLanguage.chinese:  return '收到客户咨询';
    case AppLanguage.mongolian:return 'Үйлчлүүлэгчийн лавлагаа ирлээ';
  }}
  String get enableNotifications { switch (language) {
    case AppLanguage.korean:   return '알림 켜기';
    case AppLanguage.english:  return 'Enable Notifications';
    case AppLanguage.japanese: return '通知をオンにする';
    case AppLanguage.chinese:  return '开启通知';
    case AppLanguage.mongolian:return 'Мэдэгдэл идэвхжүүлэх';
  }}
  String get notificationEnabled { switch (language) {
    case AppLanguage.korean:   return '알림이 활성화되었습니다';
    case AppLanguage.english:  return 'Notifications enabled';
    case AppLanguage.japanese: return '通知が有効になりました';
    case AppLanguage.chinese:  return '通知已开启';
    case AppLanguage.mongolian:return 'Мэдэгдэл идэвхжлээ';
  }}

  // ── PC 상단바 / 헤더 ──
  String get pcFreeShipping { switch (language) {
    case AppLanguage.korean:   return '30만원 이상 무료배송  ·  단체 커스텀 전문  ·  고품질 스포츠웨어';
    case AppLanguage.english:  return 'Free shipping over ₩300,000  ·  Group custom specialists  ·  Premium sportswear';
    case AppLanguage.japanese: return '30万ウォン以上送料無料  ·  団体カスタム専門  ·  高品質スポーツウェア';
    case AppLanguage.chinese:  return '满30万韩元免运费  ·  团体定制专家  ·  优质运动服';
    case AppLanguage.mongolian:return '₩300,000-аас дээш үнэ төлбөргүй хүргэлт  ·  Бүлгийн тусгай захиалга  ·  Өндөр чанарын спортын хувцас';
  }}
  String get pcCustomerCenter { switch (language) {
    case AppLanguage.korean:   return '고객센터';
    case AppLanguage.english:  return 'Support';
    case AppLanguage.japanese: return 'サポート';
    case AppLanguage.chinese:  return '客服';
    case AppLanguage.mongolian:return 'Дэмжлэг';
  }}
  String get pcOrderLookup { switch (language) {
    case AppLanguage.korean:   return '주문조회';
    case AppLanguage.english:  return 'Track Order';
    case AppLanguage.japanese: return '注文照会';
    case AppLanguage.chinese:  return '查询订单';
    case AppLanguage.mongolian:return 'Захиалга хянах';
  }}
  String get pcKakaoChannel { switch (language) {
    case AppLanguage.korean:   return '카카오 @2fitkorea';
    case AppLanguage.english:  return 'KakaoTalk @2fitkorea';
    case AppLanguage.japanese: return 'カカオ @2fitkorea';
    case AppLanguage.chinese:  return 'KakaoTalk @2fitkorea';
    case AppLanguage.mongolian:return 'KakaoTalk @2fitkorea';
  }}
  String get pcSearchHint { switch (language) {
    case AppLanguage.korean:   return '상품명, 브랜드, 카테고리 검색';
    case AppLanguage.english:  return 'Search products, brands, categories';
    case AppLanguage.japanese: return '商品名、ブランド、カテゴリ検索';
    case AppLanguage.chinese:  return '搜索商品名、品牌、分类';
    case AppLanguage.mongolian:return 'Бараа, брэнд, ангилал хайх';
  }}
  String get pcSearchBtn { switch (language) {
    case AppLanguage.korean:   return '검색';
    case AppLanguage.english:  return 'Search';
    case AppLanguage.japanese: return '検索';
    case AppLanguage.chinese:  return '搜索';
    case AppLanguage.mongolian:return 'Хайх';
  }}
  String get pcMyPage { switch (language) {
    case AppLanguage.korean:   return '마이페이지';
    case AppLanguage.english:  return 'My Page';
    case AppLanguage.japanese: return 'マイページ';
    case AppLanguage.chinese:  return '我的';
    case AppLanguage.mongolian:return 'Миний хуудас';
  }}
  String get pcCartLabel { switch (language) {
    case AppLanguage.korean:   return '장바구니';
    case AppLanguage.english:  return 'Cart';
    case AppLanguage.japanese: return 'カート';
    case AppLanguage.chinese:  return '购物车';
    case AppLanguage.mongolian:return 'Сагс';
  }}

  // ── PC 푸터 번역 ──
  String get footerBrandDesc { switch (language) {
    case AppLanguage.korean:   return '고퀄리티 단체 스포츠웨어 전문 브랜드\n팀복 · 단체복 · 커스텀 유니폼';
    case AppLanguage.english:  return 'Premium group sportswear specialist\nTeam wear · Group uniforms · Custom kits';
    case AppLanguage.japanese: return '高品質団体スポーツウェア専門ブランド\nチームウェア · ユニフォーム · カスタム';
    case AppLanguage.chinese:  return '高品质团体运动服专业品牌\n团队服 · 团体服 · 定制制服';
    case AppLanguage.mongolian:return 'Өндөр чанарын бүлгийн спортын хувцасны мэргэжлийн брэнд\nБагийн хувцас · Бүлгийн хувцас · Тусгай захиалга';
  }}
  String get footerShopGuide { switch (language) {
    case AppLanguage.korean:   return '쇼핑 안내';
    case AppLanguage.english:  return 'Shopping Guide';
    case AppLanguage.japanese: return 'ショッピングガイド';
    case AppLanguage.chinese:  return '购物指南';
    case AppLanguage.mongolian:return 'Худалдааны зааварчилгаа';
  }}
  String get footerProductList { switch (language) {
    case AppLanguage.korean:   return '상품 목록';
    case AppLanguage.english:  return 'Products';
    case AppLanguage.japanese: return '商品一覧';
    case AppLanguage.chinese:  return '商品列表';
    case AppLanguage.mongolian:return 'Барааны жагсаалт';
  }}
  String get footerDeliveryGuide { switch (language) {
    case AppLanguage.korean:   return '배송 안내';
    case AppLanguage.english:  return 'Delivery Info';
    case AppLanguage.japanese: return '配送案内';
    case AppLanguage.chinese:  return '配送说明';
    case AppLanguage.mongolian:return 'Хүргэлтийн мэдээлэл';
  }}
  String get footerReturnPolicy { switch (language) {
    case AppLanguage.korean:   return '교환/반품 정책';
    case AppLanguage.english:  return 'Return Policy';
    case AppLanguage.japanese: return '交換・返品ポリシー';
    case AppLanguage.chinese:  return '退换货政策';
    case AppLanguage.mongolian:return 'Буцаалтын бодлого';
  }}
  String get footerSizeGuide { switch (language) {
    case AppLanguage.korean:   return '사이즈 가이드';
    case AppLanguage.english:  return 'Size Guide';
    case AppLanguage.japanese: return 'サイズガイド';
    case AppLanguage.chinese:  return '尺码指南';
    case AppLanguage.mongolian:return 'Хэмжээний заавар';
  }}
  String get footerOrderService { switch (language) {
    case AppLanguage.korean:   return '주문 서비스';
    case AppLanguage.english:  return 'Order Services';
    case AppLanguage.japanese: return '注文サービス';
    case AppLanguage.chinese:  return '订单服务';
    case AppLanguage.mongolian:return 'Захиалгын үйлчилгээ';
  }}
  String get footerGroupOrder { switch (language) {
    case AppLanguage.korean:   return '단체 주문 안내';
    case AppLanguage.english:  return 'Group Order Guide';
    case AppLanguage.japanese: return '団体注文案内';
    case AppLanguage.chinese:  return '团体订单指南';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгын заавар';
  }}
  String get footerPersonalOrder { switch (language) {
    case AppLanguage.korean:   return '개인 맞춤 주문';
    case AppLanguage.english:  return 'Custom Order';
    case AppLanguage.japanese: return '個人カスタム注文';
    case AppLanguage.chinese:  return '个人定制订单';
    case AppLanguage.mongolian:return 'Тусгай захиалга';
  }}
  String get footerOrderStatus { switch (language) {
    case AppLanguage.korean:   return '주문 현황 조회';
    case AppLanguage.english:  return 'Order Status';
    case AppLanguage.japanese: return '注文状況照会';
    case AppLanguage.chinese:  return '查询订单状态';
    case AppLanguage.mongolian:return 'Захиалгын байдал';
  }}
  String get footerSupport { switch (language) {
    case AppLanguage.korean:   return '고객 지원';
    case AppLanguage.english:  return 'Customer Support';
    case AppLanguage.japanese: return 'カスタマーサポート';
    case AppLanguage.chinese:  return '客户支持';
    case AppLanguage.mongolian:return 'Үйлчлүүлэгчийн дэмжлэг';
  }}
  String get footerInquiry { switch (language) {
    case AppLanguage.korean:   return '1:1 문의';
    case AppLanguage.english:  return '1:1 Inquiry';
    case AppLanguage.japanese: return '1:1お問い合わせ';
    case AppLanguage.chinese:  return '1对1咨询';
    case AppLanguage.mongolian:return '1:1 Асуулт';
  }}
  String get footerFaq { switch (language) {
    case AppLanguage.korean:   return '자주 묻는 질문';
    case AppLanguage.english:  return 'FAQ';
    case AppLanguage.japanese: return 'よくある質問';
    case AppLanguage.chinese:  return '常见问题';
    case AppLanguage.mongolian:return 'Түгээмэл асуултууд';
  }}
  String get footerKakaoChannel { switch (language) {
    case AppLanguage.korean:   return '카카오톡 채널';
    case AppLanguage.english:  return 'KakaoTalk Channel';
    case AppLanguage.japanese: return 'カカオトークチャンネル';
    case AppLanguage.chinese:  return 'KakaoTalk频道';
    case AppLanguage.mongolian:return 'KakaoTalk суваг';
  }}
  String get footerTerms { switch (language) {
    case AppLanguage.korean:   return '이용약관';
    case AppLanguage.english:  return 'Terms of Use';
    case AppLanguage.japanese: return '利用規約';
    case AppLanguage.chinese:  return '使用条款';
    case AppLanguage.mongolian:return 'Үйлчилгээний нөхцөл';
  }}
  String get footerPrivacy { switch (language) {
    case AppLanguage.korean:   return '개인정보처리방침';
    case AppLanguage.english:  return 'Privacy Policy';
    case AppLanguage.japanese: return 'プライバシーポリシー';
    case AppLanguage.chinese:  return '隐私政策';
    case AppLanguage.mongolian:return 'Нууцлалын бодлого';
  }}
  String get footerKakao { switch (language) {
    case AppLanguage.korean:   return '카카오';
    case AppLanguage.english:  return 'KakaoTalk';
    case AppLanguage.japanese: return 'カカオ';
    case AppLanguage.chinese:  return 'KakaoTalk';
    case AppLanguage.mongolian:return 'KakaoTalk';
  }}

  // ── 공지사항 팝업 ──
  String get noticeDontShowToday { switch (language) {
    case AppLanguage.korean:   return '오늘 하루 보지 않기';
    case AppLanguage.english:  return 'Don\'t show today';
    case AppLanguage.japanese: return '今日は表示しない';
    case AppLanguage.chinese:  return '今天不再显示';
    case AppLanguage.mongolian:return 'Өнөөдөр харуулахгүй';
  }}
  String get noticeNext { switch (language) {
    case AppLanguage.korean:   return '다음 공지 ›';
    case AppLanguage.english:  return 'Next Notice ›';
    case AppLanguage.japanese: return '次のお知らせ ›';
    case AppLanguage.chinese:  return '下一条通知 ›';
    case AppLanguage.mongolian:return 'Дараагийн мэдэгдэл ›';
  }}
  String get noticeConfirm { switch (language) {
    case AppLanguage.korean:   return '확인';
    case AppLanguage.english:  return 'Confirm';
    case AppLanguage.japanese: return '確認';
    case AppLanguage.chinese:  return '确认';
    case AppLanguage.mongolian:return 'Батлах';
  }}

  // ── 결제/주문 화면 ──
  String get checkoutTitle { switch (language) {
    case AppLanguage.korean:   return '주문 / 결제';
    case AppLanguage.english:  return 'Checkout';
    case AppLanguage.japanese: return '注文 / 決済';
    case AppLanguage.chinese:  return '下单 / 付款';
    case AppLanguage.mongolian:return 'Захиалга / Төлбөр';
  }}
  String get ordererInfo { switch (language) {
    case AppLanguage.korean:   return '주문자 정보';
    case AppLanguage.english:  return 'Orderer Info';
    case AppLanguage.japanese: return '注文者情報';
    case AppLanguage.chinese:  return '下单人信息';
    case AppLanguage.mongolian:return 'Захиалагчийн мэдээлэл';
  }}
  String get shippingInfo { switch (language) {
    case AppLanguage.korean:   return '배송지 정보';
    case AppLanguage.english:  return 'Shipping Address';
    case AppLanguage.japanese: return '配送先情報';
    case AppLanguage.chinese:  return '收货地址';
    case AppLanguage.mongolian:return 'Хүргэлтийн хаяг';
  }}
  String get orderItems { switch (language) {
    case AppLanguage.korean:   return '주문 상품';
    case AppLanguage.english:  return 'Order Items';
    case AppLanguage.japanese: return '注文商品';
    case AppLanguage.chinese:  return '订购商品';
    case AppLanguage.mongolian:return 'Захиалгын бараа';
  }}
  String get paymentMethod { switch (language) {
    case AppLanguage.korean:   return '결제 수단';
    case AppLanguage.english:  return 'Payment Method';
    case AppLanguage.japanese: return '決済方法';
    case AppLanguage.chinese:  return '支付方式';
    case AppLanguage.mongolian:return 'Төлбөрийн арга';
  }}
  String get couponSection { switch (language) {
    case AppLanguage.korean:   return '쿠폰';
    case AppLanguage.english:  return 'Coupon';
    case AppLanguage.japanese: return 'クーポン';
    case AppLanguage.chinese:  return '优惠券';
    case AppLanguage.mongolian:return 'Купон';
  }}
  String get pointSection { switch (language) {
    case AppLanguage.korean:   return '포인트 사용';
    case AppLanguage.english:  return 'Use Points';
    case AppLanguage.japanese: return 'ポイント使用';
    case AppLanguage.chinese:  return '使用积分';
    case AppLanguage.mongolian:return 'Оноо ашиглах';
  }}
  String get priceSummary { switch (language) {
    case AppLanguage.korean:   return '결제 금액';
    case AppLanguage.english:  return 'Price Summary';
    case AppLanguage.japanese: return '決済金額';
    case AppLanguage.chinese:  return '结算金额';
    case AppLanguage.mongolian:return 'Төлбөрийн дүн';
  }}
  String get domesticAddress { switch (language) {
    case AppLanguage.korean:   return '국내';
    case AppLanguage.english:  return 'Domestic';
    case AppLanguage.japanese: return '国内';
    case AppLanguage.chinese:  return '国内';
    case AppLanguage.mongolian:return 'Дотоодын';
  }}
  String get overseasAddress { switch (language) {
    case AppLanguage.korean:   return '해외';
    case AppLanguage.english:  return 'International';
    case AppLanguage.japanese: return '海外';
    case AppLanguage.chinese:  return '海外';
    case AppLanguage.mongolian:return 'Гадаадын';
  }}
  String get checkoutAgree { switch (language) {
    case AppLanguage.korean:   return '주문 정보를 확인하였으며, 결제에 동의합니다.';
    case AppLanguage.english:  return 'I confirm the order information and agree to payment.';
    case AppLanguage.japanese: return '注文情報を確認し、決済に同意します。';
    case AppLanguage.chinese:  return '我已确认订单信息，并同意付款。';
    case AppLanguage.mongolian:return 'Захиалгын мэдээллийг баталгаажуулж, төлбөрт зөвшөөрч байна.';
  }}
  String get freeShippingAchieved { switch (language) {
    case AppLanguage.korean:   return '🎉 무료배송 조건 달성!';
    case AppLanguage.english:  return '🎉 Free shipping unlocked!';
    case AppLanguage.japanese: return '🎉 送料無料達成！';
    case AppLanguage.chinese:  return '🎉 已达免运费条件！';
    case AppLanguage.mongolian:return '🎉 Үнэгүй хүргэлт нөхцөл биелэв!';
  }}
  String get freeShippingRemaining { switch (language) {
    case AppLanguage.korean:   return '원 더 담으면 무료배송!';
    case AppLanguage.english:  return ' more for free shipping!';
    case AppLanguage.japanese: return 'をあと追加すると送料無料！';
    case AppLanguage.chinese:  return ' 可享免运费！';
    case AppLanguage.mongolian:return ' нэмбэл үнэгүй хүргэлт!';
  }}
  String get freeShippingThreshold { switch (language) {
    case AppLanguage.korean:   return '30만원 이상 무료';
    case AppLanguage.english:  return 'Free over ₩300K';
    case AppLanguage.japanese: return '30万ウォン以上無料';
    case AppLanguage.chinese:  return '满30万韩元免运费';
    case AppLanguage.mongolian:return '₩300K-аас дээш үнэгүй';
  }}
  String get sslSecure { switch (language) {
    case AppLanguage.korean:   return 'SSL 보안 결제';
    case AppLanguage.english:  return 'SSL Secure Payment';
    case AppLanguage.japanese: return 'SSL安全決済';
    case AppLanguage.chinese:  return 'SSL安全支付';
    case AppLanguage.mongolian:return 'SSL аюулгүй төлбөр';
  }}
  String get returnIn7Days { switch (language) {
    case AppLanguage.korean:   return '7일 내 교환/반품';
    case AppLanguage.english:  return '7-day exchange/return';
    case AppLanguage.japanese: return '7日以内交換・返品';
    case AppLanguage.chinese:  return '7天内换货/退货';
    case AppLanguage.mongolian:return '7 хоногт солих/буцаах';
  }}
  String get couponApply { switch (language) {
    case AppLanguage.korean:   return '쿠폰 적용';
    case AppLanguage.english:  return 'Apply Coupon';
    case AppLanguage.japanese: return 'クーポン適用';
    case AppLanguage.chinese:  return '使用优惠券';
    case AppLanguage.mongolian:return 'Купон ашиглах';
  }}
  String get couponInputHint { switch (language) {
    case AppLanguage.korean:   return '쿠폰 코드를 입력하세요 (예: WELCOME2FIT)';
    case AppLanguage.english:  return 'Enter coupon code (e.g. WELCOME2FIT)';
    case AppLanguage.japanese: return 'クーポンコードを入力 (例: WELCOME2FIT)';
    case AppLanguage.chinese:  return '请输入优惠券码 (示例: WELCOME2FIT)';
    case AppLanguage.mongolian:return 'Купоны код оруулах (жш: WELCOME2FIT)';
  }}
  String get applyBtnAlt { switch (language) {
    case AppLanguage.korean:   return '적용';
    case AppLanguage.english:  return 'Apply';
    case AppLanguage.japanese: return '適用';
    case AppLanguage.chinese:  return '使用';
    case AppLanguage.mongolian:return 'Хэрэглэх';
  }}
  String get availableCoupons { switch (language) {
    case AppLanguage.korean:   return '사용 가능한 쿠폰';
    case AppLanguage.english:  return 'Available Coupons';
    case AppLanguage.japanese: return '使用可能なクーポン';
    case AppLanguage.chinese:  return '可用优惠券';
    case AppLanguage.mongolian:return 'Ашиглах боломжтой купонууд';
  }}
  String get paymentAmountTitle { switch (language) {
    case AppLanguage.korean:   return '최종 결제 금액';
    case AppLanguage.english:  return 'Final Amount';
    case AppLanguage.japanese: return '最終決済金額';
    case AppLanguage.chinese:  return '最终结算金额';
    case AppLanguage.mongolian:return 'Эцсийн төлбөр';
  }}
  String get productAmount { switch (language) {
    case AppLanguage.korean:   return '상품 금액';
    case AppLanguage.english:  return 'Subtotal';
    case AppLanguage.japanese: return '商品金額';
    case AppLanguage.chinese:  return '商品金额';
    case AppLanguage.mongolian:return 'Барааны дүн';
  }}
  String get shippingFeeLabel { switch (language) {
    case AppLanguage.korean:   return '배송비';
    case AppLanguage.english:  return 'Shipping';
    case AppLanguage.japanese: return '送料';
    case AppLanguage.chinese:  return '运费';
    case AppLanguage.mongolian:return 'Хүргэлтийн төлбөр';
  }}
  String get freeLabel { switch (language) {
    case AppLanguage.korean:   return '무료';
    case AppLanguage.english:  return 'Free';
    case AppLanguage.japanese: return '無料';
    case AppLanguage.chinese:  return '免费';
    case AppLanguage.mongolian:return 'Үнэгүй';
  }}
  String get couponDiscount { switch (language) {
    case AppLanguage.korean:   return '쿠폰 할인';
    case AppLanguage.english:  return 'Coupon Discount';
    case AppLanguage.japanese: return 'クーポン割引';
    case AppLanguage.chinese:  return '优惠券折扣';
    case AppLanguage.mongolian:return 'Купоны хөнгөлөлт';
  }}
  String get pointDiscount { switch (language) {
    case AppLanguage.korean:   return '포인트 사용';
    case AppLanguage.english:  return 'Points Used';
    case AppLanguage.japanese: return 'ポイント使用';
    case AppLanguage.chinese:  return '积分抵扣';
    case AppLanguage.mongolian:return 'Оноо ашиглалт';
  }}
  String get finalPayment { switch (language) {
    case AppLanguage.korean:   return '최종 결제';
    case AppLanguage.english:  return 'Total';
    case AppLanguage.japanese: return '最終決済';
    case AppLanguage.chinese:  return '最终支付';
    case AppLanguage.mongolian:return 'Нийт дүн';
  }}

  // ── 상품 상세 화면 ──
  String get orderTypeSelect { switch (language) {
    case AppLanguage.korean:   return '주문 유형 선택';
    case AppLanguage.english:  return 'Select Order Type';
    case AppLanguage.japanese: return '注文タイプ選択';
    case AppLanguage.chinese:  return '选择订单类型';
    case AppLanguage.mongolian:return 'Захиалгын төрөл сонгох';
  }}
  String get deliveryInfo { switch (language) {
    case AppLanguage.korean:   return '배송 정보';
    case AppLanguage.english:  return 'Delivery Info';
    case AppLanguage.japanese: return '配送情報';
    case AppLanguage.chinese:  return '配送信息';
    case AppLanguage.mongolian:return 'Хүргэлтийн мэдээлэл';
  }}
  String get bottomLengthLabel { switch (language) {
    case AppLanguage.korean:   return '하의 길이';
    case AppLanguage.english:  return 'Length';
    case AppLanguage.japanese: return '丈';
    case AppLanguage.chinese:  return '裤长';
    case AppLanguage.mongolian:return 'Урт';
  }}
  String get genderAutoLock { switch (language) {
    case AppLanguage.korean:   return '성별 자동 고정';
    case AppLanguage.english:  return 'Gender Auto-Lock';
    case AppLanguage.japanese: return '性別自動固定';
    case AppLanguage.chinese:  return '性别自动锁定';
    case AppLanguage.mongolian:return 'Хүйс автоматаар тогтоох';
  }}
  String get restrictApply { switch (language) {
    case AppLanguage.korean:   return '제한 적용';
    case AppLanguage.english:  return 'Apply Restriction';
    case AppLanguage.japanese: return '制限適用';
    case AppLanguage.chinese:  return '应用限制';
    case AppLanguage.mongolian:return 'Хязгаарлалт хэрэглэх';
  }}
  String get confirm2 { switch (language) {
    case AppLanguage.korean:   return '확정';
    case AppLanguage.english:  return 'Confirm';
    case AppLanguage.japanese: return '確定';
    case AppLanguage.chinese:  return '确定';
    case AppLanguage.mongolian:return 'Батлах';
  }}
  String get colorSelect { switch (language) {
    case AppLanguage.korean:   return '색상 선택';
    case AppLanguage.english:  return 'Select Color';
    case AppLanguage.japanese: return '色の選択';
    case AppLanguage.chinese:  return '选择颜色';
    case AppLanguage.mongolian:return 'Өнгө сонгох';
  }}
  String get selected { switch (language) {
    case AppLanguage.korean:   return '선택:';
    case AppLanguage.english:  return 'Selected:';
    case AppLanguage.japanese: return '選択中:';
    case AppLanguage.chinese:  return '已选:';
    case AppLanguage.mongolian:return 'Сонгосон:';
  }}
  String get readyMadeBuy { switch (language) {
    case AppLanguage.korean:   return '바로 구매';
    case AppLanguage.english:  return 'Buy Now';
    case AppLanguage.japanese: return '今すぐ購入';
    case AppLanguage.chinese:  return '立即购买';
    case AppLanguage.mongolian:return 'Шууд авах';
  }}
  String get groupBuy { switch (language) {
    case AppLanguage.korean:   return '단체구매';
    case AppLanguage.english:  return 'Group Buy';
    case AppLanguage.japanese: return '団体購入';
    case AppLanguage.chinese:  return '团体购买';
    case AppLanguage.mongolian:return 'Бүлгийн худалдан авалт';
  }}
  String get imageUpload { switch (language) {
    case AppLanguage.korean:   return '이미지 업로드';
    case AppLanguage.english:  return 'Upload Image';
    case AppLanguage.japanese: return '画像アップロード';
    case AppLanguage.chinese:  return '上传图片';
    case AppLanguage.mongolian:return 'Зураг оруулах';
  }}
  String get noImageSelected { switch (language) {
    case AppLanguage.korean:   return '선택된 이미지가 없습니다';
    case AppLanguage.english:  return 'No image selected';
    case AppLanguage.japanese: return '画像が選択されていません';
    case AppLanguage.chinese:  return '未选择图片';
    case AppLanguage.mongolian:return 'Зураг сонгоогүй байна';
  }}
  String get addMoreImages { switch (language) {
    case AppLanguage.korean:   return '이미지 더 추가하기';
    case AppLanguage.english:  return 'Add More Images';
    case AppLanguage.japanese: return '画像を追加する';
    case AppLanguage.chinese:  return '添加更多图片';
    case AppLanguage.mongolian:return 'Зураг нэмэх';
  }}
  String get deleteAll { switch (language) {
    case AppLanguage.korean:   return '전체 삭제';
    case AppLanguage.english:  return 'Delete All';
    case AppLanguage.japanese: return '全て削除';
    case AppLanguage.chinese:  return '全部删除';
    case AppLanguage.mongolian:return 'Бүгдийг устгах';
  }}
  String get fabricComposition { switch (language) {
    case AppLanguage.korean:   return '섬유 혼용율';
    case AppLanguage.english:  return 'Fabric Composition';
    case AppLanguage.japanese: return '繊維混用率';
    case AppLanguage.chinese:  return '面料成分';
    case AppLanguage.mongolian:return 'Даавуун найрлага';
  }}
  String get productReview { switch (language) {
    case AppLanguage.korean:   return '상품 리뷰';
    case AppLanguage.english:  return 'Product Reviews';
    case AppLanguage.japanese: return '商品レビュー';
    case AppLanguage.chinese:  return '商品评价';
    case AppLanguage.mongolian:return 'Барааны сэтгэгдэл';
  }}
  String get addToCartAction { switch (language) {
    case AppLanguage.korean:   return '장바구니 담기';
    case AppLanguage.english:  return 'Add to Cart';
    case AppLanguage.japanese: return 'カートに入れる';
    case AppLanguage.chinese:  return '加入购物车';
    case AppLanguage.mongolian:return 'Сагсанд нэмэх';
  }}
  String get buyNowAction { switch (language) {
    case AppLanguage.korean:   return '바로 구매';
    case AppLanguage.english:  return 'Buy Now';
    case AppLanguage.japanese: return '今すぐ購入';
    case AppLanguage.chinese:  return '立即购买';
    case AppLanguage.mongolian:return 'Шууд авах';
  }}
  String get purchaseTypeSelect { switch (language) {
    case AppLanguage.korean:   return '구매 유형 선택';
    case AppLanguage.english:  return 'Select Purchase Type';
    case AppLanguage.japanese: return '購入タイプ選択';
    case AppLanguage.chinese:  return '选择购买类型';
    case AppLanguage.mongolian:return 'Худалдан авалтын төрөл сонгох';
  }}
  String get purchaseTypeDesc { switch (language) {
    case AppLanguage.korean:   return '원하시는 구매 방식을 선택해주세요';
    case AppLanguage.english:  return 'Please select your purchase method';
    case AppLanguage.japanese: return 'ご希望の購入方法をお選びください';
    case AppLanguage.chinese:  return '请选择您的购买方式';
    case AppLanguage.mongolian:return 'Худалдан авах аргаа сонгоно уу';
  }}
  String get singletOption { switch (language) {
    case AppLanguage.korean:   return '싱글렛 옵션';
    case AppLanguage.english:  return 'Singlet Options';
    case AppLanguage.japanese: return 'シングレットオプション';
    case AppLanguage.chinese:  return '背心选项';
    case AppLanguage.mongolian:return 'Сингл хувцасны сонголт';
  }}
  String get styleType { switch (language) {
    case AppLanguage.korean:   return '스타일 타입';
    case AppLanguage.english:  return 'Style Type';
    case AppLanguage.japanese: return 'スタイルタイプ';
    case AppLanguage.chinese:  return '款式类型';
    case AppLanguage.mongolian:return 'Загварын төрөл';
  }}
  String get selectSizeFirst2 { switch (language) {
    case AppLanguage.korean:   return '사이즈를 먼저 선택해주세요';
    case AppLanguage.english:  return 'Please select a size first';
    case AppLanguage.japanese: return 'サイズを先に選択してください';
    case AppLanguage.chinese:  return '请先选择尺码';
    case AppLanguage.mongolian:return 'Эхлээд хэмжээ сонгоно уу';
  }}
  String get addedToCartMsgSimple { switch (language) {
    case AppLanguage.korean:   return '장바구니에 담았습니다';
    case AppLanguage.english:  return 'Added to cart';
    case AppLanguage.japanese: return 'カートに追加しました';
    case AppLanguage.chinese:  return '已加入购物车';
    case AppLanguage.mongolian:return 'Сагсанд нэмэгдлээ';
  }}
  String get weightSelect { switch (language) {
    case AppLanguage.korean:   return '무게 선택';
    case AppLanguage.english:  return 'Select Weight';
    case AppLanguage.japanese: return '重量選択';
    case AppLanguage.chinese:  return '选择重量';
    case AppLanguage.mongolian:return 'Жин сонгох';
  }}
  String get nextStep { switch (language) {
    case AppLanguage.korean:   return '다음 단계';
    case AppLanguage.english:  return 'Next Step';
    case AppLanguage.japanese: return '次のステップ';
    case AppLanguage.chinese:  return '下一步';
    case AppLanguage.mongolian:return 'Дараагийн алхам';
  }}
  String get normalFabricOnly { switch (language) {
    case AppLanguage.korean:   return '일반(봉제) 소재만 가능 · 이미지 색상 그대로 제작';
    case AppLanguage.english:  return 'Normal fabric only · Color as shown';
    case AppLanguage.japanese: return '一般(縫製)素材のみ · 画像色そのまま制作';
    case AppLanguage.chinese:  return '仅普通面料 · 按图片颜色制作';
    case AppLanguage.mongolian:return 'Энгийн даавуу л боломжтой · Зургийн өнгөөр хийх';
  }}
  String get sizeGuideTitle { switch (language) {
    case AppLanguage.korean:   return '사이즈 가이드';
    case AppLanguage.english:  return 'Size Guide';
    case AppLanguage.japanese: return 'サイズガイド';
    case AppLanguage.chinese:  return '尺码指南';
    case AppLanguage.mongolian:return 'Хэмжээний гарын авлага';
  }}
  String get bottomLengthRefImg { switch (language) {
    case AppLanguage.korean:   return '하의길이 참조 이미지 (남자 / 여자 분리)';
    case AppLanguage.english:  return 'Length reference image (Male / Female)';
    case AppLanguage.japanese: return '丈参考画像 (男性 / 女性)';
    case AppLanguage.chinese:  return '裤长参考图 (男 / 女)';
    case AppLanguage.mongolian:return 'Урт лавлах зураг (Эрэгтэй / Эмэгтэй)';
  }}
  String get dragToReorder { switch (language) {
    case AppLanguage.korean:   return '드래그하여 순서 변경';
    case AppLanguage.english:  return 'Drag to reorder';
    case AppLanguage.japanese: return 'ドラッグして並び替え';
    case AppLanguage.chinese:  return '拖动更改顺序';
    case AppLanguage.mongolian:return 'Дарж чирж дараалал өөрчлөх';
  }}

  // ── 장바구니 화면 ──
  String get cartOrderNotice { switch (language) {
    case AppLanguage.korean:   return '선택된 상품을 주문합니다. 수량 변경이 가능합니다.';
    case AppLanguage.english:  return 'Selected items will be ordered. Quantity can be changed.';
    case AppLanguage.japanese: return '選択した商品を注文します。数量変更が可能です。';
    case AppLanguage.chinese:  return '将订购选中商品，可修改数量。';
    case AppLanguage.mongolian:return 'Сонгосон барааг захиална. Тоо хэмжээг өөрчилж болно.';
  }}
  String get orderSummary { switch (language) {
    case AppLanguage.korean:   return '주문 요약';
    case AppLanguage.english:  return 'Order Summary';
    case AppLanguage.japanese: return '注文サマリー';
    case AppLanguage.chinese:  return '订单摘要';
    case AppLanguage.mongolian:return 'Захиалгын хураангуй';
  }}
  String get payNow { switch (language) {
    case AppLanguage.korean:   return '결제하기';
    case AppLanguage.english:  return 'Pay Now';
    case AppLanguage.japanese: return '決済する';
    case AppLanguage.chinese:  return '立即结算';
    case AppLanguage.mongolian:return 'Төлбөр хийх';
  }}
  String get clearCart { switch (language) {
    case AppLanguage.korean:   return '장바구니 비우기';
    case AppLanguage.english:  return 'Clear Cart';
    case AppLanguage.japanese: return 'カートを空にする';
    case AppLanguage.chinese:  return '清空购物车';
    case AppLanguage.mongolian:return 'Сагс цэвэрлэх';
  }}
  String get clearCartConfirm { switch (language) {
    case AppLanguage.korean:   return '모든 상품을 장바구니에서 삭제하겠습니까?';
    case AppLanguage.english:  return 'Delete all items from cart?';
    case AppLanguage.japanese: return 'カートの全商品を削除しますか？';
    case AppLanguage.chinese:  return '确定删除购物车中所有商品？';
    case AppLanguage.mongolian:return 'Сагснаас бүх барааг устгах уу?';
  }}
  String get bankTransferGuide { switch (language) {
    case AppLanguage.korean:   return '무통장입금 안내';
    case AppLanguage.english:  return 'Bank Transfer Guide';
    case AppLanguage.japanese: return '銀行振込案内';
    case AppLanguage.chinese:  return '银行转账说明';
    case AppLanguage.mongolian:return 'Банкны шилжүүлгийн заавар';
  }}
  String get bankAccount { switch (language) {
    case AppLanguage.korean:   return '입금 계좌: 국민은행 123-456-789012 (주)2FIT코리아';
    case AppLanguage.english:  return 'Account: Kookmin Bank 123-456-789012 2FIT Korea';
    case AppLanguage.japanese: return '口座: 国民銀行 123-456-789012 2FITコリア';
    case AppLanguage.chinese:  return '账户: 国民银行 123-456-789012 2FIT韩国';
    case AppLanguage.mongolian:return 'Данс: Kookmin Bank 123-456-789012 2FIT Korea';
  }}
  String get bankTransferDeadline { switch (language) {
    case AppLanguage.korean:   return '입금 기한: 주문 후 24시간 이내';
    case AppLanguage.english:  return 'Transfer deadline: Within 24 hours of order';
    case AppLanguage.japanese: return '入金期限: ご注文後24時間以内';
    case AppLanguage.chinese:  return '转账期限: 下单后24小时内';
    case AppLanguage.mongolian:return 'Шилжүүлгийн хугацаа: Захиалсанаас хойш 24 цагийн дотор';
  }}
  String get orderComplete { switch (language) {
    case AppLanguage.korean:   return '주문이 완료되었습니다!';
    case AppLanguage.english:  return 'Order Complete!';
    case AppLanguage.japanese: return 'ご注文が完了しました！';
    case AppLanguage.chinese:  return '订单已完成！';
    case AppLanguage.mongolian:return 'Захиалга амжилттай!';
  }}
  String get continueShopping2 { switch (language) {
    case AppLanguage.korean:   return '계속 쇼핑';
    case AppLanguage.english:  return 'Continue Shopping';
    case AppLanguage.japanese: return 'ショッピングを続ける';
    case AppLanguage.chinese:  return '继续购物';
    case AppLanguage.mongolian:return 'Дэлгүүрлэлт үргэлжлүүлэх';
  }}
  String get viewOrder { switch (language) {
    case AppLanguage.korean:   return '주문 확인';
    case AppLanguage.english:  return 'View Order';
    case AppLanguage.japanese: return '注文確認';
    case AppLanguage.chinese:  return '查看订单';
    case AppLanguage.mongolian:return 'Захиалга харах';
  }}
  String get fillShippingInfo { switch (language) {
    case AppLanguage.korean:   return '배송 정보를 모두 입력해주세요';
    case AppLanguage.english:  return 'Please fill in all shipping information';
    case AppLanguage.japanese: return '配送情報をすべて入力してください';
    case AppLanguage.chinese:  return '请填写所有收货地址信息';
    case AppLanguage.mongolian:return 'Хүргэлтийн мэдээллийг бүрэн оруулна уу';
  }}

  // ── 마이페이지 화면 ──
  String get cancelledOrderNotice { switch (language) {
    case AppLanguage.korean:   return '취소된 주문은 추가제작/수정 요청이 불가합니다';
    case AppLanguage.english:  return 'Cancelled orders cannot be modified or reordered';
    case AppLanguage.japanese: return 'キャンセル注文は追加制作・修正不可です';
    case AppLanguage.chinese:  return '已取消的订单不可追加生产/修改';
    case AppLanguage.mongolian:return 'Цуцлагдсан захиалгыг нэмж үйлдвэрлэх/засах боломжгүй';
  }}
  String get groupOrderOnly { switch (language) {
    case AppLanguage.korean:   return '추가제작은 단체커스텀 주문에서만 가능합니다';
    case AppLanguage.english:  return 'Additional production is only for group custom orders';
    case AppLanguage.japanese: return '追加製作は団体カスタム注文のみ可能です';
    case AppLanguage.chinese:  return '追加生产仅限团体定制订单';
    case AppLanguage.mongolian:return 'Нэмэлт үйлдвэрлэл зөвхөн бүлгийн тусгай захиалганд боломжтой';
  }}
  String get reviewDelete { switch (language) {
    case AppLanguage.korean:   return '리뷰 삭제';
    case AppLanguage.english:  return 'Delete Review';
    case AppLanguage.japanese: return 'レビュー削除';
    case AppLanguage.chinese:  return '删除评价';
    case AppLanguage.mongolian:return 'Сэтгэгдэл устгах';
  }}
  String get reviewDeleteConfirm { switch (language) {
    case AppLanguage.korean:   return '이 리뷰를 삭제하시겠습니까?';
    case AppLanguage.english:  return 'Delete this review?';
    case AppLanguage.japanese: return 'このレビューを削除しますか？';
    case AppLanguage.chinese:  return '确定删除此评价？';
    case AppLanguage.mongolian:return 'Энэ сэтгэгдлийг устгах уу?';
  }}
  String get reviewDeleted { switch (language) {
    case AppLanguage.korean:   return '리뷰가 삭제되었습니다';
    case AppLanguage.english:  return 'Review deleted';
    case AppLanguage.japanese: return 'レビューが削除されました';
    case AppLanguage.chinese:  return '评价已删除';
    case AppLanguage.mongolian:return 'Сэтгэгдэл устгагдлаа';
  }}
  String get reviewDeleteFailed { switch (language) {
    case AppLanguage.korean:   return '삭제 실패. 다시 시도해주세요.';
    case AppLanguage.english:  return 'Delete failed. Please try again.';
    case AppLanguage.japanese: return '削除失敗。再試行してください。';
    case AppLanguage.chinese:  return '删除失败，请重试。';
    case AppLanguage.mongolian:return 'Устгаж чадсангүй. Дахин оролдоно уу.';
  }}
  String get reviewEdit { switch (language) {
    case AppLanguage.korean:   return '리뷰 수정';
    case AppLanguage.english:  return 'Edit Review';
    case AppLanguage.japanese: return 'レビュー編集';
    case AppLanguage.chinese:  return '编辑评价';
    case AppLanguage.mongolian:return 'Сэтгэгдэл засах';
  }}
  String get starRating { switch (language) {
    case AppLanguage.korean:   return '별점';
    case AppLanguage.english:  return 'Rating';
    case AppLanguage.japanese: return '星評価';
    case AppLanguage.chinese:  return '评分';
    case AppLanguage.mongolian:return 'Одны үнэлгээ';
  }}
  String get reviewContent { switch (language) {
    case AppLanguage.korean:   return '내용';
    case AppLanguage.english:  return 'Content';
    case AppLanguage.japanese: return '内容';
    case AppLanguage.chinese:  return '内容';
    case AppLanguage.mongolian:return 'Агуулга';
  }}
  String get reviewUpdated { switch (language) {
    case AppLanguage.korean:   return '리뷰가 수정되었습니다';
    case AppLanguage.english:  return 'Review updated';
    case AppLanguage.japanese: return 'レビューが更新されました';
    case AppLanguage.chinese:  return '评价已更新';
    case AppLanguage.mongolian:return 'Сэтгэгдэл шинэчлэгдлээ';
  }}
  String get reviewUpdateFailed { switch (language) {
    case AppLanguage.korean:   return '수정 실패. 다시 시도해주세요.';
    case AppLanguage.english:  return 'Update failed. Please try again.';
    case AppLanguage.japanese: return '更新失敗。再試行してください。';
    case AppLanguage.chinese:  return '更新失败，请重试。';
    case AppLanguage.mongolian:return 'Засаж чадсангүй. Дахин оролдоно уу.';
  }}
  String get additionalProduction { switch (language) {
    case AppLanguage.korean:   return '추가제작 신청';
    case AppLanguage.english:  return 'Additional Production';
    case AppLanguage.japanese: return '追加製作申請';
    case AppLanguage.chinese:  return '追加生产申请';
    case AppLanguage.mongolian:return 'Нэмэлт үйлдвэрлэл хүсэх';
  }}
  String get groupCustomOnly { switch (language) {
    case AppLanguage.korean:   return '단체커스텀 전용 · 1장부터 가능';
    case AppLanguage.english:  return 'Group Custom Only · From 1 piece';
    case AppLanguage.japanese: return '団体カスタム専用 · 1枚から可';
    case AppLanguage.chinese:  return '仅团体定制 · 最少1件';
    case AppLanguage.mongolian:return 'Зөвхөн бүлгийн тусгай захиалга · 1-ээс эхлэн';
  }}
  String get sizeInput { switch (language) {
    case AppLanguage.korean:   return '사이즈 입력';
    case AppLanguage.english:  return 'Enter Size';
    case AppLanguage.japanese: return 'サイズ入力';
    case AppLanguage.chinese:  return '输入尺码';
    case AppLanguage.mongolian:return 'Хэмжээ оруулах';
  }}
  String get additionalQty { switch (language) {
    case AppLanguage.korean:   return '추가 수량';
    case AppLanguage.english:  return 'Additional Qty';
    case AppLanguage.japanese: return '追加数量';
    case AppLanguage.chinese:  return '追加数量';
    case AppLanguage.mongolian:return 'Нэмэлт тоо';
  }}
  String get writeAdditionalOrder { switch (language) {
    case AppLanguage.korean:   return '추가제작 주문서 작성';
    case AppLanguage.english:  return 'Fill Additional Order';
    case AppLanguage.japanese: return '追加製作注文書作成';
    case AppLanguage.chinese:  return '填写追加生产订单';
    case AppLanguage.mongolian:return 'Нэмэлт захиалга бөглөх';
  }}
  String get colorNameModify { switch (language) {
    case AppLanguage.korean:   return '컬러·단체명 수정요청';
    case AppLanguage.english:  return 'Color/Group Name Modification';
    case AppLanguage.japanese: return 'カラー・団体名修正要求';
    case AppLanguage.chinese:  return '颜色·团体名修改申请';
    case AppLanguage.mongolian:return 'Өнгө·багийн нэр засах хүсэлт';
  }}
  String get modifyAccepted { switch (language) {
    case AppLanguage.korean:   return '수정요청이 접수되었습니다';
    case AppLanguage.english:  return 'Modification request accepted';
    case AppLanguage.japanese: return '修正要求が受け付けられました';
    case AppLanguage.chinese:  return '修改申请已受理';
    case AppLanguage.mongolian:return 'Засах хүсэлт хүлээн авагдлаа';
  }}
  String get modifyRequest { switch (language) {
    case AppLanguage.korean:   return '수정요청 제출';
    case AppLanguage.english:  return 'Submit Modification';
    case AppLanguage.japanese: return '修正要求提出';
    case AppLanguage.chinese:  return '提交修改申请';
    case AppLanguage.mongolian:return 'Засах хүсэлт илгээх';
  }}
  String get colorModify { switch (language) {
    case AppLanguage.korean:   return '변경할 컬러 *';
    case AppLanguage.english:  return 'New Color *';
    case AppLanguage.japanese: return '変更カラー *';
    case AppLanguage.chinese:  return '更改颜色 *';
    case AppLanguage.mongolian:return 'Шинэ өнгө *';
  }}
  String get selectColor2 { switch (language) {
    case AppLanguage.korean:   return '컬러를 선택해주세요';
    case AppLanguage.english:  return 'Please select a color';
    case AppLanguage.japanese: return 'カラーを選択してください';
    case AppLanguage.chinese:  return '请选择颜色';
    case AppLanguage.mongolian:return 'Өнгө сонгоно уу';
  }}
  String get groupNameModify { switch (language) {
    case AppLanguage.korean:   return '변경할 단체명 (선택)';
    case AppLanguage.english:  return 'New Group Name (Optional)';
    case AppLanguage.japanese: return '変更団体名 (任意)';
    case AppLanguage.chinese:  return '更改团体名称 (可选)';
    case AppLanguage.mongolian:return 'Шинэ багийн нэр (сонголттой)';
  }}
  String get additionalRequest { switch (language) {
    case AppLanguage.korean:   return '추가 요청사항 (선택)';
    case AppLanguage.english:  return 'Additional Request (Optional)';
    case AppLanguage.japanese: return '追加リクエスト (任意)';
    case AppLanguage.chinese:  return '额外要求 (可选)';
    case AppLanguage.mongolian:return 'Нэмэлт хүсэлт (сонголттой)';
  }}

  // ── 주문 안내 화면 ──
  String get orderGuideTitle { switch (language) {
    case AppLanguage.korean:   return '주문 안내';
    case AppLanguage.english:  return 'Order Guide';
    case AppLanguage.japanese: return '注文案内';
    case AppLanguage.chinese:  return '订购指南';
    case AppLanguage.mongolian:return 'Захиалгын заавар';
  }}
  String get groupCustomOrder { switch (language) {
    case AppLanguage.korean:   return '단체 커스텀 주문';
    case AppLanguage.english:  return 'Group Custom Order';
    case AppLanguage.japanese: return '団体カスタム注文';
    case AppLanguage.chinese:  return '团体定制订单';
    case AppLanguage.mongolian:return 'Бүлгийн тусгай захиалга';
  }}
  String get viewGuide { switch (language) {
    case AppLanguage.korean:   return '안내 보기';
    case AppLanguage.english:  return 'View Guide';
    case AppLanguage.japanese: return '案内を見る';
    case AppLanguage.chinese:  return '查看说明';
    case AppLanguage.mongolian:return 'Заавар харах';
  }}
  String get fillOrderForm { switch (language) {
    case AppLanguage.korean:   return '주문서 작성';
    case AppLanguage.english:  return 'Fill Order Form';
    case AppLanguage.japanese: return '注文書作成';
    case AppLanguage.chinese:  return '填写订单表格';
    case AppLanguage.mongolian:return 'Захиалгын маягт бөглөх';
  }}
  String get orderProcess { switch (language) {
    case AppLanguage.korean:   return '주문 흐름';
    case AppLanguage.english:  return 'Order Process';
    case AppLanguage.japanese: return '注文フロー';
    case AppLanguage.chinese:  return '订单流程';
    case AppLanguage.mongolian:return 'Захиалгын явц';
  }}
  String get customerCenter { switch (language) {
    case AppLanguage.korean:   return '고객센터';
    case AppLanguage.english:  return 'Customer Center';
    case AppLanguage.japanese: return 'カスタマーセンター';
    case AppLanguage.chinese:  return '客服中心';
    case AppLanguage.mongolian:return 'Үйлчлүүлэгчийн төв';
  }}
  String get additionalPurchase { switch (language) {
    case AppLanguage.korean:   return '추가구매';
    case AppLanguage.english:  return 'Additional Purchase';
    case AppLanguage.japanese: return '追加購入';
    case AppLanguage.chinese:  return '追加购买';
    case AppLanguage.mongolian:return 'Нэмэлт худалдан авалт';
  }}
  String get addToExistingOrder { switch (language) {
    case AppLanguage.korean:   return '기존 주문에 추가';
    case AppLanguage.english:  return 'Add to Existing Order';
    case AppLanguage.japanese: return '既存の注文に追加';
    case AppLanguage.chinese:  return '添加到现有订单';
    case AppLanguage.mongolian:return 'Одоо байгаа захиалганд нэмэх';
  }}
  String get additionalPurchaseGuide { switch (language) {
    case AppLanguage.korean:   return '추가구매 안내';
    case AppLanguage.english:  return 'Additional Purchase Guide';
    case AppLanguage.japanese: return '追加購入案内';
    case AppLanguage.chinese:  return '追加购买说明';
    case AppLanguage.mongolian:return 'Нэмэлт худалдан авалтын заавар';
  }}
  String get orderProcessTitle { switch (language) {
    case AppLanguage.korean:   return '주문 프로세스';
    case AppLanguage.english:  return 'Order Process';
    case AppLanguage.japanese: return '注文プロセス';
    case AppLanguage.chinese:  return '订单流程';
    case AppLanguage.mongolian:return 'Захиалгын процесс';
  }}
  String get orderFormTitle { switch (language) {
    case AppLanguage.korean:   return '주문서 양식';
    case AppLanguage.english:  return 'Order Form';
    case AppLanguage.japanese: return '注文書様式';
    case AppLanguage.chinese:  return '订单表格';
    case AppLanguage.mongolian:return 'Захиалгын маягт';
  }}
  String get cancelRefundPolicy { switch (language) {
    case AppLanguage.korean:   return '취소/교환/환불 정책';
    case AppLanguage.english:  return 'Cancel/Exchange/Refund Policy';
    case AppLanguage.japanese: return 'キャンセル・交換・返金ポリシー';
    case AppLanguage.chinese:  return '取消/换货/退款政策';
    case AppLanguage.mongolian:return 'Цуцлах/Солих/Буцаалтын бодлого';
  }}
  String get shippingGuide { switch (language) {
    case AppLanguage.korean:   return '배송 안내';
    case AppLanguage.english:  return 'Shipping Guide';
    case AppLanguage.japanese: return '配送案内';
    case AppLanguage.chinese:  return '配送说明';
    case AppLanguage.mongolian:return 'Хүргэлтийн заавар';
  }}
  String get faqTitle { switch (language) {
    case AppLanguage.korean:   return '자주 묻는 질문 FAQ';
    case AppLanguage.english:  return 'FAQ';
    case AppLanguage.japanese: return 'よくある質問 FAQ';
    case AppLanguage.chinese:  return '常见问题 FAQ';
    case AppLanguage.mongolian:return 'Түгээмэл асуулт FAQ';
  }}

  // ── 로그인 화면 ──
  String get adminAccount { switch (language) {
    case AppLanguage.korean:   return '관리자 계정';
    case AppLanguage.english:  return 'Admin Account';
    case AppLanguage.japanese: return '管理者アカウント';
    case AppLanguage.chinese:  return '管理员账户';
    case AppLanguage.mongolian:return 'Удирдагчийн бүртгэл';
  }}
  String get adminAccountEntered { switch (language) {
    case AppLanguage.korean:   return '관리자 계정이 입력되었습니다';
    case AppLanguage.english:  return 'Admin account entered';
    case AppLanguage.japanese: return '管理者アカウントが入力されました';
    case AppLanguage.chinese:  return '已输入管理员账户';
    case AppLanguage.mongolian:return 'Удирдагчийн бүртгэл оруулагдлаа';
  }}
  String get passwordResetTitle { switch (language) {
    case AppLanguage.korean:   return '비밀번호 찾기';
    case AppLanguage.english:  return 'Password Reset';
    case AppLanguage.japanese: return 'パスワードリセット';
    case AppLanguage.chinese:  return '找回密码';
    case AppLanguage.mongolian:return 'Нууц үг сэргээх';
  }}
  String get emailSent { switch (language) {
    case AppLanguage.korean:   return '이메일을 발송했습니다';
    case AppLanguage.english:  return 'Email sent';
    case AppLanguage.japanese: return 'メールを送信しました';
    case AppLanguage.chinese:  return '邮件已发送';
    case AppLanguage.mongolian:return 'Имэйл илгээгдлээ';
  }}
  String get checkMailbox { switch (language) {
    case AppLanguage.korean:   return '메일함을 확인해주세요.';
    case AppLanguage.english:  return 'Please check your mailbox.';
    case AppLanguage.japanese: return 'メールボックスをご確認ください。';
    case AppLanguage.chinese:  return '请检查您的邮箱。';
    case AppLanguage.mongolian:return 'Имэйл хайрцгаа шалгана уу.';
  }}
  String get passwordResetGuide { switch (language) {
    case AppLanguage.korean:   return '가입하신 이메일 주소를 입력하시면\n비밀번호 재설정 링크를 보내드립니다.';
    case AppLanguage.english:  return 'Enter your registered email address\nand we will send a password reset link.';
    case AppLanguage.japanese: return 'ご登録のメールアドレスを入力いただければ\nパスワードリセットリンクをお送りします。';
    case AppLanguage.chinese:  return '请输入您注册的邮箱地址，\n我们将发送密码重置链接。';
    case AppLanguage.mongolian:return 'Бүртгэлтэй имэйл хаягаа оруулбал\nнууц үг шинэчлэх холбоос илгээнэ.';
  }}
  String get sendResetEmail { switch (language) {
    case AppLanguage.korean:   return '재설정 메일 발송';
    case AppLanguage.english:  return 'Send Reset Email';
    case AppLanguage.japanese: return 'リセットメール送信';
    case AppLanguage.chinese:  return '发送重置邮件';
    case AppLanguage.mongolian:return 'Шинэчлэлийн имэйл илгээх';
  }}

  // ── 상품 목록 화면 ──
  String get allProductsTitle { switch (language) {
    case AppLanguage.korean:   return '전체 상품';
    case AppLanguage.english:  return 'All Products';
    case AppLanguage.japanese: return '全商品';
    case AppLanguage.chinese:  return '全部商品';
    case AppLanguage.mongolian:return 'Бүх бараа';
  }}
  String get priceRange { switch (language) {
    case AppLanguage.korean:   return '가격 범위';
    case AppLanguage.english:  return 'Price Range';
    case AppLanguage.japanese: return '価格範囲';
    case AppLanguage.chinese:  return '价格范围';
    case AppLanguage.mongolian:return 'Үнийн хязгаар';
  }}
  String get filterReset { switch (language) {
    case AppLanguage.korean:   return '필터 초기화';
    case AppLanguage.english:  return 'Reset Filter';
    case AppLanguage.japanese: return 'フィルタリセット';
    case AppLanguage.chinese:  return '重置筛选';
    case AppLanguage.mongolian:return 'Шүүлтүүр цэвэрлэх';
  }}
  String get viewAllProducts2 { switch (language) {
    case AppLanguage.korean:   return '전체 상품 보기';
    case AppLanguage.english:  return 'View All Products';
    case AppLanguage.japanese: return '全商品を見る';
    case AppLanguage.chinese:  return '查看全部商品';
    case AppLanguage.mongolian:return 'Бүх барааг харах';
  }}

  // ── 알림 센터 ──
  String get notificationCenter { switch (language) {
    case AppLanguage.korean:   return '알림 센터';
    case AppLanguage.english:  return 'Notification Center';
    case AppLanguage.japanese: return '通知センター';
    case AppLanguage.chinese:  return '通知中心';
    case AppLanguage.mongolian:return 'Мэдэгдлийн төв';
  }}
  String get noNotificationsYet { switch (language) {
    case AppLanguage.korean:   return '알림이 없습니다';
    case AppLanguage.english:  return 'No notifications';
    case AppLanguage.japanese: return '通知がありません';
    case AppLanguage.chinese:  return '暂无通知';
    case AppLanguage.mongolian:return 'Мэдэгдэл байхгүй';
  }}

  // ── 공통 에러/성공 메시지 ──
  String get errorOccurred { switch (language) {
    case AppLanguage.korean:   return '오류가 발생했습니다';
    case AppLanguage.english:  return 'An error occurred';
    case AppLanguage.japanese: return 'エラーが発生しました';
    case AppLanguage.chinese:  return '发生错误';
    case AppLanguage.mongolian:return 'Алдаа гарлаа';
  }}
  String get selectGender { switch (language) {
    case AppLanguage.korean:   return '성별 선택';
    case AppLanguage.english:  return 'Select Gender';
    case AppLanguage.japanese: return '性別選択';
    case AppLanguage.chinese:  return '选择性别';
    case AppLanguage.mongolian:return 'Хүйс сонгох';
  }}

  String get sameAsPrevious { switch (language) {
    case AppLanguage.korean:   return '기존 주문과 동일한 옵션으로 추가 제작';
    case AppLanguage.english:  return 'Additional production with same options as previous order';
    case AppLanguage.japanese: return '既存注文と同じオプションで追加製作';
    case AppLanguage.chinese:  return '与原订单相同选项追加生产';
    case AppLanguage.mongolian:return 'Өмнөх захиалгатай ижил сонголтоор нэмэлт үйлдвэрлэл';
  }}

  // ── 상품 상세 / 구매 공통 ──
  String get groupOrderBtn { switch (language) {
    case AppLanguage.korean:   return '단체주문 하기';
    case AppLanguage.english:  return 'Group Order';
    case AppLanguage.japanese: return '団体注文する';
    case AppLanguage.chinese:  return '提交团体订单';
    case AppLanguage.mongolian:return 'Бүлгийн захиалга өгөх';
  }}
  String get groupOrderApply { switch (language) {
    case AppLanguage.korean:   return '단체주문 신청하기';
    case AppLanguage.english:  return 'Apply Group Order';
    case AppLanguage.japanese: return '団体注文を申し込む';
    case AppLanguage.chinese:  return '申请团体订单';
    case AppLanguage.mongolian:return 'Бүлгийн захиалга илгээх';
  }}
  String get groupOrderInfo { switch (language) {
    case AppLanguage.korean:   return '단체주문 안내';
    case AppLanguage.english:  return 'Group Order Info';
    case AppLanguage.japanese: return '団体注文案内';
    case AppLanguage.chinese:  return '团体订单说明';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгын мэдээлэл';
  }}
  String get groupOrderMin { switch (language) {
    case AppLanguage.korean:   return '5벌 이상 단체 주문 가능';
    case AppLanguage.english:  return 'Minimum 5 items for group order';
    case AppLanguage.japanese: return '5着以上の団体注文が可能';
    case AppLanguage.chinese:  return '团体订单最少5件';
    case AppLanguage.mongolian:return '5-аас дээш ширхэг захиалах боломжтой';
  }}
  String get groupOrderPrint { switch (language) {
    case AppLanguage.korean:   return '팀 로고 · 이름 · 번호 인쇄';
    case AppLanguage.english:  return 'Team logo · name · number printing';
    case AppLanguage.japanese: return 'チームロゴ・名前・番号プリント';
    case AppLanguage.chinese:  return '团队徽标·姓名·号码印刷';
    case AppLanguage.mongolian:return 'Багийн лого · нэр · дугаар хэвлэх';
  }}
  String get groupOrderDiscount { switch (language) {
    case AppLanguage.korean:   return '단체 할인 적용';
    case AppLanguage.english:  return 'Group discount applied';
    case AppLanguage.japanese: return '団体割引適用';
    case AppLanguage.chinese:  return '适用团体折扣';
    case AppLanguage.mongolian:return 'Бүлгийн хөнгөлөлт үйлчлэнэ';
  }}
  String get orderType { switch (language) {
    case AppLanguage.korean:   return '주문 유형 선택';
    case AppLanguage.english:  return 'Select Order Type';
    case AppLanguage.japanese: return '注文タイプを選択';
    case AppLanguage.chinese:  return '选择订单类型';
    case AppLanguage.mongolian:return 'Захиалгын төрөл сонгох';
  }}
  String get sizeLabel { switch (language) {
    case AppLanguage.korean:   return '사이즈';
    case AppLanguage.english:  return 'Size';
    case AppLanguage.japanese: return 'サイズ';
    case AppLanguage.chinese:  return '尺码';
    case AppLanguage.mongolian:return 'Хэмжээ';
  }}
  String get colorLabel { switch (language) {
    case AppLanguage.korean:   return '색상';
    case AppLanguage.english:  return 'Color';
    case AppLanguage.japanese: return 'カラー';
    case AppLanguage.chinese:  return '颜色';
    case AppLanguage.mongolian:return 'Өнгө';
  }}
  String get quantityLabel { switch (language) {
    case AppLanguage.korean:   return '수량';
    case AppLanguage.english:  return 'Quantity';
    case AppLanguage.japanese: return '数量';
    case AppLanguage.chinese:  return '数量';
    case AppLanguage.mongolian:return 'Тоо хэмжээ';
  }}
  String get cartLabel { switch (language) {
    case AppLanguage.korean:   return '장바구니';
    case AppLanguage.english:  return 'Cart';
    case AppLanguage.japanese: return 'カート';
    case AppLanguage.chinese:  return '购物车';
    case AppLanguage.mongolian:return 'Сагс';
  }}
  String get readyProduct { switch (language) {
    case AppLanguage.korean:   return '기성품';
    case AppLanguage.english:  return 'Ready-made';
    case AppLanguage.japanese: return '既製品';
    case AppLanguage.chinese:  return '现货商品';
    case AppLanguage.mongolian:return 'Бэлэн бараа';
  }}
  String get readyProductBuy { switch (language) {
    case AppLanguage.korean:   return '바로 구매';
    case AppLanguage.english:  return 'Buy Now';
    case AppLanguage.japanese: return '今すぐ購入';
    case AppLanguage.chinese:  return '立即购买';
    case AppLanguage.mongolian:return 'Шууд авах';
  }}
  String get materialLabel { switch (language) {
    case AppLanguage.korean:   return '소재';
    case AppLanguage.english:  return 'Material';
    case AppLanguage.japanese: return '素材';
    case AppLanguage.chinese:  return '材质';
    case AppLanguage.mongolian:return 'Материал';
  }}
  String get shippingDays { switch (language) {
    case AppLanguage.korean:   return '배송기간';
    case AppLanguage.english:  return 'Delivery';
    case AppLanguage.japanese: return '配送期間';
    case AppLanguage.chinese:  return '配送时间';
    case AppLanguage.mongolian:return 'Хүргэлтийн хугацаа';
  }}
  String get returnPolicy { switch (language) {
    case AppLanguage.korean:   return '교환/반품';
    case AppLanguage.english:  return 'Exchange/Return';
    case AppLanguage.japanese: return '交換/返品';
    case AppLanguage.chinese:  return '换货/退货';
    case AppLanguage.mongolian:return 'Буцаалт/Солилт';
  }}
  String get shippingFeeValue { switch (language) {
    case AppLanguage.korean:   return '3,000원 (30만원↑ 무료)';
    case AppLanguage.english:  return '₩3,000 (Free over ₩300,000)';
    case AppLanguage.japanese: return '3,000ウォン(30万ウォン以上無料)';
    case AppLanguage.chinese:  return '3,000韩元(满30万免运费)';
    case AppLanguage.mongolian:return '₩3,000 (₩300,000-аас дээш үнэгүй)';
  }}
  String get deliveryDaysValue { switch (language) {
    case AppLanguage.korean:   return '주문 후 5~7일';
    case AppLanguage.english:  return '5~7 days after order';
    case AppLanguage.japanese: return '注文後5〜7日';
    case AppLanguage.chinese:  return '下单后5~7天';
    case AppLanguage.mongolian:return 'Захиалгын дараа 5~7 хоног';
  }}
  String get returnPolicyValue { switch (language) {
    case AppLanguage.korean:   return '수령 후 7일 이내';
    case AppLanguage.english:  return 'Within 7 days of receipt';
    case AppLanguage.japanese: return '受領後7日以内';
    case AppLanguage.chinese:  return '收货后7天内';
    case AppLanguage.mongolian:return 'Хүлээн авсанаас хойш 7 хоногт';
  }}
  String get freeShippingBadge { switch (language) {
    case AppLanguage.korean:   return '무료배송';
    case AppLanguage.english:  return 'Free Shipping';
    case AppLanguage.japanese: return '送料無料';
    case AppLanguage.chinese:  return '免运费';
    case AppLanguage.mongolian:return 'Үнэгүй хүргэлт';
  }}
  String get myPageLabel { switch (language) {
    case AppLanguage.korean:   return '마이페이지';
    case AppLanguage.english:  return 'My Page';
    case AppLanguage.japanese: return 'マイページ';
    case AppLanguage.chinese:  return '我的页面';
    case AppLanguage.mongolian:return 'Миний хуудас';
  }}
  String get review { switch (language) {
    case AppLanguage.korean:   return '리뷰';
    case AppLanguage.english:  return 'Review';
    case AppLanguage.japanese: return 'レビュー';
    case AppLanguage.chinese:  return '评价';
    case AppLanguage.mongolian:return 'Үнэлгээ';
  }}
  String get allCategories { switch (language) {
    case AppLanguage.korean:   return '전체 카테고리';
    case AppLanguage.english:  return 'All Categories';
    case AppLanguage.japanese: return '全カテゴリ';
    case AppLanguage.chinese:  return '全部分类';
    case AppLanguage.mongolian:return 'Бүх ангилал';
  }}
  String get categoryLabel { switch (language) {
    case AppLanguage.korean:   return '카테고리';
    case AppLanguage.english:  return 'Category';
    case AppLanguage.japanese: return 'カテゴリ';
    case AppLanguage.chinese:  return '分类';
    case AppLanguage.mongolian:return 'Ангилал';
  }}
  String get apply { switch (language) {
    case AppLanguage.korean:   return '적용';
    case AppLanguage.english:  return 'Apply';
    case AppLanguage.japanese: return '適用';
    case AppLanguage.chinese:  return '应用';
    case AppLanguage.mongolian:return 'Хэрэглэх';
  }}
  String get select { switch (language) {
    case AppLanguage.korean:   return '선택';
    case AppLanguage.english:  return 'Select';
    case AppLanguage.japanese: return '選択';
    case AppLanguage.chinese:  return '选择';
    case AppLanguage.mongolian:return 'Сонгох';
  }}
  String get signup { switch (language) {
    case AppLanguage.korean:   return '회원가입';
    case AppLanguage.english:  return 'Sign Up';
    case AppLanguage.japanese: return '会員登録';
    case AppLanguage.chinese:  return '注册';
    case AppLanguage.mongolian:return 'Бүртгүүлэх';
  }}
  String get noResults { switch (language) {
    case AppLanguage.korean:   return '검색 결과가 없습니다';
    case AppLanguage.english:  return 'No results found';
    case AppLanguage.japanese: return '検索結果がありません';
    case AppLanguage.chinese:  return '未找到结果';
    case AppLanguage.mongolian:return 'Хайлтын үр дүн байхгүй';
  }}

  // ── 단체주문 안내 (Group Order Guide) ──────────────────────
  String get groupOrderGuideTitle { switch (language) {
    case AppLanguage.korean:   return '단체 주문 안내';
    case AppLanguage.english:  return 'Group Order Guide';
    case AppLanguage.japanese: return '団体注文案内';
    case AppLanguage.chinese:  return '团体订单指南';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгын заавар';
  }}
  String get groupOrderFormTab { switch (language) {
    case AppLanguage.korean:   return '주문 양식';
    case AppLanguage.english:  return 'Order Form';
    case AppLanguage.japanese: return '注文フォーム';
    case AppLanguage.chinese:  return '订单表格';
    case AppLanguage.mongolian:return 'Захиалгын маягт';
  }}
  String get groupOrderGuideTab { switch (language) {
    case AppLanguage.korean:   return '주문 안내';
    case AppLanguage.english:  return 'Order Guide';
    case AppLanguage.japanese: return '注文案内';
    case AppLanguage.chinese:  return '订单指南';
    case AppLanguage.mongolian:return 'Захиалгын заавар';
  }}
  String get groupOrderAgreement { switch (language) {
    case AppLanguage.korean:   return '위 안내 내용을 모두 확인하였습니다.';
    case AppLanguage.english:  return 'I have read and understood all the above guidelines.';
    case AppLanguage.japanese: return '上記の案内内容をすべて確認しました。';
    case AppLanguage.chinese:  return '我已阅读并理解以上所有指南内容。';
    case AppLanguage.mongolian:return 'Дээрх бүх мэдээллийг уншиж ойлголоо.';
  }}
  String get groupOrderAgreementCheck { switch (language) {
    case AppLanguage.korean:   return '안내를 확인 체크 후 양식 작성이 가능합니다';
    case AppLanguage.english:  return 'Please check the agreement to proceed to the form';
    case AppLanguage.japanese: return '案内を確認チェック後、フォーム記入が可能です';
    case AppLanguage.chinese:  return '请确认勾选协议后填写表格';
    case AppLanguage.mongolian:return 'Маягт бөглөхийн өмнө зөвшөөрлөө шалгана уу';
  }}
  String get groupOrderWriteForm { switch (language) {
    case AppLanguage.korean:   return '주문 양식 작성하기';
    case AppLanguage.english:  return 'Fill Out Order Form';
    case AppLanguage.japanese: return '注文フォームを記入する';
    case AppLanguage.chinese:  return '填写订单表格';
    case AppLanguage.mongolian:return 'Захиалгын маягт бөглөх';
  }}
  String get groupOrderMinQty { switch (language) {
    case AppLanguage.korean:   return '최소 수량';
    case AppLanguage.english:  return 'Minimum Quantity';
    case AppLanguage.japanese: return '最低数量';
    case AppLanguage.chinese:  return '最低数量';
    case AppLanguage.mongolian:return 'Хамгийн бага тоо';
  }}
  String get groupOrderMinQtyDesc { switch (language) {
    case AppLanguage.korean:   return '단체 커스텀 제작은 최소 5명부터 가능합니다.';
    case AppLanguage.english:  return 'Group custom orders require a minimum of 5 people.';
    case AppLanguage.japanese: return '団体カスタム製作は最低5名から可能です。';
    case AppLanguage.chinese:  return '团体定制最少5人起订。';
    case AppLanguage.mongolian:return 'Бүлгийн захиалга хамгийн багадаа 5 хүнээс эхэлнэ.';
  }}
  String get groupOrderProductionPeriod { switch (language) {
    case AppLanguage.korean:   return '제작 기간';
    case AppLanguage.english:  return 'Production Period';
    case AppLanguage.japanese: return '製作期間';
    case AppLanguage.chinese:  return '制作周期';
    case AppLanguage.mongolian:return 'Үйлдвэрлэлийн хугацаа';
  }}
  String get groupOrderProductionPeriodDesc { switch (language) {
    case AppLanguage.korean:   return '주문 확정 후 14~21일 소요됩니다.\n• 디자인 수정: 1회당 3일 이내 수정 요청 없을 시 확정 후 제작 시작\n(시즌/물량에 따라 변동될 수 있습니다)';
    case AppLanguage.english:  return '14–21 days after order confirmation.\n• Design revision: If no revision request within 3 days per revision, production starts automatically.\n(May vary by season/volume)';
    case AppLanguage.japanese: return 'ご注文確定後14~21日かかります。\n• デザイン修正：1回につき3日以内に修正依頼がない場合、確定し製作開始\n(シーズン・数量により変動する場合があります)';
    case AppLanguage.chinese:  return '订单确认后需14~21天。\n• 设计修改：每次修改3天内无修改申请则确认并开始制作\n(可能因季节/数量而有所变动)';
    case AppLanguage.mongolian:return 'Захиалга баталгаажсанаас хойш 14~21 өдөр.\n• Дизайн засвар: Нэг засвар тутамд 3 хоногийн дотор хүсэлт гараагүй бол баталгаажиж үйлдвэрлэл эхэлнэ.\n(Улирал/тоо хэмжээнээс хамаарч өөрчлөгдөж болно)';
  }}
  String get groupOrderShippingTitle { switch (language) {
    case AppLanguage.korean:   return '배송 안내';
    case AppLanguage.english:  return 'Shipping Guide';
    case AppLanguage.japanese: return '配送案内';
    case AppLanguage.chinese:  return '配送说明';
    case AppLanguage.mongolian:return 'Хүргэлтийн мэдээлэл';
  }}
  String get groupOrderShipping1 { switch (language) {
    case AppLanguage.korean:   return '• 20만원 이상 구매 시: 무료배송';
    case AppLanguage.english:  return '• Orders over ₩200,000: Free shipping';
    case AppLanguage.japanese: return '• 20万ウォン以上のご購入：送料無料';
    case AppLanguage.chinese:  return '• 购买满20万韩元：免费配送';
    case AppLanguage.mongolian:return '• 200,000₩-аас дээш захиалга: Үнэгүй хүргэлт';
  }}
  String get groupOrderShipping2 { switch (language) {
    case AppLanguage.korean:   return '• 20만원 미만: 배송비 별도';
    case AppLanguage.english:  return '• Orders under ₩200,000: Shipping fee applies';
    case AppLanguage.japanese: return '• 20万ウォン未満：配送料別途';
    case AppLanguage.chinese:  return '• 购买不足20万韩元：额外收取配送费';
    case AppLanguage.mongolian:return '• 200,000₩-аас бага захиалга: Тусдаа хүргэлтийн мөнгө';
  }}
  String get groupOrderShipping3 { switch (language) {
    case AppLanguage.korean:   return '• 추가 제작 배송비: 4,000원';
    case AppLanguage.english:  return '• Additional production shipping: ₩4,000';
    case AppLanguage.japanese: return '• 追加製作送料：4,000ウォン';
    case AppLanguage.chinese:  return '• 追加制作配送费：4,000韩元';
    case AppLanguage.mongolian:return '• Нэмэлт үйлдвэрлэлийн хүргэлт: 4,000₩';
  }}
  String get groupOrderShipping4 { switch (language) {
    case AppLanguage.korean:   return '• 단체 주문은 일괄 배송이 원칙입니다.';
    case AppLanguage.english:  return '• Group orders are shipped together in bulk.';
    case AppLanguage.japanese: return '• 団体注文は一括配送が原則です。';
    case AppLanguage.chinese:  return '• 团体订单原则上统一配送。';
    case AppLanguage.mongolian:return '• Бүлгийн захиалга нэг удаа нэгдсэн хүргэлт хийгддэг.';
  }}
  String get groupOrderCustomTitle { switch (language) {
    case AppLanguage.korean:   return '커스텀 옵션';
    case AppLanguage.english:  return 'Custom Options';
    case AppLanguage.japanese: return 'カスタムオプション';
    case AppLanguage.chinese:  return '定制选项';
    case AppLanguage.mongolian:return 'Захиалгат сонголтууд';
  }}
  String get groupOrderCustom1 { switch (language) {
    case AppLanguage.korean:   return '• 팀 로고/마킹 추가 가능 (5명 이상 무료)';
    case AppLanguage.english:  return '• Team logo/marking available (free for 5+)';
    case AppLanguage.japanese: return '• チームロゴ/マーキング追加可能（5名以上無料）';
    case AppLanguage.chinese:  return '• 可添加团队标志/标记（5人以上免费）';
    case AppLanguage.mongolian:return '• Багийн лого/тэмдэглэгээ нэмэх боломжтой (5+хүн үнэгүй)';
  }}
  String get groupOrderCustom2 { switch (language) {
    case AppLanguage.korean:   return '• 색상 커스텀: 심리스 소재 전용';
    case AppLanguage.english:  return '• Color custom: seamless fabric only';
    case AppLanguage.japanese: return '• カラーカスタム：シームレス素材専用';
    case AppLanguage.chinese:  return '• 颜色定制：仅限无缝面料';
    case AppLanguage.mongolian:return '• Өнгөний тохиргоо: зөвхөн seamless даавуу';
  }}
  String get groupOrderCustom3 { switch (language) {
    case AppLanguage.korean:   return '• 허리밴드 색상 변경 가능 (형태·디자인 변경 불가)';
    case AppLanguage.english:  return '• Waistband color change available (shape/design unchangeable)';
    case AppLanguage.japanese: return '• ウエストバンドの色変更可能（形状・デザイン変更不可）';
    case AppLanguage.chinese:  return '• 可更改腰带颜色（不可更改形状·设计）';
    case AppLanguage.mongolian:return '• Бүсний өнгийг өөрчлөх боломжтой (хэлбэр/дизайн өөрчлөх боломжгүй)';
  }}
  String get groupOrderDiscountTitle { switch (language) {
    case AppLanguage.korean:   return '수량별 할인';
    case AppLanguage.english:  return 'Volume Discounts';
    case AppLanguage.japanese: return '数量別割引';
    case AppLanguage.chinese:  return '数量折扣';
    case AppLanguage.mongolian:return 'Тооны хэмжээгээр хямдрал';
  }}
  String get groupOrderDiscount1 { switch (language) {
    case AppLanguage.korean:   return '• 30개 이상: 10% 할인';
    case AppLanguage.english:  return '• 30+ items: 10% discount';
    case AppLanguage.japanese: return '• 30個以上：10%割引';
    case AppLanguage.chinese:  return '• 30件以上：9折';
    case AppLanguage.mongolian:return '• 30+ ширхэг: 10% хямдрал';
  }}
  String get groupOrderDiscount2 { switch (language) {
    case AppLanguage.korean:   return '• 50개 이상: 20% 할인';
    case AppLanguage.english:  return '• 50+ items: 20% discount';
    case AppLanguage.japanese: return '• 50個以上：20%割引';
    case AppLanguage.chinese:  return '• 50件以上：8折';
    case AppLanguage.mongolian:return '• 50+ ширхэг: 20% хямдрал';
  }}
  String get groupOrderDiscount3 { switch (language) {
    case AppLanguage.korean:   return '• 100개 이상: 별도 협의';
    case AppLanguage.english:  return '• 100+ items: custom negotiation';
    case AppLanguage.japanese: return '• 100個以上：別途協議';
    case AppLanguage.chinese:  return '• 100件以上：另行协商';
    case AppLanguage.mongolian:return '• 100+ ширхэг: тусдаа хэлэлцэх';
  }}
  String get groupOrderExchangeTitle { switch (language) {
    case AppLanguage.korean:   return '교환·환불 정책';
    case AppLanguage.english:  return 'Exchange & Refund Policy';
    case AppLanguage.japanese: return '交換・返金ポリシー';
    case AppLanguage.chinese:  return '退换货政策';
    case AppLanguage.mongolian:return 'Солилцоо ба буцаалтын бодлого';
  }}
  String get groupOrderExchange1 { switch (language) {
    case AppLanguage.korean:   return '• 의류 자체 불량 외 교환·환불은 불가합니다.';
    case AppLanguage.english:  return '• Exchanges/refunds are only available for product defects.';
    case AppLanguage.japanese: return '• 衣類自体の不良以外の交換・返金は不可です。';
    case AppLanguage.chinese:  return '• 除产品本身缺陷外，不接受退换货。';
    case AppLanguage.mongolian:return '• Бүтээгдэхүүний гэмтлээс бусад тохиолдолд солилцоо/буцаалт хийх боломжгүй.';
  }}
  String get groupOrderExchange2 { switch (language) {
    case AppLanguage.korean:   return '• 커스텀 마킹이 포함된 경우 교환·환불이 불가합니다.';
    case AppLanguage.english:  return '• No exchanges/refunds for items with custom markings.';
    case AppLanguage.japanese: return '• カスタムマーキングが含まれる場合、交換・返金は不可です。';
    case AppLanguage.chinese:  return '• 含定制标记的商品不接受退换货。';
    case AppLanguage.mongolian:return '• Захиалгат тэмдэглэгээтэй бараанд солилцоо/буцаалт хийх боломжгүй.';
  }}
  String get groupOrderNoSizeHint { switch (language) {
    case AppLanguage.korean:   return '원하는 사이즈가 없을 경우';
    case AppLanguage.english:  return 'If your size is not listed';
    case AppLanguage.japanese: return '希望のサイズがない場合';
    case AppLanguage.chinese:  return '如果没有您想要的尺码';
    case AppLanguage.mongolian:return 'Хэмжээ байхгүй бол';
  }}
  String get groupOrderNoSizeDesc { switch (language) {
    case AppLanguage.korean:   return '키(cm)와 몸무게(kg)를 아래 주문서에 입력해 주세요.\n담당자가 최적 사이즈를 추천해 드립니다.';
    case AppLanguage.english:  return 'Please enter your height (cm) and weight (kg) in the order form below.\nOur staff will recommend the best size for you.';
    case AppLanguage.japanese: return '身長(cm)と体重(kg)を下の注文書に入力してください。\n担当者が最適なサイズをご提案します。';
    case AppLanguage.chinese:  return '请在下方订单中填写您的身高(cm)和体重(kg)。\n工作人员将为您推荐最合适的尺码。';
    case AppLanguage.mongolian:return 'Өндөр (cm) болон жин (kg)-ийг доорх захиалгын хуудсанд оруулна уу.\nАжилтан таны хамгийн тохиромжтой хэмжээг зөвлөнө.';
  }}
  String get adultSizeTable { switch (language) {
    case AppLanguage.korean:   return '성인 사이즈표 (XS~XXXL)';
    case AppLanguage.english:  return 'Adult Size Chart (XS~XXXL)';
    case AppLanguage.japanese: return '大人サイズ表（XS~XXXL）';
    case AppLanguage.chinese:  return '成人尺码表（XS~XXXL）';
    case AppLanguage.mongolian:return 'Насанд хүрэгчдийн хэмжээний хүснэгт (XS~XXXL)';
  }}
  String get juniorSizeTable { switch (language) {
    case AppLanguage.korean:   return '주니어 사이즈표 (XXS~L)';
    case AppLanguage.english:  return 'Junior Size Chart (XXS~L)';
    case AppLanguage.japanese: return 'ジュニアサイズ表（XXS~L）';
    case AppLanguage.chinese:  return '青少年尺码表（XXS~L）';
    case AppLanguage.mongolian:return 'Жуниорын хэмжээний хүснэгт (XXS~L)';
  }}
  String get sizeColSize { switch (language) {
    case AppLanguage.korean:   return '사이즈';
    case AppLanguage.english:  return 'Size';
    case AppLanguage.japanese: return 'サイズ';
    case AppLanguage.chinese:  return '尺码';
    case AppLanguage.mongolian:return 'Хэмжээ';
  }}
  String get sizeColChest { switch (language) {
    case AppLanguage.korean:   return '가슴(cm)';
    case AppLanguage.english:  return 'Chest(cm)';
    case AppLanguage.japanese: return '胸囲(cm)';
    case AppLanguage.chinese:  return '胸围(cm)';
    case AppLanguage.mongolian:return 'Цээж(cm)';
  }}
  String get sizeColWaist { switch (language) {
    case AppLanguage.korean:   return '허리(cm)';
    case AppLanguage.english:  return 'Waist(cm)';
    case AppLanguage.japanese: return 'ウエスト(cm)';
    case AppLanguage.chinese:  return '腰围(cm)';
    case AppLanguage.mongolian:return 'Бүсэлхий(cm)';
  }}
  String get sizeColHip { switch (language) {
    case AppLanguage.korean:   return '엉덩이(cm)';
    case AppLanguage.english:  return 'Hip(cm)';
    case AppLanguage.japanese: return 'ヒップ(cm)';
    case AppLanguage.chinese:  return '臀围(cm)';
    case AppLanguage.mongolian:return 'Нуруу(cm)';
  }}
  String get sizeColHeight { switch (language) {
    case AppLanguage.korean:   return '키(cm)';
    case AppLanguage.english:  return 'Height(cm)';
    case AppLanguage.japanese: return '身長(cm)';
    case AppLanguage.chinese:  return '身高(cm)';
    case AppLanguage.mongolian:return 'Өндөр(cm)';
  }}

  // ── 단체주문 서식 (Group Order Form) ──────────────────────
  String get groupOrderFormTitle2 { switch (language) {
    case AppLanguage.korean:   return '단체 커스텀 오더';
    case AppLanguage.english:  return 'Group Custom Order';
    case AppLanguage.japanese: return '団体カスタムオーダー';
    case AppLanguage.chinese:  return '团体定制订单';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгат захиалга';
  }}
  String get colorSelect2 { switch (language) {
    case AppLanguage.korean:   return '색상 선택';
    case AppLanguage.english:  return 'Color Selection';
    case AppLanguage.japanese: return '色選択';
    case AppLanguage.chinese:  return '颜色选择';
    case AppLanguage.mongolian:return 'Өнгө сонгох';
  }}
  String get fabricWeight { switch (language) {
    case AppLanguage.korean:   return '원단 / 무게';
    case AppLanguage.english:  return 'Fabric / Weight';
    case AppLanguage.japanese: return '生地 / 重量';
    case AppLanguage.chinese:  return '面料 / 重量';
    case AppLanguage.mongolian:return 'Даавуу / Жин';
  }}
  String get bottomLengthSelect { switch (language) {
    case AppLanguage.korean:   return '하의 길이 선택';
    case AppLanguage.english:  return 'Bottom Length';
    case AppLanguage.japanese: return 'ボトムス丈選択';
    case AppLanguage.chinese:  return '下装长度选择';
    case AppLanguage.mongolian:return 'Доод хэсгийн урт';
  }}
  String get bottomLengthNote { switch (language) {
    case AppLanguage.korean:   return '✅ 여기서 선택한 하의 기장이 전체 인원에 동일하게 적용됩니다';
    case AppLanguage.english:  return '✅ The selected length applies equally to all members';
    case AppLanguage.japanese: return '✅ ここで選択した丈が全員に同様に適用されます';
    case AppLanguage.chinese:  return '✅ 此处选择的长度适用于所有成员';
    case AppLanguage.mongolian:return '✅ Сонгосон урт бүх гишүүдэд адилхан хэрэглэгдэнэ';
  }}
  String get personSizeInput { switch (language) {
    case AppLanguage.korean:   return '인원별 사이즈 입력';
    case AppLanguage.english:  return 'Size Input per Person';
    case AppLanguage.japanese: return 'メンバー別サイズ入力';
    case AppLanguage.chinese:  return '按人员输入尺码';
    case AppLanguage.mongolian:return 'Хүн бүрийн хэмжээ оруулах';
  }}
  String get personSizeInputNote { switch (language) {
    case AppLanguage.korean:   return '※ 하의 길이는 위에서 선택한 기장이 전체 인원에 동일하게 적용됩니다';
    case AppLanguage.english:  return '※ The bottom length selected above applies to all members equally';
    case AppLanguage.japanese: return '※ ボトムスの丈は上で選択した丈が全員に同様に適用されます';
    case AppLanguage.chinese:  return '※ 下装长度与上方选择的长度相同，适用于所有成员';
    case AppLanguage.mongolian:return '※ Доод хэсгийн урт дээр сонгосон хэмжээгээр бүх гишүүдэд хэрэглэгдэнэ';
  }}
  String get teamInfoSection { switch (language) {
    case AppLanguage.korean:   return '팀 / 담당자 정보';
    case AppLanguage.english:  return 'Team / Contact Info';
    case AppLanguage.japanese: return 'チーム / 担当者情報';
    case AppLanguage.chinese:  return '团队 / 负责人信息';
    case AppLanguage.mongolian:return 'Баг / Холбоо барих мэдээлэл';
  }}
  String get teamName { switch (language) {
    case AppLanguage.korean:   return '팀/단체명';
    case AppLanguage.english:  return 'Team/Group Name';
    case AppLanguage.japanese: return 'チーム/団体名';
    case AppLanguage.chinese:  return '团队/团体名称';
    case AppLanguage.mongolian:return 'Багийн нэр';
  }}
  String get teamNameHint { switch (language) {
    case AppLanguage.korean:   return '팀/단체명을 입력해주세요';
    case AppLanguage.english:  return 'Enter team/group name';
    case AppLanguage.japanese: return 'チーム/団体名を入力してください';
    case AppLanguage.chinese:  return '请输入团队/团体名称';
    case AppLanguage.mongolian:return 'Багийн нэрийг оруулна уу';
  }}
  String get managerName { switch (language) {
    case AppLanguage.korean:   return '담당자 이름';
    case AppLanguage.english:  return 'Contact Person';
    case AppLanguage.japanese: return '担当者名';
    case AppLanguage.chinese:  return '负责人姓名';
    case AppLanguage.mongolian:return 'Холбоо барих хүний нэр';
  }}
  String get managerNameHint { switch (language) {
    case AppLanguage.korean:   return '담당자 이름을 입력해주세요';
    case AppLanguage.english:  return 'Enter contact person name';
    case AppLanguage.japanese: return '担当者名を入力してください';
    case AppLanguage.chinese:  return '请输入负责人姓名';
    case AppLanguage.mongolian:return 'Холбоо барих хүний нэрийг оруулна уу';
  }}
  String get contactPhone { switch (language) {
    case AppLanguage.korean:   return '연락처';
    case AppLanguage.english:  return 'Phone Number';
    case AppLanguage.japanese: return '連絡先';
    case AppLanguage.chinese:  return '联系方式';
    case AppLanguage.mongolian:return 'Утасны дугаар';
  }}
  String get contactPhoneHint { switch (language) {
    case AppLanguage.korean:   return '연락처를 입력해주세요 (예: 010-0000-0000)';
    case AppLanguage.english:  return 'Enter phone number';
    case AppLanguage.japanese: return '連絡先を入力してください';
    case AppLanguage.chinese:  return '请输入联系方式';
    case AppLanguage.mongolian:return 'Утасны дугаараа оруулна уу';
  }}
  String get memoSection { switch (language) {
    case AppLanguage.korean:   return '요청 사항 (선택)';
    case AppLanguage.english:  return 'Special Requests (Optional)';
    case AppLanguage.japanese: return 'ご要望（任意）';
    case AppLanguage.chinese:  return '特殊要求（可选）';
    case AppLanguage.mongolian:return 'Тусгай хүсэлт (заавал биш)';
  }}
  String get memoHint { switch (language) {
    case AppLanguage.korean:   return '커스텀 관련 요청사항을 입력해주세요';
    case AppLanguage.english:  return 'Enter any custom requests';
    case AppLanguage.japanese: return 'カスタムに関するご要望を入力してください';
    case AppLanguage.chinese:  return '请输入定制相关要求';
    case AppLanguage.mongolian:return 'Захиалгатай холбоотой хүсэлтээ оруулна уу';
  }}
  String get submitOrder { switch (language) {
    case AppLanguage.korean:   return '주문 신청하기';
    case AppLanguage.english:  return 'Submit Order';
    case AppLanguage.japanese: return '注文申請する';
    case AppLanguage.chinese:  return '提交订单';
    case AppLanguage.mongolian:return 'Захиалга илгээх';
  }}
  String get personAddBtn { switch (language) {
    case AppLanguage.korean:   return '인원 추가';
    case AppLanguage.english:  return 'Add Person';
    case AppLanguage.japanese: return '人員追加';
    case AppLanguage.chinese:  return '添加人员';
    case AppLanguage.mongolian:return 'Хүн нэмэх';
  }}
  String get personAddBtnFull { switch (language) {
    case AppLanguage.korean:   return '+ 인원 추가';
    case AppLanguage.english:  return '+ Add Person';
    case AppLanguage.japanese: return '+ 人員追加';
    case AppLanguage.chinese:  return '+ 添加人员';
    case AppLanguage.mongolian:return '+ Хүн нэмэх';
  }}
  String get personNameLabel { switch (language) {
    case AppLanguage.korean:   return '이름 입력 (선택)';
    case AppLanguage.english:  return 'Name (Optional)';
    case AppLanguage.japanese: return '名前入力（任意）';
    case AppLanguage.chinese:  return '输入姓名（可选）';
    case AppLanguage.mongolian:return 'Нэр оруулах (заавал биш)';
  }}
  String get personNameRequired { switch (language) {
    case AppLanguage.korean:   return '이름 입력 (필수)';
    case AppLanguage.english:  return 'Name (Required)';
    case AppLanguage.japanese: return '名前入力（必須）';
    case AppLanguage.chinese:  return '输入姓名（必填）';
    case AppLanguage.mongolian:return 'Нэр оруулах (заавал)';
  }}
  String get personNameOver10Notice { switch (language) {
    case AppLanguage.korean:   return '10명 이상 주문 시 각 인원의 이름 입력이 필요합니다.';
    case AppLanguage.english:  return 'Name input is required for orders of 10 or more people.';
    case AppLanguage.japanese: return '10名以上の注文の場合、各メンバーの名前入力が必要です。';
    case AppLanguage.chinese:  return '10人及以上订单需要输入每位成员的姓名。';
    case AppLanguage.mongolian:return '10 ба түүнээс дээш хүний захиалгад бүх гишүүдийн нэр шаардлагатай.';
  }}
  String get sizeSelectLabel { switch (language) {
    case AppLanguage.korean:   return '사이즈 선택';
    case AppLanguage.english:  return 'Select Size';
    case AppLanguage.japanese: return 'サイズ選択';
    case AppLanguage.chinese:  return '选择尺码';
    case AppLanguage.mongolian:return 'Хэмжээ сонгох';
  }}
  String get topSizeLabel { switch (language) {
    case AppLanguage.korean:   return '상의 사이즈';
    case AppLanguage.english:  return 'Top Size';
    case AppLanguage.japanese: return 'トップスサイズ';
    case AppLanguage.chinese:  return '上装尺码';
    case AppLanguage.mongolian:return 'Дээд хэсгийн хэмжээ';
  }}
  String get bottomSizeLabel { switch (language) {
    case AppLanguage.korean:   return '하의 사이즈';
    case AppLanguage.english:  return 'Bottom Size';
    case AppLanguage.japanese: return 'ボトムスサイズ';
    case AppLanguage.chinese:  return '下装尺码';
    case AppLanguage.mongolian:return 'Доод хэсгийн хэмжээ';
  }}
  String get measureSizeLabel { switch (language) {
    case AppLanguage.korean:   return '실측 사이즈 입력';
    case AppLanguage.english:  return 'Enter Body Measurements';
    case AppLanguage.japanese: return '実測サイズ入力';
    case AppLanguage.chinese:  return '输入实测尺寸';
    case AppLanguage.mongolian:return 'Биеийн хэмжилт оруулах';
  }}
  String get measureSizeDesc { switch (language) {
    case AppLanguage.korean:   return '사이즈표에 맞는 사이즈가 없을 경우 입력해 주세요';
    case AppLanguage.english:  return 'Enter if your size is not in the size chart';
    case AppLanguage.japanese: return 'サイズ表に合うサイズがない場合に入力してください';
    case AppLanguage.chinese:  return '如果尺码表中没有合适的尺码，请填写';
    case AppLanguage.mongolian:return 'Хэмжээний хүснэгтэд тохирох хэмжээ байхгүй бол оруулна уу';
  }}
  String get measureHeight { switch (language) {
    case AppLanguage.korean:   return '키';
    case AppLanguage.english:  return 'Height';
    case AppLanguage.japanese: return '身長';
    case AppLanguage.chinese:  return '身高';
    case AppLanguage.mongolian:return 'Өндөр';
  }}
  String get measureWeight { switch (language) {
    case AppLanguage.korean:   return '몸무게';
    case AppLanguage.english:  return 'Weight';
    case AppLanguage.japanese: return '体重';
    case AppLanguage.chinese:  return '体重';
    case AppLanguage.mongolian:return 'Жин';
  }}
  String get measureChest { switch (language) {
    case AppLanguage.korean:   return '가슴둘레';
    case AppLanguage.english:  return 'Chest';
    case AppLanguage.japanese: return '胸囲';
    case AppLanguage.chinese:  return '胸围';
    case AppLanguage.mongolian:return 'Цээжний тойрог';
  }}
  String get measureWaist { switch (language) {
    case AppLanguage.korean:   return '허리둘레';
    case AppLanguage.english:  return 'Waist';
    case AppLanguage.japanese: return 'ウエスト';
    case AppLanguage.chinese:  return '腰围';
    case AppLanguage.mongolian:return 'Бүсэлхийн тойрог';
  }}
  String get measureHip { switch (language) {
    case AppLanguage.korean:   return '엉덩이둘레';
    case AppLanguage.english:  return 'Hip';
    case AppLanguage.japanese: return 'ヒップ';
    case AppLanguage.chinese:  return '臀围';
    case AppLanguage.mongolian:return 'Нурууны тойрог';
  }}
  String get measureThigh { switch (language) {
    case AppLanguage.korean:   return '허벅지둘레';
    case AppLanguage.english:  return 'Thigh';
    case AppLanguage.japanese: return '太もも';
    case AppLanguage.chinese:  return '大腿围';
    case AppLanguage.mongolian:return 'Гуяны тойрог';
  }}
  String get specialRequest { switch (language) {
    case AppLanguage.korean:   return '특이사항 · 개인 요청';
    case AppLanguage.english:  return 'Special Notes · Personal Requests';
    case AppLanguage.japanese: return '特記事項 · 個人リクエスト';
    case AppLanguage.chinese:  return '特殊说明 · 个人要求';
    case AppLanguage.mongolian:return 'Тусгай тэмдэглэл · Хувийн хүсэлт';
  }}
  String get specialRequestHint { switch (language) {
    case AppLanguage.korean:   return '예) 어깨가 넓어서 한 사이즈 크게, 왼쪽 소매 번호 인쇄 등';
    case AppLanguage.english:  return 'e.g.) Wide shoulders, order one size up; print number on left sleeve';
    case AppLanguage.japanese: return '例）肩幅が広いのでワンサイズ大きく、左袖に番号印刷など';
    case AppLanguage.chinese:  return '例）肩宽，需要大一码；左袖印刷号码等';
    case AppLanguage.mongolian:return 'Жнь.) Мөрний өргөн тул нэг хэмжээ том захиалж байна, зүүн ханцуйд дугаар хэвлэх гэх мэт';
  }}
  String get orderComplete2 { switch (language) {
    case AppLanguage.korean:   return '주문 접수 완료';
    case AppLanguage.english:  return 'Order Received';
    case AppLanguage.japanese: return '注文受付完了';
    case AppLanguage.chinese:  return '订单已受理';
    case AppLanguage.mongolian:return 'Захиалга хүлээн авагдлаа';
  }}
  String get orderCompleteMsg { switch (language) {
    case AppLanguage.korean:   return '주문 접수 후 영업일 1~2일 이내 견적서를 이메일로 발송해드립니다.\n제작 기간: 주문 확정 후 14~21일 소요됩니다.\n• 디자인 수정: 1회당 3일 이내 수정 요청 없을 시 확정 후 제작 시작';
    case AppLanguage.english:  return 'A quote will be sent to your email within 1-2 business days after order receipt.\nProduction time: 14-21 days after order confirmation.\n• Design revision: If no revision request within 3 days per revision, production starts automatically.';
    case AppLanguage.japanese: return 'ご注文受付後、1~2営業日以内にメールにて見積書をお送りします。\n製作期間：ご注文確定後、14~21日かかります。\n• デザイン修正：1回につき3日以内に修正依頼がない場合、確定し製作開始。';
    case AppLanguage.chinese:  return '收到订单后1~2个工作日内将通过电子邮件发送报价单。\n制作周期：订单确认后需14~21天。\n• 设计修改：每次修改3天内无修改申请则确认并开始制作。';
    case AppLanguage.mongolian:return 'Захиалга хүлээн авснаас хойш 1~2 ажлын өдрийн дотор имэйлээр үнийн санал илгээгдэнэ.\nҮйлдвэрлэлийн хугацаа: захиалга баталгаажсанаас хойш 14~21 өдөр.\n• Дизайн засвар: Нэг засвар тутамд 3 хоногийн дотор хүсэлт гараагүй бол баталгаажиж үйлдвэрлэл эхэлнэ.';
  }}
  String get bottomLengthApplyNote { switch (language) {
    case AppLanguage.korean:   return '하의 기장(길이)은 위의 \'하의 길이 선택\'에서 선택하시면\n전체 인원에 동일하게 적용됩니다.';
    case AppLanguage.english:  return 'Select the bottom length in \'Bottom Length\' above.\nIt will be applied equally to all members.';
    case AppLanguage.japanese: return 'ボトムスの丈は上の「ボトムス丈選択」で選択すると\n全員に同様に適用されます。';
    case AppLanguage.chinese:  return '下装长度请在上方"下装长度选择"中选择，\n将同等适用于所有成员。';
    case AppLanguage.mongolian:return 'Доод хэсгийн уртыг дээрх "Доод хэсгийн урт" -аас сонгоно уу.\nЭнэ нь бүх гишүүдэд адилхан хэрэглэгдэнэ.';
  }}

  // ── 단체주문 안내 바텀시트 번역 ──────────────────────────────
  String get groupOrderSheetBasicInfo { switch (language) {
    case AppLanguage.korean:   return '단체 주문 안내';
    case AppLanguage.english:  return 'Group Order Info';
    case AppLanguage.japanese: return '団体注文案内';
    case AppLanguage.chinese:  return '团体订单信息';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгын мэдээлэл';
  }}
  String get groupOrderSheetGroupCustom { switch (language) {
    case AppLanguage.korean:   return '단체 맞춤 제작';
    case AppLanguage.english:  return 'Group Custom Production';
    case AppLanguage.japanese: return '団体オーダーメイド製作';
    case AppLanguage.chinese:  return '团体定制生产';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгат үйлдвэрлэл';
  }}
  String get groupOrderSheetMinPeople { switch (language) {
    case AppLanguage.korean:   return '5인 이상 단체 주문';
    case AppLanguage.english:  return 'Group Orders: 5+ People';
    case AppLanguage.japanese: return '5名以上の団体注文';
    case AppLanguage.chinese:  return '5人以上团体订单';
    case AppLanguage.mongolian:return '5+ хүний бүлгийн захиалга';
  }}
  String get groupOrderSheetDiscount { switch (language) {
    case AppLanguage.korean:   return '단체 할인 혜택';
    case AppLanguage.english:  return 'Group Discount Benefits';
    case AppLanguage.japanese: return '団体割引特典';
    case AppLanguage.chinese:  return '团体折扣优惠';
    case AppLanguage.mongolian:return 'Бүлгийн хямдралын давуу тал';
  }}
  String get groupOrderSheetAgreeBtn { switch (language) {
    case AppLanguage.korean:   return '주문 안내 내용을 모두 확인하였습니다';
    case AppLanguage.english:  return 'I have reviewed all order guidelines';
    case AppLanguage.japanese: return '注文案内の内容をすべて確認しました';
    case AppLanguage.chinese:  return '我已确认所有订单指南内容';
    case AppLanguage.mongolian:return 'Бүх захиалгын зааврыг уншлаа';
  }}
  String get groupOrderSheetFillForm { switch (language) {
    case AppLanguage.korean:   return '단체 서식 작성하기';
    case AppLanguage.english:  return 'Fill Out Group Order Form';
    case AppLanguage.japanese: return '団体フォームを記入する';
    case AppLanguage.chinese:  return '填写团体订单表格';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгын маягт бөглөх';
  }}
  String get groupOrderSheetViewGuide { switch (language) {
    case AppLanguage.korean:   return '주문 안내 보기';
    case AppLanguage.english:  return 'View Order Guide';
    case AppLanguage.japanese: return '注文案内を見る';
    case AppLanguage.chinese:  return '查看订单指南';
    case AppLanguage.mongolian:return 'Захиалгын зааврыг харах';
  }}

  // ── 회원가입 (Sign Up) ─────────────────────────────────────
  String get signupTitle { switch (language) {
    case AppLanguage.korean:   return '회원가입';
    case AppLanguage.english:  return 'Create Account';
    case AppLanguage.japanese: return '会員登録';
    case AppLanguage.chinese:  return '注册账号';
    case AppLanguage.mongolian:return 'Бүртгүүлэх';
  }}
  String get signupSubtitle { switch (language) {
    case AppLanguage.korean:   return '2FIT MALL에 오신 것을 환영합니다';
    case AppLanguage.english:  return 'Welcome to 2FIT MALL';
    case AppLanguage.japanese: return '2FIT MALLへようこそ';
    case AppLanguage.chinese:  return '欢迎来到2FIT MALL';
    case AppLanguage.mongolian:return '2FIT MALL-д тавтай морилно уу';
  }}
  String get signupEmailHint { switch (language) {
    case AppLanguage.korean:   return '이메일 주소를 입력해주세요';
    case AppLanguage.english:  return 'Enter your email address';
    case AppLanguage.japanese: return 'メールアドレスを入力してください';
    case AppLanguage.chinese:  return '请输入邮箱地址';
    case AppLanguage.mongolian:return 'И-мэйл хаягаа оруулна уу';
  }}
  String get signupPasswordHint { switch (language) {
    case AppLanguage.korean:   return '비밀번호 (8자 이상)';
    case AppLanguage.english:  return 'Password (8+ characters)';
    case AppLanguage.japanese: return 'パスワード（8文字以上）';
    case AppLanguage.chinese:  return '密码（8位以上）';
    case AppLanguage.mongolian:return 'Нууц үг (8+ тэмдэгт)';
  }}
  String get signupPasswordConfirm { switch (language) {
    case AppLanguage.korean:   return '비밀번호 확인';
    case AppLanguage.english:  return 'Confirm Password';
    case AppLanguage.japanese: return 'パスワード確認';
    case AppLanguage.chinese:  return '确认密码';
    case AppLanguage.mongolian:return 'Нууц үгийг баталгаажуулах';
  }}
  String get signupNameHint { switch (language) {
    case AppLanguage.korean:   return '이름을 입력해주세요';
    case AppLanguage.english:  return 'Enter your name';
    case AppLanguage.japanese: return '名前を入力してください';
    case AppLanguage.chinese:  return '请输入姓名';
    case AppLanguage.mongolian:return 'Нэрээ оруулна уу';
  }}
  String get signupPhoneHint { switch (language) {
    case AppLanguage.korean:   return '연락처를 입력해주세요 (선택)';
    case AppLanguage.english:  return 'Phone number (optional)';
    case AppLanguage.japanese: return '連絡先を入力してください（任意）';
    case AppLanguage.chinese:  return '请输入联系方式（可选）';
    case AppLanguage.mongolian:return 'Утасны дугаар (заавал биш)';
  }}
  String get signupBtn { switch (language) {
    case AppLanguage.korean:   return '가입하기';
    case AppLanguage.english:  return 'Sign Up';
    case AppLanguage.japanese: return '登録する';
    case AppLanguage.chinese:  return '注册';
    case AppLanguage.mongolian:return 'Бүртгүүлэх';
  }}
  String get signupAlreadyAccount { switch (language) {
    case AppLanguage.korean:   return '이미 계정이 있으신가요?';
    case AppLanguage.english:  return 'Already have an account?';
    case AppLanguage.japanese: return 'すでにアカウントをお持ちですか？';
    case AppLanguage.chinese:  return '已有账号？';
    case AppLanguage.mongolian:return 'Бүртгэл байна уу?';
  }}
  String get signupLoginLink { switch (language) {
    case AppLanguage.korean:   return '로그인하기';
    case AppLanguage.english:  return 'Log In';
    case AppLanguage.japanese: return 'ログインする';
    case AppLanguage.chinese:  return '登录';
    case AppLanguage.mongolian:return 'Нэвтрэх';
  }}
  String get nameLabel { switch (language) {
    case AppLanguage.korean:   return '이름';
    case AppLanguage.english:  return 'Name';
    case AppLanguage.japanese: return '名前';
    case AppLanguage.chinese:  return '姓名';
    case AppLanguage.mongolian:return 'Нэр';
  }}
  String get phoneLabelAlt { switch (language) {
    case AppLanguage.korean:   return '연락처';
    case AppLanguage.english:  return 'Phone';
    case AppLanguage.japanese: return '電話番号';
    case AppLanguage.chinese:  return '电话';
    case AppLanguage.mongolian:return 'Утас';
  }}

  // ── 개인주문 서식 (Personal Order Form) ────────────────────
  String get personalOrderTitle { switch (language) {
    case AppLanguage.korean:   return '개인 커스텀 오더';
    case AppLanguage.english:  return 'Personal Custom Order';
    case AppLanguage.japanese: return '個人カスタムオーダー';
    case AppLanguage.chinese:  return '个人定制订单';
    case AppLanguage.mongolian:return 'Хувийн захиалгат захиалга';
  }}
  String get personalOrderInfo { switch (language) {
    case AppLanguage.korean:   return '개인 주문 안내';
    case AppLanguage.english:  return 'Personal Order Info';
    case AppLanguage.japanese: return '個人注文案内';
    case AppLanguage.chinese:  return '个人订单信息';
    case AppLanguage.mongolian:return 'Хувийн захиалгын мэдээлэл';
  }}

  // ── 주문 프로세스 상태 표시 ──────────────────────────────────
  String get orderStep1 { switch (language) {
    case AppLanguage.korean:   return '컬러만 변경';
    case AppLanguage.english:  return 'Color Change Only';
    case AppLanguage.japanese: return 'カラーのみ変更';
    case AppLanguage.chinese:  return '仅更改颜色';
    case AppLanguage.mongolian:return 'Зөвхөн өнгө өөрчлөх';
  }}
  String get orderStep1Desc { switch (language) {
    case AppLanguage.korean:   return '공통 컬러 선택. 기본 디자인 유지.';
    case AppLanguage.english:  return 'Select common color. Keep base design.';
    case AppLanguage.japanese: return '共通カラー選択。基本デザインを維持。';
    case AppLanguage.chinese:  return '选择通用颜色，保持基本设计。';
    case AppLanguage.mongolian:return 'Нийтлэг өнгө сонгоно. Үндсэн дизайн хадгалагдана.';
  }}
  String get orderStep2 { switch (language) {
    case AppLanguage.korean:   return '단체명 + 컬러';
    case AppLanguage.english:  return 'Team Name + Color';
    case AppLanguage.japanese: return '団体名 + カラー';
    case AppLanguage.chinese:  return '团队名称 + 颜色';
    case AppLanguage.mongolian:return 'Багийн нэр + Өнгө';
  }}
  String get orderStep2Desc { switch (language) {
    case AppLanguage.korean:   return '앞면 팀/단체명 인쇄. 폰트·위치 조정 가능.';
    case AppLanguage.english:  return 'Front team/group name print. Font & position adjustable.';
    case AppLanguage.japanese: return '前面にチーム/団体名を印刷。フォント・位置調整可能。';
    case AppLanguage.chinese:  return '正面印刷团队/团体名称，可调整字体和位置。';
    case AppLanguage.mongolian:return 'Урд талд баг/бүлгийн нэр хэвлэх. Фонт, байрлал тохируулах боломжтой.';
  }}
  String get orderStep3 { switch (language) {
    case AppLanguage.korean:   return '단체명 + 컬러 + 개인명';
    case AppLanguage.english:  return 'Team Name + Color + Personal Name';
    case AppLanguage.japanese: return '団体名 + カラー + 個人名';
    case AppLanguage.chinese:  return '团队名称 + 颜色 + 个人姓名';
    case AppLanguage.mongolian:return 'Багийн нэр + Өнгө + Хувийн нэр';
  }}
  String get orderStep3Desc { switch (language) {
    case AppLanguage.korean:   return '뒷면에 개인 이름 추가 인쇄.';
    case AppLanguage.english:  return 'Additional personal name print on the back.';
    case AppLanguage.japanese: return '背面に個人名を追加印刷。';
    case AppLanguage.chinese:  return '背面额外印刷个人姓名。';
    case AppLanguage.mongolian:return 'Ард талд нэмэлт хувийн нэр хэвлэх.';
  }}
  String get totalPersonCountTemplate { switch (language) {
    case AppLanguage.korean:   return '총 {n}명';
    case AppLanguage.english:  return 'Total {n} people';
    case AppLanguage.japanese: return '合計{n}名';
    case AppLanguage.chinese:  return '共{n}人';
    case AppLanguage.mongolian:return 'Нийт {n} хүн';
  }}
  String totalPersonCountN(int n) {
    return totalPersonCountTemplate.replaceAll('{n}', '$n');
  }
  String get orderGuideCheckAll { switch (language) {
    case AppLanguage.korean:   return '주문 안내 내용을 모두 확인하였습니다';
    case AppLanguage.english:  return 'I have checked all order guide contents';
    case AppLanguage.japanese: return '注文案内の内容をすべて確認しました';
    case AppLanguage.chinese:  return '我已确认所有订单指南内容';
    case AppLanguage.mongolian:return 'Захиалгын зааврын бүх агуулгыг шалгалаа';
  }}
  String get orderGuideCheckBtn { switch (language) {
    case AppLanguage.korean:   return '안내를 확인 체크 후 주문 양식 작성이 가능합니다.';
    case AppLanguage.english:  return 'Please check the guide to proceed with the order form.';
    case AppLanguage.japanese: return '案内を確認チェック後、注文フォームの記入が可能です。';
    case AppLanguage.chinese:  return '请确认指南后方可填写订单表格。';
    case AppLanguage.mongolian:return 'Захиалгын маягт бөглөхийн өмнө заавраа шалгана уу.';
  }}

  // ══════════════════════════════════════════════════════════════
  // 단체주문 안내 화면 (GroupOrderGuideScreen) 추가 키
  // ══════════════════════════════════════════════════════════════
  String get groupOrderGuideAppBar { switch (language) {
    case AppLanguage.korean:   return '단체 주문 안내';
    case AppLanguage.english:  return 'Group Order Guide';
    case AppLanguage.japanese: return '団体注文案内';
    case AppLanguage.chinese:  return '团体订单指南';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгын заавар';
  }}
  String get groupOrderGuideTabGuide { switch (language) {
    case AppLanguage.korean:   return '주문 안내';
    case AppLanguage.english:  return 'Order Guide';
    case AppLanguage.japanese: return '注文案内';
    case AppLanguage.chinese:  return '订单说明';
    case AppLanguage.mongolian:return 'Захиалгын заавар';
  }}
  String get groupOrderGuideTabForm { switch (language) {
    case AppLanguage.korean:   return '주문 양식';
    case AppLanguage.english:  return 'Order Form';
    case AppLanguage.japanese: return '注文フォーム';
    case AppLanguage.chinese:  return '订单表格';
    case AppLanguage.mongolian:return 'Захиалгын маягт';
  }}
  String get groupOrderGuideHeroTitle { switch (language) {
    case AppLanguage.korean:   return '단체 맞춤 제작';
    case AppLanguage.english:  return 'Group Custom Order';
    case AppLanguage.japanese: return '団体カスタム製作';
    case AppLanguage.chinese:  return '团体定制生产';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгат үйлдвэрлэл';
  }}
  String get groupOrderGuideHeroSub { switch (language) {
    case AppLanguage.korean:   return '5인 이상 단체 주문';
    case AppLanguage.english:  return 'Group orders of 5 or more';
    case AppLanguage.japanese: return '5名以上の団体注文';
    case AppLanguage.chinese:  return '5人以上团体订单';
    case AppLanguage.mongolian:return '5-аас дээш хүний бүлгийн захиалга';
  }}
  String get groupOrderGuideDiscountBadge { switch (language) {
    case AppLanguage.korean:   return '단체 할인 혜택';
    case AppLanguage.english:  return 'Group Discount';
    case AppLanguage.japanese: return '団体割引特典';
    case AppLanguage.chinese:  return '团体折扣优惠';
    case AppLanguage.mongolian:return 'Бүлгийн хөнгөлөлт';
  }}
  String get groupOrderGuideAgreeCheck { switch (language) {
    case AppLanguage.korean:   return '주문 안내 내용을 모두 확인하였습니다';
    case AppLanguage.english:  return 'I have confirmed all order guide contents';
    case AppLanguage.japanese: return '注文案内の内容をすべて確認しました';
    case AppLanguage.chinese:  return '我已确认所有订单指南内容';
    case AppLanguage.mongolian:return 'Захиалгын зааврын бүх агуулгыг шалгасан';
  }}
  String get groupOrderGuideWriteBtn { switch (language) {
    case AppLanguage.korean:   return '주문 양식 작성하기';
    case AppLanguage.english:  return 'Write Order Form';
    case AppLanguage.japanese: return '注文フォームを記入する';
    case AppLanguage.chinese:  return '填写订单表格';
    case AppLanguage.mongolian:return 'Захиалгын маягт бөглөх';
  }}
  String get groupOrderGuideCheckFirst { switch (language) {
    case AppLanguage.korean:   return '안내를 확인 체크 후 양식 작성이 가능합니다';
    case AppLanguage.english:  return 'Please check the guide before filling in the form';
    case AppLanguage.japanese: return '案内を確認後、フォームの記入が可能です';
    case AppLanguage.chinese:  return '请先确认指南再填写表格';
    case AppLanguage.mongolian:return 'Маягт бөглөхийн өмнө зааврыг шалгана уу';
  }}
  String get groupOrderGuideShippingTitle { switch (language) {
    case AppLanguage.korean:   return '배송 안내';
    case AppLanguage.english:  return 'Shipping Info';
    case AppLanguage.japanese: return '配送案内';
    case AppLanguage.chinese:  return '配送说明';
    case AppLanguage.mongolian:return 'Хүргэлтийн мэдээлэл';
  }}
  String get groupOrderGuideShipping1 { switch (language) {
    case AppLanguage.korean:   return '• 단체커스텀 5장 이상: 무료배송';
    case AppLanguage.english:  return '• Group custom 5+ items: Free shipping';
    case AppLanguage.japanese: return '• 団体カスタム5枚以上：送料無料';
    case AppLanguage.chinese:  return '• 团体定制5件以上：免费配送';
    case AppLanguage.mongolian:return '• Бүлгийн захиалга 5+ ширхэг: үнэгүй хүргэлт';
  }}
  String get groupOrderGuideShipping2 { switch (language) {
    case AppLanguage.korean:   return '• 5장 미만: 배송비 3,000원';
    case AppLanguage.english:  return '• Under 5 items: ₩3,000 shipping fee';
    case AppLanguage.japanese: return '• 5枚未満：配送料3,000ウォン';
    case AppLanguage.chinese:  return '• 5件以下：运费3,000韩元';
    case AppLanguage.mongolian:return '• 5-аас доош: 3,000₩ хүргэлтийн төлбөр';
  }}
  String get groupOrderGuideShipping3 { switch (language) {
    case AppLanguage.korean:   return '• 추가 제작 (5장 미만): 배송비 4,000원 추가';
    case AppLanguage.english:  return '• Additional production (under 5): +₩4,000 shipping';
    case AppLanguage.japanese: return '• 追加製作（5枚未満）：送料4,000ウォン追加';
    case AppLanguage.chinese:  return '• 追加生产（5件以下）：运费加收4,000韩元';
    case AppLanguage.mongolian:return '• Нэмэлт үйлдвэрлэл (5-аас доош): +4,000₩ хүргэлт';
  }}
  String get groupOrderGuideShipping4 { switch (language) {
    case AppLanguage.korean:   return '• 단체 주문은 일괄 배송이 원칙입니다.';
    case AppLanguage.english:  return '• Group orders are shipped in bulk.';
    case AppLanguage.japanese: return '• 団体注文は一括配送が原則です。';
    case AppLanguage.chinese:  return '• 团体订单原则上统一配送。';
    case AppLanguage.mongolian:return '• Бүлгийн захиалга нэг дор хүргэгдэнэ.';
  }}
  String get groupOrderGuideCustomTitle { switch (language) {
    case AppLanguage.korean:   return '커스텀 옵션';
    case AppLanguage.english:  return 'Custom Options';
    case AppLanguage.japanese: return 'カスタムオプション';
    case AppLanguage.chinese:  return '定制选项';
    case AppLanguage.mongolian:return 'Захиалгат сонголтууд';
  }}
  String get groupOrderGuideCustom1 { switch (language) {
    case AppLanguage.korean:   return '• 팀 로고/마킹 추가 가능 (5장 이상 무료)';
    case AppLanguage.english:  return '• Team logo/marking available (free for 5+)';
    case AppLanguage.japanese: return '• チームロゴ/マーキング追加可能（5枚以上無料）';
    case AppLanguage.chinese:  return '• 可添加团队标志/标记（5件以上免费）';
    case AppLanguage.mongolian:return '• Багийн лого/тэмдэглэгээ нэмэх боломжтой (5+дээш үнэгүй)';
  }}
  String get groupOrderGuideCustom2 { switch (language) {
    case AppLanguage.korean:   return '• 색상 커스텀 가능';
    case AppLanguage.english:  return '• Color customization available';
    case AppLanguage.japanese: return '• カラーカスタマイズ可能';
    case AppLanguage.chinese:  return '• 可定制颜色';
    case AppLanguage.mongolian:return '• Өнгийг тохируулах боломжтой';
  }}
  String get groupOrderGuideCustom3 { switch (language) {
    case AppLanguage.korean:   return '• 허리밴드 색상 변경 가능 (형태·디자인 변경 불가)';
    case AppLanguage.english:  return '• Waistband color change available (no shape/design changes)';
    case AppLanguage.japanese: return '• ウエストバンドカラー変更可能（形状・デザイン変更不可）';
    case AppLanguage.chinese:  return '• 腰带颜色可更改（形状·设计不可更改）';
    case AppLanguage.mongolian:return '• Бүсний өнгийг өөрчлөх боломжтой (хэлбэр/дизайн өөрчлөх боломжгүй)';
  }}
  String get groupOrderGuideExclusiveTitle { switch (language) {
    case AppLanguage.korean:   return '1년 독점 사용권 (+100,000원)';
    case AppLanguage.english:  return '1-Year Exclusive License (+₩100,000)';
    case AppLanguage.japanese: return '1年独占使用権（+100,000ウォン）';
    case AppLanguage.chinese:  return '1年独家使用权（+100,000韩元）';
    case AppLanguage.mongolian:return '1 жилийн онцгой эрх (+100,000₩)';
  }}
  String get groupOrderGuideExclusive1 { switch (language) {
    case AppLanguage.korean:   return '• 추가 10만원 결제 시 해당 디자인을 1년간 타인에게 배포하지 않습니다.';
    case AppLanguage.english:  return '• Pay extra ₩100,000 to keep the design exclusive for 1 year.';
    case AppLanguage.japanese: return '• 追加10万ウォン支払いで、そのデザインを1年間他者に配布しません。';
    case AppLanguage.chinese:  return '• 额外支付10万韩元，该设计1年内不向他人分发。';
    case AppLanguage.mongolian:return '• Нэмэлт 100,000₩ төлвөл дизайныг 1 жилийн хугацаанд бусдад өгөхгүй.';
  }}
  String get groupOrderGuideExclusive2 { switch (language) {
    case AppLanguage.korean:   return '• 1년 이후에는 2FIT 쇼핑몰에서 판매될 수 있습니다.';
    case AppLanguage.english:  return '• After 1 year, the design may be sold in the 2FIT mall.';
    case AppLanguage.japanese: return '• 1年後は2FITショッピングモールで販売される場合があります。';
    case AppLanguage.chinese:  return '• 1年后可能在2FIT商城出售。';
    case AppLanguage.mongolian:return '• 1 жилийн дараа 2FIT дэлгүүрт зарагдаж болно.';
  }}
  String get groupOrderGuideExclusive3 { switch (language) {
    case AppLanguage.korean:   return '• 선택 사항이며, 미선택 시 디자인은 공유될 수 있습니다.';
    case AppLanguage.english:  return '• Optional; if not selected, the design may be shared.';
    case AppLanguage.japanese: return '• 任意であり、未選択の場合デザインは共有される可能性があります。';
    case AppLanguage.chinese:  return '• 为可选项，未选择时设计可能被共享。';
    case AppLanguage.mongolian:return '• Заавал биш; сонгоогүй тохиолдолд дизайн хуваалцагдаж болно.';
  }}
  String get groupOrderGuideDiscountTitle { switch (language) {
    case AppLanguage.korean:   return '수량 할인';
    case AppLanguage.english:  return 'Quantity Discount';
    case AppLanguage.japanese: return '数量割引';
    case AppLanguage.chinese:  return '数量折扣';
    case AppLanguage.mongolian:return 'Тоо хэмжээний хөнгөлөлт';
  }}
  String get groupOrderGuideDiscount1 { switch (language) {
    case AppLanguage.korean:   return '• 30개 이상: 10% 할인';
    case AppLanguage.english:  return '• 30+: 10% discount';
    case AppLanguage.japanese: return '• 30個以上：10%割引';
    case AppLanguage.chinese:  return '• 30件以上：九折优惠';
    case AppLanguage.mongolian:return '• 30+: 10% хөнгөлөлт';
  }}
  String get groupOrderGuideDiscount2 { switch (language) {
    case AppLanguage.korean:   return '• 50개 이상: 20% 할인';
    case AppLanguage.english:  return '• 50+: 20% discount';
    case AppLanguage.japanese: return '• 50個以上：20%割引';
    case AppLanguage.chinese:  return '• 50件以上：八折优惠';
    case AppLanguage.mongolian:return '• 50+: 20% хөнгөлөлт';
  }}
  String get groupOrderGuideDiscount3 { switch (language) {
    case AppLanguage.korean:   return '• 100개 이상: 별도 협의';
    case AppLanguage.english:  return '• 100+: negotiable pricing';
    case AppLanguage.japanese: return '• 100個以上：別途協議';
    case AppLanguage.chinese:  return '• 100件以上：另行协商';
    case AppLanguage.mongolian:return '• 100+: тохиролцох үнэ';
  }}
  // ── 새로 추가된 단체 주문 안내 번역키 ──
  String get groupOrderGuideWaistbandTitle { switch (language) {
    case AppLanguage.korean:   return '허리밴드 옵션';
    case AppLanguage.english:  return 'Waistband Options';
    case AppLanguage.japanese: return 'ウエストバンドオプション';
    case AppLanguage.chinese:  return '腰带选项';
    case AppLanguage.mongolian:return 'Бүсний сонголт';
  }}
  String get groupOrderGuideWaistband1 { switch (language) {
    case AppLanguage.korean:   return '• 허리밴드 각각 색상 변경 가능 (추가비용 50,000원)';
    case AppLanguage.english:  return '• Individual waistband color change available (+₩50,000)';
    case AppLanguage.japanese: return '• ウエストバンドのカラー変更可能（追加料金50,000ウォン）';
    case AppLanguage.chinese:  return '• 每条腰带可单独变色（附加费用50,000韩元）';
    case AppLanguage.mongolian:return '• Бүс тус бүрийн өнгийг өөрчлөх боломжтой (+50,000 вон)';
  }}
  String get groupOrderGuideWaistband2 { switch (language) {
    case AppLanguage.korean:   return '• 허리밴드 디자인 변경 가능 (추가비용 50,000원)';
    case AppLanguage.english:  return '• Individual waistband design change available (+₩50,000)';
    case AppLanguage.japanese: return '• ウエストバンドのデザイン変更可能（追加料金50,000ウォン）';
    case AppLanguage.chinese:  return '• 每条腰带可单独变设计（附加费用50,000韩元）';
    case AppLanguage.mongolian:return '• Бүс тус бүрийн дизайныг өөрчлөх боломжтой (+50,000 вон)';
  }}
  String get groupOrderGuideWaistband3 { switch (language) {
    case AppLanguage.korean:   return '• 색상 + 디자인 동시 변경: 추가비용 70,000원';
    case AppLanguage.english:  return '• Color + design change together: +₩70,000';
    case AppLanguage.japanese: return '• カラー＋デザイン同時変更：追加料金70,000ウォン';
    case AppLanguage.chinese:  return '• 颜色+设计同时变更：附加费用70,000韩元';
    case AppLanguage.mongolian:return '• Өнгө + дизайн хамт өөрчлөх: +70,000 вон';
  }}
  String get groupOrderGuideAdditionalTitle { switch (language) {
    case AppLanguage.korean:   return '추가 주문 안내';
    case AppLanguage.english:  return 'Additional Order Guide';
    case AppLanguage.japanese: return '追加注文案内';
    case AppLanguage.chinese:  return '追加订单说明';
    case AppLanguage.mongolian:return 'Нэмэлт захиалгын мэдээлэл';
  }}
  String get groupOrderGuideAdditional1 { switch (language) {
    case AppLanguage.korean:   return '• 추가 주문 시 기존 주문번호 필수 입력';
    case AppLanguage.english:  return '• Existing order number required for additional orders';
    case AppLanguage.japanese: return '• 追加注文には既存注文番号が必要です';
    case AppLanguage.chinese:  return '• 追加订单需填写原始订单号';
    case AppLanguage.mongolian:return '• Нэмэлт захиалга хийхэд анхны захиалгын дугаар шаардлагатай';
  }}
  String get groupOrderGuideAdditional2 { switch (language) {
    case AppLanguage.korean:   return '• 1장부터 추가 가능';
    case AppLanguage.english:  return '• Can add from 1 piece';
    case AppLanguage.japanese: return '• 1枚から追加可能';
    case AppLanguage.chinese:  return '• 可从1件起追加';
    case AppLanguage.mongolian:return '• 1 ширхэгээс нэмэж болно';
  }}
  String get groupOrderGuideAdditional3 { switch (language) {
    case AppLanguage.korean:   return '• 5장 이하 추가 주문: 배송비 4,000원 별도';
    case AppLanguage.english:  return '• Additional order of 5 or fewer: ₩4,000 shipping fee';
    case AppLanguage.japanese: return '• 5枚以下の追加注文：送料4,000ウォン別途';
    case AppLanguage.chinese:  return '• 5件以下追加订单：配送费4,000韩元';
    case AppLanguage.mongolian:return '• 5 ширхэг хүртэлх нэмэлт захиалга: 4,000 вон тээврийн зардал';
  }}
  String get groupOrderGuideDesignFileTitle { switch (language) {
    case AppLanguage.korean:   return '디자인 파일 안내';
    case AppLanguage.english:  return 'Design File Guide';
    case AppLanguage.japanese: return 'デザインファイル案内';
    case AppLanguage.chinese:  return '设计文件说明';
    case AppLanguage.mongolian:return 'Дизайн файлын мэдээлэл';
  }}
  String get groupOrderGuideDesignFile1 { switch (language) {
    case AppLanguage.korean:   return '• 디자인 변경은 디자인 파일 첨부 시에만 가능합니다';
    case AppLanguage.english:  return '• Design changes are only possible when a design file is attached';
    case AppLanguage.japanese: return '• デザイン変更はデザインファイル添付時のみ可能です';
    case AppLanguage.chinese:  return '• 只有附上设计文件时才能更改设计';
    case AppLanguage.mongolian:return '• Дизайны файл хавсаргасан тохиолдолд л дизайн өөрчлөх боломжтой';
  }}
  String get groupOrderGuideDesignFile2 { switch (language) {
    case AppLanguage.korean:   return '📎 AI / PDF / PNG 파일 첨부 필수';
    case AppLanguage.english:  return '📎 AI / PDF / PNG file attachment required';
    case AppLanguage.japanese: return '📎 AI / PDF / PNG ファイル添付必須';
    case AppLanguage.chinese:  return '📎 必须附上 AI / PDF / PNG 文件';
    case AppLanguage.mongolian:return '📎 AI / PDF / PNG файл хавсаргах шаардлагатай';
  }}
  String get groupOrderGuideColorSystemTitle { switch (language) {
    case AppLanguage.korean:   return '색상 선택 시스템';
    case AppLanguage.english:  return 'Color Selection System';
    case AppLanguage.japanese: return 'カラー選択システム';
    case AppLanguage.chinese:  return '颜色选择系统';
    case AppLanguage.mongolian:return 'Өнгийн сонгох систем';
  }}
  String get groupOrderGuideColorSystem1 { switch (language) {
    case AppLanguage.korean:   return '• 등록된 색상명 팔레트에서 직접 선택';
    case AppLanguage.english:  return '• Select directly from registered color palette';
    case AppLanguage.japanese: return '• 登録済みカラーパレットから直接選択';
    case AppLanguage.chinese:  return '• 从注册色板中直接选择';
    case AppLanguage.mongolian:return '• Бүртгэгдсэн өнгийн палитраас шууд сонго';
  }}
  String get groupOrderGuideColorSystem2 { switch (language) {
    case AppLanguage.korean:   return '• 등록 색상 외 모든 색상 → 30색+ 팔레트에서 선택';
    case AppLanguage.english:  return '• All colors beyond registered ones → select from 30+ palette';
    case AppLanguage.japanese: return '• 登録外の全カラー → 30色以上のパレットで選択';
    case AppLanguage.chinese:  return '• 注册色以外的所有颜色 → 从30色以上的色板中选择';
    case AppLanguage.mongolian:return '• Бүртгэгдсэнээс бусад өнгө → 30+ палитраас сонго';
  }}
  String get groupOrderGuideColorSystem3 { switch (language) {
    case AppLanguage.korean:   return '• 색상 코드 직접 입력 (#RRGGBB)';
    case AppLanguage.english:  return '• Direct color code input (#RRGGBB)';
    case AppLanguage.japanese: return '• カラーコードを直接入力（#RRGGBB）';
    case AppLanguage.chinese:  return '• 直接输入颜色代码 (#RRGGBB)';
    case AppLanguage.mongolian:return '• Өнгийн кодыг шууд оруулах (#RRGGBB)';
  }}
  String get groupOrderGuideColorSystem4 { switch (language) {
    case AppLanguage.korean:   return '• 컬러피커로 즉시 확인 · 선택 가능';
    case AppLanguage.english:  return '• Instant preview and selection via color picker';
    case AppLanguage.japanese: return '• カラーピッカーで即確認・選択可能';
    case AppLanguage.chinese:  return '• 通过颜色选择器即时查看和选择';
    case AppLanguage.mongolian:return '• Өнгийн сонгогчоор шууд харж сонгох боломжтой';
  }}

  // ── 수량별 규칙 ──
  String get groupOrderGuideQtyRuleTitle { switch (language) {
    case AppLanguage.korean:   return '수량별 제작 규칙';
    case AppLanguage.english:  return 'Production Rules by Quantity';
    case AppLanguage.japanese: return '数量別制作ルール';
    case AppLanguage.chinese:  return '按数量制作规则';
    case AppLanguage.mongolian:return 'Тоо хэмжээгээр үйлдвэрлэлийн дүрмүүд';
  }}
  String get groupOrderGuideQtyRule5 { switch (language) {
    case AppLanguage.korean:   return '• 5개 이상: 디자인 및 색상 변경 가능';
    case AppLanguage.english:  return '• 5+ pieces: design and color changes allowed';
    case AppLanguage.japanese: return '• 5個以上：デザイン・カラー変更可';
    case AppLanguage.chinese:  return '• 5件以上：可更改设计及颜色';
    case AppLanguage.mongolian:return '• 5+ ширхэг: дизайн болон өнгийг өөрчлөх боломжтой';
  }}
  String get groupOrderGuideQtyRule10 { switch (language) {
    case AppLanguage.korean:   return '• 10개 이상: 디자인·색상·후면 개인명 변경 가능';
    case AppLanguage.english:  return '• 10+ pieces: design, color, and back personal name changes allowed';
    case AppLanguage.japanese: return '• 10個以上：デザイン・カラー・背面個人名変更可';
    case AppLanguage.chinese:  return '• 10件以上：可更改设计、颜色及背面个人姓名';
    case AppLanguage.mongolian:return '• 10+ ширхэг: дизайн, өнгө, ар талын нэрийг өөрчлөх боломжтой';
  }}
  String get groupOrderGuideQtyRule2Items { switch (language) {
    case AppLanguage.korean:   return '• 2가지 동시 작업 시: 추가 70,000원';
    case AppLanguage.english:  return '• Processing two items simultaneously: +₩70,000';
    case AppLanguage.japanese: return '• 2点同時作業の場合：追加70,000ウォン';
    case AppLanguage.chinese:  return '• 同时处理2件：附加70,000韩元';
    case AppLanguage.mongolian:return '• 2 зүйлийг нэгэн зэрэг боловсруулах: +70,000 вон';
  }}

  String get groupOrderGuideSizeTitle { switch (language) {
    case AppLanguage.korean:   return '사이즈 안내';
    case AppLanguage.english:  return 'Size Guide';
    case AppLanguage.japanese: return 'サイズ案内';
    case AppLanguage.chinese:  return '尺码指南';
    case AppLanguage.mongolian:return 'Хэмжээний заавар';
  }}
  String get groupOrderGuideNoSizeHint { switch (language) {
    case AppLanguage.korean:   return '원하는 사이즈가 없을 경우';
    case AppLanguage.english:  return 'If your size is not available';
    case AppLanguage.japanese: return '希望のサイズがない場合';
    case AppLanguage.chinese:  return '如果没有所需尺码';
    case AppLanguage.mongolian:return 'Хэрэв хэмжээ байхгүй бол';
  }}
  String get groupOrderGuideNoSizeDesc { switch (language) {
    case AppLanguage.korean:   return '주문 양식에 키와 체중을 입력해주세요';
    case AppLanguage.english:  return 'Enter height and weight in the order form';
    case AppLanguage.japanese: return '注文フォームに身長と体重を入力してください';
    case AppLanguage.chinese:  return '请在订单表格中输入身高和体重';
    case AppLanguage.mongolian:return 'Захиалгын маягтад өндөр, жингээ оруулна уу';
  }}
  String get groupOrderGuideExchangeTitle { switch (language) {
    case AppLanguage.korean:   return '교환·환불 정책';
    case AppLanguage.english:  return 'Exchange & Return Policy';
    case AppLanguage.japanese: return '交換・返金ポリシー';
    case AppLanguage.chinese:  return '换货·退款政策';
    case AppLanguage.mongolian:return 'Солих/буцаах бодлого';
  }}
  String get groupOrderGuideExchange1 { switch (language) {
    case AppLanguage.korean:   return '• 의류 자체 불량 외 교환·환불은 불가합니다.';
    case AppLanguage.english:  return '• No exchange/return except for product defects.';
    case AppLanguage.japanese: return '• 衣類自体の不良以外、交換・返金は不可です。';
    case AppLanguage.chinese:  return '• 除服装本身质量问题外，不可换货·退款。';
    case AppLanguage.mongolian:return '• Бүтээгдэхүүний гэмтлээс бусад тохиолдолд солих/буцаах боломжгүй.';
  }}
  String get groupOrderGuideExchange2 { switch (language) {
    case AppLanguage.korean:   return '• 커스텀 마킹이 포함된 경우 교환·환불이 불가합니다.';
    case AppLanguage.english:  return '• No exchange/return for custom-marked items.';
    case AppLanguage.japanese: return '• カスタムマーキングが含まれる場合、交換・返金は不可です。';
    case AppLanguage.chinese:  return '• 包含定制标记的情况下，不可换货·退款。';
    case AppLanguage.mongolian:return '• Захиалгат тэмдэглэгээтэй бол солих/буцаах боломжгүй.';
  }}
  String get groupOrderGuideViewOrderGuide { switch (language) {
    case AppLanguage.korean:   return '주문 안내 보기';
    case AppLanguage.english:  return 'View Order Guide';
    case AppLanguage.japanese: return '注文案内を見る';
    case AppLanguage.chinese:  return '查看订单说明';
    case AppLanguage.mongolian:return 'Захиалгын заавар харах';
  }}
  String get groupOrderGuideAgreeAll { switch (language) {
    case AppLanguage.korean:   return '위 안내 내용을 모두 확인하였습니다.';
    case AppLanguage.english:  return 'I have confirmed all of the above.';
    case AppLanguage.japanese: return '上記の案内内容をすべて確認しました。';
    case AppLanguage.chinese:  return '我已确认以上所有内容。';
    case AppLanguage.mongolian:return 'Дээрх бүх зааврыг шалгасан.';
  }}
  String get groupOrderGuidePriceUnit { switch (language) {
    case AppLanguage.korean:   return '/ 1개';
    case AppLanguage.english:  return '/ each';
    case AppLanguage.japanese: return '/ 1個';
    case AppLanguage.chinese:  return '/ 每件';
    case AppLanguage.mongolian:return '/ нэг';
  }}
  String get groupOrderGuideSizeAdult { switch (language) {
    case AppLanguage.korean:   return '성인 사이즈';
    case AppLanguage.english:  return 'Adult Size';
    case AppLanguage.japanese: return '大人サイズ';
    case AppLanguage.chinese:  return '成人尺码';
    case AppLanguage.mongolian:return 'Насанд хүрэгчдийн хэмжээ';
  }}
  String get groupOrderGuideSizeJunior { switch (language) {
    case AppLanguage.korean:   return '주니어 사이즈';
    case AppLanguage.english:  return 'Junior Size';
    case AppLanguage.japanese: return 'ジュニアサイズ';
    case AppLanguage.chinese:  return '青少年尺码';
    case AppLanguage.mongolian:return 'Залуучуудын хэмжээ';
  }}
  String get groupOrderGuidePrintTypeTitle { switch (language) {
    case AppLanguage.korean:   return '인쇄 타입 선택';
    case AppLanguage.english:  return 'Select Print Type';
    case AppLanguage.japanese: return '印刷タイプ選択';
    case AppLanguage.chinese:  return '选择印刷类型';
    case AppLanguage.mongolian:return 'Хэвлэлийн төрөл сонгох';
  }}
  String get groupOrderGuideLockedMsg { switch (language) {
    case AppLanguage.korean:   return '주문 안내 탭에서 내용을 확인하고\n동의 체크 후 이용해 주세요.';
    case AppLanguage.english:  return 'Please check the order guide tab\nand agree before proceeding.';
    case AppLanguage.japanese: return '注文案内タブで内容を確認し\n同意チェック後にご利用ください。';
    case AppLanguage.chinese:  return '请在订单说明选项卡确认内容\n同意后方可使用。';
    case AppLanguage.mongolian:return 'Захиалгын заавар таб дахь агуулгыг шалгаад\nзөвшөөрснөөр үргэлжлүүлнэ үү.';
  }}

  // ══════════════════════════════════════════════════════════════
  // 단체주문 양식 화면 (GroupOrderFormScreen) 추가 키
  // ══════════════════════════════════════════════════════════════
  String get groupFormTitle { switch (language) {
    case AppLanguage.korean:   return '단체 주문서 작성';
    case AppLanguage.english:  return 'Group Order Form';
    case AppLanguage.japanese: return '団体注文書作成';
    case AppLanguage.chinese:  return '填写团体订单';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгын маягт бөглөх';
  }}
  String get groupFormOrderSummary { switch (language) {
    case AppLanguage.korean:   return '주문 요약';
    case AppLanguage.english:  return 'Order Summary';
    case AppLanguage.japanese: return '注文概要';
    case AppLanguage.chinese:  return '订单摘要';
    case AppLanguage.mongolian:return 'Захиалгын хураангуй';
  }}
  String get groupFormFinalPrice { switch (language) {
    case AppLanguage.korean:   return '최종 결제금액';
    case AppLanguage.english:  return 'Final Payment';
    case AppLanguage.japanese: return '最終決済金額';
    case AppLanguage.chinese:  return '最终付款金额';
    case AppLanguage.mongolian:return 'Эцсийн төлбөр';
  }}
  String get groupFormCartBtn { switch (language) {
    case AppLanguage.korean:   return '장바구니';
    case AppLanguage.english:  return 'Cart';
    case AppLanguage.japanese: return 'カート';
    case AppLanguage.chinese:  return '购物车';
    case AppLanguage.mongolian:return 'Сагс';
  }}
  String get groupFormBuyNowBtn { switch (language) {
    case AppLanguage.korean:   return '바로 구매';
    case AppLanguage.english:  return 'Buy Now';
    case AppLanguage.japanese: return 'すぐ購入';
    case AppLanguage.chinese:  return '立即购买';
    case AppLanguage.mongolian:return 'Шууд худалдаж авах';
  }}
  String get groupFormQtyLabel { switch (language) {
    case AppLanguage.korean:   return '주문 수량 (인원수)';
    case AppLanguage.english:  return 'Order Qty (people)';
    case AppLanguage.japanese: return '注文数量（人数）';
    case AppLanguage.chinese:  return '订单数量（人数）';
    case AppLanguage.mongolian:return 'Захиалгын тоо (хүний тоо)';
  }}
  String get groupFormRequired { switch (language) {
    case AppLanguage.korean:   return '필수';
    case AppLanguage.english:  return 'Required';
    case AppLanguage.japanese: return '必須';
    case AppLanguage.chinese:  return '必填';
    case AppLanguage.mongolian:return 'Заавал';
  }}
  String get groupFormQtyHint { switch (language) {
    case AppLanguage.korean:   return '- / + 버튼으로 인원수를 조절하고 확인을 눌러주세요';
    case AppLanguage.english:  return 'Adjust the number of people with - / + and press confirm';
    case AppLanguage.japanese: return '- / +ボタンで人数を調整して確認を押してください';
    case AppLanguage.chinese:  return '用 - / + 按钮调整人数后点击确认';
    case AppLanguage.mongolian:return '- / + товчлуурааар хүний тоог тохируулж баталгаажуулна уу';
  }}
  String get groupFormPersonUnit { switch (language) {
    case AppLanguage.korean:   return '명';
    case AppLanguage.english:  return 'people';
    case AppLanguage.japanese: return '名';
    case AppLanguage.chinese:  return '人';
    case AppLanguage.mongolian:return 'хүн';
  }}
  String get groupFormBasePrice { switch (language) {
    case AppLanguage.korean:   return '기본가';
    case AppLanguage.english:  return 'Base Price';
    case AppLanguage.japanese: return '基本価格';
    case AppLanguage.chinese:  return '基础价格';
    case AppLanguage.mongolian:return 'Үндсэн үнэ';
  }}
  String get groupFormOrderInfoTitle { switch (language) {
    case AppLanguage.korean:   return '📋 단체 주문 정보';
    case AppLanguage.english:  return '📋 Group Order Info';
    case AppLanguage.japanese: return '📋 団体注文情報';
    case AppLanguage.chinese:  return '📋 团体订单信息';
    case AppLanguage.mongolian:return '📋 Бүлгийн захиалгын мэдээлэл';
  }}
  String get groupForm10Plus { switch (language) {
    case AppLanguage.korean:   return '10인 이상';
    case AppLanguage.english:  return '10+ people';
    case AppLanguage.japanese: return '10名以上';
    case AppLanguage.chinese:  return '10人以上';
    case AppLanguage.mongolian:return '10+ хүн';
  }}
  String get groupFormSingletColorTitle { switch (language) {
    case AppLanguage.korean:   return '싱글렛세트 컬러 선택';
    case AppLanguage.english:  return 'Singlet Set Color Selection';
    case AppLanguage.japanese: return 'シングレットセットカラー選択';
    case AppLanguage.chinese:  return '单衫套装颜色选择';
    case AppLanguage.mongolian:return 'Сингл багцын өнгө сонгох';
  }}
  String get groupFormSingletColorDesc { switch (language) {
    case AppLanguage.korean:   return '상의와 하의를 같은 색상 또는 다른 색상으로 선택할 수 있습니다.';
    case AppLanguage.english:  return 'You can choose the same or different colors for top and bottom.';
    case AppLanguage.japanese: return 'トップスとボトムスを同じ色または異なる色で選択できます。';
    case AppLanguage.chinese:  return '上衣和下装可以选择相同或不同的颜色。';
    case AppLanguage.mongolian:return 'Дээд болон доод хэсгийг ижил эсвэл өөр өнгөөр сонгож болно.';
  }}
  String get groupFormColorSplitLabel { switch (language) {
    case AppLanguage.korean:   return '상의·하의 색상 분리 선택';
    case AppLanguage.english:  return 'Separate color for top/bottom';
    case AppLanguage.japanese: return 'トップス・ボトムスのカラーを分けて選択';
    case AppLanguage.chinese:  return '上下分开选色';
    case AppLanguage.mongolian:return 'Дээд/доод хэсгийн өнгийг тусад нь сонгох';
  }}
  String get groupFormPhantomChart { switch (language) {
    case AppLanguage.korean:   return '팬텀차트';
    case AppLanguage.english:  return 'Phantom Chart';
    case AppLanguage.japanese: return 'ファントムチャート';
    case AppLanguage.chinese:  return '幻影色卡';
    case AppLanguage.mongolian:return 'Хандивын хүснэгт';
  }}
  String get groupFormPhantomChartPreview { switch (language) {
    case AppLanguage.korean:   return '색상 팬텀차트 미리보기';
    case AppLanguage.english:  return 'Color Phantom Chart Preview';
    case AppLanguage.japanese: return 'カラーファントムチャートプレビュー';
    case AppLanguage.chinese:  return '颜色幻影色卡预览';
    case AppLanguage.mongolian:return 'Өнгийн хандивын хүснэгт урьдчилан харах';
  }}
  String get groupFormFabricCostNote { switch (language) {
    case AppLanguage.korean:   return '소재 선택에 따라 추가 비용이 발생할 수 있습니다.';
    case AppLanguage.english:  return 'Additional cost may apply depending on fabric selection.';
    case AppLanguage.japanese: return '素材の選択によって追加費用が発生する場合があります。';
    case AppLanguage.chinese:  return '根据面料选择可能产生额外费用。';
    case AppLanguage.mongolian:return 'Материалын сонголтоос хамааран нэмэлт зардал гарч болно.';
  }}
  String get groupFormFabricWeightNote { switch (language) {
    case AppLanguage.korean:   return '원단 무게에 따라 착용감이 달라집니다.';
    case AppLanguage.english:  return 'Wearing comfort varies by fabric weight.';
    case AppLanguage.japanese: return '生地の重さによって着用感が異なります。';
    case AppLanguage.chinese:  return '穿着感因面料重量而异。';
    case AppLanguage.mongolian:return 'Материалын жингээс хамаарч өмсөлт ялгаатай байдаг.';
  }}
  String get groupFormWaistbandNote { switch (language) {
    case AppLanguage.korean:   return '허리밴드 변경이 필요한 경우 체크하세요.';
    case AppLanguage.english:  return 'Check if waistband change is needed.';
    case AppLanguage.japanese: return 'ウエストバンドの変更が必要な場合はチェックしてください。';
    case AppLanguage.chinese:  return '如需更换腰带，请勾选。';
    case AppLanguage.mongolian:return 'Хэрэв бүс солих шаардлагатай бол тэмдэглэнэ үү.';
  }}
  String get groupFormWaistbandChange { switch (language) {
    case AppLanguage.korean:   return '허리밴드 변경';
    case AppLanguage.english:  return 'Waistband Change';
    case AppLanguage.japanese: return 'ウエストバンド変更';
    case AppLanguage.chinese:  return '腰带更换';
    case AppLanguage.mongolian:return 'Бүс солих';
  }}
  String get groupFormWaistbandDesc { switch (language) {
    case AppLanguage.korean:   return '단체명 인쇄 · 색상 변경 옵션 선택 가능';
    case AppLanguage.english:  return 'Team name printing · color change option available';
    case AppLanguage.japanese: return '団体名印刷・カラー変更オプション選択可能';
    case AppLanguage.chinese:  return '可选择团体名印刷·颜色变更选项';
    case AppLanguage.mongolian:return 'Бүлгийн нэр хэвлэх · өнгө солих сонголт байгаа';
  }}
  String get groupFormChangeOptionTitle { switch (language) {
    case AppLanguage.korean:   return '변경 옵션 선택 (1개)';
    case AppLanguage.english:  return 'Select Change Option (1)';
    case AppLanguage.japanese: return '変更オプション選択（1つ）';
    case AppLanguage.chinese:  return '选择变更选项（1个）';
    case AppLanguage.mongolian:return 'Өөрчлөлтийн сонголт (1)';
  }}
  String get groupFormChangeOptionPlaceholder { switch (language) {
    case AppLanguage.korean:   return '위에서 변경 옵션을 선택해 주세요.';
    case AppLanguage.english:  return 'Please select a change option above.';
    case AppLanguage.japanese: return '上から変更オプションを選択してください。';
    case AppLanguage.chinese:  return '请从上方选择变更选项。';
    case AppLanguage.mongolian:return 'Дээрээс өөрчлөлтийн сонголт хийнэ үү.';
  }}
  String get groupFormAddPerson { switch (language) {
    case AppLanguage.korean:   return '인원 추가';
    case AppLanguage.english:  return 'Add Person';
    case AppLanguage.japanese: return '人員追加';
    case AppLanguage.chinese:  return '添加人员';
    case AppLanguage.mongolian:return 'Хүн нэмэх';
  }}
  String get groupFormLengthCompare { switch (language) {
    case AppLanguage.korean:   return '길이 비교';
    case AppLanguage.english:  return 'Length Comparison';
    case AppLanguage.japanese: return '長さ比較';
    case AppLanguage.chinese:  return '长度对比';
    case AppLanguage.mongolian:return 'Урт харьцуулах';
  }}
  String get groupFormBottomLengthCompare { switch (language) {
    case AppLanguage.korean:   return '하의 길이 비교';
    case AppLanguage.english:  return 'Bottom Length Comparison';
    case AppLanguage.japanese: return '下半身の長さ比較';
    case AppLanguage.chinese:  return '下装长度对比';
    case AppLanguage.mongolian:return 'Доод хэсгийн урт харьцуулах';
  }}
  String get groupFormTotalCount { switch (language) {
    case AppLanguage.korean:   return '{n}명';
    case AppLanguage.english:  return '{n} people';
    case AppLanguage.japanese: return '{n}名';
    case AppLanguage.chinese:  return '{n}人';
    case AppLanguage.mongolian:return '{n} хүн';
  }}
  String groupFormTotalCountN(int n) => groupFormTotalCount.replaceAll('{n}', '$n');
  String get groupFormFinalPriceLabel { switch (language) {
    case AppLanguage.korean:   return '최종 결제금액';
    case AppLanguage.english:  return 'Final Payment';
    case AppLanguage.japanese: return '最終決済金額';
    case AppLanguage.chinese:  return '最终付款金额';
    case AppLanguage.mongolian:return 'Эцсийн төлбөр';
  }}
  String get groupFormBuyNowFull { switch (language) {
    case AppLanguage.korean:   return '바로 구매하기';
    case AppLanguage.english:  return 'Buy Now';
    case AppLanguage.japanese: return 'すぐ購入する';
    case AppLanguage.chinese:  return '立即购买';
    case AppLanguage.mongolian:return 'Шууд худалдаж авах';
  }}
  String get groupFormColorRequired { switch (language) {
    case AppLanguage.korean:   return '메인 컬러를 선택해주세요';
    case AppLanguage.english:  return 'Please select a main color';
    case AppLanguage.japanese: return 'メインカラーを選択してください';
    case AppLanguage.chinese:  return '请选择主颜色';
    case AppLanguage.mongolian:return 'Үндсэн өнгийг сонгоно уу';
  }}
  String get groupFormCartAdded { switch (language) {
    case AppLanguage.korean:   return '장바구니에 {n}명 담겼습니다';
    case AppLanguage.english:  return '{n} people added to cart';
    case AppLanguage.japanese: return 'カートに{n}名入れました';
    case AppLanguage.chinese:  return '{n}人已加入购物车';
    case AppLanguage.mongolian:return '{n} хүн сагсанд нэмэгдлээ';
  }}
  String groupFormCartAddedN(int n) => groupFormCartAdded.replaceAll('{n}', '$n');
  String get groupFormTeamRequired { switch (language) {
    case AppLanguage.korean:   return '팀/단체명을 입력해주세요';
    case AppLanguage.english:  return 'Please enter team/group name';
    case AppLanguage.japanese: return 'チーム/団体名を入力してください';
    case AppLanguage.chinese:  return '请输入团队/团体名称';
    case AppLanguage.mongolian:return 'Баг/бүлгийн нэрийг оруулна уу';
  }}
  String get groupFormPhoneRequired { switch (language) {
    case AppLanguage.korean:   return '연락처를 입력해주세요';
    case AppLanguage.english:  return 'Please enter a phone number';
    case AppLanguage.japanese: return '連絡先を入力してください';
    case AppLanguage.chinese:  return '请输入联系方式';
    case AppLanguage.mongolian:return 'Утасны дугаарыг оруулна уу';
  }}
  String get groupFormMinQtyError { switch (language) {
    case AppLanguage.korean:   return '단체 주문은 최소 5인 이상이어야 합니다';
    case AppLanguage.english:  return 'Group orders require a minimum of 5 people';
    case AppLanguage.japanese: return '団体注文は最低5名以上必要です';
    case AppLanguage.chinese:  return '团体订单至少需要5人';
    case AppLanguage.mongolian:return 'Бүлгийн захиалга хамгийн багадаа 5 хүн байх ёстой';
  }}
  String get groupFormAdditionalQtyError { switch (language) {
    case AppLanguage.korean:   return '추가제작 수량을 1장 이상 입력해주세요';
    case AppLanguage.english:  return 'Please enter at least 1 for additional production';
    case AppLanguage.japanese: return '追加製作数量を1枚以上入力してください';
    case AppLanguage.chinese:  return '请输入至少1件的追加制作数量';
    case AppLanguage.mongolian:return 'Нэмэлт үйлдвэрлэлийн тоог 1-ээс багагүй оруулна уу';
  }}
  String get groupFormAddressInput { switch (language) {
    case AppLanguage.korean:   return '배송지 입력';
    case AppLanguage.english:  return 'Enter Delivery Address';
    case AppLanguage.japanese: return '配送先入力';
    case AppLanguage.chinese:  return '输入配送地址';
    case AppLanguage.mongolian:return 'Хүргэлтийн хаяг оруулах';
  }}
  String get groupFormSearch { switch (language) {
    case AppLanguage.korean:   return '검색';
    case AppLanguage.english:  return 'Search';
    case AppLanguage.japanese: return '検索';
    case AppLanguage.chinese:  return '搜索';
    case AppLanguage.mongolian:return 'Хайх';
  }}
  String get groupFormOrderConfirmTitle { switch (language) {
    case AppLanguage.korean:   return '주문서 확인 완료 ✅';
    case AppLanguage.english:  return 'Order Confirmed ✅';
    case AppLanguage.japanese: return '注文書確認完了 ✅';
    case AppLanguage.chinese:  return '订单确认完成 ✅';
    case AppLanguage.mongolian:return 'Захиалга баталгаажлаа ✅';
  }}
  String get groupFormOrderChangeNote { switch (language) {
    case AppLanguage.korean:   return '주문 변경 안내';
    case AppLanguage.english:  return 'Order Change Notice';
    case AppLanguage.japanese: return '注文変更案内';
    case AppLanguage.chinese:  return '订单变更说明';
    case AppLanguage.mongolian:return 'Захиалга өөрчлөх мэдэгдэл';
  }}
  String get groupFormSizeConditionTitle { switch (language) {
    case AppLanguage.korean:   return '사이즈 조건표';
    case AppLanguage.english:  return 'Size Condition Table';
    case AppLanguage.japanese: return 'サイズ条件表';
    case AppLanguage.chinese:  return '尺码条件表';
    case AppLanguage.mongolian:return 'Хэмжээний нөхцлийн хүснэгт';
  }}
  String get groupFormSizeStandard { switch (language) {
    case AppLanguage.korean:   return '(스탠다드 체형 기준 권장 사이즈)';
    case AppLanguage.english:  return '(Recommended size based on standard body type)';
    case AppLanguage.japanese: return '（標準体型基準の推奨サイズ）';
    case AppLanguage.chinese:  return '（基于标准体型的推荐尺码）';
    case AppLanguage.mongolian:return '(Стандарт биеийн хэмжээнд суурилсан зөвлөмж)';
  }}
  String get groupFormGenderSelectFirst { switch (language) {
    case AppLanguage.korean:   return '성별 선택 후 가능';
    case AppLanguage.english:  return 'Select gender first';
    case AppLanguage.japanese: return '性別選択後に可能';
    case AppLanguage.chinese:  return '先选择性别';
    case AppLanguage.mongolian:return 'Эхлээд хүйсийг сонгоно уу';
  }}
  String get groupFormSelectLength { switch (language) {
    case AppLanguage.korean:   return '길이를 선택해주세요';
    case AppLanguage.english:  return 'Please select a length';
    case AppLanguage.japanese: return '長さを選択してください';
    case AppLanguage.chinese:  return '请选择长度';
    case AppLanguage.mongolian:return 'Уртыг сонгоно уу';
  }}
  String get groupFormImageUpload { switch (language) {
    case AppLanguage.korean:   return '탭하여 이미지 업로드';
    case AppLanguage.english:  return 'Tap to upload image';
    case AppLanguage.japanese: return 'タップして画像をアップロード';
    case AppLanguage.chinese:  return '点击上传图片';
    case AppLanguage.mongolian:return 'Зураг оруулахын тулд дарна уу';
  }}
  String get groupFormAddressSearch { switch (language) {
    case AppLanguage.korean:   return '주소 검색';
    case AppLanguage.english:  return 'Address Search';
    case AppLanguage.japanese: return '住所検索';
    case AppLanguage.chinese:  return '地址搜索';
    case AppLanguage.mongolian:return 'Хаяг хайх';
  }}
  String get groupFormAddressLoading { switch (language) {
    case AppLanguage.korean:   return '주소 검색 로딩 중...';
    case AppLanguage.english:  return 'Loading address search...';
    case AppLanguage.japanese: return '住所検索をロード中...';
    case AppLanguage.chinese:  return '正在加载地址搜索...';
    case AppLanguage.mongolian:return 'Хаяг хайлт ачаалж байна...';
  }}
  String get groupFormImageError { switch (language) {
    case AppLanguage.korean:   return '이미지 선택 실패';
    case AppLanguage.english:  return 'Image selection failed';
    case AppLanguage.japanese: return '画像選択失敗';
    case AppLanguage.chinese:  return '图片选择失败';
    case AppLanguage.mongolian:return 'Зураг сонгоход алдаа гарлаа';
  }}
  String get groupFormSkinFriction { switch (language) {
    case AppLanguage.korean:   return '피부 마찰 최소화';
    case AppLanguage.english:  return 'Minimize skin friction';
    case AppLanguage.japanese: return '肌との摩擦を最小化';
    case AppLanguage.chinese:  return '最小化皮肤摩擦';
    case AppLanguage.mongolian:return 'Арьстай үрэлтийг багасгах';
  }}
  String get groupFormNormalStitch { switch (language) {
    case AppLanguage.korean:   return '일반 봉제 구조';
    case AppLanguage.english:  return 'Normal stitching structure';
    case AppLanguage.japanese: return '一般縫製構造';
    case AppLanguage.chinese:  return '普通缝制结构';
    case AppLanguage.mongolian:return 'Ердийн оёдлын бүтэц';
  }}

  // ══════════════════════════════════════════════════════════════
  // group_custom_order_screen 추가 누락 키
  // ══════════════════════════════════════════════════════════════
  String get customNoColorInfo { switch (language) {
    case AppLanguage.korean:   return '색상 정보가 없습니다';
    case AppLanguage.english:  return 'No color information';
    case AppLanguage.japanese: return 'カラー情報がありません';
    case AppLanguage.chinese:  return '暂无颜色信息';
    case AppLanguage.mongolian:return 'Өнгийн мэдээлэл байхгүй';
  }}
  String get customFabricType { switch (language) {
    case AppLanguage.korean:   return '원단 타입';
    case AppLanguage.english:  return 'Fabric Type';
    case AppLanguage.japanese: return '生地タイプ';
    case AppLanguage.chinese:  return '面料类型';
    case AppLanguage.mongolian:return 'Материалын төрөл';
  }}
  String get customFabricWeightLabel { switch (language) {
    case AppLanguage.korean:   return '원단 무게';
    case AppLanguage.english:  return 'Fabric Weight';
    case AppLanguage.japanese: return '生地の重さ';
    case AppLanguage.chinese:  return '面料重量';
    case AppLanguage.mongolian:return 'Материалын жин';
  }}
  String get customAddPerson { switch (language) {
    case AppLanguage.korean:   return '인원 추가';
    case AppLanguage.english:  return 'Add Person';
    case AppLanguage.japanese: return '人員追加';
    case AppLanguage.chinese:  return '添加人员';
    case AppLanguage.mongolian:return 'Хүн нэмэх';
  }}
  String get customAddPersonBtn { switch (language) {
    case AppLanguage.korean:   return '+ 인원 추가';
    case AppLanguage.english:  return '+ Add Person';
    case AppLanguage.japanese: return '+ 人員追加';
    case AppLanguage.chinese:  return '+ 添加人员';
    case AppLanguage.mongolian:return '+ Хүн нэмэх';
  }}
  String get customNoSizeMeasureHint { switch (language) {
    case AppLanguage.korean:   return '맞는 사이즈가 없으면 실측 치수를 입력해주세요';
    case AppLanguage.english:  return 'Enter actual measurements if your size is not available';
    case AppLanguage.japanese: return 'サイズが合わない場合は実測寸法を入力してください';
    case AppLanguage.chinese:  return '如果没有合适尺码，请输入实际测量尺寸';
    case AppLanguage.mongolian:return 'Тохирсон хэмжээ байхгүй бол бодит хэмжилтийг оруулна уу';
  }}
  String get customPricePerPerson { switch (language) {
    case AppLanguage.korean:   return '{n}명 × {price}원';
    case AppLanguage.english:  return '{n} × {price}₩';
    case AppLanguage.japanese: return '{n}名 × {price}ウォン';
    case AppLanguage.chinese:  return '{n}人 × {price}₩';
    case AppLanguage.mongolian:return '{n} хүн × {price}₩';
  }}
  String customPricePerPersonFmt(int n, String price) =>
      customPricePerPerson.replaceAll('{n}', '$n').replaceAll('{price}', price);
  String get customTotalPrice { switch (language) {
    case AppLanguage.korean:   return '{total}원';
    case AppLanguage.english:  return '₩{total}';
    case AppLanguage.japanese: return '{total}ウォン';
    case AppLanguage.chinese:  return '₩{total}';
    case AppLanguage.mongolian:return '₩{total}';
  }}
  String customTotalPriceFmt(String total) => customTotalPrice.replaceAll('{total}', total);
  String get customSubmitBtn { switch (language) {
    case AppLanguage.korean:   return '커스텀 오더 접수';
    case AppLanguage.english:  return 'Submit Custom Order';
    case AppLanguage.japanese: return 'カスタムオーダー受付';
    case AppLanguage.chinese:  return '提交定制订单';
    case AppLanguage.mongolian:return 'Захиалгат захиалга илгээх';
  }}
  String get customOrderTitle { switch (language) {
    case AppLanguage.korean:   return '단체 커스텀 오더';
    case AppLanguage.english:  return 'Group Custom Order';
    case AppLanguage.japanese: return '団体カスタムオーダー';
    case AppLanguage.chinese:  return '团体定制订单';
    case AppLanguage.mongolian:return 'Бүлгийн захиалгат захиалга';
  }}

  // ── 사이즈표 공통 헤더 키 ──────────────────────────────────────
  String get chestLabel { switch (language) {
    case AppLanguage.korean:   return '가슴';
    case AppLanguage.english:  return 'Chest';
    case AppLanguage.japanese: return '胸';
    case AppLanguage.chinese:  return '胸围';
    case AppLanguage.mongolian:return 'Цээж';
  }}
  String get waistLabel { switch (language) {
    case AppLanguage.korean:   return '허리';
    case AppLanguage.english:  return 'Waist';
    case AppLanguage.japanese: return 'ウエスト';
    case AppLanguage.chinese:  return '腰围';
    case AppLanguage.mongolian:return 'Бэлхүүс';
  }}
  String get hipLabel { switch (language) {
    case AppLanguage.korean:   return '엉덩이';
    case AppLanguage.english:  return 'Hip';
    case AppLanguage.japanese: return '腰';
    case AppLanguage.chinese:  return '臀围';
    case AppLanguage.mongolian:return 'Нүсэр';
  }}
  String get heightLabel { switch (language) {
    case AppLanguage.korean:   return '키';
    case AppLanguage.english:  return 'Height';
    case AppLanguage.japanese: return '身長';
    case AppLanguage.chinese:  return '身高';
    case AppLanguage.mongolian:return 'Өндөр';
  }}
  String get setProduct { switch (language) {
    case AppLanguage.korean:   return '세트 상품';
    case AppLanguage.english:  return 'Set Product';
    case AppLanguage.japanese: return 'セット商品';
    case AppLanguage.chinese:  return '套装商品';
    case AppLanguage.mongolian:return 'Багц бүтээгдэхүүн';
  }}
  String get groupOrderOnlyLabel { switch (language) {
    case AppLanguage.korean:   return '단체 전용';
    case AppLanguage.english:  return 'Group Only';
    case AppLanguage.japanese: return '団体専用';
    case AppLanguage.chinese:  return '团体专用';
    case AppLanguage.mongolian:return 'Бүлгийн зориулалт';
  }}

  // ── 단체주문 안내 시트 추가 키 ──────────────────────────────────
  String get groupOrderSheetCancelNote { switch (language) {
    case AppLanguage.korean:   return '• 주문 확정 후 제작 착수 전까지만 취소 가능합니다.';
    case AppLanguage.english:  return '• Cancellation is possible before production starts.';
    case AppLanguage.japanese: return '• 製作開始前までキャンセル可能です。';
    case AppLanguage.chinese:  return '• 生产开始前可以取消订单。';
    case AppLanguage.mongolian:return '• Үйлдвэрлэл эхлэхээс өмнө цуцлах боломжтой.';
  }}
  String get groupOrderSheetColorNote { switch (language) {
    case AppLanguage.korean:   return '• 색상은 모니터 환경에 따라 실제와 다소 다를 수 있습니다.';
    case AppLanguage.english:  return '• Colors may vary slightly from actual due to monitor settings.';
    case AppLanguage.japanese: return '• 色はモニター環境により実際と多少異なる場合があります。';
    case AppLanguage.chinese:  return '• 颜色因显示器环境可能与实际略有差异。';
    case AppLanguage.mongolian:return '• Өнгө нь дэлгэцийн тохиргооноос хамаарч бодитоос арай ялгаатай байж болно.';
  }}

  // ── 상품 상세 페이지 추가 번역 키 ──────────────────────────────────
  String get shippingLabel { switch (language) {
    case AppLanguage.korean:   return '배송';
    case AppLanguage.english:  return 'Shipping';
    case AppLanguage.japanese: return '配送';
    case AppLanguage.chinese:  return '配送';
    case AppLanguage.mongolian:return 'Хүргэлт';
  }}
  String get basicShippingFeeInfo { switch (language) {
    case AppLanguage.korean:   return '기본 배송비 3,000원 (30,000원 이상 무료)';
    case AppLanguage.english:  return 'Basic shipping ₩3,000 (Free over ₩30,000)';
    case AppLanguage.japanese: return '基本送料3,000ウォン（30,000ウォン以上無料）';
    case AppLanguage.chinese:  return '基本运费3,000韩元（满30,000免运费）';
    case AppLanguage.mongolian:return 'Үндсэн хүргэлт ₩3,000 (₩30,000-аас дээш үнэгүй)';
  }}
  String get dispatchLabel { switch (language) {
    case AppLanguage.korean:   return '발송';
    case AppLanguage.english:  return 'Dispatch';
    case AppLanguage.japanese: return '発送';
    case AppLanguage.chinese:  return '发货';
    case AppLanguage.mongolian:return 'Илгээлт';
  }}
  String get dispatchDaysInfo { switch (language) {
    case AppLanguage.korean:   return '결제 완료 후 2~3 영업일 내 발송';
    case AppLanguage.english:  return 'Ships within 2~3 business days after payment';
    case AppLanguage.japanese: return 'お支払い完了後2〜3営業日以内に発送';
    case AppLanguage.chinese:  return '付款完成后2~3个工作日内发货';
    case AppLanguage.mongolian:return 'Төлбөр хийснээс хойш 2~3 ажлын өдрийн дотор илгээнэ';
  }}
  String get pointLabel { switch (language) {
    case AppLanguage.korean:   return '포인트';
    case AppLanguage.english:  return 'Points';
    case AppLanguage.japanese: return 'ポイント';
    case AppLanguage.chinese:  return '积分';
    case AppLanguage.mongolian:return 'Оноо';
  }}
  String get pointAccumulateInfo { switch (language) {
    case AppLanguage.korean:   return '결제 금액의 1% 포인트 적립';
    case AppLanguage.english:  return '1% of payment accumulated as points';
    case AppLanguage.japanese: return '決済金額の1%ポイント積立';
    case AppLanguage.chinese:  return '支付金额的1%积累积分';
    case AppLanguage.mongolian:return 'Төлбөрийн 1%-ийг оноо болгон хуримтлуулна';
  }}
  String get exchangeReturnLabel { switch (language) {
    case AppLanguage.korean:   return '교환/반품';
    case AppLanguage.english:  return 'Exchange/Return';
    case AppLanguage.japanese: return '交換/返品';
    case AppLanguage.chinese:  return '换货/退货';
    case AppLanguage.mongolian:return 'Солилт/Буцаалт';
  }}
  String get exchangeReturnInfo { switch (language) {
    case AppLanguage.korean:   return '수령 후 7일 이내 가능 (단순 변심)';
    case AppLanguage.english:  return 'Available within 7 days of receipt (change of mind)';
    case AppLanguage.japanese: return '受領後7日以内可能（単純変心）';
    case AppLanguage.chinese:  return '收货后7天内可申请（单纯变心）';
    case AppLanguage.mongolian:return 'Хүлээн авсанаас хойш 7 хоногт боломжтой';
  }}
  String get groupOrderLabel { switch (language) {
    case AppLanguage.korean:   return '단체주문';
    case AppLanguage.english:  return 'Group Order';
    case AppLanguage.japanese: return '団体注文';
    case AppLanguage.chinese:  return '团体订单';
    case AppLanguage.mongolian:return 'Бүлгийн захиалга';
  }}
  String get groupOrderSubLabel { switch (language) {
    case AppLanguage.korean:   return '5명~ · 단체 할인';
    case AppLanguage.english:  return '5+ · Group discount';
    case AppLanguage.japanese: return '5名以上 · 団体割引';
    case AppLanguage.chinese:  return '5人以上 · 团体折扣';
    case AppLanguage.mongolian:return '5+ · Бүлгийн хөнгөлөлт';
  }}
  String get readyMadeLabel { switch (language) {
    case AppLanguage.korean:   return '기성품';
    case AppLanguage.english:  return 'Ready-made';
    case AppLanguage.japanese: return '既製品';
    case AppLanguage.chinese:  return '现货商品';
    case AppLanguage.mongolian:return 'Бэлэн бараа';
  }}
  String get bottomLengthTitle { switch (language) {
    case AppLanguage.korean:   return '하의 길이';
    case AppLanguage.english:  return 'Bottom Length';
    case AppLanguage.japanese: return 'ボトムス丈';
    case AppLanguage.chinese:  return '下装长度';
    case AppLanguage.mongolian:return 'Доод хэсгийн урт';
  }}
  String get genderAutoFix { switch (language) {
    case AppLanguage.korean:   return '성별 자동 고정';
    case AppLanguage.english:  return 'Auto gender lock';
    case AppLanguage.japanese: return '性別自動固定';
    case AppLanguage.chinese:  return '性别自动锁定';
    case AppLanguage.mongolian:return 'Хүйс автоматаар тогохгол';
  }}
  String get restrictedLabel { switch (language) {
    case AppLanguage.korean:   return '제한 적용';
    case AppLanguage.english:  return 'Restricted';
    case AppLanguage.japanese: return '制限適用';
    case AppLanguage.chinese:  return '限制适用';
    case AppLanguage.mongolian:return 'Хязгаарлалт';
  }}
  String get bottomLengthSelectTitle { switch (language) {
    case AppLanguage.korean:   return '하의 길이 선택';
    case AppLanguage.english:  return 'Select Bottom Length';
    case AppLanguage.japanese: return 'ボトムス丈を選択';
    case AppLanguage.chinese:  return '选择下装长度';
    case AppLanguage.mongolian:return 'Доод хэсгийн урт сонгох';
  }}
  String get colorSelectLabel { switch (language) {
    case AppLanguage.korean:   return '색상 선택';
    case AppLanguage.english:  return 'Select Color';
    case AppLanguage.japanese: return '色を選択';
    case AppLanguage.chinese:  return '选择颜色';
    case AppLanguage.mongolian:return 'Өнгө сонгох';
  }}
  String get selectedLabel { switch (language) {
    case AppLanguage.korean:   return '선택:';
    case AppLanguage.english:  return 'Selected:';
    case AppLanguage.japanese: return '選択中:';
    case AppLanguage.chinese:  return '已选:';
    case AppLanguage.mongolian:return 'Сонгосон:';
  }}
  String get confirmLabel { switch (language) {
    case AppLanguage.korean:   return '확정';
    case AppLanguage.english:  return 'Confirm';
    case AppLanguage.japanese: return '確定';
    case AppLanguage.chinese:  return '确认';
    case AppLanguage.mongolian:return 'Баталгаажуулах';
  }}
  String get fixedLabel { switch (language) {
    case AppLanguage.korean:   return '고정';
    case AppLanguage.english:  return 'Fixed';
    case AppLanguage.japanese: return '固定';
    case AppLanguage.chinese:  return '固定';
    case AppLanguage.mongolian:return 'Тогтсон';
  }}
  String get productReviewLabel { switch (language) {
    case AppLanguage.korean:   return '상품 리뷰';
    case AppLanguage.english:  return 'Product Reviews';
    case AppLanguage.japanese: return '商品レビュー';
    case AppLanguage.chinese:  return '商品评价';
    case AppLanguage.mongolian:return 'Бүтээгдэхүүний сэтгэгдэл';
  }}
  String get fiberMixRatio { switch (language) {
    case AppLanguage.korean:   return '섬유 혼용율';
    case AppLanguage.english:  return 'Fiber Composition';
    case AppLanguage.japanese: return '繊維混用率';
    case AppLanguage.chinese:  return '纤维混纺率';
    case AppLanguage.mongolian:return 'Утас холих харьцаа';
  }}
  String get fiberCategory { switch (language) {
    case AppLanguage.korean:   return '품목';
    case AppLanguage.english:  return 'Category';
    case AppLanguage.japanese: return '品目';
    case AppLanguage.chinese:  return '品类';
    case AppLanguage.mongolian:return 'Ангилал';
  }}
  String get fiberMainMaterial { switch (language) {
    case AppLanguage.korean:   return '주원단';
    case AppLanguage.english:  return 'Main Fabric';
    case AppLanguage.japanese: return '主素材';
    case AppLanguage.chinese:  return '主面料';
    case AppLanguage.mongolian:return 'Үндсэн даавуу';
  }}
  String get fiberMix { switch (language) {
    case AppLanguage.korean:   return '혼용';
    case AppLanguage.english:  return 'Mix';
    case AppLanguage.japanese: return '混用';
    case AppLanguage.chinese:  return '混纺';
    case AppLanguage.mongolian:return 'Холимог';
  }}
  String get addToCartSuccess { switch (language) {
    case AppLanguage.korean:   return '장바구니에 담았습니다';
    case AppLanguage.english:  return 'Added to cart';
    case AppLanguage.japanese: return 'カートに追加しました';
    case AppLanguage.chinese:  return '已添加到购物车';
    case AppLanguage.mongolian:return 'Сагсанд нэмэгдлээ';
  }}
  String get selectSizeFirstMsg { switch (language) {
    case AppLanguage.korean:   return '사이즈를 먼저 선택해주세요';
    case AppLanguage.english:  return 'Please select a size first';
    case AppLanguage.japanese: return 'まずサイズを選択してください';
    case AppLanguage.chinese:  return '请先选择尺码';
    case AppLanguage.mongolian:return 'Эхлээд хэмжээ сонгоно уу';
  }}
  String get purchaseTypeTitle { switch (language) {
    case AppLanguage.korean:   return '구매 유형 선택';
    case AppLanguage.english:  return 'Select Purchase Type';
    case AppLanguage.japanese: return '購入タイプを選択';
    case AppLanguage.chinese:  return '选择购买类型';
    case AppLanguage.mongolian:return 'Худалдан авалтын төрөл сонгох';
  }}
  String get purchaseTypeSubtitle { switch (language) {
    case AppLanguage.korean:   return '원하시는 구매 방식을 선택해주세요';
    case AppLanguage.english:  return 'Please select your preferred purchase method';
    case AppLanguage.japanese: return 'ご希望の購入方法をお選びください';
    case AppLanguage.chinese:  return '请选择您偏好的购买方式';
    case AppLanguage.mongolian:return 'Худалдан авалтын аргаа сонгоно уу';
  }}
  String get singletOptionLabel { switch (language) {
    case AppLanguage.korean:   return '싱글렛 옵션';
    case AppLanguage.english:  return 'Singlet Options';
    case AppLanguage.japanese: return 'シングレットオプション';
    case AppLanguage.chinese:  return '背心选项';
    case AppLanguage.mongolian:return 'Дотоод өмд сонголт';
  }}
  String get styleTypeLabel { switch (language) {
    case AppLanguage.korean:   return '스타일 타입';
    case AppLanguage.english:  return 'Style Type';
    case AppLanguage.japanese: return 'スタイルタイプ';
    case AppLanguage.chinese:  return '款式类型';
    case AppLanguage.mongolian:return 'Загварын төрөл';
  }}
  String get bottomAutoApplyTitle { switch (language) {
    case AppLanguage.korean:   return '하의 기장 자동 적용';
    case AppLanguage.english:  return 'Auto Bottom Length Applied';
    case AppLanguage.japanese: return 'ボトムス丈自動適用';
    case AppLanguage.chinese:  return '自动应用下装长度';
    case AppLanguage.mongolian:return 'Доод хэсгийн урт автоматаар хэрэглэгдэнэ';
  }}
  String get bottomAutoApplyDesc { switch (language) {
    case AppLanguage.korean:   return '남성 → 5부 자동 적용  ·  여성 → 2.5부 자동 적용';
    case AppLanguage.english:  return 'Male → 5/10 auto  ·  Female → 2.5/10 auto';
    case AppLanguage.japanese: return '男性 → 5部自動  ·  女性 → 2.5部自動';
    case AppLanguage.chinese:  return '男性 → 5分自动  ·  女性 → 2.5分自动';
    case AppLanguage.mongolian:return 'Эрэгтэй → 5/10 автомат  ·  Эмэгтэй → 2.5/10 автомат';
  }}
  String get bottomFixedTitle { switch (language) {
    case AppLanguage.korean:   return '하의 길이 9부 고정';
    case AppLanguage.english:  return 'Bottom Length Fixed at 9/10';
    case AppLanguage.japanese: return 'ボトムス丈9部固定';
    case AppLanguage.chinese:  return '下装长度固定9分';
    case AppLanguage.mongolian:return 'Доод хэсгийн урт 9/10 тогтоосон';
  }}
  String get bottomFixedDesc { switch (language) {
    case AppLanguage.korean:   return '트레이닝세트 하의는 9부 기장으로 제작됩니다';
    case AppLanguage.english:  return 'Training set bottom is made at 9/10 length';
    case AppLanguage.japanese: return 'トレーニングセットのボトムスは9部丈で製作されます';
    case AppLanguage.chinese:  return '训练套装下装按9分长度制作';
    case AppLanguage.mongolian:return 'Дасгалын хувцасны доод хэсэг 9/10 уртаар хийгдэнэ';
  }}

  String get fileSelecting { switch (language) {
    case AppLanguage.korean:   return '파일 선택 중...';
    case AppLanguage.english:  return 'Selecting file...';
    case AppLanguage.japanese: return 'ファイル選択中...';
    case AppLanguage.chinese:  return '选择文件中...';
    case AppLanguage.mongolian:return 'Файл сонгож байна...';
  }}
  String get imageSelectFailed { switch (language) {
    case AppLanguage.korean:   return '이미지 선택 실패';
    case AppLanguage.english:  return 'Image selection failed';
    case AppLanguage.japanese: return '画像選択失敗';
    case AppLanguage.chinese:  return '图片选择失败';
    case AppLanguage.mongolian:return 'Зураг сонгоход амжилтгүй болсон';
  }}
  String get sizeSelectTitle { switch (language) {
    case AppLanguage.korean:   return '사이즈 선택';
    case AppLanguage.english:  return 'Select Size';
    case AppLanguage.japanese: return 'サイズを選択';
    case AppLanguage.chinese:  return '选择尺码';
    case AppLanguage.mongolian:return 'Хэмжээ сонгох';
  }}
  String get quantitySelectTitle { switch (language) {
    case AppLanguage.korean:   return '수량';
    case AppLanguage.english:  return 'Quantity';
    case AppLanguage.japanese: return '数量';
    case AppLanguage.chinese:  return '数量';
    case AppLanguage.mongolian:return 'Тоо хэмжээ';
  }}
  String get optionSelectTitle { switch (language) {
    case AppLanguage.korean:   return '옵션 선택';
    case AppLanguage.english:  return 'Select Option';
    case AppLanguage.japanese: return 'オプション選択';
    case AppLanguage.chinese:  return '选择选项';
    case AppLanguage.mongolian:return 'Сонголт сонгох';
  }}
  String get buyNowCheckoutDesc { switch (language) {
    case AppLanguage.korean:   return '사이즈와 컬러를 선택하고 바로 결제로 이동합니다';
    case AppLanguage.english:  return 'Select size and color, then proceed to checkout';
    case AppLanguage.japanese: return 'サイズとカラーを選択してすぐに決済へ';
    case AppLanguage.chinese:  return '选择尺码和颜色后直接进入结账';
    case AppLanguage.mongolian:return 'Хэмжээ, өнгөө сонгоод шууд төлбөр тооцоонд оч';
  }}
  String get colorLabel2 { switch (language) {
    case AppLanguage.korean:   return '컬러';
    case AppLanguage.english:  return 'Color';
    case AppLanguage.japanese: return 'カラー';
    case AppLanguage.chinese:  return '颜色';
    case AppLanguage.mongolian:return 'Өнгө';
  }}
  String get blackNavyLabel { switch (language) {
    case AppLanguage.korean:   return '검정 · 남색';
    case AppLanguage.english:  return 'Black · Navy';
    case AppLanguage.japanese: return 'ブラック · ネイビー';
    case AppLanguage.chinese:  return '黑色 · 深蓝';
    case AppLanguage.mongolian:return 'Хар · Цэнхэр';
  }}
  String get otherColorFee { switch (language) {
    case AppLanguage.korean:   return '기타 +₩20,000';
    case AppLanguage.english:  return 'Other +₩20,000';
    case AppLanguage.japanese: return 'その他 +₩20,000';
    case AppLanguage.chinese:  return '其他 +₩20,000';
    case AppLanguage.mongolian:return 'Бусад +₩20,000';
  }}
  String get directInputLabel { switch (language) {
    case AppLanguage.korean:   return '직접\n입력';
    case AppLanguage.english:  return 'Direct\nInput';
    case AppLanguage.japanese: return '直接\n入力';
    case AppLanguage.chinese:  return '直接\n输入';
    case AppLanguage.mongolian:return 'Шууд\nоруулах';
  }}
  String get colorCodeInput { switch (language) {
    case AppLanguage.korean:   return '색상 코드 직접 입력';
    case AppLanguage.english:  return 'Enter color code directly';
    case AppLanguage.japanese: return 'カラーコードを直接入力';
    case AppLanguage.chinese:  return '直接输入颜色代码';
    case AppLanguage.mongolian:return 'Өнгийн кодыг шууд оруулна уу';
  }}
  String get applyLabel { switch (language) {
    case AppLanguage.korean:   return '적용';
    case AppLanguage.english:  return 'Apply';
    case AppLanguage.japanese: return '適用';
    case AppLanguage.chinese:  return '应用';
    case AppLanguage.mongolian:return 'Хэрэглэх';
  }}
  String get frequentColors { switch (language) {
    case AppLanguage.korean:   return '자주 쓰는 색상';
    case AppLanguage.english:  return 'Frequent Colors';
    case AppLanguage.japanese: return 'よく使う色';
    case AppLanguage.chinese:  return '常用颜色';
    case AppLanguage.mongolian:return 'Байнга хэрэглэдэг өнгө';
  }}
  String get nextStepLabel { switch (language) {
    case AppLanguage.korean:   return '다음 단계';
    case AppLanguage.english:  return 'Next Step';
    case AppLanguage.japanese: return '次のステップ';
    case AppLanguage.chinese:  return '下一步';
    case AppLanguage.mongolian:return 'Дараагийн алхам';
  }}
  String get weightSelectTitle { switch (language) {
    case AppLanguage.korean:   return '무게 선택';
    case AppLanguage.english:  return 'Select Weight';
    case AppLanguage.japanese: return '重量を選択';
    case AppLanguage.chinese:  return '选择重量';
    case AppLanguage.mongolian:return 'Жин сонгох';
  }}
  String get imageUploadLabel { switch (language) {
    case AppLanguage.korean:   return '이미지 업로드';
    case AppLanguage.english:  return 'Image Upload';
    case AppLanguage.japanese: return '画像アップロード';
    case AppLanguage.chinese:  return '上传图片';
    case AppLanguage.mongolian:return 'Зураг байршуулах';
  }}
  String get deleteAllLabel { switch (language) {
    case AppLanguage.korean:   return '전체 삭제';
    case AppLanguage.english:  return 'Delete All';
    case AppLanguage.japanese: return '全削除';
    case AppLanguage.chinese:  return '全部删除';
    case AppLanguage.mongolian:return 'Бүгдийг устгах';
  }}
  String get seamlessMaterialNote { switch (language) {
    case AppLanguage.korean:   return '일반(봉제) 소재만 가능 · 이미지 색상 그대로 제작';
    case AppLanguage.english:  return 'Regular (sewn) material only · Made in image color';
    case AppLanguage.japanese: return '一般（縫製）素材のみ可能・画像の色そのまま製作';
    case AppLanguage.chinese:  return '仅限普通（缝制）素材 · 按图片颜色制作';
    case AppLanguage.mongolian:return 'Зөвхөн энгийн (оёдол) материал · Зурагны өнгөөр хийгдэнэ';
  }}
  String get productLengthRefImg { switch (language) {
    case AppLanguage.korean:   return '하의길이 참조 이미지 (남자 / 여자 분리)';
    case AppLanguage.english:  return 'Bottom length reference image (Male / Female)';
    case AppLanguage.japanese: return 'ボトムス丈参照画像（男性 / 女性）';
    case AppLanguage.chinese:  return '下装长度参考图片（男性 / 女性）';
    case AppLanguage.mongolian:return 'Доод хэсгийн урт лавлах зураг (Эрэгтэй / Эмэгтэй)';
  }}
  String get restrictedLengthNote { switch (language) {
    case AppLanguage.korean:   return '이 상품은 %s 길이만 선택 가능합니다';
    case AppLanguage.english:  return 'Only %s length available for this product';
    case AppLanguage.japanese: return 'この商品は%sの丈のみ選択できます';
    case AppLanguage.chinese:  return '此商品只能选择%s长度';
    case AppLanguage.mongolian:return 'Энэ бүтээгдэхүүнд зөвхөн %s урт сонгох боломжтой';
  }}
  String get reviewCountLabel { switch (language) {
    case AppLanguage.korean:   return '리뷰 %d개';
    case AppLanguage.english:  return '%d Reviews';
    case AppLanguage.japanese: return 'レビュー%d件';
    case AppLanguage.chinese:  return '%d条评价';
    case AppLanguage.mongolian:return '%d сэтгэгдэл';
  }}
  String get noReviewYet { switch (language) {
    case AppLanguage.korean:   return '아직 리뷰가 없습니다';
    case AppLanguage.english:  return 'No reviews yet';
    case AppLanguage.japanese: return 'まだレビューがありません';
    case AppLanguage.chinese:  return '暂无评价';
    case AppLanguage.mongolian:return 'Одоохондоо сэтгэгдэл байхгүй';
  }}

  // ── 단체 주문서 폼 추가 번역 키 ──────────────────────────────────
  String get countPersonUnit { switch (language) {
    case AppLanguage.korean:   return '명';
    case AppLanguage.english:  return 'ppl';
    case AppLanguage.japanese: return '名';
    case AppLanguage.chinese:  return '人';
    case AppLanguage.mongolian:return 'хүн';
  }}
  String get basePriceLabel { switch (language) {
    case AppLanguage.korean:   return '기본가';
    case AppLanguage.english:  return 'Base Price';
    case AppLanguage.japanese: return '基本価格';
    case AppLanguage.chinese:  return '基础价格';
    case AppLanguage.mongolian:return 'Суурь үнэ';
  }}
  String get singletColorSelectTitle { switch (language) {
    case AppLanguage.korean:   return '싱글렛세트 컬러 선택';
    case AppLanguage.english:  return 'Singlet Set Color Selection';
    case AppLanguage.japanese: return 'シングレットセットカラー選択';
    case AppLanguage.chinese:  return '背心套装颜色选择';
    case AppLanguage.mongolian:return 'Дотоод өмд багцын өнгө сонгох';
  }}
  String get singletTopBottomSeparate { switch (language) {
    case AppLanguage.korean:   return '상의·하의 색상 분리 선택';
    case AppLanguage.english:  return 'Top & Bottom color separate';
    case AppLanguage.japanese: return 'トップス・ボトムス個別カラー選択';
    case AppLanguage.chinese:  return '上衣·下装分别选色';
    case AppLanguage.mongolian:return 'Дээд·доод хэсэг тусдаа өнгө';
  }}
  String get phantomChartPreview { switch (language) {
    case AppLanguage.korean:   return '색상 팬텀차트 미리보기';
    case AppLanguage.english:  return 'Color Phantom Chart Preview';
    case AppLanguage.japanese: return 'カラーファントムチャートプレビュー';
    case AppLanguage.chinese:  return '颜色幻影图表预览';
    case AppLanguage.mongolian:return 'Өнгийн хуваарийн урьдчилсан харагдац';
  }}
  String get finalPaymentLabel { switch (language) {
    case AppLanguage.korean:   return '최종 결제금액';
    case AppLanguage.english:  return 'Final Payment';
    case AppLanguage.japanese: return '最終決済金額';
    case AppLanguage.chinese:  return '最终付款金额';
    case AppLanguage.mongolian:return 'Эцсийн төлбөр';
  }}
  String get shippingAddressInput { switch (language) {
    case AppLanguage.korean:   return '배송지 입력';
    case AppLanguage.english:  return 'Enter Shipping Address';
    case AppLanguage.japanese: return '配送先を入力';
    case AppLanguage.chinese:  return '输入收货地址';
    case AppLanguage.mongolian:return 'Хүргэлтийн хаяг оруулах';
  }}
  String get searchLabel { switch (language) {
    case AppLanguage.korean:   return '검색';
    case AppLanguage.english:  return 'Search';
    case AppLanguage.japanese: return '検索';
    case AppLanguage.chinese:  return '搜索';
    case AppLanguage.mongolian:return 'Хайх';
  }}
  String get cancelLabel { switch (language) {
    case AppLanguage.korean:   return '취소';
    case AppLanguage.english:  return 'Cancel';
    case AppLanguage.japanese: return 'キャンセル';
    case AppLanguage.chinese:  return '取消';
    case AppLanguage.mongolian:return 'Цуцлах';
  }}
  String get nextArrowLabel { switch (language) {
    case AppLanguage.korean:   return '다음 →';
    case AppLanguage.english:  return 'Next →';
    case AppLanguage.japanese: return '次へ →';
    case AppLanguage.chinese:  return '下一步 →';
    case AppLanguage.mongolian:return 'Дараах →';
  }}
  String get orderChangeNoticeTitle { switch (language) {
    case AppLanguage.korean:   return '주문 변경 안내';
    case AppLanguage.english:  return 'Order Change Notice';
    case AppLanguage.japanese: return '注文変更案内';
    case AppLanguage.chinese:  return '订单变更说明';
    case AppLanguage.mongolian:return 'Захиалга өөрчлөх мэдэгдэл';
  }}
  String get okLabel { switch (language) {
    case AppLanguage.korean:   return '확인';
    case AppLanguage.english:  return 'OK';
    case AppLanguage.japanese: return '確認';
    case AppLanguage.chinese:  return '确认';
    case AppLanguage.mongolian:return 'Тийм';
  }}
  String get requiredBadgeLabel { switch (language) {
    case AppLanguage.korean:   return '필수';
    case AppLanguage.english:  return 'Required';
    case AppLanguage.japanese: return '必須';
    case AppLanguage.chinese:  return '必填';
    case AppLanguage.mongolian:return 'Заавал';
  }}
  String get genderSelectFirst { switch (language) {
    case AppLanguage.korean:   return '성별 선택 후 가능';
    case AppLanguage.english:  return 'Select gender first';
    case AppLanguage.japanese: return '性別選択後に可能';
    case AppLanguage.chinese:  return '请先选择性别';
    case AppLanguage.mongolian:return 'Эхлээд хүйс сонгоно уу';
  }}
  String get lengthSelectHint { switch (language) {
    case AppLanguage.korean:   return '길이를 선택해주세요';
    case AppLanguage.english:  return 'Please select a length';
    case AppLanguage.japanese: return '丈を選択してください';
    case AppLanguage.chinese:  return '请选择长度';
    case AppLanguage.mongolian:return 'Уртыг сонгоно уу';
  }}
  String get wonUnit { return '원'; }
  String get groupFormFinalPayment { switch (language) {
    case AppLanguage.korean:   return '최종 결제금액';
    case AppLanguage.english:  return 'Final Payment';
    case AppLanguage.japanese: return '最終お支払い金額';
    case AppLanguage.chinese:  return '最终付款金额';
    case AppLanguage.mongolian:return 'Эцсийн төлбөр';
  }}
  String get groupFormNextBtn { switch (language) {
    case AppLanguage.korean:   return '다음 →';
    case AppLanguage.english:  return 'Next →';
    case AppLanguage.japanese: return '次へ →';
    case AppLanguage.chinese:  return '下一步 →';
    case AppLanguage.mongolian:return 'Дараах →';
  }}
  String get groupFormCancelBtn { switch (language) {
    case AppLanguage.korean:   return '취소';
    case AppLanguage.english:  return 'Cancel';
    case AppLanguage.japanese: return 'キャンセル';
    case AppLanguage.chinese:  return '取消';
    case AppLanguage.mongolian:return 'Цуцлах';
  }}
  String get groupFormPersonTotalLabel { switch (language) {
    case AppLanguage.korean:   return '인원';
    case AppLanguage.english:  return 'People';
    case AppLanguage.japanese: return '人数';
    case AppLanguage.chinese:  return '人数';
    case AppLanguage.mongolian:return 'Хүний тоо';
  }}
  String get groupFormSummaryTitle { switch (language) {
    case AppLanguage.korean:   return '주문 요약';
    case AppLanguage.english:  return 'Order Summary';
    case AppLanguage.japanese: return '注文サマリー';
    case AppLanguage.chinese:  return '订单摘要';
    case AppLanguage.mongolian:return 'Захиалгын хураангуй';
  }}


  String get groupFormConfirmOrderBtn { switch (language) {
    case AppLanguage.korean:   return '주문서 확인하기';
    case AppLanguage.english:  return 'Review Order';
    case AppLanguage.japanese: return '注文書を確認する';
    case AppLanguage.chinese:  return '确认订单';
    case AppLanguage.mongolian:return 'Захиалга шалгах';
  }}
  String get groupFormAdditionalConfirmBtn { switch (language) {
    case AppLanguage.korean:   return '추가제작 주문 확인하기';
    case AppLanguage.english:  return 'Review Additional Order';
    case AppLanguage.japanese: return '追加製作注文を確認する';
    case AppLanguage.chinese:  return '确认追加制作订单';
    case AppLanguage.mongolian:return 'Нэмэлт захиалга шалгах';
  }}
  String get groupFormQtyInputFirst { switch (language) {
    case AppLanguage.korean:   return '수량 입력 후 확인 가능';
    case AppLanguage.english:  return 'Enter qty to proceed';
    case AppLanguage.japanese: return '数量入力後に確認可能';
    case AppLanguage.chinese:  return '输入数量后可确认';
    case AppLanguage.mongolian:return 'Тоог оруулж баталгаажуулна';
  }}
  String get groupFormMin5Required { switch (language) {
    case AppLanguage.korean:   return '최소 5인 이상 입력 필요';
    case AppLanguage.english:  return 'Minimum 5 people required';
    case AppLanguage.japanese: return '最低5名以上の入力が必要';
    case AppLanguage.chinese:  return '需要输入至少5人';
    case AppLanguage.mongolian:return 'Хамгийн багадаа 5 хүн хэрэгтэй';
  }}

  // ── 단체 커스텀 주문 추가 번역 키 ──────────────────────────────────

  String get selectColorHint { switch (language) {
    case AppLanguage.korean:   return '색상을 선택해주세요';
    case AppLanguage.english:  return 'Please select a color';
    case AppLanguage.japanese: return '色を選択してください';
    case AppLanguage.chinese:  return '请选择颜色';
    case AppLanguage.mongolian:return 'Өнгө сонгоно уу';
  }}
  String get bottomLengthSelectHint { switch (language) {
    case AppLanguage.korean:   return '하의 길이를 선택해주세요';
    case AppLanguage.english:  return 'Please select bottom length';
    case AppLanguage.japanese: return 'ボトムス丈を選択してください';
    case AppLanguage.chinese:  return '请选择下装长度';
    case AppLanguage.mongolian:return 'Доод хэсгийн уртыг сонгоно уу';
  }}
  String get teamNameRequired { switch (language) {
    case AppLanguage.korean:   return '팀/단체명을 입력해주세요';
    case AppLanguage.english:  return 'Please enter team/group name';
    case AppLanguage.japanese: return 'チーム/団体名を入力してください';
    case AppLanguage.chinese:  return '请输入队伍/团体名称';
    case AppLanguage.mongolian:return 'Багийн/бүлгийн нэрийг оруулна уу';
  }}
  String get phoneRequired { switch (language) {
    case AppLanguage.korean:   return '연락처를 입력해주세요';
    case AppLanguage.english:  return 'Please enter phone number';
    case AppLanguage.japanese: return '連絡先を入力してください';
    case AppLanguage.chinese:  return '请输入联系方式';
    case AppLanguage.mongolian:return 'Утасны дугаар оруулна уу';
  }}
  String get groupCustomTag { switch (language) {
    case AppLanguage.korean:   return '단체 커스텀';
    case AppLanguage.english:  return 'Group Custom';
    case AppLanguage.japanese: return '団体カスタム';
    case AppLanguage.chinese:  return '团体定制';
    case AppLanguage.mongolian:return 'Бүлгийн захиалга';
  }}
  String get teamNameFieldLabel { switch (language) {
    case AppLanguage.korean:   return '팀 / 단체명 *';
    case AppLanguage.english:  return 'Team / Group Name *';
    case AppLanguage.japanese: return 'チーム / 団体名 *';
    case AppLanguage.chinese:  return '队伍 / 团体名 *';
    case AppLanguage.mongolian:return 'Баг / Бүлгийн нэр *';
  }}
  String get managerNameFieldLabel { switch (language) {
    case AppLanguage.korean:   return '담당자 이름';
    case AppLanguage.english:  return 'Manager Name';
    case AppLanguage.japanese: return '担当者名';
    case AppLanguage.chinese:  return '负责人姓名';
    case AppLanguage.mongolian:return 'Хариуцлагатны нэр';
  }}
  String get phoneFieldLabel { switch (language) {
    case AppLanguage.korean:   return '연락처 *';
    case AppLanguage.english:  return 'Phone *';
    case AppLanguage.japanese: return '連絡先 *';
    case AppLanguage.chinese:  return '联系方式 *';
    case AppLanguage.mongolian:return 'Утас *';
  }}
  String get emailQuotationLabel { switch (language) {
    case AppLanguage.korean:   return '이메일 (견적서 수신)';
    case AppLanguage.english:  return 'Email (for quotation)';
    case AppLanguage.japanese: return 'メール（見積書受信）';
    case AppLanguage.chinese:  return '邮箱（接收报价单）';
    case AppLanguage.mongolian:return 'Имэйл (үнийн санал)';
  }}
  String get specialRequestLabel { switch (language) {
    case AppLanguage.korean:   return '특이사항 · 개인 요청';
    case AppLanguage.english:  return 'Special Requests';
    case AppLanguage.japanese: return '特記事項 · 個人要望';
    case AppLanguage.chinese:  return '特殊要求 · 个人请求';
    case AppLanguage.mongolian:return 'Тусгай хүсэлт';
  }}
  String get lengthApplyAllDesc { switch (language) {
    case AppLanguage.korean:   return '선택한 길이는 전체 인원에 동일하게 적용됩니다. 인원별로 다르게 원하시면 메모란에 기재해주세요.';
    case AppLanguage.english:  return 'Selected length applies to all members equally. For individual lengths, please note in the memo field.';
    case AppLanguage.japanese: return '選択した丈は全員に同様に適用されます。個別対応をご希望の場合はメモ欄にご記入ください。';
    case AppLanguage.chinese:  return '所选长度统一适用于所有成员。如需个别调整，请在备注栏注明。';
    case AppLanguage.mongolian:return 'Сонгосон урт бүх гишүүдэд адил хэрэглэгдэнэ. Тус тусын уртыг хүсвэл тэмдэглэлд бичнэ үү.';
  }}

  // ══════════════════════════════════════════════════════════════
  // GroupOrderFormScreen - 폼 필드 레이블/힌트
  // ══════════════════════════════════════════════════════════════
  String get groupFormTeamNameLabel { switch (language) {
    case AppLanguage.korean:   return '팀/단체명';
    case AppLanguage.english:  return 'Team/Group Name';
    case AppLanguage.japanese: return 'チーム/団体名';
    case AppLanguage.chinese:  return '队伍/团体名称';
    case AppLanguage.mongolian:return 'Баг/Бүлгийн нэр';
  }}
  String get groupFormTeamNameHint { switch (language) {
    case AppLanguage.korean:   return '예: 서울 런너스 클럽';
    case AppLanguage.english:  return 'e.g. Seoul Runners Club';
    case AppLanguage.japanese: return '例：ソウルランナーズクラブ';
    case AppLanguage.chinese:  return '例：首尔跑者俱乐部';
    case AppLanguage.mongolian:return 'жн: Seoul Runners Club';
  }}
  String get groupFormManagerNameLabel { switch (language) {
    case AppLanguage.korean:   return '담당자명';
    case AppLanguage.english:  return 'Contact Person';
    case AppLanguage.japanese: return '担当者名';
    case AppLanguage.chinese:  return '负责人姓名';
    case AppLanguage.mongolian:return 'Холбоо барих хүн';
  }}
  String get groupFormManagerNameHint { switch (language) {
    case AppLanguage.korean:   return '예: 홍길동';
    case AppLanguage.english:  return 'e.g. John Smith';
    case AppLanguage.japanese: return '例：山田太郎';
    case AppLanguage.chinese:  return '例：张三';
    case AppLanguage.mongolian:return 'жн: Батбаяр';
  }}
  String get groupFormPhoneLabel { switch (language) {
    case AppLanguage.korean:   return '연락처';
    case AppLanguage.english:  return 'Phone Number';
    case AppLanguage.japanese: return '連絡先';
    case AppLanguage.chinese:  return '联系方式';
    case AppLanguage.mongolian:return 'Утасны дугаар';
  }}
  String get groupFormPhoneHint { switch (language) {
    case AppLanguage.korean:   return '예: 010-1234-5678';
    case AppLanguage.english:  return 'e.g. +82-10-1234-5678';
    case AppLanguage.japanese: return '例：090-1234-5678';
    case AppLanguage.chinese:  return '例：138-0000-0000';
    case AppLanguage.mongolian:return 'жн: 9911-1234';
  }}
  String get groupFormEmailLabel { switch (language) {
    case AppLanguage.korean:   return '이메일 (견적서 수신)';
    case AppLanguage.english:  return 'Email (for quote)';
    case AppLanguage.japanese: return 'メール（見積書受信）';
    case AppLanguage.chinese:  return '邮箱（接收报价单）';
    case AppLanguage.mongolian:return 'Имэйл (үнийн санал авах)';
  }}
  String get groupFormEmailHint { switch (language) {
    case AppLanguage.korean:   return '예: team@example.com';
    case AppLanguage.english:  return 'e.g. team@example.com';
    case AppLanguage.japanese: return '例：team@example.com';
    case AppLanguage.chinese:  return '例：team@example.com';
    case AppLanguage.mongolian:return 'жн: team@example.com';
  }}
  String get groupFormMemoLabel { switch (language) {
    case AppLanguage.korean:   return '기타 요청사항';
    case AppLanguage.english:  return 'Additional Requests';
    case AppLanguage.japanese: return 'その他ご要望';
    case AppLanguage.chinese:  return '其他要求';
    case AppLanguage.mongolian:return 'Бусад хүсэлт';
  }}
  String get groupFormMemoHint { switch (language) {
    case AppLanguage.korean:   return '허리밴드 컬러 변경 내용, 로고 파일 전송 방법 등을 기재해주세요.';
    case AppLanguage.english:  return 'Waistband color change, logo file delivery method, etc.';
    case AppLanguage.japanese: return 'ウエストバンドカラー変更内容、ロゴファイル送付方法などをご記入ください。';
    case AppLanguage.chinese:  return '请填写腰带颜色变更内容、标志文件传送方式等。';
    case AppLanguage.mongolian:return 'Бүсний өнгийн өөрчлөлт, лого файл дамжуулах арга зэргийг бичнэ үү.';
  }}
  String get groupFormMaleLabel { switch (language) {
    case AppLanguage.korean:   return '남자';
    case AppLanguage.english:  return 'Male';
    case AppLanguage.japanese: return '男性';
    case AppLanguage.chinese:  return '男';
    case AppLanguage.mongolian:return 'Эрэгтэй';
  }}
  String get groupFormFemaleLabel { switch (language) {
    case AppLanguage.korean:   return '여자';
    case AppLanguage.english:  return 'Female';
    case AppLanguage.japanese: return '女性';
    case AppLanguage.chinese:  return '女';
    case AppLanguage.mongolian:return 'Эмэгтэй';
  }}
  String get groupFormBottomColorLabel { switch (language) {
    case AppLanguage.korean:   return '하의 색상 선택';
    case AppLanguage.english:  return 'Bottom Color';
    case AppLanguage.japanese: return 'ボトムカラー選択';
    case AppLanguage.chinese:  return '下装颜色选择';
    case AppLanguage.mongolian:return 'Доод хэсгийн өнгө';
  }}
  String get groupFormWaistbandColorLabel { switch (language) {
    case AppLanguage.korean:   return '허리밴드 컬러 선택 (필수)';
    case AppLanguage.english:  return 'Waistband Color (required)';
    case AppLanguage.japanese: return 'ウエストバンドカラー選択（必須）';
    case AppLanguage.chinese:  return '腰带颜色选择（必填）';
    case AppLanguage.mongolian:return 'Бүсний өнгө (заавал)';
  }}
  String get groupFormTopSizeLabel { switch (language) {
    case AppLanguage.korean:   return '상의 사이즈';
    case AppLanguage.english:  return 'Top Size';
    case AppLanguage.japanese: return 'トップスサイズ';
    case AppLanguage.chinese:  return '上衣尺码';
    case AppLanguage.mongolian:return 'Дээд хэсгийн хэмжээ';
  }}
  String get groupFormBottomSizeLabel { switch (language) {
    case AppLanguage.korean:   return '하의 사이즈';
    case AppLanguage.english:  return 'Bottom Size';
    case AppLanguage.japanese: return 'ボトムスサイズ';
    case AppLanguage.chinese:  return '下装尺码';
    case AppLanguage.mongolian:return 'Доод хэсгийн хэмжээ';
  }}
  String get groupFormViewMoreBtn { switch (language) {
    case AppLanguage.korean:   return '보러가기';
    case AppLanguage.english:  return 'View';
    case AppLanguage.japanese: return '見る';
    case AppLanguage.chinese:  return '查看';
    case AppLanguage.mongolian:return 'Харах';
  }}
  String get groupFormAddressHint { switch (language) {
    case AppLanguage.korean:   return '주소 검색 버튼을 눌러 주소 입력';
    case AppLanguage.english:  return 'Press search to enter address';
    case AppLanguage.japanese: return '検索ボタンを押して住所を入力';
    case AppLanguage.chinese:  return '按搜索按钮输入地址';
    case AppLanguage.mongolian:return 'Хайх товч дарж хаяг оруулна';
  }}
  String get groupFormDetailAddressHint { switch (language) {
    case AppLanguage.korean:   return '상세 주소 입력 (동/호수 등)';
    case AppLanguage.english:  return 'Enter detailed address (unit/floor)';
    case AppLanguage.japanese: return '詳細住所入力（部屋番号など）';
    case AppLanguage.chinese:  return '输入详细地址（房间号等）';
    case AppLanguage.mongolian:return 'Дэлгэрэнгүй хаяг оруулах (орц/тасалгаа)';
  }}
  String get groupFormNameInputHint { switch (language) {
    case AppLanguage.korean:   return '이름 입력';
    case AppLanguage.english:  return 'Enter name';
    case AppLanguage.japanese: return '名前入力';
    case AppLanguage.chinese:  return '输入姓名';
    case AppLanguage.mongolian:return 'Нэр оруулах';
  }}
  String get groupFormSelectHint { switch (language) {
    case AppLanguage.korean:   return '선택';
    case AppLanguage.english:  return 'Select';
    case AppLanguage.japanese: return '選択';
    case AppLanguage.chinese:  return '选择';
    case AppLanguage.mongolian:return 'Сонгох';
  }}
  String get groupFormSizeCustomHint { switch (language) {
    case AppLanguage.korean:   return '예: 100, 허리32 등';
    case AppLanguage.english:  return 'e.g. waist32, chest100';
    case AppLanguage.japanese: return '例：100、ウエスト32など';
    case AppLanguage.chinese:  return '例：100，腰围32等';
    case AppLanguage.mongolian:return 'жн: 100, хөндлөн32';
  }}
  String get groupFormDiscount10 { switch (language) {
    case AppLanguage.korean:   return '10% 할인';
    case AppLanguage.english:  return '10% off';
    case AppLanguage.japanese: return '10%割引';
    case AppLanguage.chinese:  return '九折优惠';
    case AppLanguage.mongolian:return '10% хөнгөлөлт';
  }}
  String get groupFormDiscount5 { switch (language) {
    case AppLanguage.korean:   return '5% 할인';
    case AppLanguage.english:  return '5% off';
    case AppLanguage.japanese: return '5%割引';
    case AppLanguage.chinese:  return '九五折优惠';
    case AppLanguage.mongolian:return '5% хөнгөлөлт';
  }}
  String get groupFormNoDiscount { switch (language) {
    case AppLanguage.korean:   return '할인 없음';
    case AppLanguage.english:  return 'No discount';
    case AppLanguage.japanese: return '割引なし';
    case AppLanguage.chinese:  return '无折扣';
    case AppLanguage.mongolian:return 'Хөнгөлөлт байхгүй';
  }}
  String get groupFormDiscountBadge20 { switch (language) {
    case AppLanguage.korean:   return '20% 할인 적용';
    case AppLanguage.english:  return '20% discount applied';
    case AppLanguage.japanese: return '20%割引適用';
    case AppLanguage.chinese:  return '享八折优惠';
    case AppLanguage.mongolian:return '20% хөнгөлөлт хэрэглэгдлээ';
  }}
  String get groupFormDiscountBadge10 { switch (language) {
    case AppLanguage.korean:   return '10% 할인 적용';
    case AppLanguage.english:  return '10% discount applied';
    case AppLanguage.japanese: return '10%割引適用';
    case AppLanguage.chinese:  return '享九折优惠';
    case AppLanguage.mongolian:return '10% хөнгөлөлт хэрэглэгдлээ';
  }}
  String get groupFormNamePrintBadge { switch (language) {
    case AppLanguage.korean:   return '이름 인쇄 가능';
    case AppLanguage.english:  return 'Name printing available';
    case AppLanguage.japanese: return '名前印刷可能';
    case AppLanguage.chinese:  return '可打印姓名';
    case AppLanguage.mongolian:return 'Нэр хэвлэх боломжтой';
  }}
  String get groupFormGroupMakeBadge { switch (language) {
    case AppLanguage.korean:   return '단체 제작 가능';
    case AppLanguage.english:  return 'Group production available';
    case AppLanguage.japanese: return '団体製作可能';
    case AppLanguage.chinese:  return '可团体制作';
    case AppLanguage.mongolian:return 'Бүлгийн үйлдвэрлэл боломжтой';
  }}
  String get groupFormBelow5Badge { switch (language) {
    case AppLanguage.korean:   return '5명 미만';
    case AppLanguage.english:  return 'Under 5 people';
    case AppLanguage.japanese: return '5名未満';
    case AppLanguage.chinese:  return '不足5人';
    case AppLanguage.mongolian:return '5-аас доош хүн';
  }}
  String get groupFormConfirmedSuffix { switch (language) {
    case AppLanguage.korean:   return '확정됨';
    case AppLanguage.english:  return 'confirmed';
    case AppLanguage.japanese: return '確定済み';
    case AppLanguage.chinese:  return '已确认';
    case AppLanguage.mongolian:return 'баталгаажсан';
  }}
  String get groupFormConfirmSuffix { switch (language) {
    case AppLanguage.korean:   return '으로 확인';
    case AppLanguage.english:  return 'confirmed';
    case AppLanguage.japanese: return 'で確認';
    case AppLanguage.chinese:  return '确认';
    case AppLanguage.mongolian:return 'баталгаажуулах';
  }}
  String get groupFormCurrentPeople { switch (language) {
    case AppLanguage.korean:   return '현재 인원';
    case AppLanguage.english:  return 'Current count';
    case AppLanguage.japanese: return '現在の人数';
    case AppLanguage.chinese:  return '当前人数';
    case AppLanguage.mongolian:return 'Одоогийн тоо';
  }}

  // ══════════════════════════════════════════════════════════════
  // GroupCustomOrderScreen 추가 키
  // ══════════════════════════════════════════════════════════════
  String get customOrderMemoHint { switch (language) {
    case AppLanguage.korean:   return '요청 사항이나 특이사항을 입력해주세요\n예: 10번 인원은 5부 길이로 변경 요청';
    case AppLanguage.english:  return 'Enter special requests\ne.g. Person #10 requests shorter length';
    case AppLanguage.japanese: return 'ご要望や特記事項を入力してください\n例：10番の人は5部丈に変更希望';
    case AppLanguage.chinese:  return '请输入特殊要求\n例：第10位成员申请改为较短长度';
    case AppLanguage.mongolian:return 'Тусгай хүсэлт оруулна уу\nжн: 10-р гишүүн богино уртыг хүсч байна';
  }}
  String get customOrderPersonMemoHint { switch (language) {
    case AppLanguage.korean:   return '예) 어깨가 넓어서 한 사이즈 크게, 왼쪽 소매 번호 인쇄 등';
    case AppLanguage.english:  return 'e.g. broad shoulders, one size up; print number on left sleeve';
    case AppLanguage.japanese: return '例）肩幅が広いため一サイズ大きく、左袖に番号印刷など';
    case AppLanguage.chinese:  return '例）肩宽需大一码，左袖打印编号等';
    case AppLanguage.mongolian:return 'жн: мөр өргөн тул нэг хэмжээ том, зүүн ханцуйнд дугаар хэвлэх';
  }}
  // ══════════════════════════════════════════════════════════════
  // GroupCustomOrderScreen - PersonRowWidget & 추가 UI 키
  // ══════════════════════════════════════════════════════════════
  String get customNameRequiredHint { switch (language) {
    case AppLanguage.korean:   return '이름 입력 (필수)';
    case AppLanguage.english:  return 'Enter name (required)';
    case AppLanguage.japanese: return '名前を入力（必須）';
    case AppLanguage.chinese:  return '输入姓名（必填）';
    case AppLanguage.mongolian:return 'Нэр оруулах (заавал)';
  }}
  String get customNameOptionalHint { switch (language) {
    case AppLanguage.korean:   return '이름 입력 (선택)';
    case AppLanguage.english:  return 'Enter name (optional)';
    case AppLanguage.japanese: return '名前を入力（任意）';
    case AppLanguage.chinese:  return '输入姓名（可选）';
    case AppLanguage.mongolian:return 'Нэр оруулах (сонголтот)';
  }}
  String get customSizeSectionLabel { switch (language) {
    case AppLanguage.korean:   return '사이즈 선택';
    case AppLanguage.english:  return 'Select Size';
    case AppLanguage.japanese: return 'サイズ選択';
    case AppLanguage.chinese:  return '选择尺码';
    case AppLanguage.mongolian:return 'Хэмжээ сонгох';
  }}
  String get customMeasureInputTitle { switch (language) {
    case AppLanguage.korean:   return '실측 사이즈 입력';
    case AppLanguage.english:  return 'Enter Custom Measurements';
    case AppLanguage.japanese: return '実寸サイズ入力';
    case AppLanguage.chinese:  return '输入实测尺码';
    case AppLanguage.mongolian:return 'Хэмжилт оруулах';
  }}
  String get customMeasureInputDesc { switch (language) {
    case AppLanguage.korean:   return '사이즈표에 맞는 사이즈가 없을 경우 입력해 주세요';
    case AppLanguage.english:  return 'Enter if no matching size in the size chart';
    case AppLanguage.japanese: return 'サイズ表に合うサイズがない場合に入力してください';
    case AppLanguage.chinese:  return '如尺码表中没有合适尺码，请输入';
    case AppLanguage.mongolian:return 'Хэмжээний хүснэгтэд тохирох хэмжээ байхгүй бол оруулна уу';
  }}
  String get customHeightLabel { switch (language) {
    case AppLanguage.korean:   return '키';
    case AppLanguage.english:  return 'Height';
    case AppLanguage.japanese: return '身長';
    case AppLanguage.chinese:  return '身高';
    case AppLanguage.mongolian:return 'Өндөр';
  }}
  String get customWeightLabel { switch (language) {
    case AppLanguage.korean:   return '몸무게';
    case AppLanguage.english:  return 'Weight';
    case AppLanguage.japanese: return '体重';
    case AppLanguage.chinese:  return '体重';
    case AppLanguage.mongolian:return 'Жин';
  }}
  String get customThighLabel { switch (language) {
    case AppLanguage.korean:   return '허벅지둘레';
    case AppLanguage.english:  return 'Thigh circumference';
    case AppLanguage.japanese: return '太もも周り';
    case AppLanguage.chinese:  return '大腿围';
    case AppLanguage.mongolian:return 'Гуяны тойрог';
  }}
  String get customMaleLabel { switch (language) {
    case AppLanguage.korean:   return '♂ 남';
    case AppLanguage.english:  return '♂ M';
    case AppLanguage.japanese: return '♂ 男';
    case AppLanguage.chinese:  return '♂ 男';
    case AppLanguage.mongolian:return '♂ Эр';
  }}
  String get customFemaleLabel { switch (language) {
    case AppLanguage.korean:   return '♀ 여';
    case AppLanguage.english:  return '♀ F';
    case AppLanguage.japanese: return '♀ 女';
    case AppLanguage.chinese:  return '♀ 女';
    case AppLanguage.mongolian:return '♀ Эм';
  }}
  String get customMaleGender { switch (language) {
    case AppLanguage.korean:   return '남';
    case AppLanguage.english:  return 'M';
    case AppLanguage.japanese: return '男';
    case AppLanguage.chinese:  return '男';
    case AppLanguage.mongolian:return 'Эр';
  }}
  String get customFemaleGender { switch (language) {
    case AppLanguage.korean:   return '여';
    case AppLanguage.english:  return 'F';
    case AppLanguage.japanese: return '女';
    case AppLanguage.chinese:  return '女';
    case AppLanguage.mongolian:return 'Эм';
  }}
  String get customBottomLengthInfo { switch (language) {
    case AppLanguage.korean:   return '하의 기장(길이)은 위의 \'하의 길이 선택\'에서 선택하시면\n전체 인원에 동일하게 적용됩니다.';
    case AppLanguage.english:  return 'Selecting bottom length above applies to all members.';
    case AppLanguage.japanese: return '下部の丈を上の「下部の丈選択」で選ぶと全員に適用されます。';
    case AppLanguage.chinese:  return '在上方"下装长度选择"中选择后，将统一适用于所有人员。';
    case AppLanguage.mongolian:return 'Доод уртыг сонгоход бүх гишүүдэд адил хэрэглэгдэнэ.';
  }}
  String get customTenPersonNameRequired { switch (language) {
    case AppLanguage.korean:   return '10명 이상 주문 시 각 인원의 이름 입력이 필요합니다.';
    case AppLanguage.english:  return 'Name entry required for orders of 10 or more people.';
    case AppLanguage.japanese: return '10名以上の注文時、各人員の名前入力が必要です。';
    case AppLanguage.chinese:  return '10人以上订单时，需要输入每位人员的姓名。';
    case AppLanguage.mongolian:return '10 ба түүнээс дээш захиалгад бүх гишүүний нэр шаардлагатай.';
  }}
  String get customTenPersonNameRequiredSnack { switch (language) {
    case AppLanguage.korean:   return '10명 이상 주문 시 모든 인원의 이름을 입력해주세요';
    case AppLanguage.english:  return 'Please enter names for all members in orders of 10+';
    case AppLanguage.japanese: return '10名以上の場合は全員の名前を入力してください';
    case AppLanguage.chinese:  return '10人以上时请输入所有人员的姓名';
    case AppLanguage.mongolian:return '10-аас дээш захиалгад бүх гишүүний нэрийг оруулна уу';
  }}
  String customTenPersonNameRequiredSnackFull(int count) { switch (language) {
    case AppLanguage.korean:   return '10명 이상 주문 시 모든 인원의 이름을 입력해주세요 ($count명 미입력)';
    case AppLanguage.english:  return 'Enter names for all members ($count missing)';
    case AppLanguage.japanese: return '10名以上の場合は全員の名前を入力してください（$count名未入力）';
    case AppLanguage.chinese:  return '10人以上时请输入所有人员的姓名（未输入$count名）';
    case AppLanguage.mongolian:return '10-аас дээш захиалгад бүх гишүүний нэрийг оруулна уу ($count дутуу)';
  }}
  String get customSizeTableHeader { switch (language) {
    case AppLanguage.korean:   return '사이즈';
    case AppLanguage.english:  return 'Size';
    case AppLanguage.japanese: return 'サイズ';
    case AppLanguage.chinese:  return '尺码';
    case AppLanguage.mongolian:return 'Хэмжээ';
  }}
  String get customSizeTableWaist { switch (language) {
    case AppLanguage.korean:   return '허리(cm)';
    case AppLanguage.english:  return 'Waist(cm)';
    case AppLanguage.japanese: return 'ウエスト(cm)';
    case AppLanguage.chinese:  return '腰围(cm)';
    case AppLanguage.mongolian:return 'Бүс(cm)';
  }}
  String get customSizeTableHip { switch (language) {
    case AppLanguage.korean:   return '엉덩이(cm)';
    case AppLanguage.english:  return 'Hip(cm)';
    case AppLanguage.japanese: return '腰回り(cm)';
    case AppLanguage.chinese:  return '臀围(cm)';
    case AppLanguage.mongolian:return 'Ташааны тойрог(cm)';
  }}
  String get customSizeTableThigh { switch (language) {
    case AppLanguage.korean:   return '허벅지(cm)';
    case AppLanguage.english:  return 'Thigh(cm)';
    case AppLanguage.japanese: return '太もも(cm)';
    case AppLanguage.chinese:  return '大腿围(cm)';
    case AppLanguage.mongolian:return 'Гуяны тойрог(cm)';
  }}

  // ══════════════════════════════════════════════════════════════
  // ProductDetailScreen - _GroupOrderGuideSheet 사이즈 표 헤더
  // ══════════════════════════════════════════════════════════════
  String get sheetSizeTableSize { switch (language) {
    case AppLanguage.korean:   return '사이즈';
    case AppLanguage.english:  return 'Size';
    case AppLanguage.japanese: return 'サイズ';
    case AppLanguage.chinese:  return '尺码';
    case AppLanguage.mongolian:return 'Хэмжээ';
  }}
  String get sheetSizeTableChest { switch (language) {
    case AppLanguage.korean:   return '가슴(cm)';
    case AppLanguage.english:  return 'Chest(cm)';
    case AppLanguage.japanese: return '胸囲(cm)';
    case AppLanguage.chinese:  return '胸围(cm)';
    case AppLanguage.mongolian:return 'Цээж(cm)';
  }}
  String get sheetSizeTableWaist { switch (language) {
    case AppLanguage.korean:   return '허리(cm)';
    case AppLanguage.english:  return 'Waist(cm)';
    case AppLanguage.japanese: return 'ウエスト(cm)';
    case AppLanguage.chinese:  return '腰围(cm)';
    case AppLanguage.mongolian:return 'Бүс(cm)';
  }}
  String get sheetSizeTableHip { switch (language) {
    case AppLanguage.korean:   return '엉덩이(cm)';
    case AppLanguage.english:  return 'Hip(cm)';
    case AppLanguage.japanese: return '腰回り(cm)';
    case AppLanguage.chinese:  return '臀围(cm)';
    case AppLanguage.mongolian:return 'Ташаа(cm)';
  }}
  String get sheetSizeTableHeight { switch (language) {
    case AppLanguage.korean:   return '키(cm)';
    case AppLanguage.english:  return 'Height(cm)';
    case AppLanguage.japanese: return '身長(cm)';
    case AppLanguage.chinese:  return '身高(cm)';
    case AppLanguage.mongolian:return 'Өндөр(cm)';
  }}

  // ── signup ──
  String get signupBenefitTitle {
    switch (language) {
      case AppLanguage.english: return '2FIT MALL Member Benefits';
      case AppLanguage.japanese: return '2FIT MALL 会員特典';
      case AppLanguage.chinese: return '2FIT MALL 会员福利';
      case AppLanguage.mongolian: return '2FIT MALL гишүүний давуу эрх';
      case AppLanguage.korean: return '2FIT MALL 회원 혜택';
    }
  }
  String get signupBenefitDesc {
    switch (language) {
      case AppLanguage.english: return 'Get 1,000P instantly + New member discount coupon';
      case AppLanguage.japanese: return '即時1,000P付与 + 新規会員割引クーポン';
      case AppLanguage.chinese: return '立即获得1,000P + 新会员折扣券';
      case AppLanguage.mongolian: return 'Нэн даруй 1,000P олгох + шинэ гишүүний хөнгөлөлтийн купон';
      case AppLanguage.korean: return '가입 즉시 1,000P 지급 + 신규회원 할인쿠폰';
    }
  }
  String get signupNameLabel {
    switch (language) {
      case AppLanguage.english: return 'Name *';
      case AppLanguage.japanese: return 'お名前 *';
      case AppLanguage.chinese: return '姓名 *';
      case AppLanguage.mongolian: return 'Нэр *';
      case AppLanguage.korean: return '이름 *';
    }
  }
  String get signupNameError {
    switch (language) {
      case AppLanguage.english: return 'Name must be at least 2 characters.';
      case AppLanguage.japanese: return '名前は2文字以上入力してください。';
      case AppLanguage.chinese: return '请输入至少2个字符的姓名。';
      case AppLanguage.mongolian: return 'Нэр нь дор хаяж 2 тэмдэгт байх ёстой.';
      case AppLanguage.korean: return '이름은 2자 이상 입력해주세요.';
    }
  }
  String get signupEmailLabel {
    switch (language) {
      case AppLanguage.english: return 'Email *';
      case AppLanguage.japanese: return 'メール *';
      case AppLanguage.chinese: return '邮箱 *';
      case AppLanguage.mongolian: return 'Имэйл *';
      case AppLanguage.korean: return '이메일 *';
    }
  }
  String get signupEmailError {
    switch (language) {
      case AppLanguage.english: return 'Please enter a valid email address.';
      case AppLanguage.japanese: return '有効なメールアドレスを入力してください。';
      case AppLanguage.chinese: return '请输入有效的电子邮件地址。';
      case AppLanguage.mongolian: return 'Зөв имэйл хаяг оруулна уу.';
      case AppLanguage.korean: return '유효한 이메일 주소를 입력해주세요.';
    }
  }
  String get signupPhoneLabel {
    switch (language) {
      case AppLanguage.english: return 'Mobile Number';
      case AppLanguage.japanese: return '携帯電話番号';
      case AppLanguage.chinese: return '手机号码';
      case AppLanguage.mongolian: return 'Гар утасны дугаар';
      case AppLanguage.korean: return '휴대폰 번호';
    }
  }
  String get signupPasswordLabel {
    switch (language) {
      case AppLanguage.english: return 'Password *';
      case AppLanguage.japanese: return 'パスワード *';
      case AppLanguage.chinese: return '密码 *';
      case AppLanguage.mongolian: return 'Нууц үг *';
      case AppLanguage.korean: return '비밀번호 *';
    }
  }
  String get signupPasswordError {
    switch (language) {
      case AppLanguage.english: return 'Password must be at least 6 characters.';
      case AppLanguage.japanese: return 'パスワードは6文字以上にしてください。';
      case AppLanguage.chinese: return '密码必须至少6个字符。';
      case AppLanguage.mongolian: return 'Нууц үг нь дор хаяж 6 тэмдэгт байх ёстой.';
      case AppLanguage.korean: return '비밀번호는 6자 이상이어야 합니다.';
    }
  }
  String get signupConfirmPasswordLabel {
    switch (language) {
      case AppLanguage.english: return 'Confirm Password *';
      case AppLanguage.japanese: return 'パスワード確認 *';
      case AppLanguage.chinese: return '确认密码 *';
      case AppLanguage.mongolian: return 'Нууц үг баталгаажуулах *';
      case AppLanguage.korean: return '비밀번호 확인 *';
    }
  }
  String get signupConfirmPasswordHint {
    switch (language) {
      case AppLanguage.english: return 'Re-enter your password';
      case AppLanguage.japanese: return 'パスワードを再入力してください';
      case AppLanguage.chinese: return '请再次输入密码';
      case AppLanguage.mongolian: return 'Нууц үгээ дахин оруулна уу';
      case AppLanguage.korean: return '비밀번호를 다시 입력해주세요';
    }
  }
  String get signupConfirmPasswordError {
    switch (language) {
      case AppLanguage.english: return 'Passwords do not match.';
      case AppLanguage.japanese: return 'パスワードが一致しません。';
      case AppLanguage.chinese: return '密码不匹配。';
      case AppLanguage.mongolian: return 'Нууц үг таарахгүй байна.';
      case AppLanguage.korean: return '비밀번호가 일치하지 않습니다.';
    }
  }
  String get signupSubmitBtn {
    switch (language) {
      case AppLanguage.english: return 'Complete Sign Up';
      case AppLanguage.japanese: return '会員登録を完了';
      case AppLanguage.chinese: return '完成注册';
      case AppLanguage.mongolian: return 'Бүртгэл дуусгах';
      case AppLanguage.korean: return '회원가입 완료';
    }
  }
  String get signupAlreadyHaveAccount {
    switch (language) {
      case AppLanguage.english: return 'Already have an account? ';
      case AppLanguage.japanese: return 'すでにアカウントをお持ちですか？ ';
      case AppLanguage.chinese: return '已有账号？ ';
      case AppLanguage.mongolian: return 'Аль хэдийн данстай юу? ';
      case AppLanguage.korean: return '이미 계정이 있으신가요? ';
    }
  }
  String get signupTermsTitle {
    switch (language) {
      case AppLanguage.english: return 'Terms of Agreement';
      case AppLanguage.japanese: return '利用規約同意';
      case AppLanguage.chinese: return '条款协议';
      case AppLanguage.mongolian: return 'Нөхцөл тохиролцоо';
      case AppLanguage.korean: return '약관 동의';
    }
  }
  String get signupAgreeAll {
    switch (language) {
      case AppLanguage.english: return 'Agree to All';
      case AppLanguage.japanese: return '全て同意';
      case AppLanguage.chinese: return '全部同意';
      case AppLanguage.mongolian: return 'Бүгдийг зөвшөөрөх';
      case AppLanguage.korean: return '전체 동의';
    }
  }
  String get signupTermsRequired {
    switch (language) {
      case AppLanguage.english: return '[Required] Terms of Service Agreement';
      case AppLanguage.japanese: return '【必須】利用規約同意';
      case AppLanguage.chinese: return '[必填] 服务条款同意';
      case AppLanguage.mongolian: return '[Заавал] Үйлчилгээний нөхцөл зөвшөөрөх';
      case AppLanguage.korean: return '[필수] 이용약관 동의';
    }
  }
  String get signupPrivacyRequired {
    switch (language) {
      case AppLanguage.english: return '[Required] Privacy Policy Agreement';
      case AppLanguage.japanese: return '【必須】個人情報処理方針同意';
      case AppLanguage.chinese: return '[必填] 隐私政策同意';
      case AppLanguage.mongolian: return '[Заавал] Нууцлалын бодлогын зөвшөөрөл';
      case AppLanguage.korean: return '[필수] 개인정보 처리방침 동의';
    }
  }
  String get signupMarketingOptional {
    switch (language) {
      case AppLanguage.english: return '[Optional] Marketing Information Consent';
      case AppLanguage.japanese: return '【任意】マーケティング情報受信同意';
      case AppLanguage.chinese: return '[可选] 营销信息接收同意';
      case AppLanguage.mongolian: return '[Сонголтот] Маркетингийн мэдээллийг хүлээн авах зөвшөөрөл';
      case AppLanguage.korean: return '[선택] 마케팅 정보 수신 동의';
    }
  }
  String get signupRequiredTermsError {
    switch (language) {
      case AppLanguage.english: return 'Please agree to the required terms.';
      case AppLanguage.japanese: return '必須約款に同意してください。';
      case AppLanguage.chinese: return '请同意必填条款。';
      case AppLanguage.mongolian: return 'Заавал шаардагдах нөхцөлд зөвшөөрнө үү.';
      case AppLanguage.korean: return '필수 약관에 동의해주세요.';
    }
  }
  String get signupSuccessMsg {
    switch (language) {
      case AppLanguage.english: return 'Sign up complete! 1,000P bonus points have been awarded 🎉';
      case AppLanguage.japanese: return '会員登録が完了しました！1,000Pボーナスポイントが付与されました🎉';
      case AppLanguage.chinese: return '注册完成！已获得1,000P积分奖励🎉';
      case AppLanguage.mongolian: return 'Бүртгэл амжилттай! 1,000P урамшуулал олгогдлоо 🎉';
      case AppLanguage.korean: return '회원가입이 완료되었습니다! 가입 축하 포인트 1,000P가 지급되었습니다 🎉';
    }
  }
  String get signupFailMsg {
    switch (language) {
      case AppLanguage.english: return 'Sign up failed. Please try again.';
      case AppLanguage.japanese: return '会員登録に失敗しました。もう一度お試しください。';
      case AppLanguage.chinese: return '注册失败。请重试。';
      case AppLanguage.mongolian: return 'Бүртгэл амжилтгүй болсон. Дахин оролдоно уу.';
      case AppLanguage.korean: return '회원가입에 실패했습니다. 다시 시도해주세요.';
    }
  }

  // ── signup extended keys ──
  String get signupPasswordStrengthVeryWeak {
    switch (language) {
      case AppLanguage.english: return 'Very Weak';
      case AppLanguage.japanese: return '非常に弱い';
      case AppLanguage.chinese: return '非常弱';
      case AppLanguage.mongolian: return 'Маш сул';
      case AppLanguage.korean: return '매우 약함';
    }
  }
  String get signupPasswordStrengthWeak {
    switch (language) {
      case AppLanguage.english: return 'Weak';
      case AppLanguage.japanese: return '弱い';
      case AppLanguage.chinese: return '弱';
      case AppLanguage.mongolian: return 'Сул';
      case AppLanguage.korean: return '약함';
    }
  }
  String get signupPasswordStrengthFair {
    switch (language) {
      case AppLanguage.english: return 'Fair';
      case AppLanguage.japanese: return '普通';
      case AppLanguage.chinese: return '一般';
      case AppLanguage.mongolian: return 'Дунд';
      case AppLanguage.korean: return '보통';
    }
  }
  String get signupPasswordStrengthStrong {
    switch (language) {
      case AppLanguage.english: return 'Strong';
      case AppLanguage.japanese: return '強い';
      case AppLanguage.chinese: return '强';
      case AppLanguage.mongolian: return 'Хүчтэй';
      case AppLanguage.korean: return '강함';
    }
  }
  String get signupPasswordStrengthVeryStrong {
    switch (language) {
      case AppLanguage.english: return 'Very Strong';
      case AppLanguage.japanese: return '非常に強い';
      case AppLanguage.chinese: return '非常强';
      case AppLanguage.mongolian: return 'Маш хүчтэй';
      case AppLanguage.korean: return '매우 강함';
    }
  }
  String get signupPasswordStrengthUppercase {
    switch (language) {
      case AppLanguage.english: return 'Uppercase letter';
      case AppLanguage.japanese: return '大文字';
      case AppLanguage.chinese: return '大写字母';
      case AppLanguage.mongolian: return 'Том үсэг';
      case AppLanguage.korean: return '대문자 포함';
    }
  }
  String get signupPasswordStrengthLowercase {
    switch (language) {
      case AppLanguage.english: return 'Lowercase letter';
      case AppLanguage.japanese: return '小文字';
      case AppLanguage.chinese: return '小写字母';
      case AppLanguage.mongolian: return 'Жижиг үсэг';
      case AppLanguage.korean: return '소문자 포함';
    }
  }
  String get signupPasswordStrengthNumber {
    switch (language) {
      case AppLanguage.english: return 'Number';
      case AppLanguage.japanese: return '数字';
      case AppLanguage.chinese: return '数字';
      case AppLanguage.mongolian: return 'Тоо';
      case AppLanguage.korean: return '숫자 포함';
    }
  }
  String get signupPasswordStrengthSpecial {
    switch (language) {
      case AppLanguage.english: return 'Special character';
      case AppLanguage.japanese: return '特殊文字';
      case AppLanguage.chinese: return '特殊字符';
      case AppLanguage.mongolian: return 'Тусгай тэмдэгт';
      case AppLanguage.korean: return '특수문자 포함';
    }
  }
  String get signupPasswordStrength8Chars {
    switch (language) {
      case AppLanguage.english: return 'At least 8 characters';
      case AppLanguage.japanese: return '8文字以上';
      case AppLanguage.chinese: return '至少8个字符';
      case AppLanguage.mongolian: return '8-аас дээш тэмдэгт';
      case AppLanguage.korean: return '8자 이상';
    }
  }
  String get signupInvalidEmail {
    switch (language) {
      case AppLanguage.english: return 'Invalid email format';
      case AppLanguage.japanese: return 'メール形式が正しくありません';
      case AppLanguage.chinese: return '邮箱格式不正确';
      case AppLanguage.mongolian: return 'Имэйлийн формат буруу байна';
      case AppLanguage.korean: return '이메일 형식이 올바르지 않습니다';
    }
  }
  String get signupEmailAvailable {
    switch (language) {
      case AppLanguage.english: return 'Email is available';
      case AppLanguage.japanese: return 'このメールは使用可能です';
      case AppLanguage.chinese: return '该邮箱可以使用';
      case AppLanguage.mongolian: return 'Имэйл ашиглах боломжтой';
      case AppLanguage.korean: return '사용 가능한 이메일입니다';
    }
  }
  String get signupEmailAlreadyUsed {
    switch (language) {
      case AppLanguage.english: return 'Email is already in use';
      case AppLanguage.japanese: return 'このメールは既に使用されています';
      case AppLanguage.chinese: return '该邮箱已被使用';
      case AppLanguage.mongolian: return 'Имэйл аль хэдийн ашиглагдсан байна';
      case AppLanguage.korean: return '이미 사용 중인 이메일입니다';
    }
  }
  String get signupCountrySelect {
    switch (language) {
      case AppLanguage.english: return 'Select Country';
      case AppLanguage.japanese: return '国を選択';
      case AppLanguage.chinese: return '选择国家';
      case AppLanguage.mongolian: return 'Улс сонгох';
      case AppLanguage.korean: return '국가 선택';
    }
  }
  String get signupTermsTitleShort {
    switch (language) {
      case AppLanguage.english: return 'Terms';
      case AppLanguage.japanese: return '規約';
      case AppLanguage.chinese: return '条款';
      case AppLanguage.mongolian: return 'Нөхцөл';
      case AppLanguage.korean: return '약관';
    }
  }
  String signupRateLimitSecondsMsg(int seconds) {
    switch (language) {
      case AppLanguage.english: return 'Please wait $seconds seconds';
      case AppLanguage.japanese: return '$seconds秒後に再試行してください';
      case AppLanguage.chinese: return '请等待$seconds秒';
      case AppLanguage.mongolian: return '$seconds секунд хүлээнэ үү';
      case AppLanguage.korean: return '$seconds초 후에 다시 시도해주세요';
    }
  }
  String get signupPasswordTooWeak {
    switch (language) {
      case AppLanguage.english: return 'Password is too weak';
      case AppLanguage.japanese: return 'パスワードが弱すぎます';
      case AppLanguage.chinese: return '密码太弱';
      case AppLanguage.mongolian: return 'Нууц үг хэт сул байна';
      case AppLanguage.korean: return '비밀번호가 너무 약합니다';
    }
  }
  String get signupEmailCheckFirst {
    switch (language) {
      case AppLanguage.english: return 'Please check email availability first';
      case AppLanguage.japanese: return 'まずメールの使用可否を確認してください';
      case AppLanguage.chinese: return '请先检查邮箱是否可用';
      case AppLanguage.mongolian: return 'Эхлээд имэйл шалгана уу';
      case AppLanguage.korean: return '먼저 이메일 중복 확인을 해주세요';
    }
  }
  String get signupTimeoutError {
    switch (language) {
      case AppLanguage.english: return 'Request timed out. Please try again.';
      case AppLanguage.japanese: return 'タイムアウトしました。もう一度お試しください。';
      case AppLanguage.chinese: return '请求超时，请重试。';
      case AppLanguage.mongolian: return 'Хүсэлт цаг хэтэрсэн. Дахин оролдоно уу.';
      case AppLanguage.korean: return '요청 시간이 초과되었습니다. 다시 시도해주세요.';
    }
  }
  String get signupPasswordSafetyHint {
    switch (language) {
      case AppLanguage.english: return 'Use a mix of letters, numbers, and special characters';
      case AppLanguage.japanese: return '文字・数字・記号を組み合わせてください';
      case AppLanguage.chinese: return '请结合使用字母、数字和特殊字符';
      case AppLanguage.mongolian: return 'Үсэг, тоо, тусгай тэмдэгтийг хослуулан ашиглана уу';
      case AppLanguage.korean: return '문자, 숫자, 특수문자를 조합하여 사용하세요';
    }
  }
  String get signupContinuousAttemptDetected {
    switch (language) {
      case AppLanguage.english: return 'Too many attempts detected';
      case AppLanguage.japanese: return '試行回数が多すぎます';
      case AppLanguage.chinese: return '检测到频繁尝试';
      case AppLanguage.mongolian: return 'Олон удаа оролдлого илэрсэн';
      case AppLanguage.korean: return '연속 시도가 감지되었습니다';
    }
  }
  String signupContinuousAttemptWait(int minutes, int seconds) {
    final timeStr = minutes > 0 ? '${minutes}분 ${seconds}초' : '${seconds}초';
    final timeStrEn = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
    switch (language) {
      case AppLanguage.english: return 'Please wait $timeStrEn before trying again';
      case AppLanguage.japanese: return '$timeStrEn後に再試行してください';
      case AppLanguage.chinese: return '请等待$timeStrEn后再试';
      case AppLanguage.mongolian: return '$timeStrEn хүлээгээд дахин оролдоно уу';
      case AppLanguage.korean: return '$timeStr 후에 다시 시도해주세요';
    }
  }
  String get signupNameEmptyError {
    switch (language) {
      case AppLanguage.english: return 'Name is required';
      case AppLanguage.japanese: return '名前を入力してください';
      case AppLanguage.chinese: return '请输入姓名';
      case AppLanguage.mongolian: return 'Нэр оруулах шаардлагатай';
      case AppLanguage.korean: return '이름을 입력해주세요';
    }
  }
  String get signupNameTooLong {
    switch (language) {
      case AppLanguage.english: return 'Name is too long';
      case AppLanguage.japanese: return '名前が長すぎます';
      case AppLanguage.chinese: return '名称太长';
      case AppLanguage.mongolian: return 'Нэр хэт урт байна';
      case AppLanguage.korean: return '이름이 너무 깁니다';
    }
  }
  String get signupNameFormatError {
    switch (language) {
      case AppLanguage.english: return 'Invalid name format';
      case AppLanguage.japanese: return '名前の形式が正しくありません';
      case AppLanguage.chinese: return '姓名格式不正确';
      case AppLanguage.mongolian: return 'Нэрний формат буруу байна';
      case AppLanguage.korean: return '이름 형식이 올바르지 않습니다';
    }
  }
  String get signupNameSpaceError {
    switch (language) {
      case AppLanguage.english: return 'Name cannot start or end with spaces';
      case AppLanguage.japanese: return '名前の前後にスペースを入れないでください';
      case AppLanguage.chinese: return '姓名前后不能有空格';
      case AppLanguage.mongolian: return 'Нэрний эхэн эсвэл төгсгөлд зай байж болохгүй';
      case AppLanguage.korean: return '이름 앞뒤에 공백이 있으면 안 됩니다';
    }
  }
  String signupRateLimitCountdown(int minutes, int seconds) {
    final timeStr = minutes > 0 ? '${minutes}분 ${seconds}초' : '${seconds}초';
    final timeStrEn = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
    switch (language) {
      case AppLanguage.english: return 'Too many requests. Try again in $timeStrEn.';
      case AppLanguage.japanese: return 'リクエストが多すぎます。$timeStrEn後にお試しください。';
      case AppLanguage.chinese: return '请求过多，请$timeStrEn后重试。';
      case AppLanguage.mongolian: return 'Хэт олон хүсэлт. $timeStrEn хойно дахин оролдоно уу.';
      case AppLanguage.korean: return '요청이 너무 많습니다. $timeStr 후에 다시 시도해주세요.';
    }
  }

  // ── category ──
  String get sortNewest {
    switch (language) {
      case AppLanguage.english: return 'Newest';
      case AppLanguage.japanese: return '新着順';
      case AppLanguage.chinese: return '最新';
      case AppLanguage.mongolian: return 'Шинэ';
      case AppLanguage.korean: return '최신순';
    }
  }
  String get sortNewArrival {
    switch (language) {
      case AppLanguage.english: return 'New Arrival';
      case AppLanguage.japanese: return '新着商品';
      case AppLanguage.chinese: return '新品';
      case AppLanguage.mongolian: return 'Шинэ бараа';
      case AppLanguage.korean: return '신상품';
    }
  }
  String get sortRating {
    switch (language) {
      case AppLanguage.english: return 'Rating';
      case AppLanguage.japanese: return '評価順';
      case AppLanguage.chinese: return '评分';
      case AppLanguage.mongolian: return 'Үнэлгээ';
      case AppLanguage.korean: return '별점순';
    }
  }
  String get filterSize {
    switch (language) {
      case AppLanguage.english: return 'Size';
      case AppLanguage.japanese: return 'サイズ';
      case AppLanguage.chinese: return '尺码';
      case AppLanguage.mongolian: return 'Хэмжээ';
      case AppLanguage.korean: return '사이즈';
    }
  }
  String get filterExtraOption {
    switch (language) {
      case AppLanguage.english: return 'Extra Options';
      case AppLanguage.japanese: return '追加オプション';
      case AppLanguage.chinese: return '附加选项';
      case AppLanguage.mongolian: return 'Нэмэлт сонголт';
      case AppLanguage.korean: return '추가 옵션';
    }
  }

  // ── custom order ──
  String get customOrderScreenTitle {
    switch (language) {
      case AppLanguage.english: return 'Custom Order';
      case AppLanguage.japanese: return 'カスタムオーダー';
      case AppLanguage.chinese: return '定制订单';
      case AppLanguage.mongolian: return 'Захиалгат захиалга';
      case AppLanguage.korean: return '커스텀 주문';
    }
  }
  String get customOrderGroupInfo {
    switch (language) {
      case AppLanguage.english: return 'Group Information';
      case AppLanguage.japanese: return 'グループ情報';
      case AppLanguage.chinese: return '团体信息';
      case AppLanguage.mongolian: return 'Бүлгийн мэдээлэл';
      case AppLanguage.korean: return '단체 정보';
    }
  }
  String get customOrderTeamName {
    switch (language) {
      case AppLanguage.english: return 'Team/Group Name';
      case AppLanguage.japanese: return 'チーム/グループ名';
      case AppLanguage.chinese: return '团队/团体名称';
      case AppLanguage.mongolian: return 'Багийн/Бүлгийн нэр';
      case AppLanguage.korean: return '팀/단체명';
    }
  }
  String get customOrderTeamNameHint {
    switch (language) {
      case AppLanguage.english: return 'e.g. ○○ Club';
      case AppLanguage.japanese: return '例: ○○クラブ';
      case AppLanguage.chinese: return '例如：○○俱乐部';
      case AppLanguage.mongolian: return 'жнь: ○○ клуб';
      case AppLanguage.korean: return '예: ○○ 클럽';
    }
  }
  String get customOrderTeamNameError {
    switch (language) {
      case AppLanguage.english: return 'Please enter team name';
      case AppLanguage.japanese: return 'チーム名を入力してください';
      case AppLanguage.chinese: return '请输入团队名称';
      case AppLanguage.mongolian: return 'Багийн нэрийг оруулна уу';
      case AppLanguage.korean: return '팀명을 입력해주세요';
    }
  }
  String get customOrderContact {
    switch (language) {
      case AppLanguage.english: return 'Manager Contact';
      case AppLanguage.japanese: return '担当者連絡先';
      case AppLanguage.chinese: return '负责人联系方式';
      case AppLanguage.mongolian: return 'Холбоо барих';
      case AppLanguage.korean: return '담당자 연락처';
    }
  }
  String get customOrderContactError {
    switch (language) {
      case AppLanguage.english: return 'Please enter contact';
      case AppLanguage.japanese: return '連絡先を入力してください';
      case AppLanguage.chinese: return '请输入联系方式';
      case AppLanguage.mongolian: return 'Холбоо барих мэдээлэл оруулна уу';
      case AppLanguage.korean: return '연락처를 입력해주세요';
    }
  }
  String get customOrderQty {
    switch (language) {
      case AppLanguage.english: return 'Order Quantity';
      case AppLanguage.japanese: return '注文数量';
      case AppLanguage.chinese: return '订购数量';
      case AppLanguage.mongolian: return 'Захиалгын тоо';
      case AppLanguage.korean: return '주문 수량';
    }
  }
  String get customOrderDeliveryAddr {
    switch (language) {
      case AppLanguage.english: return 'Delivery Address';
      case AppLanguage.japanese: return '配送先住所';
      case AppLanguage.chinese: return '收货地址';
      case AppLanguage.mongolian: return 'Хүргэлтийн хаяг';
      case AppLanguage.korean: return '배송 주소';
    }
  }
  String get customOrderDeliveryAddrHint {
    switch (language) {
      case AppLanguage.english: return 'Please enter delivery address';
      case AppLanguage.japanese: return '配送先住所を入力してください';
      case AppLanguage.chinese: return '请输入收货地址';
      case AppLanguage.mongolian: return 'Хүргэлтийн хаяг оруулна уу';
      case AppLanguage.korean: return '배송 주소를 입력해주세요';
    }
  }
  String get customOrderNote {
    switch (language) {
      case AppLanguage.english: return 'Custom orders are processed by our staff (1-2 business days).';
      case AppLanguage.japanese: return 'カスタムオーダーは担当者確認後に見積もりをお送りします。（営業日1〜2日以内）';
      case AppLanguage.chinese: return '定制订单由工作人员确认后提供报价。（1-2个工作日）';
      case AppLanguage.mongolian: return 'Захиалгат захиалга нь ажилтан шалгасны дараа үнийн санал өгнө. (1-2 ажлын өдөр)';
      case AppLanguage.korean: return '커스텀 주문은 담당자 확인 후 견적 안내가 진행됩니다. (영업일 1~2일 내)';
    }
  }

  // ── group order only ──
  String get groupOrderOnlyTitle {
    switch (language) {
      case AppLanguage.english: return 'Group Order Only';
      case AppLanguage.japanese: return '団体注文専用';
      case AppLanguage.chinese: return '团体专用订单';
      case AppLanguage.mongolian: return 'Бүлгийн захиалга';
      case AppLanguage.korean: return '단체주문 전용';
    }
  }
  String get groupOrderRegisterProduct {
    switch (language) {
      case AppLanguage.english: return 'Register Product';
      case AppLanguage.japanese: return '商品登録';
      case AppLanguage.chinese: return '注册商品';
      case AppLanguage.mongolian: return 'Бараа бүртгэх';
      case AppLanguage.korean: return '상품 등록';
    }
  }
  String get groupOrderProductAdded {
    switch (language) {
      case AppLanguage.english: return 'Product added! Select from Group Order tab.';
      case AppLanguage.japanese: return '商品が登録されました！団体注文タブから選択してください。';
      case AppLanguage.chinese: return '商品已添加！请在团体订单标签中选择。';
      case AppLanguage.mongolian: return 'Бараа нэмэгдсэн! Бүлгийн захиалгын хуудаснаас сонгоно уу.';
      case AppLanguage.korean: return '상품이 등록되었습니다! 단체주문 탭에서 선택하세요.';
    }
  }
  String get groupOrderSelectProduct {
    switch (language) {
      case AppLanguage.english: return 'Please select a product.';
      case AppLanguage.japanese: return '商品を選択してください。';
      case AppLanguage.chinese: return '请选择商品。';
      case AppLanguage.mongolian: return 'Барааг сонгоно уу.';
      case AppLanguage.korean: return '상품을 선택해주세요.';
    }
  }
  String get groupOrderSelectColor {
    switch (language) {
      case AppLanguage.english: return 'Please select a color.';
      case AppLanguage.japanese: return 'カラーを選択してください。';
      case AppLanguage.chinese: return '请选择颜色。';
      case AppLanguage.mongolian: return 'Өнгийг сонгоно уу.';
      case AppLanguage.korean: return '색상을 선택해주세요.';
    }
  }
  String get groupOrderSelectSize {
    switch (language) {
      case AppLanguage.english: return 'Please select a size.';
      case AppLanguage.japanese: return 'サイズを選択してください。';
      case AppLanguage.chinese: return '请选择尺码。';
      case AppLanguage.mongolian: return 'Хэмжээг сонгоно уу.';
      case AppLanguage.korean: return '사이즈를 선택해주세요.';
    }
  }
  String get groupOrderMinimum5 {
    switch (language) {
      case AppLanguage.english: return 'Group orders require a minimum of 5 people.';
      case AppLanguage.japanese: return '団体注文は最低5名以上必要です。';
      case AppLanguage.chinese: return '团体订单至少需要5人。';
      case AppLanguage.mongolian: return 'Бүлгийн захиалга дор хаяж 5 хүн байх ёстой.';
      case AppLanguage.korean: return '단체주문은 최소 5명 이상입니다.';
    }
  }
  String get groupOrderColorLabel {
    switch (language) {
      case AppLanguage.english: return 'Color';
      case AppLanguage.japanese: return 'カラー';
      case AppLanguage.chinese: return '颜色';
      case AppLanguage.mongolian: return 'Өнгө';
      case AppLanguage.korean: return '색상';
    }
  }
  String get groupOrderProductDesc {
    switch (language) {
      case AppLanguage.english: return 'Enter product description';
      case AppLanguage.japanese: return '商品説明を入力してください';
      case AppLanguage.chinese: return '请输入商品描述';
      case AppLanguage.mongolian: return 'Барааны тайлбар оруулна уу';
      case AppLanguage.korean: return '상품 설명을 입력하세요';
    }
  }

  // ── personal order guide ──
  String get personalOrderGuideTitle {
    switch (language) {
      case AppLanguage.english: return 'Personal Custom Guide';
      case AppLanguage.japanese: return '個人カスタム案内';
      case AppLanguage.chinese: return '个人定制指南';
      case AppLanguage.mongolian: return 'Хувийн захиалгын гарын авлага';
      case AppLanguage.korean: return '개인 맞춤 제작 안내';
    }
  }
  String get personalOrderGuideFeature {
    switch (language) {
      case AppLanguage.english: return 'Key Features';
      case AppLanguage.japanese: return '主な特長';
      case AppLanguage.chinese: return '主要特点';
      case AppLanguage.mongolian: return 'Гол онцлогууд';
      case AppLanguage.korean: return '주요 특징';
    }
  }
  String get personalOrderGuideFrom1 {
    switch (language) {
      case AppLanguage.english: return 'Available from 1 person';
      case AppLanguage.japanese: return '1名から可能';
      case AppLanguage.chinese: return '1人即可';
      case AppLanguage.mongolian: return '1 хүнээс боломжтой';
      case AppLanguage.korean: return '1인부터 가능';
    }
  }
  String get personalOrderGuideNoMin {
    switch (language) {
      case AppLanguage.english: return 'No minimum quantity';
      case AppLanguage.japanese: return '最小数量制限なし';
      case AppLanguage.chinese: return '无最低数量限制';
      case AppLanguage.mongolian: return 'Хамгийн бага тоо хэмжээ байхгүй';
      case AppLanguage.korean: return '최소 수량 제한 없음';
    }
  }
  String get personalOrderGuideFreeColor {
    switch (language) {
      case AppLanguage.english: return 'Free color customization';
      case AppLanguage.japanese: return 'カラー自由カスタム';
      case AppLanguage.chinese: return '自由颜色定制';
      case AppLanguage.mongolian: return 'Өнгийг чөлөөтэй тохируулах';
      case AppLanguage.korean: return '색상 자유 커스텀';
    }
  }
  String get personalOrderGuideSub {
    switch (language) {
      case AppLanguage.english: return 'Available from 1 person · Free custom';
      case AppLanguage.japanese: return '1名から可能 · 自由カスタム';
      case AppLanguage.chinese: return '1人即可 · 自由定制';
      case AppLanguage.mongolian: return '1 хүнээс боломжтой · Чөлөөт тохиргоо';
      case AppLanguage.korean: return '1인부터 가능 · 자유 커스텀';
    }
  }
  String get personalOrderPriceUp {
    switch (language) {
      case AppLanguage.english: return '+80,000 KRW';
      case AppLanguage.japanese: return '+80,000円';
      case AppLanguage.chinese: return '+80,000韩元';
      case AppLanguage.mongolian: return '+80,000 ₩';
      case AppLanguage.korean: return '+80,000원';
    }
  }
  String get personalOrderFreeShipping300k {
    switch (language) {
      case AppLanguage.english: return 'Free shipping over 300,000 KRW';
      case AppLanguage.japanese: return '30万ウォン以上購入で送料無料';
      case AppLanguage.chinese: return '购买30万韩元以上免运费';
      case AppLanguage.mongolian: return '300,000 ₩-аас дээш захиалгад үнэгүй хүргэлт';
      case AppLanguage.korean: return '300,000원 이상 구매 시';
    }
  }
  String get personalOrderDefect {
    switch (language) {
      case AppLanguage.english: return 'Defect Report';
      case AppLanguage.japanese: return '不良申告';
      case AppLanguage.chinese: return '缺陷申报';
      case AppLanguage.mongolian: return 'Согог мэдэгдэх';
      case AppLanguage.korean: return '결함 접수';
    }
  }
  String get personalOrderChooseColor {
    switch (language) {
      case AppLanguage.english: return 'Choose your color';
      case AppLanguage.japanese: return '好きな色を選択';
      case AppLanguage.chinese: return '选择您喜欢的颜色';
      case AppLanguage.mongolian: return 'Өнгөө сонгоно уу';
      case AppLanguage.korean: return '원하는 색상 선택';
    }
  }

  // ── personal order form ──
  String get personalFormTitle {
    switch (language) {
      case AppLanguage.english: return 'Personal Order Form';
      case AppLanguage.japanese: return '個人注文書作成';
      case AppLanguage.chinese: return '个人订单表单';
      case AppLanguage.mongolian: return 'Хувийн захиалгын маягт';
      case AppLanguage.korean: return '개인 주문서 작성';
    }
  }
  String get personalFormSubmit {
    switch (language) {
      case AppLanguage.english: return 'Submit Order';
      case AppLanguage.japanese: return '注文を提出';
      case AppLanguage.chinese: return '提交订单';
      case AppLanguage.mongolian: return 'Захиалга илгээх';
      case AppLanguage.korean: return '주문 제출';
    }
  }
  String get personalFormSubmitNote {
    switch (language) {
      case AppLanguage.english: return 'After submitting the order, our staff will contact you via KakaoTalk or email.';
      case AppLanguage.japanese: return '注文書提出後、担当者がカカオトークまたはメールでご連絡いたします。';
      case AppLanguage.chinese: return '提交订单后，工作人员将通过KakaoTalk或电子邮件联系您。';
      case AppLanguage.mongolian: return 'Захиалга илгээсний дараа ажилтан KakaoTalk эсвэл имэйлээр холбоо барина.';
      case AppLanguage.korean: return '주문서 제출 후 담당자가 확인하여\n카카오톡 또는 이메일로 안내드립니다.';
    }
  }
  String get personalFormColorOnly {
    switch (language) {
      case AppLanguage.english: return '① Color Change Only';
      case AppLanguage.japanese: return '① カラーのみ変更';
      case AppLanguage.chinese: return '① 仅更改颜色';
      case AppLanguage.mongolian: return '① Зөвхөн өнгө өөрчлөх';
      case AppLanguage.korean: return '① 컬러만 변경';
    }
  }
  String get personalFormFrontName {
    switch (language) {
      case AppLanguage.english: return '② Front Group Name + Color';
      case AppLanguage.japanese: return '② 前面グループ名 + カラー';
      case AppLanguage.chinese: return '② 正面团队名称 + 颜色';
      case AppLanguage.mongolian: return '② Урд хэсгийн нэр + Өнгө';
      case AppLanguage.korean: return '② 앞면 단체명 + 컬러';
    }
  }
  String get personalFormFullCustom {
    switch (language) {
      case AppLanguage.english: return '③ Group Name + Color + Names';
      case AppLanguage.japanese: return '③ グループ名 + カラー + 名前';
      case AppLanguage.chinese: return '③ 团队名称 + 颜色 + 姓名';
      case AppLanguage.mongolian: return '③ Бүлгийн нэр + Өнгө + Нэр';
      case AppLanguage.korean: return '③ 단체명 + 컬러 + 이름';
    }
  }
  String get personalFormSizeSelect {
    switch (language) {
      case AppLanguage.english: return 'Please select a size';
      case AppLanguage.japanese: return 'サイズを選択してください';
      case AppLanguage.chinese: return '请选择尺码';
      case AppLanguage.mongolian: return 'Хэмжээг сонгоно уу';
      case AppLanguage.korean: return '사이즈를 선택해주세요';
    }
  }
  String get personalFormWaistbandOption {
    switch (language) {
      case AppLanguage.english: return 'Waistband Option';
      case AppLanguage.japanese: return 'ウエストバンドオプション';
      case AppLanguage.chinese: return '腰带选项';
      case AppLanguage.mongolian: return 'Бүсний сонголт';
      case AppLanguage.korean: return '허리밴드 옵션';
    }
  }
  String get personalFormShipAfter {
    switch (language) {
      case AppLanguage.english: return '3. Ships after 14-21 days';
      case AppLanguage.japanese: return '3. 14〜21日後に発送';
      case AppLanguage.chinese: return '3. 14-21天后发货';
      case AppLanguage.mongolian: return '3. 14-21 хоногийн дараа илгээнэ';
      case AppLanguage.korean: return '3. 14~21일 후 발송';
    }
  }
  String get personalFormCartLabel {
    switch (language) {
      case AppLanguage.english: return 'Cart';
      case AppLanguage.japanese: return 'カート';
      case AppLanguage.chinese: return '购物车';
      case AppLanguage.mongolian: return 'Сагс';
      case AppLanguage.korean: return '장바구니';
    }
  }
  String get personalFormSelectLabel {
    switch (language) {
      case AppLanguage.english: return 'Select';
      case AppLanguage.japanese: return '選択';
      case AppLanguage.chinese: return '选择';
      case AppLanguage.mongolian: return 'Сонгох';
      case AppLanguage.korean: return '선택';
    }
  }


  // ── cart screen ──
  String get cartOrderSelectedNote {
    switch (language) {
      case AppLanguage.english: return 'Selected products will be ordered. Quantity can be changed.';
      case AppLanguage.japanese: return '選択された商品を注文します。数量変更が可能です。';
      case AppLanguage.chinese: return '将订购所选商品。可以更改数量。';
      case AppLanguage.mongolian: return 'Сонгосон бараанууд захиалагдана. Тоо хэмжээг өөрчилж болно.';
      case AppLanguage.korean: return '선택된 상품을 주문합니다. 수량 변경이 가능합니다.';
    }
  }
  String get cartOrderSummary {
    switch (language) {
      case AppLanguage.english: return 'Order Summary';
      case AppLanguage.japanese: return '注文サマリー';
      case AppLanguage.chinese: return '订单摘要';
      case AppLanguage.mongolian: return 'Захиалгын хураангуй';
      case AppLanguage.korean: return '주문 요약';
    }
  }
  String get cartSubtotal {
    switch (language) {
      case AppLanguage.english: return 'Subtotal';
      case AppLanguage.japanese: return '商品金額';
      case AppLanguage.chinese: return '商品金额';
      case AppLanguage.mongolian: return 'Барааны дүн';
      case AppLanguage.korean: return '상품 금액';
    }
  }
  String get cartShipping {
    switch (language) {
      case AppLanguage.english: return 'Shipping';
      case AppLanguage.japanese: return '配送料';
      case AppLanguage.chinese: return '运费';
      case AppLanguage.mongolian: return 'Хүргэлт';
      case AppLanguage.korean: return '배송비';
    }
  }
  String get cartShippingFee {
    switch (language) {
      case AppLanguage.english: return '₩3,000';
      case AppLanguage.japanese: return '3,000円';
      case AppLanguage.chinese: return '3,000韩元';
      case AppLanguage.mongolian: return '₩3,000';
      case AppLanguage.korean: return '3,000원';
    }
  }
  String get cartTotal {
    switch (language) {
      case AppLanguage.english: return 'Total';
      case AppLanguage.japanese: return '合計金額';
      case AppLanguage.chinese: return '总支付金额';
      case AppLanguage.mongolian: return 'Нийт';
      case AppLanguage.korean: return '총 결제금액';
    }
  }

  String get drawerCatTop {
    switch (language) {
      case AppLanguage.english: return 'Top';
      case AppLanguage.japanese: return 'トップス';
      case AppLanguage.chinese: return '上衣';
      case AppLanguage.mongolian: return 'Дээд';
      default: return '상의';
    }
  }
  String get drawerCatAllTop {
    switch (language) {
      case AppLanguage.english: return 'All Tops';
      case AppLanguage.japanese: return '全トップス';
      case AppLanguage.chinese: return '全部上衣';
      case AppLanguage.mongolian: return 'Бүх дээд';
      default: return '전체 상의';
    }
  }
  String get drawerCatSingletA {
    switch (language) {
      case AppLanguage.english: return 'Singlet Type A';
      case AppLanguage.japanese: return 'シングレット Aタイプ';
      case AppLanguage.chinese: return '背心 A型';
      case AppLanguage.mongolian: return 'Сингл А';
      default: return '싱글렛 A타입';
    }
  }
  String get drawerCatSingletB {
    switch (language) {
      case AppLanguage.english: return 'Singlet Type B';
      case AppLanguage.japanese: return 'シングレット Bタイプ';
      case AppLanguage.chinese: return '背心 B型';
      case AppLanguage.mongolian: return 'Сингл Б';
      default: return '싱글렛 B타입';
    }
  }
  String get drawerCatRoundTee {
    switch (language) {
      case AppLanguage.english: return 'Round Tee';
      case AppLanguage.japanese: return 'ラウンドTシャツ';
      case AppLanguage.chinese: return '圆领T恤';
      case AppLanguage.mongolian: return 'Дугуй хүзүүтэй';
      default: return '라운드 반팔티';
    }
  }
  String get drawerCatCropTop {
    switch (language) {
      case AppLanguage.english: return 'Crop Top';
      case AppLanguage.japanese: return 'クロップトップ';
      case AppLanguage.chinese: return '短款上衣';
      case AppLanguage.mongolian: return 'Кроп топ';
      default: return '크롭탑';
    }
  }
  String get drawerCatLongSleeve {
    switch (language) {
      case AppLanguage.english: return 'Long Sleeve';
      case AppLanguage.japanese: return 'ロングスリーブ';
      case AppLanguage.chinese: return '长袖';
      case AppLanguage.mongolian: return 'Урт ханцуй';
      default: return '롱 슬리브';
    }
  }
  String get drawerCatSweatshirt {
    switch (language) {
      case AppLanguage.english: return 'Sweatshirt';
      case AppLanguage.japanese: return 'スウェット';
      case AppLanguage.chinese: return '卫衣';
      case AppLanguage.mongolian: return 'Свитшот';
      default: return '맨투맨';
    }
  }
  String get drawerCatHoodie {
    switch (language) {
      case AppLanguage.english: return 'Hoodie Zip-Up';
      case AppLanguage.japanese: return 'フードジップアップ';
      case AppLanguage.chinese: return '连帽衫';
      case AppLanguage.mongolian: return 'Хүүди';
      default: return '후드집업';
    }
  }
  String get drawerCatPolo {
    switch (language) {
      case AppLanguage.english: return 'Polo Shirt';
      case AppLanguage.japanese: return 'ポロシャツ';
      case AppLanguage.chinese: return 'Polo衫';
      case AppLanguage.mongolian: return 'Поло';
      default: return '카라티';
    }
  }
  String get drawerCatBottom {
    switch (language) {
      case AppLanguage.english: return 'Bottom';
      case AppLanguage.japanese: return 'ボトムス';
      case AppLanguage.chinese: return '下装';
      case AppLanguage.mongolian: return 'Доод';
      default: return '하의';
    }
  }
  String get drawerCatAllBottom {
    switch (language) {
      case AppLanguage.english: return 'All Bottoms';
      case AppLanguage.japanese: return '全ボトムス';
      case AppLanguage.chinese: return '全部下装';
      case AppLanguage.mongolian: return 'Бүх доод';
      default: return '전체 하의';
    }
  }
  String get drawerCatTights9 {
    switch (language) {
      case AppLanguage.english: return 'Full Tights';
      case AppLanguage.japanese: return 'フルタイツ';
      case AppLanguage.chinese: return '全长紧身裤';
      case AppLanguage.mongolian: return 'Тайтс 9';
      default: return '타이즈 9부';
    }
  }
  String get drawerCatTights5 {
    switch (language) {
      case AppLanguage.english: return '3/4 Tights';
      case AppLanguage.japanese: return '5分タイツ';
      case AppLanguage.chinese: return '五分紧身裤';
      case AppLanguage.mongolian: return 'Тайтс 5';
      default: return '타이즈 5부';
    }
  }
  String get drawerCatTights4 {
    switch (language) {
      case AppLanguage.english: return 'Capri Tights';
      case AppLanguage.japanese: return '4分タイツ';
      case AppLanguage.chinese: return '四分紧身裤';
      case AppLanguage.mongolian: return 'Тайтс 4';
      default: return '타이즈 4부';
    }
  }
  String get drawerCatTights3 {
    switch (language) {
      case AppLanguage.english: return 'Mid Tights';
      case AppLanguage.japanese: return '3分タイツ';
      case AppLanguage.chinese: return '三分紧身裤';
      case AppLanguage.mongolian: return 'Тайтс 3';
      default: return '타이즈 3부';
    }
  }
  String get drawerCatTights25 {
    switch (language) {
      case AppLanguage.english: return 'Short Tights';
      case AppLanguage.japanese: return '2.5分タイツ';
      case AppLanguage.chinese: return '超短紧身裤';
      case AppLanguage.mongolian: return 'Тайтс 2.5';
      default: return '타이즈 2.5부';
    }
  }
  String get drawerCatShortShorts {
    switch (language) {
      case AppLanguage.english: return 'Short Shorts';
      case AppLanguage.japanese: return 'ショートショーツ';
      case AppLanguage.chinese: return '超短裤';
      case AppLanguage.mongolian: return 'Богино шорт';
      default: return '숏쇼츠';
    }
  }
  String get drawerCatTrainingPants {
    switch (language) {
      case AppLanguage.english: return 'Training Pants';
      case AppLanguage.japanese: return 'トレーニングパンツ';
      case AppLanguage.chinese: return '运动裤';
      case AppLanguage.mongolian: return 'Трэйнинг';
      default: return '트레이닝바지';
    }
  }
  String get drawerCatShorts {
    switch (language) {
      case AppLanguage.english: return 'Shorts';
      case AppLanguage.japanese: return 'ショーツ';
      case AppLanguage.chinese: return '短裤';
      case AppLanguage.mongolian: return 'Шорт';
      default: return '반바지';
    }
  }
  String get drawerCatSet {
    switch (language) {
      case AppLanguage.english: return 'Set';
      case AppLanguage.japanese: return 'セット';
      case AppLanguage.chinese: return '套装';
      case AppLanguage.mongolian: return 'Иж бүрдэл';
      default: return '세트';
    }
  }
  String get drawerCatAllSet {
    switch (language) {
      case AppLanguage.english: return 'All Sets';
      case AppLanguage.japanese: return '全セット';
      case AppLanguage.chinese: return '全部套装';
      case AppLanguage.mongolian: return 'Бүх иж бүрдэл';
      default: return '전체 세트';
    }
  }
  String get drawerCatSingletSet {
    switch (language) {
      case AppLanguage.english: return 'Singlet A Set';
      case AppLanguage.japanese: return 'シングレットAセット';
      case AppLanguage.chinese: return '背心A套装';
      case AppLanguage.mongolian: return 'Сингл А иж';
      default: return '싱글렛 A타입세트';
    }
  }
  String get drawerCatTrainingSet {
    switch (language) {
      case AppLanguage.english: return 'Training Set';
      case AppLanguage.japanese: return 'トレーニングセット';
      case AppLanguage.chinese: return '运动套装';
      case AppLanguage.mongolian: return 'Трэйнинг иж';
      default: return '트레이닝세트';
    }
  }
  String get drawerCatOuter {
    switch (language) {
      case AppLanguage.english: return 'Outer';
      case AppLanguage.japanese: return 'アウター';
      case AppLanguage.chinese: return '外套';
      case AppLanguage.mongolian: return 'Гадуур';
      default: return '아우터';
    }
  }
  String get drawerCatAllOuter {
    switch (language) {
      case AppLanguage.english: return 'All Outerwear';
      case AppLanguage.japanese: return '全アウター';
      case AppLanguage.chinese: return '全部外套';
      case AppLanguage.mongolian: return 'Бүх гадуур';
      default: return '전체 아우터';
    }
  }
  String get drawerCatWindbreaker {
    switch (language) {
      case AppLanguage.english: return 'Windbreaker';
      case AppLanguage.japanese: return 'ウィンドブレーカー';
      case AppLanguage.chinese: return '防风外套';
      case AppLanguage.mongolian: return 'Салхины куртка';
      default: return '바람막이';
    }
  }
  String get drawerCatTrainingZip {
    switch (language) {
      case AppLanguage.english: return 'Training Zip-Up';
      case AppLanguage.japanese: return 'トレーニングジップアップ';
      case AppLanguage.chinese: return '运动拉链衫';
      case AppLanguage.mongolian: return 'Трэйнинг хүүди';
      default: return '트레이닝집업';
    }
  }
  String get drawerCatDownPadding {
    switch (language) {
      case AppLanguage.english: return 'Down Padding';
      case AppLanguage.japanese: return 'ダウンジャケット';
      case AppLanguage.chinese: return '羽绒服';
      case AppLanguage.mongolian: return 'Дааш';
      default: return '다운패딩';
    }
  }
  String get drawerCatDownVest {
    switch (language) {
      case AppLanguage.english: return 'Down Vest';
      case AppLanguage.japanese: return 'ダウンベスト';
      case AppLanguage.chinese: return '羽绒马甲';
      case AppLanguage.mongolian: return 'Хилэн дааш';
      default: return '다운조끼패딩';
    }
  }
  String get drawerCatLongPadding {
    switch (language) {
      case AppLanguage.english: return 'Long Padding';
      case AppLanguage.japanese: return 'ロングパッディング';
      case AppLanguage.chinese: return '长款羽绒服';
      case AppLanguage.mongolian: return 'Урт дааш';
      default: return '롱패딩';
    }
  }
  String get drawerCatSkinsuit {
    switch (language) {
      case AppLanguage.english: return 'Skinsuit';
      case AppLanguage.japanese: return 'スキンスーツ';
      case AppLanguage.chinese: return '紧身连体衣';
      case AppLanguage.mongolian: return 'Скинсьют';
      default: return '스킨슈트';
    }
  }
  String get drawerCatAllSkinsuit {
    switch (language) {
      case AppLanguage.english: return 'All Skinsuits';
      case AppLanguage.japanese: return '全スキンスーツ';
      case AppLanguage.chinese: return '全部紧身衣';
      case AppLanguage.mongolian: return 'Бүх скинсьют';
      default: return '전체 스킨슈트';
    }
  }
  String get drawerCatAccessory {
    switch (language) {
      case AppLanguage.english: return 'Accessory';
      case AppLanguage.japanese: return 'アクセサリー';
      case AppLanguage.chinese: return '配件';
      case AppLanguage.mongolian: return 'Нэмэлт';
      default: return '악세사리';
    }
  }
  String get drawerCatAllAccessory {
    switch (language) {
      case AppLanguage.english: return 'All Accessories';
      case AppLanguage.japanese: return '全アクセサリー';
      case AppLanguage.chinese: return '全部配件';
      case AppLanguage.mongolian: return 'Бүх нэмэлт';
      default: return '전체 악세사리';
    }
  }
  String get drawerCatHat {
    switch (language) {
      case AppLanguage.english: return 'Hat';
      case AppLanguage.japanese: return '帽子';
      case AppLanguage.chinese: return '帽子';
      case AppLanguage.mongolian: return 'Малгай';
      default: return '모자';
    }
  }
  String get drawerCatBackpack {
    switch (language) {
      case AppLanguage.english: return 'Backpack';
      case AppLanguage.japanese: return 'バックパック';
      case AppLanguage.chinese: return '双肩包';
      case AppLanguage.mongolian: return 'Уут';
      default: return '백팩';
    }
  }
  String get drawerCatEvent {
    switch (language) {
      case AppLanguage.english: return 'Event';
      case AppLanguage.japanese: return 'イベント';
      case AppLanguage.chinese: return '活动';
      case AppLanguage.mongolian: return 'Арга хэмжээ';
      default: return '이벤트';
    }
  }
  String get drawerCatAllEvent {
    switch (language) {
      case AppLanguage.english: return 'All Events';
      case AppLanguage.japanese: return '全イベント';
      case AppLanguage.chinese: return '全部活动';
      case AppLanguage.mongolian: return 'Бүх арга хэмжээ';
      default: return '전체 이벤트';
    }
  }
  String get drawerCatSeasonSale {
    switch (language) {
      case AppLanguage.english: return 'Season SALE';
      case AppLanguage.japanese: return 'シーズンSALE';
      case AppLanguage.chinese: return '季节特卖';
      case AppLanguage.mongolian: return 'Улирлын хямдрал';
      default: return '시즌 SALE';
    }
  }
  String get drawerMyPage {
    switch (language) {
      case AppLanguage.english: return 'My Page';
      case AppLanguage.japanese: return 'マイページ';
      case AppLanguage.chinese: return '我的页面';
      case AppLanguage.mongolian: return 'Миний хуудас';
      default: return '마이페이지';
    }
  }
  String get drawerGroupOrder {
    switch (language) {
      case AppLanguage.english: return 'Group Order Form';
      case AppLanguage.japanese: return '団体注文フォーム';
      case AppLanguage.chinese: return '团体订单表格';
      case AppLanguage.mongolian: return 'Бүлгийн захиалга';
      default: return '단체 주문 서식';
    }
  }
  String get drawerGroupProducts {
    switch (language) {
      case AppLanguage.english: return 'Group Products';
      case AppLanguage.japanese: return '団体専用商品';
      case AppLanguage.chinese: return '团体专用商品';
      case AppLanguage.mongolian: return 'Бүлгийн бүтээгдэхүүн';
      default: return '단체 전용 상품';
    }
  }
  String get drawerSupport {
    switch (language) {
      case AppLanguage.english: return 'SUPPORT';
      case AppLanguage.japanese: return 'サポート';
      case AppLanguage.chinese: return '客服';
      case AppLanguage.mongolian: return 'ДЭМЖЛЭГ';
      default: return 'SUPPORT';
    }
  }
  String get drawer2FITSupport {
    switch (language) {
      case AppLanguage.english: return '2FIT Support';
      case AppLanguage.japanese: return '2FIT サポート';
      case AppLanguage.chinese: return '2FIT 客服';
      case AppLanguage.mongolian: return '2FIT Дэмжлэг';
      default: return '2FIT 서포트';
    }
  }
  String get drawerBrandIntro {
    switch (language) {
      case AppLanguage.english: return 'Brand Story';
      case AppLanguage.japanese: return 'ブランド紹介';
      case AppLanguage.chinese: return '品牌介绍';
      case AppLanguage.mongolian: return 'Брэндийн тухай';
      default: return '브랜드 소개';
    }
  }
  String get drawerAdmin {
    switch (language) {
      case AppLanguage.english: return 'ADMIN';
      case AppLanguage.japanese: return 'ADMIN';
      case AppLanguage.chinese: return 'ADMIN';
      case AppLanguage.mongolian: return 'ADMIN';
      default: return 'ADMIN';
    }
  }
  String get drawerAdminDashboard {
    switch (language) {
      case AppLanguage.english: return 'Admin Dashboard';
      case AppLanguage.japanese: return '管理者ダッシュボード';
      case AppLanguage.chinese: return '管理员仪表板';
      case AppLanguage.mongolian: return 'Админ самбар';
      default: return '관리자 대시보드';
    }
  }
  String get drawerAdminDesc {
    switch (language) {
      case AppLanguage.english: return 'Orders · Products · Members';
      case AppLanguage.japanese: return '注文·商品·会員管理';
      case AppLanguage.chinese: return '订单·商品·会员管理';
      case AppLanguage.mongolian: return 'Захиалга·Бараа·Гишүүд';
      default: return '주문·상품·회원 관리';
    }
  }
  String get drawerLogout {
    switch (language) {
      case AppLanguage.english: return 'LOG OUT';
      case AppLanguage.japanese: return 'ログアウト';
      case AppLanguage.chinese: return '退出登录';
      case AppLanguage.mongolian: return 'ГАРАХ';
      default: return 'LOG OUT';
    }
  }
  String get drawerCopyright {
    switch (language) {
      case AppLanguage.english: return '© 2024 2FIT KOREA';
      case AppLanguage.japanese: return '© 2024 2FIT KOREA';
      case AppLanguage.chinese: return '© 2024 2FIT KOREA';
      case AppLanguage.mongolian: return '© 2024 2FIT KOREA';
      default: return '© 2024 2FIT KOREA';
    }
  }

  String get won {
    switch (language) {
      case AppLanguage.english: return 'KRW';
      case AppLanguage.japanese: return '円';
      case AppLanguage.chinese: return '韩元';
      case AppLanguage.mongolian: return '₩';
      default: return '원';
    }
  }
  String get allItems {
    switch (language) {
      case AppLanguage.english: return 'All';
      case AppLanguage.japanese: return '全て';
      case AppLanguage.chinese: return '全部';
      case AppLanguage.mongolian: return 'Бүгд';
      default: return '전체';
    }
  }
  String get newBadge {
    switch (language) {
      case AppLanguage.english: return 'NEW';
      case AppLanguage.japanese: return 'NEW';
      case AppLanguage.chinese: return 'NEW';
      case AppLanguage.mongolian: return 'NEW';
      default: return 'NEW';
    }
  }
  String get saleBadge {
    switch (language) {
      case AppLanguage.english: return 'SALE';
      case AppLanguage.japanese: return 'SALE';
      case AppLanguage.chinese: return 'SALE';
      case AppLanguage.mongolian: return 'SALE';
      default: return 'SALE';
    }
  }
  String get bestBadge {
    switch (language) {
      case AppLanguage.english: return 'BEST';
      case AppLanguage.japanese: return 'BEST';
      case AppLanguage.chinese: return 'BEST';
      case AppLanguage.mongolian: return 'BEST';
      default: return 'BEST';
    }
  }

  String get freeShippingOver {
    switch (language) {
      case AppLanguage.english: return 'Free shipping over ₩300,000';
      case AppLanguage.japanese: return '30万ウォン以上送料無料';
      case AppLanguage.chinese: return '满30万韩元免运费';
      case AppLanguage.mongolian: return '₩300,000-аас дээш үнэгүй';
      default: return '30만원 이상 무료배송';
    }
  }
  String get exchangeReturn7 {
    switch (language) {
      case AppLanguage.english: return '7-day exchange/return';
      case AppLanguage.japanese: return '受取後7日以内交換/返品';
      case AppLanguage.chinese: return '收货7天内换货/退货';
      case AppLanguage.mongolian: return '7 хоногт буцаах';
      default: return '수령 후 7일 내 교환/반품';
    }
  }
  String get qualityGuarantee {
    switch (language) {
      case AppLanguage.english: return 'Quality Guarantee';
      case AppLanguage.japanese: return '品質保証';
      case AppLanguage.chinese: return '品质保证';
      case AppLanguage.mongolian: return 'Чанарын баталгаа';
      default: return '품질보증';
    }
  }
  String get highQualityMaterial {
    switch (language) {
      case AppLanguage.english: return 'High Quality Material';
      case AppLanguage.japanese: return '高品質素材';
      case AppLanguage.chinese: return '高品质材料';
      case AppLanguage.mongolian: return 'Өндөр чанар';
      default: return '고품질 소재';
    }
  }
  String get customerSupport {
    switch (language) {
      case AppLanguage.english: return '1:1 Support';
      case AppLanguage.japanese: return '1:1 相談';
      case AppLanguage.chinese: return '1:1咨询';
      case AppLanguage.mongolian: return '1:1 Зөвлөгөө';
      default: return '1:1 상담';
    }
  }
  String get kakaoChannel {
    switch (language) {
      case AppLanguage.english: return 'Kakao Channel';
      case AppLanguage.japanese: return 'カカオチャンネル';
      case AppLanguage.chinese: return 'Kakao频道';
      case AppLanguage.mongolian: return 'Какао суваг';
      default: return '카카오 채널';
    }
  }
  String get itemsCount {
    switch (language) {
      case AppLanguage.english: return 'items';
      case AppLanguage.japanese: return '個商品';
      case AppLanguage.chinese: return '件商品';
      case AppLanguage.mongolian: return 'бараа';
      default: return '개 상품';
    }
  }
  String get viewAllBtn {
    switch (language) {
      case AppLanguage.english: return 'View All';
      case AppLanguage.japanese: return '全て見る';
      case AppLanguage.chinese: return '查看全部';
      case AppLanguage.mongolian: return 'Бүгдийг харах';
      default: return '전체보기';
    }
  }
  String get shopNow2 {
    switch (language) {
      case AppLanguage.english: return 'Shop Now';
      case AppLanguage.japanese: return '今すぐ購入';
      case AppLanguage.chinese: return '立即购物';
      case AppLanguage.mongolian: return 'Одоо худалдаж авах';
      default: return '지금 쇼핑하기';
    }
  }
  String get homeSeasonBanner {
    switch (language) {
      case AppLanguage.english: return '2025 S/S Collection · Premium Team Sportswear';
      case AppLanguage.japanese: return '2025 S/Sコレクション·高品質チームスポーツウェア';
      case AppLanguage.chinese: return '2025 S/S系列·高品质团队运动服';
      case AppLanguage.mongolian: return '2025 S/S цуглуулга · Өндөр чанарын баг';
      default: return '2025 S/S 컬렉션 · 고퀄리티 단체 스포츠웨어';
    }
  }
  String get homeTeamwearDesc {
    switch (language) {
      case AppLanguage.english: return 'Team Uniforms · Custom Sportswear Specialist';
      case AppLanguage.japanese: return 'チームウェア·ユニフォーム専門';
      case AppLanguage.chinese: return '队服·团体服·定制制服专家';
      case AppLanguage.mongolian: return 'Багийн хувцас · Захиалгат';
      default: return '팀복 · 단체복 · 커스텀 유니폼 전문';
    }
  }
  String get homeBestSeller {
    switch (language) {
      case AppLanguage.english: return 'Best Sellers';
      case AppLanguage.japanese: return 'ベストセラー';
      case AppLanguage.chinese: return '畅销商品';
      case AppLanguage.mongolian: return 'Бестселлер';
      default: return '베스트셀러';
    }
  }
  String get homeNewArrival {
    switch (language) {
      case AppLanguage.english: return 'New Arrivals';
      case AppLanguage.japanese: return '新着';
      case AppLanguage.chinese: return '新品';
      case AppLanguage.mongolian: return 'Шинэ бараа';
      default: return '신상품';
    }
  }
  String get homeRecommend {
    switch (language) {
      case AppLanguage.english: return 'Recommended';
      case AppLanguage.japanese: return 'おすすめ';
      case AppLanguage.chinese: return '推荐商品';
      case AppLanguage.mongolian: return 'Зөвлөмж';
      default: return '추천 상품';
    }
  }
  String get homeSaleItems {
    switch (language) {
      case AppLanguage.english: return 'Sale Items';
      case AppLanguage.japanese: return 'セール商品';
      case AppLanguage.chinese: return '特卖商品';
      case AppLanguage.mongolian: return 'Хямдралтай';
      default: return '세일 상품';
    }
  }
  String get homeGroupOrder {
    switch (language) {
      case AppLanguage.english: return 'Group Order';
      case AppLanguage.japanese: return '団体注文';
      case AppLanguage.chinese: return '团体订单';
      case AppLanguage.mongolian: return 'Бүлгийн захиалга';
      default: return '단체주문';
    }
  }
  String get homeGroupOrderDesc {
    switch (language) {
      case AppLanguage.english: return 'Group discount 5+ · Custom production';
      case AppLanguage.japanese: return '5名以上団体割引·カスタム製作';
      case AppLanguage.chinese: return '5人以上团购折扣·定制生产';
      case AppLanguage.mongolian: return '5+ хүнд хөнгөлөлт · Захиалгат';
      default: return '5인 이상 단체 할인 · 커스텀 제작';
    }
  }
  String get homeCustomOrder {
    switch (language) {
      case AppLanguage.english: return 'Custom Order';
      case AppLanguage.japanese: return 'カスタム注文';
      case AppLanguage.chinese: return '定制订单';
      case AppLanguage.mongolian: return 'Захиалгат';
      default: return '커스텀 주문';
    }
  }
  String get homeCustomOrderDesc {
    switch (language) {
      case AppLanguage.english: return 'From 1 person · Free custom';
      case AppLanguage.japanese: return '1名から可能·フリーカスタム';
      case AppLanguage.chinese: return '从1人起·自由定制';
      case AppLanguage.mongolian: return '1 хүнээс · Чөлөөт';
      default: return '1인부터 가능 · 자유 커스텀';
    }
  }
  String get notifTitle {
    switch (language) {
      case AppLanguage.english: return 'Notifications';
      case AppLanguage.japanese: return '通知';
      case AppLanguage.chinese: return '通知';
      case AppLanguage.mongolian: return 'Мэдэгдэл';
      default: return '알림';
    }
  }
  String get notifMarkAllRead {
    switch (language) {
      case AppLanguage.english: return 'Mark All Read';
      case AppLanguage.japanese: return '全て既読';
      case AppLanguage.chinese: return '全部已读';
      case AppLanguage.mongolian: return 'Бүгдийг уншсан';
      default: return '모두 읽음';
    }
  }
  String get notifEmpty {
    switch (language) {
      case AppLanguage.english: return 'No notifications';
      case AppLanguage.japanese: return '通知がありません';
      case AppLanguage.chinese: return '暂无通知';
      case AppLanguage.mongolian: return 'Мэдэгдэл байхгүй';
      default: return '알림이 없습니다';
    }
  }
  String get timeMinAgo {
    switch (language) {
      case AppLanguage.english: return 'min ago';
      case AppLanguage.japanese: return '分前';
      case AppLanguage.chinese: return '分钟前';
      case AppLanguage.mongolian: return 'мин өмнө';
      default: return '분 전';
    }
  }
  String get timeHourAgo {
    switch (language) {
      case AppLanguage.english: return 'hr ago';
      case AppLanguage.japanese: return '時間前';
      case AppLanguage.chinese: return '小时前';
      case AppLanguage.mongolian: return 'цаг өмнө';
      default: return '시간 전';
    }
  }
  String get timeDayAgo {
    switch (language) {
      case AppLanguage.english: return 'd ago';
      case AppLanguage.japanese: return '日前';
      case AppLanguage.chinese: return '天前';
      case AppLanguage.mongolian: return 'өдрийн өмнө';
      default: return '일 전';
    }
  }
  String get mypageEditProfile {
    switch (language) {
      case AppLanguage.english: return 'Edit Profile';
      case AppLanguage.japanese: return 'プロフィール編集';
      case AppLanguage.chinese: return '编辑资料';
      case AppLanguage.mongolian: return 'Профайл засах';
      default: return '프로필 수정';
    }
  }
  String get mypageAvailCoupon {
    switch (language) {
      case AppLanguage.english: return 'Available Coupons';
      case AppLanguage.japanese: return '利用可能クーポン';
      case AppLanguage.chinese: return '可用优惠券';
      case AppLanguage.mongolian: return 'Ашиглах купон';
      default: return '사용가능 쿠폰';
    }
  }
  String get mypageWishlist {
    switch (language) {
      case AppLanguage.english: return 'Wishlist';
      case AppLanguage.japanese: return 'お気に入り';
      case AppLanguage.chinese: return '收藏';
      case AppLanguage.mongolian: return 'Хүслийн жагсаалт';
      default: return '찜 목록';
    }
  }
  String get mypageLoginRequired {
    switch (language) {
      case AppLanguage.english: return 'Login required';
      case AppLanguage.japanese: return 'ログインが必要です';
      case AppLanguage.chinese: return '需要登录';
      case AppLanguage.mongolian: return 'Нэвтрэх шаардлагатай';
      default: return '로그인이 필요합니다';
    }
  }
  String get mypageLoginForOrders {
    switch (language) {
      case AppLanguage.english: return 'Login to view orders';
      case AppLanguage.japanese: return 'ログインして注文履歴を確認';
      case AppLanguage.chinese: return '登录查看订单记录';
      case AppLanguage.mongolian: return 'Нэвтрэн захиалгаа харна уу';
      default: return '로그인 후 주문 내역을 확인하세요';
    }
  }
  String get mypageNoOrders {
    switch (language) {
      case AppLanguage.english: return 'No orders yet';
      case AppLanguage.japanese: return '注文履歴がありません';
      case AppLanguage.chinese: return '暂无订单';
      case AppLanguage.mongolian: return 'Захиалга байхгүй';
      default: return '주문 내역이 없습니다';
    }
  }

  // ── 마이페이지 추가 번역 키 ──
  String get mypagePaymentHistory { switch (language) {
    case AppLanguage.english: return 'Payment History';
    case AppLanguage.japanese: return '決済内訳';
    case AppLanguage.chinese: return '支付记录';
    case AppLanguage.mongolian: return 'Төлбөрийн түүх';
    default: return '결제 내역';
  }}
  String get mypageCouponBox { switch (language) {
    case AppLanguage.english: return 'My Coupons';
    case AppLanguage.japanese: return 'クーポン';
    case AppLanguage.chinese: return '我的优惠券';
    case AppLanguage.mongolian: return 'Купон';
    default: return '쿠폰함';
  }}
  String get mypagePointHistory { switch (language) {
    case AppLanguage.english: return 'Points';
    case AppLanguage.japanese: return 'ポイント';
    case AppLanguage.chinese: return '积分';
    case AppLanguage.mongolian: return 'Оноо';
    default: return '포인트';
  }}
  String get mypageAddressBook { switch (language) {
    case AppLanguage.english: return 'Address Book';
    case AppLanguage.japanese: return 'お届け先';
    case AppLanguage.chinese: return '收货地址';
    case AppLanguage.mongolian: return 'Хүргэлтийн хаяг';
    default: return '배송지 관리';
  }}
  String get mypageTierBronze { switch (language) {
    case AppLanguage.english: return 'Bronze';
    case AppLanguage.japanese: return 'ブロンズ';
    case AppLanguage.chinese: return '青铜';
    case AppLanguage.mongolian: return 'Хүрэл';
    default: return '브론즈';
  }}
  String get mypageTierSilver { switch (language) {
    case AppLanguage.english: return 'Silver';
    case AppLanguage.japanese: return 'シルバー';
    case AppLanguage.chinese: return '白银';
    case AppLanguage.mongolian: return 'Мөнгө';
    default: return '실버';
  }}
  String get mypageTierGold { switch (language) {
    case AppLanguage.english: return 'Gold';
    case AppLanguage.japanese: return 'ゴールド';
    case AppLanguage.chinese: return '黄金';
    case AppLanguage.mongolian: return 'Алт';
    default: return '골드';
  }}
  String get mypageTierVip { switch (language) {
    case AppLanguage.english: return 'VIP';
    case AppLanguage.japanese: return 'VIP';
    case AppLanguage.chinese: return 'VIP';
    case AppLanguage.mongolian: return 'VIP';
    default: return 'VIP';
  }}
  String get mypageNoPayment { switch (language) {
    case AppLanguage.english: return 'No payment history';
    case AppLanguage.japanese: return '決済内訳がありません';
    case AppLanguage.chinese: return '暂无支付记录';
    case AppLanguage.mongolian: return 'Төлбөрийн түүх байхгүй';
    default: return '결제 내역이 없습니다';
  }}
  String get mypageNoCoupons { switch (language) {
    case AppLanguage.english: return 'No coupons available';
    case AppLanguage.japanese: return '利用可能なクーポンがありません';
    case AppLanguage.chinese: return '暂无可用优惠券';
    case AppLanguage.mongolian: return 'Купон байхгүй';
    default: return '보유한 쿠폰이 없습니다';
  }}
  String get mypageNoPoints { switch (language) {
    case AppLanguage.english: return 'No points yet';
    case AppLanguage.japanese: return 'ポイントがありません';
    case AppLanguage.chinese: return '暂无积分';
    case AppLanguage.mongolian: return 'Оноо байхгүй';
    default: return '포인트 내역이 없습니다';
  }}
  String get mypageAvailableCoupon { switch (language) {
    case AppLanguage.english: return 'Available';
    case AppLanguage.japanese: return '使用可能';
    case AppLanguage.chinese: return '可用';
    case AppLanguage.mongolian: return 'Ашиглах боломжтой';
    default: return '사용 가능';
  }}
  String get mypageExpiredCoupon { switch (language) {
    case AppLanguage.english: return 'Expired';
    case AppLanguage.japanese: return '期限切れ';
    case AppLanguage.chinese: return '已过期';
    case AppLanguage.mongolian: return 'Хугацаа дууссан';
    default: return '만료됨';
  }}
  String get mypageUsedCoupon { switch (language) {
    case AppLanguage.english: return 'Used';
    case AppLanguage.japanese: return '使用済み';
    case AppLanguage.chinese: return '已使用';
    case AppLanguage.mongolian: return 'Ашигласан';
    default: return '사용됨';
  }}
  String get mypageCouponExpiry { switch (language) {
    case AppLanguage.english: return 'Expires';
    case AppLanguage.japanese: return '有効期限';
    case AppLanguage.chinese: return '到期';
    case AppLanguage.mongolian: return 'Дуусах огноо';
    default: return '만료일';
  }}
  String get mypageMinOrder { switch (language) {
    case AppLanguage.english: return 'Min. order';
    case AppLanguage.japanese: return '最低注文金額';
    case AppLanguage.chinese: return '最低订单';
    case AppLanguage.mongolian: return 'Доод захиалга';
    default: return '최소 주문금액';
  }}
  String get mypagePointsTotal { switch (language) {
    case AppLanguage.english: return 'Total Points';
    case AppLanguage.japanese: return '保有ポイント';
    case AppLanguage.chinese: return '总积分';
    case AppLanguage.mongolian: return 'Нийт оноо';
    default: return '보유 포인트';
  }}
  String get mypagePointEarn { switch (language) {
    case AppLanguage.english: return 'Earned';
    case AppLanguage.japanese: return '적립';
    case AppLanguage.chinese: return '获得';
    case AppLanguage.mongolian: return 'Нэмэгдсэн';
    default: return '적립';
  }}
  String get mypagePointUse { switch (language) {
    case AppLanguage.english: return 'Used';
    case AppLanguage.japanese: return '使用';
    case AppLanguage.chinese: return '使用';
    case AppLanguage.mongolian: return 'Ашигласан';
    default: return '사용';
  }}
  String get mypageOrderTotal { switch (language) {
    case AppLanguage.english: return 'Total';
    case AppLanguage.japanese: return '合計';
    case AppLanguage.chinese: return '合计';
    case AppLanguage.mongolian: return 'Нийт';
    default: return '합계';
  }}
  String get mypageOrderDate { switch (language) {
    case AppLanguage.english: return 'Order Date';
    case AppLanguage.japanese: return '注文日';
    case AppLanguage.chinese: return '下单日期';
    case AppLanguage.mongolian: return 'Захиалсан огноо';
    default: return '주문일';
  }}
  String get mypagePaymentMethod { switch (language) {
    case AppLanguage.english: return 'Payment';
    case AppLanguage.japanese: return '決済方法';
    case AppLanguage.chinese: return '支付方式';
    case AppLanguage.mongolian: return 'Төлбөрийн арга';
    default: return '결제 수단';
  }}
  String get mypageShipping { switch (language) {
    case AppLanguage.english: return 'Shipping';
    case AppLanguage.japanese: return '送料';
    case AppLanguage.chinese: return '运费';
    case AppLanguage.mongolian: return 'Хүргэлт';
    default: return '배송비';
  }}
  String get mypageFree { switch (language) {
    case AppLanguage.english: return 'Free';
    case AppLanguage.japanese: return '無料';
    case AppLanguage.chinese: return '免费';
    case AppLanguage.mongolian: return 'Үнэгүй';
    default: return '무료';
  }}
  String get mypageSummary { switch (language) {
    case AppLanguage.english: return 'Summary';
    case AppLanguage.japanese: return 'サマリー';
    case AppLanguage.chinese: return '摘要';
    case AppLanguage.mongolian: return 'Хураангуй';
    default: return '요약';
  }}
  String get mypageOrderItems { switch (language) {
    case AppLanguage.english: return 'Items';
    case AppLanguage.japanese: return '商品';
    case AppLanguage.chinese: return '商品';
    case AppLanguage.mongolian: return 'Бараа';
    default: return '상품';
  }}
  String get mypageDefaultAddress { switch (language) {
    case AppLanguage.english: return 'Default';
    case AppLanguage.japanese: return 'デフォルト';
    case AppLanguage.chinese: return '默认';
    case AppLanguage.mongolian: return 'Үндсэн';
    default: return '기본 배송지';
  }}
  String get mypageNoAddress { switch (language) {
    case AppLanguage.english: return 'No saved addresses';
    case AppLanguage.japanese: return '登録された住所がありません';
    case AppLanguage.chinese: return '暂无收货地址';
    case AppLanguage.mongolian: return 'Хаяг хадгалагдаагүй';
    default: return '등록된 배송지가 없습니다';
  }}
  String get mypageAddAddress { switch (language) {
    case AppLanguage.english: return 'Add Address';
    case AppLanguage.japanese: return '住所を追加';
    case AppLanguage.chinese: return '添加地址';
    case AppLanguage.mongolian: return 'Хаяг нэмэх';
    default: return '배송지 추가';
  }}
  String get mypageProfileSection { switch (language) {
    case AppLanguage.english: return 'Profile';
    case AppLanguage.japanese: return 'プロフィール';
    case AppLanguage.chinese: return '个人资料';
    case AppLanguage.mongolian: return 'Профайл';
    default: return '프로필';
  }}
  String get mypageSecuritySection { switch (language) {
    case AppLanguage.english: return 'Security';
    case AppLanguage.japanese: return 'セキュリティ';
    case AppLanguage.chinese: return '安全';
    case AppLanguage.mongolian: return 'Аюулгүй байдал';
    default: return '보안';
  }}
  String get mypageNotificationSection { switch (language) {
    case AppLanguage.english: return 'Notifications';
    case AppLanguage.japanese: return '通知';
    case AppLanguage.chinese: return '通知';
    case AppLanguage.mongolian: return 'Мэдэгдэл';
    default: return '알림';
  }}
  String get mypageAppSection { switch (language) {
    case AppLanguage.english: return 'App';
    case AppLanguage.japanese: return 'アプリ';
    case AppLanguage.chinese: return '应用';
    case AppLanguage.mongolian: return 'Апп';
    default: return '앱 설정';
  }}
  String get mypageChangePassword { switch (language) {
    case AppLanguage.english: return 'Change Password';
    case AppLanguage.japanese: return 'パスワード変更';
    case AppLanguage.chinese: return '修改密码';
    case AppLanguage.mongolian: return 'Нууц үг солих';
    default: return '비밀번호 변경';
  }}
  String get mypageDeleteAccount { switch (language) {
    case AppLanguage.english: return 'Delete Account';
    case AppLanguage.japanese: return 'アカウント削除';
    case AppLanguage.chinese: return '注销账户';
    case AppLanguage.mongolian: return 'Бүртгэл устгах';
    default: return '회원 탈퇴';
  }}
  String get mypageNotifOrder { switch (language) {
    case AppLanguage.english: return 'Order Updates';
    case AppLanguage.japanese: return '注文更新';
    case AppLanguage.chinese: return '订单通知';
    case AppLanguage.mongolian: return 'Захиалгын мэдэгдэл';
    default: return '주문 알림';
  }}
  String get mypageNotifMarketing { switch (language) {
    case AppLanguage.english: return 'Marketing';
    case AppLanguage.japanese: return 'マーケティング';
    case AppLanguage.chinese: return '营销推广';
    case AppLanguage.mongolian: return 'Маркетинг';
    default: return '마케팅 알림';
  }}
  String get mypageDarkMode { switch (language) {
    case AppLanguage.english: return 'Dark Mode';
    case AppLanguage.japanese: return 'ダークモード';
    case AppLanguage.chinese: return '深色模式';
    case AppLanguage.mongolian: return 'Харанхуй горим';
    default: return '다크 모드';
  }}
  String get mypageLanguageSetting { switch (language) {
    case AppLanguage.english: return 'Language';
    case AppLanguage.japanese: return '言語';
    case AppLanguage.chinese: return '语言';
    case AppLanguage.mongolian: return 'Хэл';
    default: return '언어 설정';
  }}
  String get mypageLogout { switch (language) {
    case AppLanguage.english: return 'Logout';
    case AppLanguage.japanese: return 'ログアウト';
    case AppLanguage.chinese: return '退出登录';
    case AppLanguage.mongolian: return 'Гарах';
    default: return '로그아웃';
  }}
  String get mypageViewAll { switch (language) {
    case AppLanguage.english: return 'View All';
    case AppLanguage.japanese: return 'すべて見る';
    case AppLanguage.chinese: return '查看全部';
    case AppLanguage.mongolian: return 'Бүгдийг харах';
    default: return '전체 보기';
  }}
  String get mypageRecentOrders { switch (language) {
    case AppLanguage.english: return 'Recent Orders';
    case AppLanguage.japanese: return '最近の注文';
    case AppLanguage.chinese: return '最近订单';
    case AppLanguage.mongolian: return 'Сүүлийн захиалга';
    default: return '최근 주문';
  }}
  String get mypageLoginPrompt { switch (language) {
    case AppLanguage.english: return 'Please login to access this feature';
    case AppLanguage.japanese: return 'この機能を使用するにはログインしてください';
    case AppLanguage.chinese: return '请登录以使用此功能';
    case AppLanguage.mongolian: return 'Энэ функцийг ашиглахын тулд нэвтэрнэ үү';
    default: return '로그인이 필요한 서비스입니다';
  }}


  String get mypageFirstOrder {
    switch (language) {
      case AppLanguage.english: return 'Make your first order! Pull to refresh';
      case AppLanguage.japanese: return '最初の注文をしましょう！下に引っ張って更新';
      case AppLanguage.chinese: return '来下第一个订单！下拉刷新';
      case AppLanguage.mongolian: return 'Анхны захиалгаа өгнө үү! Татаж шинэчлэх';
      default: return '첫 주문을 해보세요! 아래로 당겨 새로고침';
    }
  }
  String get mypageMoreItems {
    switch (language) {
      case AppLanguage.english: return '+{n} more items';
      case AppLanguage.japanese: return '他{n}個商品';
      case AppLanguage.chinese: return '另外{n}件商品';
      case AppLanguage.mongolian: return '+{n} бараа';
      default: return '외 {n}개 상품';
    }
  }
  String get mypageTotalAmount {
    switch (language) {
      case AppLanguage.english: return 'Total {amount}';
      case AppLanguage.japanese: return '合計 {amount}円';
      case AppLanguage.chinese: return '总计 {amount}韩元';
      case AppLanguage.mongolian: return 'Нийт {amount}₩';
      default: return '총 {amount}원';
    }
  }
  String get mypageCancelledNote {
    switch (language) {
      case AppLanguage.english: return 'Cancelled orders cannot be modified';
      case AppLanguage.japanese: return 'キャンセル注文は追加製作/修正不可';
      case AppLanguage.chinese: return '已取消订单不可追加/修改';
      case AppLanguage.mongolian: return 'Цуцлагдсан захиалга өөрчлөх боломжгүй';
      default: return '취소된 주문은 추가제작/수정 요청이 불가합니다';
    }
  }
  String get mypageGroupOnlyNote {
    switch (language) {
      case AppLanguage.english: return 'Additional production only for group custom orders';
      case AppLanguage.japanese: return '追加製作は団体カスタム注文のみ可能';
      case AppLanguage.chinese: return '追加生产仅适用于团体定制订单';
      case AppLanguage.mongolian: return 'Нэмэлт бүтээгдэхүүн зөвхөн бүлгийн';
      default: return '추가제작은 단체커스텀 주문에서만 가능합니다';
    }
  }
  String get mypagePoints {
    switch (language) {
      case AppLanguage.english: return 'Points';
      case AppLanguage.japanese: return 'ポイント';
      case AppLanguage.chinese: return '积分';
      case AppLanguage.mongolian: return 'Оноо';
      default: return '포인트';
    }
  }
  String get mypageGrade {
    switch (language) {
      case AppLanguage.english: return 'Grade';
      case AppLanguage.japanese: return 'グレード';
      case AppLanguage.chinese: return '等级';
      case AppLanguage.mongolian: return 'Зэрэглэл';
      default: return '등급';
    }
  }
  String get mypageSilver {
    switch (language) {
      case AppLanguage.english: return 'Silver';
      case AppLanguage.japanese: return 'シルバー';
      case AppLanguage.chinese: return '银牌';
      case AppLanguage.mongolian: return 'Мөнгөн';
      default: return '실버';
    }
  }
  String get mypageGold {
    switch (language) {
      case AppLanguage.english: return 'Gold';
      case AppLanguage.japanese: return 'ゴールド';
      case AppLanguage.chinese: return '金牌';
      case AppLanguage.mongolian: return 'Алтан';
      default: return '골드';
    }
  }
  String get mypageDiamond {
    switch (language) {
      case AppLanguage.english: return 'Diamond';
      case AppLanguage.japanese: return 'ダイヤモンド';
      case AppLanguage.chinese: return '钻石';
      case AppLanguage.mongolian: return 'Очир';
      default: return '다이아몬드';
    }
  }
  String get mypageReview {
    switch (language) {
      case AppLanguage.english: return 'Review';
      case AppLanguage.japanese: return 'レビュー';
      case AppLanguage.chinese: return '评价';
      case AppLanguage.mongolian: return 'Үнэлгээ';
      default: return '리뷰';
    }
  }
  String get mypageOrderHistory {
    switch (language) {
      case AppLanguage.english: return 'Order History';
      case AppLanguage.japanese: return '注文履歴';
      case AppLanguage.chinese: return '订单历史';
      case AppLanguage.mongolian: return 'Захиалгын түүх';
      default: return '주문 내역';
    }
  }

  String get mypageSettings {
    switch (language) {
      case AppLanguage.english: return 'Settings';
      case AppLanguage.japanese: return '設定';
      case AppLanguage.chinese: return '设置';
      case AppLanguage.mongolian: return 'Тохиргоо';
      default: return '설정';
    }
  }

  String get orderStatusPending {
    switch (language) {
      case AppLanguage.english: return 'Pending';
      case AppLanguage.japanese: return '注文待ち';
      case AppLanguage.chinese: return '待处理';
      case AppLanguage.mongolian: return 'Хүлээж байна';
      default: return '주문 대기';
    }
  }
  String get orderStatusConfirmed {
    switch (language) {
      case AppLanguage.english: return 'Confirmed';
      case AppLanguage.japanese: return '注文確認';
      case AppLanguage.chinese: return '已确认';
      case AppLanguage.mongolian: return 'Баталгаажсан';
      default: return '주문 확인';
    }
  }
  String get orderStatusProducing {
    switch (language) {
      case AppLanguage.english: return 'In Production';
      case AppLanguage.japanese: return '製作/準備中';
      case AppLanguage.chinese: return '生产中';
      case AppLanguage.mongolian: return 'Бэлтгэж байна';
      default: return '제작/준비 중';
    }
  }
  String get orderStatusShipping {
    switch (language) {
      case AppLanguage.english: return 'Shipping';
      case AppLanguage.japanese: return '配送中';
      case AppLanguage.chinese: return '运输中';
      case AppLanguage.mongolian: return 'Хүргэж байна';
      default: return '배송 중';
    }
  }
  String get orderStatusDelivered {
    switch (language) {
      case AppLanguage.english: return 'Delivered';
      case AppLanguage.japanese: return '配送完了';
      case AppLanguage.chinese: return '已送达';
      case AppLanguage.mongolian: return 'Хүргэгдсэн';
      default: return '배송 완료';
    }
  }
  String get orderStatusCancelled {
    switch (language) {
      case AppLanguage.english: return 'Cancelled';
      case AppLanguage.japanese: return '注文キャンセル';
      case AppLanguage.chinese: return '已取消';
      case AppLanguage.mongolian: return 'Цуцлагдсан';
      default: return '주문 취소';
    }
  }
  String get orderStatusRefunded {
    switch (language) {
      case AppLanguage.english: return 'Refunded';
      case AppLanguage.japanese: return '返金完了';
      case AppLanguage.chinese: return '已退款';
      case AppLanguage.mongolian: return 'Буцаагдсан';
      default: return '환불 완료';
    }
  }
  String get checkoutOrdererInfo {
    switch (language) {
      case AppLanguage.english: return 'Orderer Info';
      case AppLanguage.japanese: return '注文者情報';
      case AppLanguage.chinese: return '订购人信息';
      case AppLanguage.mongolian: return 'Захиалагчийн мэдээлэл';
      default: return '주문자 정보';
    }
  }
  String get checkoutName {
    switch (language) {
      case AppLanguage.english: return 'Name';
      case AppLanguage.japanese: return '名前';
      case AppLanguage.chinese: return '姓名';
      case AppLanguage.mongolian: return 'Нэр';
      default: return '이름';
    }
  }
  String get checkoutPhone {
    switch (language) {
      case AppLanguage.english: return 'Phone';
      case AppLanguage.japanese: return '連絡先';
      case AppLanguage.chinese: return '联系方式';
      case AppLanguage.mongolian: return 'Утас';
      default: return '연락처';
    }
  }
  String get checkoutEmail {
    switch (language) {
      case AppLanguage.english: return 'Email';
      case AppLanguage.japanese: return 'メール';
      case AppLanguage.chinese: return '邮箱';
      case AppLanguage.mongolian: return 'Имэйл';
      default: return '이메일';
    }
  }
  String get checkoutDeliveryInfo {
    switch (language) {
      case AppLanguage.english: return 'Delivery Info';
      case AppLanguage.japanese: return '配送情報';
      case AppLanguage.chinese: return '配送信息';
      case AppLanguage.mongolian: return 'Хүргэлтийн мэдээлэл';
      default: return '배송 정보';
    }
  }
  String get checkoutDomestic {
    switch (language) {
      case AppLanguage.english: return '🇰🇷 Domestic';
      case AppLanguage.japanese: return '🇰🇷 国内配送';
      case AppLanguage.chinese: return '🇰🇷 国内配送';
      case AppLanguage.mongolian: return '🇰🇷 Дотоод';
      default: return '🇰🇷  국내 배송';
    }
  }
  String get checkoutOverseas {
    switch (language) {
      case AppLanguage.english: return '🌏 International';
      case AppLanguage.japanese: return '🌏 海外配送';
      case AppLanguage.chinese: return '🌏 国际配送';
      case AppLanguage.mongolian: return '🌏 Гадаад';
      default: return '🌏  해외 배송';
    }
  }
  String get checkoutDeliveryMemo {
    switch (language) {
      case AppLanguage.english: return 'Delivery memo (optional)';
      case AppLanguage.japanese: return '配送メモ (任意)';
      case AppLanguage.chinese: return '配送备注（选填）';
      case AppLanguage.mongolian: return 'Хүргэлтийн тэмдэглэл';
      default: return '배송 메모 (선택)';
    }
  }
  String get checkoutLeaveAtDoor {
    switch (language) {
      case AppLanguage.english: return 'Leave at door';
      case AppLanguage.japanese: return 'ドア前に置いてください';
      case AppLanguage.chinese: return '放门前';
      case AppLanguage.mongolian: return 'Хаалганы өмнө тавих';
      default: return '문 앞에 놔주세요';
    }
  }
  String get checkoutSearchAddress {
    switch (language) {
      case AppLanguage.english: return 'Search address (click)';
      case AppLanguage.japanese: return '住所検索（クリック）';
      case AppLanguage.chinese: return '搜索地址（点击）';
      case AppLanguage.mongolian: return 'Хаяг хайх';
      default: return '주소 검색 (클릭)';
    }
  }
  String get checkoutSearch {
    switch (language) {
      case AppLanguage.english: return 'Search';
      case AppLanguage.japanese: return '検索';
      case AppLanguage.chinese: return '搜索';
      case AppLanguage.mongolian: return 'Хайх';
      default: return '검색';
    }
  }
  String get checkoutDetailAddress {
    switch (language) {
      case AppLanguage.english: return 'Detail address';
      case AppLanguage.japanese: return '詳細住所（棟/号室）';
      case AppLanguage.chinese: return '详细地址';
      case AppLanguage.mongolian: return 'Дэлгэрэнгүй хаяг';
      default: return '상세 주소 (동/호수 등)';
    }
  }
  String get checkoutSearchFirst {
    switch (language) {
      case AppLanguage.english: return 'Please search address first';
      case AppLanguage.japanese: return 'まず住所を検索してください';
      case AppLanguage.chinese: return '请先搜索地址';
      case AppLanguage.mongolian: return 'Эхлээд хаяг хайна уу';
      default: return '먼저 주소를 검색해주세요';
    }
  }
  String get checkoutOverseasHint {
    switch (language) {
      case AppLanguage.english: return 'Enter address in English. Country is required.';
      case AppLanguage.japanese: return '英語で住所を入力してください';
      case AppLanguage.chinese: return '请用英文填写地址，Country为必填';
      case AppLanguage.mongolian: return 'Англи хэлээр хаяг оруулна уу';
      default: return '영문 주소로 입력해주세요. Country는 필수입니다.';
    }
  }
  String get checkoutPayment {
    switch (language) {
      case AppLanguage.english: return 'Payment Method';
      case AppLanguage.japanese: return '決済方法';
      case AppLanguage.chinese: return '支付方式';
      case AppLanguage.mongolian: return 'Төлбөрийн арга';
      default: return '결제 방법';
    }
  }
  String get checkoutKakaoPay {
    switch (language) {
      case AppLanguage.english: return 'Kakao Pay';
      case AppLanguage.japanese: return 'カカオペイ';
      case AppLanguage.chinese: return 'Kakao Pay';
      case AppLanguage.mongolian: return 'Какао Пэй';
      default: return '카카오페이';
    }
  }
  String get checkoutCard {
    switch (language) {
      case AppLanguage.english: return 'Credit/Debit Card';
      case AppLanguage.japanese: return 'クレジット/デビットカード';
      case AppLanguage.chinese: return '信用/借记卡';
      case AppLanguage.mongolian: return 'Карт';
      default: return '신용/체크카드';
    }
  }
  String get checkoutBankTransfer {
    switch (language) {
      case AppLanguage.english: return 'Bank Transfer';
      case AppLanguage.japanese: return '銀行振込';
      case AppLanguage.chinese: return '银行转账';
      case AppLanguage.mongolian: return 'Банкны шилжүүлэг';
      default: return '무통장입금';
    }
  }
  String get checkoutNaverPay {
    switch (language) {
      case AppLanguage.english: return 'Naver Pay';
      case AppLanguage.japanese: return 'ネイバーペイ';
      case AppLanguage.chinese: return 'Naver Pay';
      case AppLanguage.mongolian: return 'Навер Пэй';
      default: return '네이버페이';
    }
  }
  String get checkoutTossPay {
    switch (language) {
      case AppLanguage.english: return 'Toss Pay';
      case AppLanguage.japanese: return 'トスペイ';
      case AppLanguage.chinese: return 'Toss Pay';
      case AppLanguage.mongolian: return 'Тосс Пэй';
      default: return '토스페이';
    }
  }
  String get checkoutPayBtn {
    switch (language) {
      case AppLanguage.english: return 'Pay Now';
      case AppLanguage.japanese: return '決済する';
      case AppLanguage.chinese: return '立即支付';
      case AppLanguage.mongolian: return 'Төлөх';
      default: return '결제하기';
    }
  }
  String get checkoutOrderComplete {
    switch (language) {
      case AppLanguage.english: return 'Order Completed!';
      case AppLanguage.japanese: return '注文が完了しました！';
      case AppLanguage.chinese: return '订单已完成！';
      case AppLanguage.mongolian: return 'Захиалга дууслаа!';
      default: return '주문이 완료되었습니다!';
    }
  }
  String get checkoutPaySuccess {
    switch (language) {
      case AppLanguage.english: return 'Payment processed successfully.';
      case AppLanguage.japanese: return '決済が正常に処理されました。';
      case AppLanguage.chinese: return '付款处理成功。';
      case AppLanguage.mongolian: return 'Төлбөр амжилттай';
      default: return '결제가 정상 처리되었습니다.';
    }
  }
  String get checkoutBankWait {
    switch (language) {
      case AppLanguage.english: return 'Will be processed after deposit.';
      case AppLanguage.japanese: return '入金確認後に処理されます。';
      case AppLanguage.chinese: return '确认入账后处理。';
      case AppLanguage.mongolian: return 'Мөнгө орсны дараа боловсруулна';
      default: return '입금 확인 후 처리됩니다.';
    }
  }
  String get checkoutOrderNum {
    switch (language) {
      case AppLanguage.english: return 'Order No.';
      case AppLanguage.japanese: return '注文番号';
      case AppLanguage.chinese: return '订单编号';
      case AppLanguage.mongolian: return 'Захиалгын №';
      default: return '주문번호';
    }
  }
  String get checkoutPayStatus {
    switch (language) {
      case AppLanguage.english: return 'Payment Status';
      case AppLanguage.japanese: return '決済状態';
      case AppLanguage.chinese: return '支付状态';
      case AppLanguage.mongolian: return 'Төлбөрийн төлөв';
      default: return '결제상태';
    }
  }
  String get checkoutPayComplete {
    switch (language) {
      case AppLanguage.english: return '✅ Paid';
      case AppLanguage.japanese: return '✅ 決済完了';
      case AppLanguage.chinese: return '✅ 已付款';
      case AppLanguage.mongolian: return '✅ Төлсөн';
      default: return '✅ 결제완료';
    }
  }
  String get checkoutAwaitDeposit {
    switch (language) {
      case AppLanguage.english: return '⏳ Awaiting deposit';
      case AppLanguage.japanese: return '⏳ 入金待ち';
      case AppLanguage.chinese: return '⏳ 等待入款';
      case AppLanguage.mongolian: return '⏳ Хүлээж байна';
      default: return '⏳ 입금대기';
    }
  }
  String get checkoutContinueShopping {
    switch (language) {
      case AppLanguage.english: return 'Continue Shopping';
      case AppLanguage.japanese: return 'ショッピングを続ける';
      case AppLanguage.chinese: return '继续购物';
      case AppLanguage.mongolian: return 'Дэлгүүр хэсэх';
      default: return '쇼핑 계속하기';
    }
  }
  String get checkoutViewOrders {
    switch (language) {
      case AppLanguage.english: return 'View Orders';
      case AppLanguage.japanese: return '注文履歴を見る';
      case AppLanguage.chinese: return '查看订单';
      case AppLanguage.mongolian: return 'Захиалга харах';
      default: return '주문 내역 보기';
    }
  }
  String get cartCheckoutBtn {
    switch (language) {
      case AppLanguage.english: return 'Checkout';
      case AppLanguage.japanese: return '決済する';
      case AppLanguage.chinese: return '去结算';
      case AppLanguage.mongolian: return 'Төлбөр хийх';
      default: return '결제하기';
    }
  }
  String get cartFreeShippingAchieved {
    switch (language) {
      case AppLanguage.english: return '🎉 Free shipping unlocked!';
      case AppLanguage.japanese: return '🎉 送料無料達成！';
      case AppLanguage.chinese: return '🎉 已享免费送货！';
      case AppLanguage.mongolian: return '🎉 Үнэгүй хүргэлт!';
      default: return '🎉 무료배송 달성!';
    }
  }
  String get cartMoreForFree {
    switch (language) {
      case AppLanguage.english: return '{amount} more for free shipping!';
      case AppLanguage.japanese: return 'あと{amount}円で送料無料！';
      case AppLanguage.chinese: return '再购{amount}韩元可享免运费！';
      case AppLanguage.mongolian: return '{amount}₩ нэмэх - үнэгүй хүргэлт!';
      default: return '{amount}원 더 담으면 무료배송!';
    }
  }
  String get cartOrderCount {
    switch (language) {
      case AppLanguage.english: return 'Order {n} items';
      case AppLanguage.japanese: return '{n}個注文する';
      case AppLanguage.chinese: return '订购{n}件';
      case AppLanguage.mongolian: return '{n} захиалах';
      default: return '{n}개 주문하기';
    }
  }
  String get cartClearAll {
    switch (language) {
      case AppLanguage.english: return 'Clear Cart';
      case AppLanguage.japanese: return 'カートを空にする';
      case AppLanguage.chinese: return '清空购物车';
      case AppLanguage.mongolian: return 'Сагс хоослох';
      default: return '장바구니 비우기';
    }
  }
  String get cartClearConfirm {
    switch (language) {
      case AppLanguage.english: return 'Remove all items from cart?';
      case AppLanguage.japanese: return '全商品をカートから削除しますか？';
      case AppLanguage.chinese: return '确认清空所有商品吗？';
      case AppLanguage.mongolian: return 'Бүх барааг устгах уу?';
      default: return '모든 상품을 장바구니에서 삭제하겠습니까?';
    }
  }
  String get loginTitle {
    switch (language) {
      case AppLanguage.english: return 'Login';
      case AppLanguage.japanese: return 'ログイン';
      case AppLanguage.chinese: return '登录';
      case AppLanguage.mongolian: return 'Нэвтрэх';
      default: return '로그인';
    }
  }
  String get loginWelcome {
    switch (language) {
      case AppLanguage.english: return 'Welcome to 2FIT MALL';
      case AppLanguage.japanese: return '2FIT MALLへようこそ';
      case AppLanguage.chinese: return '欢迎来到 2FIT MALL';
      case AppLanguage.mongolian: return '2FIT MALL-д тавтай морил';
      default: return '2FIT MALL에 오신 것을 환영합니다';
    }
  }
  String get loginPremiumSports {
    switch (language) {
      case AppLanguage.english: return 'Premium Sportswear';
      case AppLanguage.japanese: return 'プレミアムスポーツウェア';
      case AppLanguage.chinese: return '优质运动服';
      case AppLanguage.mongolian: return 'Онцгой спортын хувцас';
      default: return '프리미엄 스포츠웨어';
    }
  }
  String get loginGroupSpecialist {
    switch (language) {
      case AppLanguage.english: return 'Group Order Specialist';
      case AppLanguage.japanese: return '団体注文専門';
      case AppLanguage.chinese: return '团体订单专家';
      case AppLanguage.mongolian: return 'Бүлгийн захиалгын мэргэжилтэн';
      default: return '단체 주문 전문';
    }
  }
  String get loginEmailHint {
    switch (language) {
      case AppLanguage.english: return 'Enter your email';
      case AppLanguage.japanese: return 'メールを入力してください';
      case AppLanguage.chinese: return '请输入邮箱';
      case AppLanguage.mongolian: return 'Имэйл оруулна уу';
      default: return '이메일을 입력해주세요';
    }
  }
  String get loginEmailError {
    switch (language) {
      case AppLanguage.english: return 'Enter valid email';
      case AppLanguage.japanese: return '正しいメール形式を入力してください';
      case AppLanguage.chinese: return '请输入有效邮箱格式';
      case AppLanguage.mongolian: return 'Зөв имэйл оруулна уу';
      default: return '올바른 이메일 형식을 입력해주세요';
    }
  }
  String get loginPasswordHint {
    switch (language) {
      case AppLanguage.english: return 'Enter password';
      case AppLanguage.japanese: return 'パスワードを入力してください';
      case AppLanguage.chinese: return '请输入密码';
      case AppLanguage.mongolian: return 'Нууц үг оруулна уу';
      default: return '비밀번호를 입력해주세요';
    }
  }
  String get loginPasswordShort {
    switch (language) {
      case AppLanguage.english: return 'Password too short';
      case AppLanguage.japanese: return 'パスワードが短すぎます';
      case AppLanguage.chinese: return '密码太短';
      case AppLanguage.mongolian: return 'Нууц үг богино байна';
      default: return '비밀번호가 너무 짧습니다';
    }
  }
  String get loginFail {
    switch (language) {
      case AppLanguage.english: return 'Login failed.';
      case AppLanguage.japanese: return 'ログインに失敗しました。';
      case AppLanguage.chinese: return '登录失败。';
      case AppLanguage.mongolian: return 'Нэвтрэх амжилтгүй.';
      default: return '로그인에 실패했습니다.';
    }
  }
  String get loginKakao {
    switch (language) {
      case AppLanguage.english: return 'Kakao';
      case AppLanguage.japanese: return 'カカオ';
      case AppLanguage.chinese: return 'Kakao';
      case AppLanguage.mongolian: return 'Какао';
      default: return '카카오';
    }
  }
  String get loginKakaoUser {
    switch (language) {
      case AppLanguage.english: return 'Kakao User';
      case AppLanguage.japanese: return 'カカオユーザー';
      case AppLanguage.chinese: return 'Kakao用户';
      case AppLanguage.mongolian: return 'Какао хэрэглэгч';
      default: return '카카오 사용자';
    }
  }
  String get loginGoogleUser {
    switch (language) {
      case AppLanguage.english: return 'Google User';
      case AppLanguage.japanese: return 'Googleユーザー';
      case AppLanguage.chinese: return 'Google用户';
      case AppLanguage.mongolian: return 'Google хэрэглэгч';
      default: return 'Google 사용자';
    }
  }
  String get loginAdminAccount {
    switch (language) {
      case AppLanguage.english: return 'Admin Account';
      case AppLanguage.japanese: return '管理者アカウント';
      case AppLanguage.chinese: return '管理员账户';
      case AppLanguage.mongolian: return 'Админ акаунт';
      default: return '관리자 계정';
    }
  }
  String get loginNoAccount {
    switch (language) {
      case AppLanguage.english: return "Don't have an account?";
      case AppLanguage.japanese: return 'アカウントをお持ちでないですか？';
      case AppLanguage.chinese: return '还没有账户？';
      case AppLanguage.mongolian: return 'Акаунт байхгүй юу?';
      default: return '아직 계정이 없으신가요?';
    }
  }
  String get loginSignUp {
    switch (language) {
      case AppLanguage.english: return 'Sign Up';
      case AppLanguage.japanese: return '会員登録';
      case AppLanguage.chinese: return '注册';
      case AppLanguage.mongolian: return 'Бүртгүүлэх';
      default: return '회원가입';
    }
  }
  String get loginForgotPassword {
    switch (language) {
      case AppLanguage.english: return 'Forgot Password';
      case AppLanguage.japanese: return 'パスワードをお忘れですか';
      case AppLanguage.chinese: return '忘记密码';
      case AppLanguage.mongolian: return 'Нууц үг мартсан';
      default: return '비밀번호 찾기';
    }
  }
  String get loginSendReset {
    switch (language) {
      case AppLanguage.english: return 'Send Reset Email';
      case AppLanguage.japanese: return 'リセットメールを送信';
      case AppLanguage.chinese: return '发送重置邮件';
      case AppLanguage.mongolian: return 'Шинэчлэх имэйл илгээх';
      default: return '재설정 메일 발송';
    }
  }
  String get productPrice {
    switch (language) {
      case AppLanguage.english: return '{price}';
      case AppLanguage.japanese: return '{price}円';
      case AppLanguage.chinese: return '{price}韩元';
      case AppLanguage.mongolian: return '{price}₩';
      default: return '{price}원';
    }
  }
  String get productReviews {
    switch (language) {
      case AppLanguage.english: return '{n} reviews';
      case AppLanguage.japanese: return 'レビュー{n}件';
      case AppLanguage.chinese: return '{n}条评价';
      case AppLanguage.mongolian: return '{n} үнэлгээ';
      default: return '리뷰 {n}개';
    }
  }
  String get filterApply {
    switch (language) {
      case AppLanguage.english: return 'Apply Filter';
      case AppLanguage.japanese: return 'フィルター適用';
      case AppLanguage.chinese: return '应用筛选';
      case AppLanguage.mongolian: return 'Шүүлтүүр хэрэглэх';
      default: return '필터 적용';
    }
  }
  String get filterSaleOnly {
    switch (language) {
      case AppLanguage.english: return 'Sale items only';
      case AppLanguage.japanese: return 'セール商品のみ';
      case AppLanguage.chinese: return '仅看特卖商品';
      case AppLanguage.mongolian: return 'Зөвхөн хямдрал';
      default: return '세일 상품만';
    }
  }
  String get filterFreeShipping {
    switch (language) {
      case AppLanguage.english: return 'Free shipping only';
      case AppLanguage.japanese: return '送料無料のみ';
      case AppLanguage.chinese: return '仅包邮商品';
      case AppLanguage.mongolian: return 'Зөвхөн үнэгүй хүргэлт';
      default: return '무료배송만';
    }
  }
  String get filterPriceRange {
    switch (language) {
      case AppLanguage.english: return 'Price Range';
      case AppLanguage.japanese: return '価格範囲';
      case AppLanguage.chinese: return '价格区间';
      case AppLanguage.mongolian: return 'Үнийн хязгаар';
      default: return '가격 범위';
    }
  }
  String get filterInit {
    switch (language) {
      case AppLanguage.english: return 'Reset';
      case AppLanguage.japanese: return 'リセット';
      case AppLanguage.chinese: return '重置';
      case AppLanguage.mongolian: return 'Цэвэрлэх';
      default: return '초기화';
    }
  }
  String get sortNewest2 {
    switch (language) {
      case AppLanguage.english: return 'Newest';
      case AppLanguage.japanese: return '新着順';
      case AppLanguage.chinese: return '最新';
      case AppLanguage.mongolian: return 'Шинэ';
      default: return '최신순';
    }
  }
  String get sortPriceLow2 {
    switch (language) {
      case AppLanguage.english: return 'Price: Low';
      case AppLanguage.japanese: return '価格が安い順';
      case AppLanguage.chinese: return '价格低到高';
      case AppLanguage.mongolian: return 'Үнэ: бага';
      default: return '가격 낮은 순';
    }
  }
  String get sortPriceHigh2 {
    switch (language) {
      case AppLanguage.english: return 'Price: High';
      case AppLanguage.japanese: return '価格が高い順';
      case AppLanguage.chinese: return '价格高到低';
      case AppLanguage.mongolian: return 'Үнэ: өндөр';
      default: return '가격 높은 순';
    }
  }
  String get sortPopular2 {
    switch (language) {
      case AppLanguage.english: return 'Popular';
      case AppLanguage.japanese: return '人気順';
      case AppLanguage.chinese: return '热门';
      case AppLanguage.mongolian: return 'Алдартай';
      default: return '인기순';
    }
  }
  String get sortRating2 {
    switch (language) {
      case AppLanguage.english: return 'Rating';
      case AppLanguage.japanese: return '評価順';
      case AppLanguage.chinese: return '评分';
      case AppLanguage.mongolian: return 'Үнэлгээ';
      default: return '평점순';
    }
  }
  String get sortNewArrival2 {
    switch (language) {
      case AppLanguage.english: return 'New';
      case AppLanguage.japanese: return '新着';
      case AppLanguage.chinese: return '新品';
      case AppLanguage.mongolian: return 'Шинэ';
      default: return '신상품';
    }
  }
  String get viewGrid {
    switch (language) {
      case AppLanguage.english: return 'Grid';
      case AppLanguage.japanese: return 'グリッド';
      case AppLanguage.chinese: return '网格';
      case AppLanguage.mongolian: return 'Торон';
      default: return '그리드';
    }
  }
  String get viewList {
    switch (language) {
      case AppLanguage.english: return 'List';
      case AppLanguage.japanese: return 'リスト';
      case AppLanguage.chinese: return '列表';
      case AppLanguage.mongolian: return 'Жагсаалт';
      default: return '리스트';
    }
  }
  String get detailAddToCart {
    switch (language) {
      case AppLanguage.english: return 'Add to Cart';
      case AppLanguage.japanese: return 'カートに入れる';
      case AppLanguage.chinese: return '加入购物车';
      case AppLanguage.mongolian: return 'Сагсанд нэмэх';
      default: return '장바구니 담기';
    }
  }
  String get detailBuyNow {
    switch (language) {
      case AppLanguage.english: return 'Buy Now';
      case AppLanguage.japanese: return '今すぐ購入';
      case AppLanguage.chinese: return '立即购买';
      case AppLanguage.mongolian: return 'Одоо авах';
      default: return '즉시 구매';
    }
  }
  String get detailDescription {
    switch (language) {
      case AppLanguage.english: return 'Description';
      case AppLanguage.japanese: return '商品説明';
      case AppLanguage.chinese: return '商品描述';
      case AppLanguage.mongolian: return 'Тайлбар';
      default: return '상품 설명';
    }
  }
  String get detailReviews {
    switch (language) {
      case AppLanguage.english: return 'Reviews';
      case AppLanguage.japanese: return 'レビュー';
      case AppLanguage.chinese: return '评价';
      case AppLanguage.mongolian: return 'Үнэлгээ';
      default: return '리뷰';
    }
  }
  String get detailSizeGuide {
    switch (language) {
      case AppLanguage.english: return 'Size Guide';
      case AppLanguage.japanese: return 'サイズガイド';
      case AppLanguage.chinese: return '尺码指南';
      case AppLanguage.mongolian: return 'Хэмжээний заавар';
      default: return '사이즈 가이드';
    }
  }
  String get detailColorSelect {
    switch (language) {
      case AppLanguage.english: return 'Color';
      case AppLanguage.japanese: return 'カラー選択';
      case AppLanguage.chinese: return '颜色选择';
      case AppLanguage.mongolian: return 'Өнгө сонгох';
      default: return '색상 선택';
    }
  }
  String get detailSizeSelect {
    switch (language) {
      case AppLanguage.english: return 'Size';
      case AppLanguage.japanese: return 'サイズ選択';
      case AppLanguage.chinese: return '尺码选择';
      case AppLanguage.mongolian: return 'Хэмжээ сонгох';
      default: return '사이즈 선택';
    }
  }
  String get detailQuantity {
    switch (language) {
      case AppLanguage.english: return 'Qty';
      case AppLanguage.japanese: return '数量';
      case AppLanguage.chinese: return '数量';
      case AppLanguage.mongolian: return 'Тоо';
      default: return '수량';
    }
  }
  String get detailStock {
    switch (language) {
      case AppLanguage.english: return 'Stock';
      case AppLanguage.japanese: return '在庫';
      case AppLanguage.chinese: return '库存';
      case AppLanguage.mongolian: return 'Нөөц';
      default: return '재고';
    }
  }
  String get detailNoStock {
    switch (language) {
      case AppLanguage.english: return 'Sold Out';
      case AppLanguage.japanese: return '売り切れ';
      case AppLanguage.chinese: return '售罄';
      case AppLanguage.mongolian: return 'Дууссан';
      default: return '품절';
    }
  }
  String get detailShipping {
    switch (language) {
      case AppLanguage.english: return 'Shipping Info';
      case AppLanguage.japanese: return '配送情報';
      case AppLanguage.chinese: return '配送信息';
      case AppLanguage.mongolian: return 'Хүргэлт';
      default: return '배송 정보';
    }
  }
  String get detailReturn {
    switch (language) {
      case AppLanguage.english: return 'Exchange/Return';
      case AppLanguage.japanese: return '交換/返品';
      case AppLanguage.chinese: return '换货/退货';
      case AppLanguage.mongolian: return 'Буцаалт';
      default: return '교환/반품';
    }
  }
  String get detailFreeShippingBenefit {
    switch (language) {
      case AppLanguage.english: return '₩300,000+';
      case AppLanguage.japanese: return '30万ウォン+';
      case AppLanguage.chinese: return '30万韩元+';
      case AppLanguage.mongolian: return '₩300,000+';
      default: return '300,000원+';
    }
  }
  String get detailBenefit {
    switch (language) {
      case AppLanguage.english: return 'Benefits';
      case AppLanguage.japanese: return '特典提供';
      case AppLanguage.chinese: return '提供优惠';
      case AppLanguage.mongolian: return 'Урамшуулал';
      default: return '혜택 제공';
    }
  }
  String get detailWriteReview {
    switch (language) {
      case AppLanguage.english: return 'Write Review';
      case AppLanguage.japanese: return 'レビュー作成';
      case AppLanguage.chinese: return '写评价';
      case AppLanguage.mongolian: return 'Үнэлгээ бичих';
      default: return '리뷰 작성';
    }
  }
  String get detailNoReviews {
    switch (language) {
      case AppLanguage.english: return 'Be the first to review!';
      case AppLanguage.japanese: return '最初のレビューを書いてください！';
      case AppLanguage.chinese: return '成为第一个评价！';
      case AppLanguage.mongolian: return 'Эхний үнэлгээ бичих!';
      default: return '첫 리뷰를 남겨주세요!';
    }
  }
  String get detailTabProduct {
    switch (language) {
      case AppLanguage.english: return 'Product Info';
      case AppLanguage.japanese: return '商品情報';
      case AppLanguage.chinese: return '商品信息';
      case AppLanguage.mongolian: return 'Бараа';
      default: return '상품정보';
    }
  }
  String get detailTabReview {
    switch (language) {
      case AppLanguage.english: return 'Review';
      case AppLanguage.japanese: return 'レビュー';
      case AppLanguage.chinese: return '评价';
      case AppLanguage.mongolian: return 'Үнэлгээ';
      default: return '리뷰';
    }
  }
  String get detailTabGuide {
    switch (language) {
      case AppLanguage.english: return 'Production Guide';
      case AppLanguage.japanese: return '製作案内';
      case AppLanguage.chinese: return '生产说明';
      case AppLanguage.mongolian: return 'Заавар';
      default: return '제작안내';
    }
  }
  String get detailTabQnA {
    switch (language) {
      case AppLanguage.english: return 'Q&A';
      case AppLanguage.japanese: return 'Q&A';
      case AppLanguage.chinese: return 'Q&A';
      case AppLanguage.mongolian: return 'Асуулт';
      default: return 'Q&A';
    }
  }
  String get detailShareBtn {
    switch (language) {
      case AppLanguage.english: return 'Share';
      case AppLanguage.japanese: return '共有';
      case AppLanguage.chinese: return '分享';
      case AppLanguage.mongolian: return 'Хуваалцах';
      default: return '공유';
    }
  }
  String get detailWishBtn {
    switch (language) {
      case AppLanguage.english: return 'Wish';
      case AppLanguage.japanese: return 'お気に入り';
      case AppLanguage.chinese: return '收藏';
      case AppLanguage.mongolian: return 'Хүсэх';
      default: return '찜';
    }
  }
  String get detailMale {
    switch (language) {
      case AppLanguage.english: return 'Male';
      case AppLanguage.japanese: return '男性';
      case AppLanguage.chinese: return '男';
      case AppLanguage.mongolian: return 'Эр';
      default: return '남';
    }
  }
  String get detailFemale {
    switch (language) {
      case AppLanguage.english: return 'Female';
      case AppLanguage.japanese: return '女性';
      case AppLanguage.chinese: return '女';
      case AppLanguage.mongolian: return 'Эм';
      default: return '여';
    }
  }
  String get detailSizeChart {
    switch (language) {
      case AppLanguage.english: return 'Size Chart';
      case AppLanguage.japanese: return 'サイズチャート';
      case AppLanguage.chinese: return '尺码表';
      case AppLanguage.mongolian: return 'Хэмжээний хүснэгт';
      default: return '사이즈 차트';
    }
  }
  String get detailChest {
    switch (language) {
      case AppLanguage.english: return 'Chest(cm)';
      case AppLanguage.japanese: return '胸囲(cm)';
      case AppLanguage.chinese: return '胸围(cm)';
      case AppLanguage.mongolian: return 'Цээж(cm)';
      default: return '가슴(cm)';
    }
  }
  String get detailWaist {
    switch (language) {
      case AppLanguage.english: return 'Waist(cm)';
      case AppLanguage.japanese: return 'ウエスト(cm)';
      case AppLanguage.chinese: return '腰围(cm)';
      case AppLanguage.mongolian: return 'Бүсэлхий(cm)';
      default: return '허리(cm)';
    }
  }
  String get detailHip {
    switch (language) {
      case AppLanguage.english: return 'Hip(cm)';
      case AppLanguage.japanese: return '腰回り(cm)';
      case AppLanguage.chinese: return '臀围(cm)';
      case AppLanguage.mongolian: return 'Ташаа(cm)';
      default: return '엉덩이(cm)';
    }
  }
  String get detailHeight {
    switch (language) {
      case AppLanguage.english: return 'Height(cm)';
      case AppLanguage.japanese: return '身長(cm)';
      case AppLanguage.chinese: return '身高(cm)';
      case AppLanguage.mongolian: return 'Өндөр(cm)';
      default: return '키(cm)';
    }
  }
  String get detailWeight {
    switch (language) {
      case AppLanguage.english: return 'Weight(kg)';
      case AppLanguage.japanese: return '体重(kg)';
      case AppLanguage.chinese: return '体重(kg)';
      case AppLanguage.mongolian: return 'Жин(kg)';
      default: return '몸무게(kg)';
    }
  }
  String get detailGenderSelect {
    switch (language) {
      case AppLanguage.english: return 'Select Gender';
      case AppLanguage.japanese: return '性別選択';
      case AppLanguage.chinese: return '选择性别';
      case AppLanguage.mongolian: return 'Хүйс сонгох';
      default: return '성별 선택';
    }
  }
  String get detailLengthPart5 {
    switch (language) {
      case AppLanguage.english: return '3/4 Length';
      case AppLanguage.japanese: return '5分丈';
      case AppLanguage.chinese: return '五分长';
      case AppLanguage.mongolian: return '5-р хэсэг';
      default: return '5부';
    }
  }
  String get detailOrderCustom {
    switch (language) {
      case AppLanguage.english: return 'Custom Order';
      case AppLanguage.japanese: return 'カスタム注文';
      case AppLanguage.chinese: return '定制订单';
      case AppLanguage.mongolian: return 'Захиалгат';
      default: return '커스텀 주문하기';
    }
  }
  String get detailGroupOrder {
    switch (language) {
      case AppLanguage.english: return 'Group Order';
      case AppLanguage.japanese: return '団体注文';
      case AppLanguage.chinese: return '团体订单';
      case AppLanguage.mongolian: return 'Бүлгийн захиалга';
      default: return '단체 주문하기';
    }
  }
  String get groupOrderTitle {
    switch (language) {
      case AppLanguage.english: return 'Group Order Guide';
      case AppLanguage.japanese: return '団体注文ガイド';
      case AppLanguage.chinese: return '团体订单指南';
      case AppLanguage.mongolian: return 'Бүлгийн захиалгын заавар';
      default: return '단체 주문 가이드';
    }
  }
  String get groupMinQty {
    switch (language) {
      case AppLanguage.english: return 'Minimum Qty';
      case AppLanguage.japanese: return '最小数量';
      case AppLanguage.chinese: return '最小数量';
      case AppLanguage.mongolian: return 'Хамгийн бага тоо';
      default: return '최소 수량';
    }
  }
  String get groupMinDesc {
    switch (language) {
      case AppLanguage.english: return 'Group custom production from 5 people.';
      case AppLanguage.japanese: return '団体カスタム製作は最小5名から可能です。';
      case AppLanguage.chinese: return '团体定制生产最少5人起。';
      case AppLanguage.mongolian: return 'Бүлгийн захиалга 5-аас хүнээс';
      default: return '단체 커스텀 제작은 최소 5명부터 가능합니다.';
    }
  }
  String get groupDelivery {
    switch (language) {
      case AppLanguage.english: return 'Delivery Info';
      case AppLanguage.japanese: return '配送案内';
      case AppLanguage.chinese: return '配送说明';
      case AppLanguage.mongolian: return 'Хүргэлтийн мэдээлэл';
      default: return '배송 안내';
    }
  }
  String get groupCustomOptions {
    switch (language) {
      case AppLanguage.english: return 'Custom Options';
      case AppLanguage.japanese: return 'カスタムオプション';
      case AppLanguage.chinese: return '定制选项';
      case AppLanguage.mongolian: return 'Захиалгат сонголт';
      default: return '커스텀 옵션';
    }
  }
  String get groupPrintType {
    switch (language) {
      case AppLanguage.english: return 'Print Type';
      case AppLanguage.japanese: return '印刷タイプ';
      case AppLanguage.chinese: return '印刷类型';
      case AppLanguage.mongolian: return 'Хэвлэлтийн төрөл';
      default: return '인쇄 타입';
    }
  }
  String get groupDiscountExclusive {
    switch (language) {
      case AppLanguage.english: return 'Exclusive Design Option (optional)';
      case AppLanguage.japanese: return 'デザイン独占使用オプション (任意)';
      case AppLanguage.chinese: return '独家设计选项（可选）';
      case AppLanguage.mongolian: return 'Онцгой дизайн (нэмэлт)';
      default: return '디자인 독점 사용 옵션 (선택)';
    }
  }
  String get groupQtyDiscount {
    switch (language) {
      case AppLanguage.english: return 'Qty Discount';
      case AppLanguage.japanese: return '数量別割引';
      case AppLanguage.chinese: return '数量折扣';
      case AppLanguage.mongolian: return 'Тоо хэмжээний хөнгөлөлт';
      default: return '수량별 할인';
    }
  }
  String get groupOrderForm {
    switch (language) {
      case AppLanguage.english: return 'Order Form';
      case AppLanguage.japanese: return '注文フォーム';
      case AppLanguage.chinese: return '订单表格';
      case AppLanguage.mongolian: return 'Захиалгын маягт';
      default: return '주문 양식';
    }
  }
  String get groupOrderGuide {
    switch (language) {
      case AppLanguage.english: return 'Order Guide';
      case AppLanguage.japanese: return '注文案内';
      case AppLanguage.chinese: return '订单指南';
      case AppLanguage.mongolian: return 'Захиалгын заавар';
      default: return '주문 안내';
    }
  }
  String get groupPeople5up {
    switch (language) {
      case AppLanguage.english: return '5+';
      case AppLanguage.japanese: return '5名↑';
      case AppLanguage.chinese: return '5人↑';
      case AppLanguage.mongolian: return '5+';
      default: return '5인↑';
    }
  }
  String get groupTeamColorPrint {
    switch (language) {
      case AppLanguage.english: return 'Team color + name print';
      case AppLanguage.japanese: return 'チームカラー+団体名印刷';
      case AppLanguage.chinese: return '团队颜色+团体名印刷';
      case AppLanguage.mongolian: return 'Багийн өнгө + нэр хэвлэх';
      default: return '팀 컬러 + 단체명 인쇄';
    }
  }
  String get groupPeople10up {
    switch (language) {
      case AppLanguage.english: return '10+';
      case AppLanguage.japanese: return '10名↑';
      case AppLanguage.chinese: return '10人↑';
      case AppLanguage.mongolian: return '10+';
      default: return '10인↑';
    }
  }
  String get groupNameNumPrint {
    switch (language) {
      case AppLanguage.english: return 'Name + number print';
      case AppLanguage.japanese: return '名前+番号追加印刷';
      case AppLanguage.chinese: return '名字+号码额外印刷';
      case AppLanguage.mongolian: return 'Нэр + дугаар хэвлэх';
      default: return '이름 + 번호 추가 인쇄';
    }
  }
  String get groupPeople30up {
    switch (language) {
      case AppLanguage.english: return '30+';
      case AppLanguage.japanese: return '30名↑';
      case AppLanguage.chinese: return '30人↑';
      case AppLanguage.mongolian: return '30+';
      default: return '30인↑';
    }
  }
  String get group10pctDiscount {
    switch (language) {
      case AppLanguage.english: return '10% Group Discount';
      case AppLanguage.japanese: return '10%団体割引';
      case AppLanguage.chinese: return '10%团体折扣';
      case AppLanguage.mongolian: return '10% хөнгөлөлт';
      default: return '10% 단체 할인';
    }
  }
  String get groupPeople50up {
    switch (language) {
      case AppLanguage.english: return '50+';
      case AppLanguage.japanese: return '50名↑';
      case AppLanguage.chinese: return '50人↑';
      case AppLanguage.mongolian: return '50+';
      default: return '50인↑';
    }
  }
  String get group20pctDiscount {
    switch (language) {
      case AppLanguage.english: return '20% Group Discount';
      case AppLanguage.japanese: return '20%団体割引';
      case AppLanguage.chinese: return '20%团体折扣';
      case AppLanguage.mongolian: return '20% хөнгөлөлт';
      default: return '20% 단체 할인';
    }
  }
  String get groupStartOrder {
    switch (language) {
      case AppLanguage.english: return 'Start Order';
      case AppLanguage.japanese: return '注文フォーム作成';
      case AppLanguage.chinese: return '填写订单';
      case AppLanguage.mongolian: return 'Захиалга үүсгэх';
      default: return '주문서 작성';
    }
  }
  String get groupSelectProduct {
    switch (language) {
      case AppLanguage.english: return 'Select & customize';
      case AppLanguage.japanese: return '商品選択＆カスタム設定';
      case AppLanguage.chinese: return '选择商品并设置定制';
      case AppLanguage.mongolian: return 'Бараа сонгох & тохируулах';
      default: return '상품 선택 & 커스텀 설정';
    }
  }
  String get groupDraftCheck {
    switch (language) {
      case AppLanguage.english: return 'Draft Review';
      case AppLanguage.japanese: return '試案確認';
      case AppLanguage.chinese: return '确认样稿';
      case AppLanguage.mongolian: return 'Загвар шалгах';
      default: return '시안 확인';
    }
  }
  String get groupDraftDays {
    switch (language) {
      case AppLanguage.english: return 'Draft in 3 business days';
      case AppLanguage.japanese: return '3営業日以内に試案送付';
      case AppLanguage.chinese: return '3个工作日内发送样稿';
      case AppLanguage.mongolian: return '3 ажлын өдөрт';
      default: return '영업일 3일 내 시안 발송';
    }
  }
  String get groupPayment {
    switch (language) {
      case AppLanguage.english: return 'Payment';
      case AppLanguage.japanese: return '決済';
      case AppLanguage.chinese: return '付款';
      case AppLanguage.mongolian: return 'Төлбөр';
      default: return '결제';
    }
  }
  String get groupPaymentAfterApproval {
    switch (language) {
      case AppLanguage.english: return 'Payment after approval';
      case AppLanguage.japanese: return '承認後決済案内';
      case AppLanguage.chinese: return '审批后支付说明';
      case AppLanguage.mongolian: return 'Зөвшөөрлийн дараа';
      default: return '승인 후 결제 안내';
    }
  }
  String get groupProduction {
    switch (language) {
      case AppLanguage.english: return 'Production';
      case AppLanguage.japanese: return '製作';
      case AppLanguage.chinese: return '生产';
      case AppLanguage.mongolian: return 'Үйлдвэрлэл';
      default: return '제작';
    }
  }
  String get groupProductionDays {
    switch (language) {
      case AppLanguage.english: return '14~21 days';
      case AppLanguage.japanese: return '14〜21日所要';
      case AppLanguage.chinese: return '需14~21天';
      case AppLanguage.mongolian: return '14~21 өдөр';
      default: return '14~21일 소요';
    }
  }
  String get groupShipping {
    switch (language) {
      case AppLanguage.english: return 'Shipping';
      case AppLanguage.japanese: return '配送';
      case AppLanguage.chinese: return '发货';
      case AppLanguage.mongolian: return 'Хүргэлт';
      default: return '배송';
    }
  }
  String get groupShippingSeq {
    switch (language) {
      case AppLanguage.english: return 'Sequential shipping';
      case AppLanguage.japanese: return '順次発送';
      case AppLanguage.chinese: return '按顺序发货';
      case AppLanguage.mongolian: return 'Дарааллаар илгээх';
      default: return '순차 발송';
    }
  }
  String get groupCustomer {
    switch (language) {
      case AppLanguage.english: return 'Customer Service';
      case AppLanguage.japanese: return 'カスタマーセンター';
      case AppLanguage.chinese: return '客服中心';
      case AppLanguage.mongolian: return 'Харилцагчийн үйлчилгээ';
      default: return '고객센터';
    }
  }
  String get groupKakaoId {
    switch (language) {
      case AppLanguage.english: return 'Kakao: @2fitkorea';
      case AppLanguage.japanese: return 'カカオトーク @2fitkorea';
      case AppLanguage.chinese: return '韩国Kakao: @2fitkorea';
      case AppLanguage.mongolian: return 'Какао: @2fitkorea';
      default: return '카카오톡 @2fitkorea';
    }
  }
  String get groupSelectType {
    switch (language) {
      case AppLanguage.english: return 'Select Order Type';
      case AppLanguage.japanese: return '注文タイプ選択';
      case AppLanguage.chinese: return '选择订单类型';
      case AppLanguage.mongolian: return 'Захиалгын төрөл';
      default: return '주문 유형 선택';
    }
  }
  String get groupSelectTypeDesc {
    switch (language) {
      case AppLanguage.english: return 'Check guide or start order form';
      case AppLanguage.japanese: return 'まず注文案内を確認するか、すぐに注文フォームへ';
      case AppLanguage.chinese: return '先查看订单指南，或直接填写订单';
      case AppLanguage.mongolian: return 'Заавар эхлээд үзэх';
      default: return '주문 안내를 먼저 확인하거나, 바로 주문서를 작성하세요';
    }
  }
  String get groupCustomOrderTitle {
    switch (language) {
      case AppLanguage.english: return 'Group Custom Order';
      case AppLanguage.japanese: return '団体カスタム注文';
      case AppLanguage.chinese: return '团体定制订单';
      case AppLanguage.mongolian: return 'Бүлгийн захиалгат';
      default: return '단체 커스텀 주문';
    }
  }
  String get group5upBenefit {
    switch (language) {
      case AppLanguage.english: return 'Group benefits 5+';
      case AppLanguage.japanese: return '5名以上団体特典';
      case AppLanguage.chinese: return '5人以上团体优惠';
      case AppLanguage.mongolian: return '5+ хүн - хөнгөлөлт';
      default: return '5인 이상 단체 혜택';
    }
  }
  String get groupLogoPrint {
    switch (language) {
      case AppLanguage.english: return 'Team logo, name/no. print, group discount';
      case AppLanguage.japanese: return 'チームロゴ、名前/番号印刷、団体割引';
      case AppLanguage.chinese: return '团队logo、名字/号码印刷、团体折扣';
      case AppLanguage.mongolian: return 'Лого, нэр/дугаар хэвлэх, хөнгөлөлт';
      default: return '팀 로고, 이름/번호 인쇄, 단체 할인 적용';
    }
  }
  String get groupPersonalOrder {
    switch (language) {
      case AppLanguage.english: return 'Personal Custom Order';
      case AppLanguage.japanese: return 'パーソナルカスタム注文';
      case AppLanguage.chinese: return '个人定制订单';
      case AppLanguage.mongolian: return 'Хувийн захиалгат';
      default: return '개인 맞춤 주문';
    }
  }
  String get groupFrom1 {
    switch (language) {
      case AppLanguage.english: return 'From 1 person';
      case AppLanguage.japanese: return '1名から可能';
      case AppLanguage.chinese: return '1人起';
      case AppLanguage.mongolian: return '1 хүнээс';
      default: return '1인부터 가능';
    }
  }
  String get groupFreeCustom {
    switch (language) {
      case AppLanguage.english: return 'Color/name/logo custom, free ship 300k+';
      case AppLanguage.japanese: return 'カラー·名前·ロゴカスタム、30万ウォン+送料無料';
      case AppLanguage.chinese: return '颜色·名字·logo定制，满30万韩元免运费';
      case AppLanguage.mongolian: return 'Өнгө·нэр·лого, ₩300k+ үнэгүй';
      default: return '색상·이름·로고 커스텀, 300,000원↑ 무료배송';
    }
  }
  String get groupLogoText {
    switch (language) {
      case AppLanguage.english: return 'Team Logo';
      case AppLanguage.japanese: return 'チームロゴ';
      case AppLanguage.chinese: return '团队Logo';
      case AppLanguage.mongolian: return 'Багийн лого';
      default: return '팀 로고';
    }
  }
  String get personalTitle {
    switch (language) {
      case AppLanguage.english: return 'Personal Custom Guide';
      case AppLanguage.japanese: return 'パーソナルカスタム製作案内';
      case AppLanguage.chinese: return '个人定制说明';
      case AppLanguage.mongolian: return 'Хувийн захиалгын заавар';
      default: return '개인 맞춤 제작 안내';
    }
  }
  String get personalFrom1 {
    switch (language) {
      case AppLanguage.english: return 'From 1 · Free custom';
      case AppLanguage.japanese: return '1名から可能·フリーカスタム';
      case AppLanguage.chinese: return '1人起·自由定制';
      case AppLanguage.mongolian: return '1 хүнээс · Чөлөөт';
      default: return '1인부터 가능 · 자유 커스텀';
    }
  }
  String get personalColorOnly {
    switch (language) {
      case AppLanguage.english: return '① Color Only';
      case AppLanguage.japanese: return '①カラーのみ変更';
      case AppLanguage.chinese: return '①仅换色';
      case AppLanguage.mongolian: return '① Зөвхөн өнгө';
      default: return '① 컬러만 변경';
    }
  }
  String get personalColorOnlyDesc {
    switch (language) {
      case AppLanguage.english: return 'Keep design · Change color';
      case AppLanguage.japanese: return 'デザイン維持·色変更';
      case AppLanguage.chinese: return '保持设计·更换颜色';
      case AppLanguage.mongolian: return 'Дизайн хэвээр · Өнгө солих';
      default: return '기본 디자인 유지 · 원하는 색상 변경';
    }
  }
  String get personalColorName {
    switch (language) {
      case AppLanguage.english: return '② Front name + color';
      case AppLanguage.japanese: return '②前面団体名+カラー';
      case AppLanguage.chinese: return '②正面团体名+颜色';
      case AppLanguage.mongolian: return '② Нэр + өнгө';
      default: return '② 앞면 단체명 + 컬러';
    }
  }
  String get personalColorNameDesc {
    switch (language) {
      case AppLanguage.english: return 'Color + front team/name print';
      case AppLanguage.japanese: return 'カラー変更+前面チーム名印刷';
      case AppLanguage.chinese: return '换色+正面印刷团队/个人名';
      case AppLanguage.mongolian: return 'Өнгө + нэр хэвлэх';
      default: return '컬러 변경 + 앞면 팀/개인명 인쇄';
    }
  }
  String get personalFullCustom {
    switch (language) {
      case AppLanguage.english: return '③ Name + color + individual';
      case AppLanguage.japanese: return '③団体名+カラー+名前';
      case AppLanguage.chinese: return '③团体名+颜色+个人名';
      case AppLanguage.mongolian: return '③ Нэр + өнгө + хувь нэрс';
      default: return '③ 단체명 + 컬러 + 이름';
    }
  }
  String get personalFullCustomDesc {
    switch (language) {
      case AppLanguage.english: return 'Front + back name print (all custom)';
      case AppLanguage.japanese: return '前面+背面名前印刷（全カスタム）';
      case AppLanguage.chinese: return '正背面均印名字（全定制）';
      case AppLanguage.mongolian: return 'Нэр хэвлэх (бүтэн)';
      default: return '앞면 + 뒷면 이름 인쇄 (모든 커스텀)';
    }
  }
  String get personalWaistband {
    switch (language) {
      case AppLanguage.english: return 'Waistband color change';
      case AppLanguage.japanese: return 'ウエストバンドカラー変更';
      case AppLanguage.chinese: return '腰带换色';
      case AppLanguage.mongolian: return 'Бүсэлхийн өнгө';
      default: return '허리밴드 컬러 변경';
    }
  }
  String get personalWaistbandDesc {
    switch (language) {
      case AppLanguage.english: return 'Waistband color only ⚠️ No design change';
      case AppLanguage.japanese: return 'ウエストバンド色変更⚠️デザイン変更不可';
      case AppLanguage.chinese: return '腰带换色⚠️不可更改设计';
      case AppLanguage.mongolian: return 'Бүсэлхий өнгө ⚠️ Дизайн биш';
      default: return '허리밴드 색상 변경 ⚠️ 디자인 변경 불가';
    }
  }
  String get personalPriceAdd80k {
    switch (language) {
      case AppLanguage.english: return '+₩80,000';
      case AppLanguage.japanese: return '+80,000円';
      case AppLanguage.chinese: return '+8万韩元';
      case AppLanguage.mongolian: return '+₩80,000';
      default: return '+80,000원';
    }
  }
  String get personalPriceAdd100k {
    switch (language) {
      case AppLanguage.english: return '+₩100,000';
      case AppLanguage.japanese: return '+100,000円';
      case AppLanguage.chinese: return '+10万韩元';
      case AppLanguage.mongolian: return '+₩100,000';
      default: return '+100,000원';
    }
  }
  String get personalPriceAdd60k {
    switch (language) {
      case AppLanguage.english: return '+₩60,000';
      case AppLanguage.japanese: return '+60,000円';
      case AppLanguage.chinese: return '+6万韩元';
      case AppLanguage.mongolian: return '+₩60,000';
      default: return '+60,000원';
    }
  }
  String get personalCheckConfirm {
    switch (language) {
      case AppLanguage.english: return 'I have read all the order information';
      case AppLanguage.japanese: return '注文案内の内容を全て確認しました';
      case AppLanguage.chinese: return '我已阅读全部订单说明';
      case AppLanguage.mongolian: return 'Бүх мэдээллийг уншсан';
      default: return '주문 안내 내용을 모두 확인하였습니다';
    }
  }
  String get personalStartOrder {
    switch (language) {
      case AppLanguage.english: return 'Start Personal Order';
      case AppLanguage.japanese: return '個人注文フォームへ';
      case AppLanguage.chinese: return '开始个人订单';
      case AppLanguage.mongolian: return 'Хувийн захиалга эхлэх';
      default: return '개인 주문서 작성하기';
    }
  }
  String get personalCheckFirst {
    switch (language) {
      case AppLanguage.english: return 'Check the guide before ordering';
      case AppLanguage.japanese: return '案内確認チェック後に注文フォーム作成可能';
      case AppLanguage.chinese: return '请先勾选确认说明再填写订单';
      case AppLanguage.mongolian: return 'Эхлээд заавар шалгана уу';
      default: return '안내를 확인 체크 후 주문서 작성이 가능합니다';
    }
  }
  String get personalDelivery14_21 {
    switch (language) {
      case AppLanguage.english: return 'Production: 14~21 days | Free ship ₩300k+';
      case AppLanguage.japanese: return '製作14~21日|30万ウォン+送料無料';
      case AppLanguage.chinese: return '生产14~21天|满30万免运费';
      case AppLanguage.mongolian: return '14~21 өдөр | ₩300k+ үнэгүй';
      default: return '제작 기간: 14~21일 | 300,000원↑ 무료배송';
    }
  }
  String get personalAdditionalOrder {
    switch (language) {
      case AppLanguage.english: return 'Additional Order';
      case AppLanguage.japanese: return '既存注文追加注文';
      case AppLanguage.chinese: return '追加订购';
      case AppLanguage.mongolian: return 'Нэмэлт захиалга';
      default: return '기존 주문 추가 주문';
    }
  }
  String get personalAdditionalNote {
    switch (language) {
      case AppLanguage.english: return 'Within 1 week of original order';
      case AppLanguage.japanese: return '元注文後1週間以内';
      case AppLanguage.chinese: return '原订单后1周内';
      case AppLanguage.mongolian: return 'Анхны захиалгаас 1 долоо хоногт';
      default: return '원본 주문 후 1주일 이내';
    }
  }

  String get personalFormSubmitBtn {
    switch (language) {
      case AppLanguage.english: return 'Submit Order';
      case AppLanguage.japanese: return '注文フォームを提出する';
      case AppLanguage.chinese: return '提交订单';
      case AppLanguage.mongolian: return 'Захиалга илгээх';
      default: return '주문서 제출하기';
    }
  }
  String get customTitle {
    switch (language) {
      case AppLanguage.english: return 'Custom Order';
      case AppLanguage.japanese: return 'カスタム注文';
      case AppLanguage.chinese: return '定制订单';
      case AppLanguage.mongolian: return 'Захиалгат';
      default: return '커스텀 주문';
    }
  }
  String get customMinQty {
    switch (language) {
      case AppLanguage.english: return 'Min. 5 pieces';
      case AppLanguage.japanese: return '最低5着以上';
      case AppLanguage.chinese: return '最少5件';
      case AppLanguage.mongolian: return 'Хамгийн бага 5 ш';
      default: return '최소 5벌 이상';
    }
  }
  String get customMinQtyHint {
    switch (language) {
      case AppLanguage.english: return 'Enter 5+ pieces';
      case AppLanguage.japanese: return '5着以上入力してください';
      case AppLanguage.chinese: return '请输入5件以上';
      case AppLanguage.mongolian: return '5-аас дээш тоо оруулна уу';
      default: return '최소 5벌 이상 입력해주세요';
    }
  }
  String get customSelectProduct {
    switch (language) {
      case AppLanguage.english: return 'Select Product';
      case AppLanguage.japanese: return '商品選択';
      case AppLanguage.chinese: return '选择商品';
      case AppLanguage.mongolian: return 'Бараа сонгох';
      default: return '상품 선택';
    }
  }
  String get customSelectProductHint {
    switch (language) {
      case AppLanguage.english: return 'Please select a product';
      case AppLanguage.japanese: return '商品を選択してください';
      case AppLanguage.chinese: return '请选择商品';
      case AppLanguage.mongolian: return 'Бараа сонгоно уу';
      default: return '상품을 선택해주세요';
    }
  }
  String get customSelectColor {
    switch (language) {
      case AppLanguage.english: return 'Please select a color';
      case AppLanguage.japanese: return 'カラーを選択してください';
      case AppLanguage.chinese: return '请选择颜色';
      case AppLanguage.mongolian: return 'Өнгө сонгоно уу';
      default: return '컬러를 선택해주세요';
    }
  }
  String get customOptions {
    switch (language) {
      case AppLanguage.english: return 'Custom Options';
      case AppLanguage.japanese: return 'カスタムオプション';
      case AppLanguage.chinese: return '定制选项';
      case AppLanguage.mongolian: return 'Захиалгат сонголт';
      default: return '커스텀 옵션';
    }
  }
  String get customTeamLogo {
    switch (language) {
      case AppLanguage.english: return 'Team Logo Print';
      case AppLanguage.japanese: return 'チームロゴ印刷';
      case AppLanguage.chinese: return '团队Logo印刷';
      case AppLanguage.mongolian: return 'Лого хэвлэх';
      default: return '팀 로고 인쇄';
    }
  }
  String get customFileGuide {
    switch (language) {
      case AppLanguage.english: return 'Separate file attachment guide';
      case AppLanguage.japanese: return 'ファイル添付案内';
      case AppLanguage.chinese: return '文件附件说明';
      case AppLanguage.mongolian: return 'Файл хавсаргах заавар';
      default: return '별도 파일 첨부 안내';
    }
  }
  String get customNamePrint {
    switch (language) {
      case AppLanguage.english: return 'Name Print';
      case AppLanguage.japanese: return '名前印刷';
      case AppLanguage.chinese: return '名字印刷';
      case AppLanguage.mongolian: return 'Нэр хэвлэх';
      default: return '이름 인쇄';
    }
  }
  String get customNumPrint {
    switch (language) {
      case AppLanguage.english: return 'Number Print';
      case AppLanguage.japanese: return '番号印刷';
      case AppLanguage.chinese: return '号码印刷';
      case AppLanguage.mongolian: return 'Дугаар хэвлэх';
      default: return '등번호 인쇄';
    }
  }
  String get customDeliveryInfo {
    switch (language) {
      case AppLanguage.english: return 'Delivery Info';
      case AppLanguage.japanese: return '配送情報';
      case AppLanguage.chinese: return '配送信息';
      case AppLanguage.mongolian: return 'Хүргэлтийн мэдээлэл';
      default: return '배송 정보';
    }
  }
  String get customAddressHint {
    switch (language) {
      case AppLanguage.english: return 'Enter delivery address';
      case AppLanguage.japanese: return '住所を入力してください';
      case AppLanguage.chinese: return '请输入配送地址';
      case AppLanguage.mongolian: return 'Хүргэлтийн хаяг';
      default: return '서울시 강남구 역삼동 000-00';
    }
  }
  String get customDesignNote {
    switch (language) {
      case AppLanguage.english: return 'Design Request';
      case AppLanguage.japanese: return 'デザインリクエスト';
      case AppLanguage.chinese: return '设计要求';
      case AppLanguage.mongolian: return 'Дизайны хүсэлт';
      default: return '디자인 요청사항';
    }
  }
  String get customDesignHint {
    switch (language) {
      case AppLanguage.english: return 'Enter design details or reference';
      case AppLanguage.japanese: return 'デザイン詳細を自由に入力してください';
      case AppLanguage.chinese: return '请自由输入所需设计或参考事项';
      case AppLanguage.mongolian: return 'Дизайны дэлгэрэнгүйг оруулна уу';
      default: return '원하시는 디자인 또는 참고 사항을 자유롭게 입력해주세요';
    }
  }
  String get customInquiry {
    switch (language) {
      case AppLanguage.english: return 'Custom Order Inquiry';
      case AppLanguage.japanese: return 'カスタム注文お問い合わせ';
      case AppLanguage.chinese: return '定制订单咨询';
      case AppLanguage.mongolian: return 'Захиалгат асуулга';
      default: return '커스텀 주문 문의하기';
    }
  }
  String get customInquiryDone {
    switch (language) {
      case AppLanguage.english: return 'Inquiry Submitted';
      case AppLanguage.japanese: return '問い合わせ受付完了';
      case AppLanguage.chinese: return '咨询已提交';
      case AppLanguage.mongolian: return 'Асуулга хүлээн авсан';
      default: return '문의 접수 완료';
    }
  }
  String get customConfirm {
    switch (language) {
      case AppLanguage.english: return 'Confirm';
      case AppLanguage.japanese: return '確認';
      case AppLanguage.chinese: return '确认';
      case AppLanguage.mongolian: return 'Баталгаажуулах';
      default: return '확인';
    }
  }
  String get colorBlack {
    switch (language) {
      case AppLanguage.english: return 'K (Black)';
      case AppLanguage.japanese: return 'K（ブラック）';
      case AppLanguage.chinese: return 'K（黑色）';
      case AppLanguage.mongolian: return 'K (Хар)';
      default: return 'K (블랙)';
    }
  }
  String get colorPurpleNavy {
    switch (language) {
      case AppLanguage.english: return 'PP (Purple Navy)';
      case AppLanguage.japanese: return 'PP（パープルネイビー）';
      case AppLanguage.chinese: return 'PP（紫藏青）';
      case AppLanguage.mongolian: return 'PP (Хар цэнхэр)';
      default: return 'PP (퍼플네이비)';
    }
  }
  String get colorNavy {
    switch (language) {
      case AppLanguage.english: return 'N (Navy)';
      case AppLanguage.japanese: return 'N（ネイビー）';
      case AppLanguage.chinese: return 'N（藏青）';
      case AppLanguage.mongolian: return 'N (Хөх)';
      default: return 'N (네이비)';
    }
  }
  String get colorWhite {
    switch (language) {
      case AppLanguage.english: return 'W (White)';
      case AppLanguage.japanese: return 'W（ホワイト）';
      case AppLanguage.chinese: return 'W（白色）';
      case AppLanguage.mongolian: return 'W (Цагаан)';
      default: return 'W (화이트)';
    }
  }
  String get colorGray {
    switch (language) {
      case AppLanguage.english: return 'G (Gray)';
      case AppLanguage.japanese: return 'G（グレー）';
      case AppLanguage.chinese: return 'G（灰色）';
      case AppLanguage.mongolian: return 'G (Саарал)';
      default: return 'G (그레이)';
    }
  }
  String get colorDarkGray {
    switch (language) {
      case AppLanguage.english: return 'DG (Dark Gray)';
      case AppLanguage.japanese: return 'DG（ダークグレー）';
      case AppLanguage.chinese: return 'DG（深灰）';
      case AppLanguage.mongolian: return 'DG (Бараан саарал)';
      default: return 'DG (다크그레이)';
    }
  }
  String get colorSkyBlue {
    switch (language) {
      case AppLanguage.english: return 'SB (Sky Blue)';
      case AppLanguage.japanese: return 'SB（スカイブルー）';
      case AppLanguage.chinese: return 'SB（天蓝）';
      case AppLanguage.mongolian: return 'SB (Тэнгэр цэнхэр)';
      default: return 'SB (스카이블루)';
    }
  }
  String get colorBlue {
    switch (language) {
      case AppLanguage.english: return 'B (Blue)';
      case AppLanguage.japanese: return 'B（ブルー）';
      case AppLanguage.chinese: return 'B（蓝色）';
      case AppLanguage.mongolian: return 'B (Цэнхэр)';
      default: return 'B (블루)';
    }
  }
  String get colorDarkBlue {
    switch (language) {
      case AppLanguage.english: return 'DB (Dark Blue)';
      case AppLanguage.japanese: return 'DB（ダークブルー）';
      case AppLanguage.chinese: return 'DB（深蓝）';
      case AppLanguage.mongolian: return 'DB (Бараан цэнхэр)';
      default: return 'DB (다크블루)';
    }
  }
  String get colorSmokePink {
    switch (language) {
      case AppLanguage.english: return 'SP (Smoke Pink)';
      case AppLanguage.japanese: return 'SP（スモークピンク）';
      case AppLanguage.chinese: return 'SP（烟粉）';
      case AppLanguage.mongolian: return 'SP (Утаат ягаан)';
      default: return 'SP (스모크핑크)';
    }
  }
  String get colorLightPink {
    switch (language) {
      case AppLanguage.english: return 'LP (Light Pink)';
      case AppLanguage.japanese: return 'LP（ライトピンク）';
      case AppLanguage.chinese: return 'LP（浅粉）';
      case AppLanguage.mongolian: return 'LP (Цайвар ягаан)';
      default: return 'LP (라이트핑크)';
    }
  }
  String get colorIvory {
    switch (language) {
      case AppLanguage.english: return 'IO (Ivory)';
      case AppLanguage.japanese: return 'IO（アイボリー）';
      case AppLanguage.chinese: return 'IO（象牙白）';
      case AppLanguage.mongolian: return 'IO (Заан цагаан)';
      default: return 'IO (아이보리)';
    }
  }
  String get colorLightGray {
    switch (language) {
      case AppLanguage.english: return 'LG (Light Gray)';
      case AppLanguage.japanese: return 'LG（ライトグレー）';
      case AppLanguage.chinese: return 'LG（浅灰）';
      case AppLanguage.mongolian: return 'LG (Цайвар саарал)';
      default: return 'LG (라이트그레이)';
    }
  }
  String get colorRed {
    switch (language) {
      case AppLanguage.english: return 'R (Red)';
      case AppLanguage.japanese: return 'R（レッド）';
      case AppLanguage.chinese: return 'R（红色）';
      case AppLanguage.mongolian: return 'R (Улаан)';
      default: return 'R (레드)';
    }
  }
  String get colorNewDark {
    switch (language) {
      case AppLanguage.english: return 'ND (New Dark)';
      case AppLanguage.japanese: return 'ND（ニューダーク）';
      case AppLanguage.chinese: return 'ND（新暗色）';
      case AppLanguage.mongolian: return 'ND (Шинэ бараан)';
      default: return 'ND (뉴다크)';
    }
  }
  String get colorTealBlue {
    switch (language) {
      case AppLanguage.english: return 'BB (Teal Blue)';
      case AppLanguage.japanese: return 'BB（ティールブルー）';
      case AppLanguage.chinese: return 'BB（蓝绿）';
      case AppLanguage.mongolian: return 'BB (Тил цэнхэр)';
      default: return 'BB (틸블루)';
    }
  }
  String get colorFluoPink {
    switch (language) {
      case AppLanguage.english: return 'FP (Fluoro Pink)';
      case AppLanguage.japanese: return 'FP（蛍光ピンク）';
      case AppLanguage.chinese: return 'FP（荧光粉）';
      case AppLanguage.mongolian: return 'FP (Флюо ягаан)';
      default: return 'FP (형광핑크)';
    }
  }
  String get colorFluoOrange {
    switch (language) {
      case AppLanguage.english: return 'FO (Fluoro Orange)';
      case AppLanguage.japanese: return 'FO（蛍光オレンジ）';
      case AppLanguage.chinese: return 'FO（荧光橙）';
      case AppLanguage.mongolian: return 'FO (Флюо улаан шар)';
      default: return 'FO (형광오렌지)';
    }
  }
  String get colorFluoGreen {
    switch (language) {
      case AppLanguage.english: return 'FG (Fluoro Green)';
      case AppLanguage.japanese: return 'FG（蛍光グリーン）';
      case AppLanguage.chinese: return 'FG（荧光绿）';
      case AppLanguage.mongolian: return 'FG (Флюо ногоон)';
      default: return 'FG (형광그린)';
    }
  }
  String get addrSearchTitle {
    switch (language) {
      case AppLanguage.english: return 'Address Search';
      case AppLanguage.japanese: return '住所検索';
      case AppLanguage.chinese: return '地址搜索';
      case AppLanguage.mongolian: return 'Хаяг хайх';
      default: return '주소 검색';
    }
  }
  String get addrSearchLoading {
    switch (language) {
      case AppLanguage.english: return 'Loading address search...';
      case AppLanguage.japanese: return 'アドレス検索読込中...';
      case AppLanguage.chinese: return '加载地址搜索...';
      case AppLanguage.mongolian: return 'Хаяг хайлт ачааллаж байна...';
      default: return '카카오 주소검색 로딩 중...';
    }
  }
  String get addrSearchFail {
    switch (language) {
      case AppLanguage.english: return 'Failed to load. Check internet.';
      case AppLanguage.japanese: return '住所検索読込失敗。インターネット接続を確認してください';
      case AppLanguage.chinese: return '地址搜索加载失败。请检查网络连接';
      case AppLanguage.mongolian: return 'Ачааллах амжилтгүй. Интернет шалгана уу';
      default: return '주소 검색 로딩 실패. 인터넷 연결을 확인해주세요.';
    }
  }
  String get addrRetry {
    switch (language) {
      case AppLanguage.english: return 'Retry';
      case AppLanguage.japanese: return '再試行';
      case AppLanguage.chinese: return '重试';
      case AppLanguage.mongolian: return 'Дахин оролдох';
      default: return '다시 시도';
    }
  }
  String get chatVisitor {
    switch (language) {
      case AppLanguage.english: return 'Visitor';
      case AppLanguage.japanese: return '訪問者';
      case AppLanguage.chinese: return '访客';
      case AppLanguage.mongolian: return 'Зочин';
      default: return '방문자';
    }
  }
  String get chatAutoReply {
    switch (language) {
      case AppLanguage.english: return 'Thank you for your inquiry! Our team will reply soon. Hours: Weekdays 10:00-18:00 (Lunch 12:00-14:00)';
      case AppLanguage.japanese: return 'お問い合わせありがとうございます！担当者が確認後、すぐに返信いたします。営業時間: 平日10:00-18:00（午休12:00-14:00）';
      case AppLanguage.chinese: return '感谢您的咨询！工作人员确认后将尽快回复。营业时间: 平日 09:00~18:00';
      case AppLanguage.mongolian: return 'Асуулгад баярлалаа! Ажилтан баталгаажуулан хариулна. Цаг: Нийт 09:00~18:00';
      default: return '문의 감사합니다! 담당자가 확인 후 빠르게 답변 드리겠습니다. 운영시간: 평일 10:00-18:00 (점심 12:00-14:00)';
    }
  }
  String get chatOriginalText {
    switch (language) {
      case AppLanguage.english: return 'Original: ';
      case AppLanguage.japanese: return '原文: ';
      case AppLanguage.chinese: return '原文: ';
      case AppLanguage.mongolian: return 'Эх бичвэр: ';
      default: return '원문: ';
    }
  }
  String get chatChecking {
    switch (language) {
      case AppLanguage.english: return 'Checking...';
      case AppLanguage.japanese: return '確認中';
      case AppLanguage.chinese: return '确认中';
      case AppLanguage.mongolian: return 'Шалгаж байна';
      default: return '확인 중';
    }
  }
  String get serviceKakaoCompany {
    switch (language) {
      case AppLanguage.english: return '🏢 2FIT Korea Co., Ltd.';
      case AppLanguage.japanese: return '🏢 株式会社 2FIT Korea';
      case AppLanguage.chinese: return '🏢 2FIT Korea有限公司';
      case AppLanguage.mongolian: return '🏢 2FIT Korea ХХК';
      default: return '🏢 주식회사 2FIT Korea';
    }
  }
  String get serviceKakaoChat {
    switch (language) {
      case AppLanguage.english: return '💬 Kakao: @2fitkorea';
      case AppLanguage.japanese: return '💬 カカオトーク @2fitkorea';
      case AppLanguage.chinese: return '💬 Kakao: @2fitkorea';
      case AppLanguage.mongolian: return '💬 Какао: @2fitkorea';
      default: return '💬 카카오톡 @2fitkorea';
    }
  }
  // ─── 카테고리 서브메뉴 ───
  String get catTopAll { switch (language) {
    case AppLanguage.english: return 'All Tops';
    case AppLanguage.japanese: return 'トップス全体';
    case AppLanguage.chinese: return '全部上衣';
    case AppLanguage.mongolian: return 'Бүх дээд хувцас';
    default: return '전체 상의';
  }}
  String get catSingletA { switch (language) {
    case AppLanguage.english: return 'Singlet Type A';
    case AppLanguage.japanese: return 'シングレットAタイプ';
    case AppLanguage.chinese: return '背心A型';
    case AppLanguage.mongolian: return 'Сингелет А хэлбэр';
    default: return '싱글렛 A타입';
  }}
  String get catSingletB { switch (language) {
    case AppLanguage.english: return 'Singlet Type B';
    case AppLanguage.japanese: return 'シングレットBタイプ';
    case AppLanguage.chinese: return '背心B型';
    case AppLanguage.mongolian: return 'Сингелет Б хэлбэр';
    default: return '싱글렛 B타입';
  }}
  String get catRoundTee { switch (language) {
    case AppLanguage.english: return 'Round Neck T-Shirt';
    case AppLanguage.japanese: return 'ラウンドTシャツ';
    case AppLanguage.chinese: return '圆领短袖T恤';
    case AppLanguage.mongolian: return 'Дугуй хүзүүтэй богино ханцуйт';
    default: return '라운드 반팔티';
  }}
  String get catCropTop { switch (language) {
    case AppLanguage.english: return 'Crop Top';
    case AppLanguage.japanese: return 'クロップトップ';
    case AppLanguage.chinese: return '短款上衣';
    case AppLanguage.mongolian: return 'Кроп топ';
    default: return '크롭탑';
  }}
  String get catLongSleeve { switch (language) {
    case AppLanguage.english: return 'Long Sleeve';
    case AppLanguage.japanese: return 'ロングスリーブ';
    case AppLanguage.chinese: return '长袖';
    case AppLanguage.mongolian: return 'Урт ханцуйт';
    default: return '롱 슬리브';
  }}
  String get catSweatshirt { switch (language) {
    case AppLanguage.english: return 'Sweatshirt';
    case AppLanguage.japanese: return 'スウェット';
    case AppLanguage.chinese: return '卫衣';
    case AppLanguage.mongolian: return 'Свитшот';
    default: return '맨투맨';
  }}
  String get catHoodZip { switch (language) {
    case AppLanguage.english: return 'Hood Zip-up';
    case AppLanguage.japanese: return 'フードジップアップ';
    case AppLanguage.chinese: return '连帽拉链卫衣';
    case AppLanguage.mongolian: return 'Худ зипп';
    default: return '후드집업';
  }}
  String get catCollarTee { switch (language) {
    case AppLanguage.english: return 'Collar T-Shirt';
    case AppLanguage.japanese: return 'カラーTシャツ';
    case AppLanguage.chinese: return '翻领T恤';
    case AppLanguage.mongolian: return 'Захтай цамц';
    default: return '카라티';
  }}
  String get catBottomAll { switch (language) {
    case AppLanguage.english: return 'All Bottoms';
    case AppLanguage.japanese: return 'ボトムス全体';
    case AppLanguage.chinese: return '全部下装';
    case AppLanguage.mongolian: return 'Бүх доод хувцас';
    default: return '전체 하의';
  }}
  String get catTights9 { switch (language) {
    case AppLanguage.english: return 'Full Tights';
    case AppLanguage.japanese: return 'フルタイツ';
    case AppLanguage.chinese: return '全长紧身裤';
    case AppLanguage.mongolian: return 'Бүтэн легинс';
    default: return '타이즈 9부';
  }}
  String get catTights5 { switch (language) {
    case AppLanguage.english: return 'Mid Tights';
    case AppLanguage.japanese: return 'ハーフタイツ';
    case AppLanguage.chinese: return '五分紧身裤';
    case AppLanguage.mongolian: return 'Дунд легинс';
    default: return '타이즈 5부';
  }}
  String get catTights4 { switch (language) {
    case AppLanguage.english: return '4/10 Tights';
    case AppLanguage.japanese: return '4分タイツ';
    case AppLanguage.chinese: return '四分紧身裤';
    case AppLanguage.mongolian: return '4/10 легинс';
    default: return '타이즈 4부';
  }}
  String get catTights3 { switch (language) {
    case AppLanguage.english: return '3/10 Tights';
    case AppLanguage.japanese: return '3分タイツ';
    case AppLanguage.chinese: return '三分紧身裤';
    case AppLanguage.mongolian: return '3/10 легинс';
    default: return '타이즈 3부';
  }}
  String get catTights25 { switch (language) {
    case AppLanguage.english: return '2.5 Tights';
    case AppLanguage.japanese: return '2.5分タイツ';
    case AppLanguage.chinese: return '2.5分紧身裤';
    case AppLanguage.mongolian: return '2.5 легинс';
    default: return '타이즈 2.5부';
  }}
  String get catShortShorts { switch (language) {
    case AppLanguage.english: return 'Short Shorts';
    case AppLanguage.japanese: return 'ショートショーツ';
    case AppLanguage.chinese: return '超短裤';
    case AppLanguage.mongolian: return 'Богино шорт';
    default: return '숏쇼츠';
  }}
  String get catTrainingPants { switch (language) {
    case AppLanguage.english: return 'Training Pants';
    case AppLanguage.japanese: return 'トレーニングパンツ';
    case AppLanguage.chinese: return '运动裤';
    case AppLanguage.mongolian: return 'Дасгалын өмд';
    default: return '트레이닝바지';
  }}
  String get catShorts { switch (language) {
    case AppLanguage.english: return 'Shorts';
    case AppLanguage.japanese: return 'ショーツ';
    case AppLanguage.chinese: return '短裤';
    case AppLanguage.mongolian: return 'Шорт';
    default: return '반바지';
  }}
  String get catSetAll { switch (language) {
    case AppLanguage.english: return 'All Sets';
    case AppLanguage.japanese: return 'セット全体';
    case AppLanguage.chinese: return '全部套装';
    case AppLanguage.mongolian: return 'Бүх иж бүрдэл';
    default: return '전체 세트';
  }}
  String get catSingletASet { switch (language) {
    case AppLanguage.english: return 'Singlet A Set';
    case AppLanguage.japanese: return 'シングレットAセット';
    case AppLanguage.chinese: return '背心A型套装';
    case AppLanguage.mongolian: return 'Сингелет А иж бүрдэл';
    default: return '싱글렛 A타입세트';
  }}
  String get catTrainingSet { switch (language) {
    case AppLanguage.english: return 'Training Set';
    case AppLanguage.japanese: return 'トレーニングセット';
    case AppLanguage.chinese: return '运动套装';
    case AppLanguage.mongolian: return 'Дасгалын иж бүрдэл';
    default: return '트레이닝세트';
  }}
  String get catOuterAll { switch (language) {
    case AppLanguage.english: return 'All Outerwear';
    case AppLanguage.japanese: return 'アウター全体';
    case AppLanguage.chinese: return '全部外套';
    case AppLanguage.mongolian: return 'Бүх гадуур хувцас';
    default: return '전체 아우터';
  }}
  String get catWindbreaker { switch (language) {
    case AppLanguage.english: return 'Windbreaker';
    case AppLanguage.japanese: return 'ウィンドブレーカー';
    case AppLanguage.chinese: return '防风外套';
    case AppLanguage.mongolian: return 'Салхинаас хамгаалах куртка';
    default: return '바람막이';
  }}
  String get catTrainingZip { switch (language) {
    case AppLanguage.english: return 'Training Zip-up';
    case AppLanguage.japanese: return 'トレーニングジップアップ';
    case AppLanguage.chinese: return '运动拉链外套';
    case AppLanguage.mongolian: return 'Дасгалын зипп';
    default: return '트레이닝집업';
  }}
  String get catDownPadding { switch (language) {
    case AppLanguage.english: return 'Down Jacket';
    case AppLanguage.japanese: return 'ダウンパディング';
    case AppLanguage.chinese: return '羽绒服';
    case AppLanguage.mongolian: return 'Өдөн куртка';
    default: return '다운패딩';
  }}
  String get catDownVest { switch (language) {
    case AppLanguage.english: return 'Down Vest';
    case AppLanguage.japanese: return 'ダウンベスト';
    case AppLanguage.chinese: return '羽绒背心';
    case AppLanguage.mongolian: return 'Өдөн жилет';
    default: return '다운조끼패딩';
  }}
  String get catLongPadding { switch (language) {
    case AppLanguage.english: return 'Long Padding';
    case AppLanguage.japanese: return 'ロングパディング';
    case AppLanguage.chinese: return '长款羽绒服';
    case AppLanguage.mongolian: return 'Урт өдөн куртка';
    default: return '롱패딩';
  }}
  String get catSkinsuitAll { switch (language) {
    case AppLanguage.english: return 'All Skinsuits';
    case AppLanguage.japanese: return 'スキンスーツ全体';
    case AppLanguage.chinese: return '全部紧身衣';
    case AppLanguage.mongolian: return 'Бүх скинсьют';
    default: return '전체 스킨슈트';
  }}
  String get catSkinsuitItem { switch (language) {
    case AppLanguage.english: return 'Skinsuit';
    case AppLanguage.japanese: return 'スキンスーツ';
    case AppLanguage.chinese: return '紧身衣';
    case AppLanguage.mongolian: return 'Скинсьют';
    default: return '스킨슈트';
  }}
  String get catAccessoryAll { switch (language) {
    case AppLanguage.english: return 'All Accessories';
    case AppLanguage.japanese: return 'アクセサリー全体';
    case AppLanguage.chinese: return '全部配件';
    case AppLanguage.mongolian: return 'Бүх дагалдах хэрэгсэл';
    default: return '전체 악세사리';
  }}
  String get catHat { switch (language) {
    case AppLanguage.english: return 'Hat';
    case AppLanguage.japanese: return '帽子';
    case AppLanguage.chinese: return '帽子';
    case AppLanguage.mongolian: return 'Малгай';
    default: return '모자';
  }}
  String get catBackpack { switch (language) {
    case AppLanguage.english: return 'Backpack';
    case AppLanguage.japanese: return 'バックパック';
    case AppLanguage.chinese: return '背包';
    case AppLanguage.mongolian: return 'Нуруун цүнх';
    default: return '백팩';
  }}
  String get catEventAll { switch (language) {
    case AppLanguage.english: return 'All Events';
    case AppLanguage.japanese: return 'イベント全体';
    case AppLanguage.chinese: return '全部活动';
    case AppLanguage.mongolian: return 'Бүх арга хэмжээ';
    default: return '전체 이벤트';
  }}
  String get catSeasonSale { switch (language) {
    case AppLanguage.english: return 'Season SALE';
    case AppLanguage.japanese: return 'シーズンセール';
    case AppLanguage.chinese: return '季节特卖';
    case AppLanguage.mongolian: return 'Улирлын хямдрал';
    default: return '시즌 SALE';
  }}
  String get catNewSpecial { switch (language) {
    case AppLanguage.english: return 'New Arrivals Special';
    case AppLanguage.japanese: return '新商品特価';
    case AppLanguage.chinese: return '新品特惠';
    case AppLanguage.mongolian: return 'Шинэ бараа онцгой үнэ';
    default: return '신상품 특가';
  }}

  // ─── 네비게이션 메뉴 추가 키 ───
  String get navGroupOrderGuide { switch (language) {
    case AppLanguage.english: return 'Group Order Guide';
    case AppLanguage.japanese: return '団体注文案内';
    case AppLanguage.chinese: return '团体订购指南';
    case AppLanguage.mongolian: return 'Бүлгийн захиалгын заавар';
    default: return '단체 주문 안내';
  }}
  String get navGroupOrderForm { switch (language) {
    case AppLanguage.english: return 'Group Order Form';
    case AppLanguage.japanese: return '団体注文書式';
    case AppLanguage.chinese: return '团体订购表格';
    case AppLanguage.mongolian: return 'Бүлгийн захиалгын маягт';
    default: return '단체 주문 서식';
  }}
  String get navGroupOrderOnly { switch (language) {
    case AppLanguage.english: return 'Group Exclusive Items';
    case AppLanguage.japanese: return '団体専用商品';
    case AppLanguage.chinese: return '团体专用商品';
    case AppLanguage.mongolian: return 'Бүлгийн онцгой бараа';
    default: return '단체 전용 상품';
  }}

  // ─── 홈 화면 텍스트 ───
  String get homeCategory { switch (language) {
    case AppLanguage.english: return 'Category';
    case AppLanguage.japanese: return 'カテゴリー';
    case AppLanguage.chinese: return '分类';
    case AppLanguage.mongolian: return 'Ангилал';
    default: return '카테고리';
  }}
  String get homeAllProducts { switch (language) {
    case AppLanguage.english: return 'All Products';
    case AppLanguage.japanese: return '全商品';
    case AppLanguage.chinese: return '全部商品';
    case AppLanguage.mongolian: return 'Бүх бараа';
    default: return '전체 상품';
  }}
  String get homeViewAll { switch (language) {
    case AppLanguage.english: return 'View All';
    case AppLanguage.japanese: return '全て見る';
    case AppLanguage.chinese: return '查看全部';
    case AppLanguage.mongolian: return 'Бүгдийг үзэх';
    default: return '전체보기';
  }}
  String get homeViewAllArrow { switch (language) {
    case AppLanguage.english: return 'View All ›';
    case AppLanguage.japanese: return '全て見る ›';
    case AppLanguage.chinese: return '查看全部 ›';
    case AppLanguage.mongolian: return 'Бүгдийг үзэх ›';
    default: return '전체보기 ›';
  }}
  String get homeGroupOnly { switch (language) {
    case AppLanguage.english: return 'Group Orders Only';
    case AppLanguage.japanese: return '団体注文専用';
    case AppLanguage.chinese: return '仅限团体订购';
    case AppLanguage.mongolian: return 'Зөвхөн бүлгийн захиалга';
    default: return '단체주문 전용';
  }}
  String get homeGroupBadge { switch (language) {
    case AppLanguage.english: return '✂️ Team Logo Printing';
    case AppLanguage.japanese: return '✂️ チームロゴプリント';
    case AppLanguage.chinese: return '✂️ 团队Logo印刷';
    case AppLanguage.mongolian: return '✂️ Багийн лого хэвлэх';
    default: return '✂️ 팀 로고 프린팅';
  }}
  String get homeGroupOrderNote { switch (language) {
    case AppLanguage.english: return 'Click on a product to apply for a group custom order';
    case AppLanguage.japanese: return '商品をクリックして団体カスタムオーダーを申請できます';
    case AppLanguage.chinese: return '点击商品即可申请团体定制订单';
    case AppLanguage.mongolian: return 'Бүлгийн захиалга өгөхийн тулд бараа дээр дарна уу';
    default: return '상품을 클릭하면 단체 커스텀 오더를 신청할 수 있습니다';
  }}
  String get homeGroupOrderNote2 { switch (language) {
    case AppLanguage.english: return 'Select a product to apply for a custom order';
    case AppLanguage.japanese: return '商品を選択してカスタムオーダーを申請できます';
    case AppLanguage.chinese: return '选择商品申请定制订单';
    case AppLanguage.mongolian: return 'Захиалга өгөхийн тулд бараа сонгоно уу';
    default: return '상품을 선택하면 커스텀 오더를 신청할 수 있습니다';
  }}
  String get homeNewSeason { switch (language) {
    case AppLanguage.english: return 'NEW SEASON\nNew Arrivals';
    case AppLanguage.japanese: return 'NEW SEASON\n新商品入荷';
    case AppLanguage.chinese: return 'NEW SEASON\n新品上市';
    case AppLanguage.mongolian: return 'NEW SEASON\nШинэ бараа ирлээ';
    default: return '새로운 시즌\n신상품 출시';
  }}
  String get homeNewSeasonSub { switch (language) {
    case AppLanguage.english: return 'Discover the latest collection now · Free shipping over 30,000 KRW';
    case AppLanguage.japanese: return '最新コレクションを今すぐチェック · 3万円以上送料無料';
    case AppLanguage.chinese: return '立即发现最新系列 · 满3万韩元免运费';
    case AppLanguage.mongolian: return 'Шинэ цуглуулгийг одоо үзнэ үү · 30,000 вонаас дээш үнэгүй хүргэлт';
    default: return '최신 컬렉션을 지금 바로 만나보세요 · 무료배송 3만원 이상';
  }}
  String get homeNewArrivalsBtn { switch (language) {
    case AppLanguage.english: return 'New Arrivals';
    case AppLanguage.japanese: return '新商品を見る';
    case AppLanguage.chinese: return '查看新品';
    case AppLanguage.mongolian: return 'Шинэ бараа';
    default: return '신상품 보기';
  }}
  String get homeEventBtn { switch (language) {
    case AppLanguage.english: return 'Event Sale';
    case AppLanguage.japanese: return 'イベントセール';
    case AppLanguage.chinese: return '活动特惠';
    case AppLanguage.mongolian: return 'Арга хэмжээний хямдрал';
    default: return '이벤트 특가';
  }}
  String get homeSeasonDiscount { switch (language) {
    case AppLanguage.english: return 'Season Event\nUp to 40% OFF';
    case AppLanguage.japanese: return 'シーズンイベント\n最大40%オフ';
    case AppLanguage.chinese: return '季节活动\n最高40%折扣';
    case AppLanguage.mongolian: return 'Улирлын арга хэмжээ\n40% хүртэл хямдрал';
    default: return '시즌 이벤트\n최대 40% 할인';
  }}
  String get homeSeasonDiscountSub { switch (language) {
    case AppLanguage.english: return 'Limited quantity · Limited time special price';
    case AppLanguage.japanese: return '数量限定 · 期間限定特価';
    case AppLanguage.chinese: return '限量 · 限时特惠';
    case AppLanguage.mongolian: return 'Хязгаарлагдмал тоо · Хугацаат хямдрал';
    default: return '한정 수량 · 기간 한정 특가';
  }}
  String get homeNewArrivalsArrow { switch (language) {
    case AppLanguage.english: return 'New Arrivals →';
    case AppLanguage.japanese: return '新商品を見る →';
    case AppLanguage.chinese: return '查看新品 →';
    case AppLanguage.mongolian: return 'Шинэ бараа →';
    default: return '신상품 보기 →';
  }}
  String get homeEventArrow { switch (language) {
    case AppLanguage.english: return 'View Event →';
    case AppLanguage.japanese: return 'イベント見る →';
    case AppLanguage.chinese: return '查看活动 →';
    case AppLanguage.mongolian: return 'Арга хэмжээ →';
    default: return '이벤트 보기 →';
  }}
  String get homeMaxDiscount { switch (language) {
    case AppLanguage.english: return 'Up to 40% OFF';
    case AppLanguage.japanese: return '最大40%オフ';
    case AppLanguage.chinese: return '最高40%折扣';
    case AppLanguage.mongolian: return '40% хүртэл хямдрал';
    default: return '최대 40% OFF';
  }}
  String get homeFreeShipping { switch (language) {
    case AppLanguage.english: return 'Free Shipping';
    case AppLanguage.japanese: return '送料無料';
    case AppLanguage.chinese: return '免运费';
    case AppLanguage.mongolian: return 'Үнэгүй хүргэлт';
    default: return '무료배송';
  }}
  String get homeFreeShippingSub { switch (language) {
    case AppLanguage.english: return 'Orders over 30,000 KRW';
    case AppLanguage.japanese: return '3万円以上のご注文';
    case AppLanguage.chinese: return '满3万韩元';
    case AppLanguage.mongolian: return '30,000 вонаас дээш';
    default: return '3만원 이상';
  }}
  String get homeQualityGuarantee { switch (language) {
    case AppLanguage.english: return 'Quality Guarantee';
    case AppLanguage.japanese: return '品質保証';
    case AppLanguage.chinese: return '品质保证';
    case AppLanguage.mongolian: return 'Чанарын баталгаа';
    default: return '품질보증';
  }}
  String get homeQualityGuaranteeSub { switch (language) {
    case AppLanguage.english: return 'Premium materials';
    case AppLanguage.japanese: return 'プレミアム素材';
    case AppLanguage.chinese: return '优质材料';
    case AppLanguage.mongolian: return 'Өндөр чанарын материал';
    default: return '고품질 소재';
  }}
  String get home7DayExchange { switch (language) {
    case AppLanguage.english: return '7-Day Exchange';
    case AppLanguage.japanese: return '7日交換';
    case AppLanguage.chinese: return '7天换货';
    case AppLanguage.mongolian: return '7 хоногийн солих';
    default: return '7일 교환';
  }}
  String get home7DayExchangeSub { switch (language) {
    case AppLanguage.english: return 'Return guaranteed';
    case AppLanguage.japanese: return '返品保証';
    case AppLanguage.chinese: return '退货保障';
    case AppLanguage.mongolian: return 'Буцаалт баталгаатай';
    default: return '반품 보장';
  }}
  String get homeConsultation { switch (language) {
    case AppLanguage.english: return '1:1 Consultation';
    case AppLanguage.japanese: return '1:1 相談';
    case AppLanguage.chinese: return '1:1 咨询';
    case AppLanguage.mongolian: return '1:1 зөвлөгөө';
    default: return '1:1 상담';
  }}
  String get homeConsultationSub { switch (language) {
    case AppLanguage.english: return 'KakaoTalk Channel';
    case AppLanguage.japanese: return 'カカオチャンネル';
    case AppLanguage.chinese: return 'Kakao频道';
    case AppLanguage.mongolian: return 'Kakao суваг';
    default: return '카카오 채널';
  }}
  String get homeMarkReadAll { switch (language) {
    case AppLanguage.english: return 'Mark all as read';
    case AppLanguage.japanese: return '全て既読にする';
    case AppLanguage.chinese: return '全部标记已读';
    case AppLanguage.mongolian: return 'Бүгдийг уншсан гэж тэмдэглэх';
    default: return '모두 읽음';
  }}
  String get homeBrandSpecialty { switch (language) {
    case AppLanguage.english: return 'Specialized in team uniforms · group wear · custom uniforms';
    case AppLanguage.japanese: return 'チームウェア · 団体ウェア · カスタムユニフォーム専門';
    case AppLanguage.chinese: return '专业团队服·集体服·定制制服';
    case AppLanguage.mongolian: return 'Багийн хувцас · бүлгийн хувцас · захиалгат дүрэмт хувцасны мэргэжилтэн';
    default: return '팀복 · 단체복 · 커스텀 유니폼 전문';
  }}
  String get homeBannerGroupOrder { switch (language) {
    case AppLanguage.english: return 'Group Order';
    case AppLanguage.japanese: return '団体注文';
    case AppLanguage.chinese: return '团体订购';
    case AppLanguage.mongolian: return 'Бүлгийн захиалга';
    default: return '단체주문 안내';
  }}
  String get homeBannerTeams { switch (language) {
    case AppLanguage.english: return 'Teams';
    case AppLanguage.japanese: return 'チーム';
    case AppLanguage.chinese: return '团队';
    case AppLanguage.mongolian: return 'Баг';
    default: return '팀 납품';
  }}
  String get homeBannerSatisfaction { switch (language) {
    case AppLanguage.english: return 'Satisfaction';
    case AppLanguage.japanese: return '満足度';
    case AppLanguage.chinese: return '满意度';
    case AppLanguage.mongolian: return 'Сэтгэл ханамж';
    default: return '만족도';
  }}
  String get homeBannerDelivery { switch (language) {
    case AppLanguage.english: return 'Delivery';
    case AppLanguage.japanese: return '制作期間';
    case AppLanguage.chinese: return '制作周期';
    case AppLanguage.mongolian: return 'Хүргэлт';
    default: return '제작기간';
  }}
  String get homeAdminDashboard { switch (language) {
    case AppLanguage.english: return 'Admin Dashboard';
    case AppLanguage.japanese: return '管理者ダッシュボード';
    case AppLanguage.chinese: return '管理员仪表盘';
    case AppLanguage.mongolian: return 'Администраторын самбар';
    default: return '관리자 대시보드';
  }}
  String get homeLatestCollection { switch (language) {
    case AppLanguage.english: return 'Discover the latest collection now';
    case AppLanguage.japanese: return '最新コレクションを今すぐチェック';
    case AppLanguage.chinese: return '立即查看最新系列';
    case AppLanguage.mongolian: return 'Шинэ цуглуулгийг одоо үзнэ үү';
    default: return '최신 컬렉션을 지금 만나보세요';
  }}
  String get homeBrandSlogan { switch (language) {
    case AppLanguage.english: return 'High quality group sportswear brand\nTeam wear · Group wear · Custom uniforms';
    case AppLanguage.japanese: return '高品質団体スポーツウェアブランド\nチームウェア · 団体ウェア · カスタムユニフォーム';
    case AppLanguage.chinese: return '高品质团体运动服品牌\n团队服·集体服·定制制服';
    case AppLanguage.mongolian: return 'Өндөр чанарын бүлгийн спортын хувцасны брэнд\nБагийн хувцас · Бүлгийн хувцас · Захиалгат дүрэмт хувцас';
    default: return '고퀄리티 단체 스포츠웨어 전문 브랜드\n팀복 · 단체복 · 커스텀 유니폼';
  }}
  String get homeKakao { switch (language) {
    case AppLanguage.english: return 'KakaoTalk';
    case AppLanguage.japanese: return 'カカオ';
    case AppLanguage.chinese: return 'Kakao';
    case AppLanguage.mongolian: return 'Какао';
    default: return '카카오';
  }}
  String get homeBanner1Subtitle { switch (language) {
    case AppLanguage.english: return 'Discover the latest sportswear collection now';
    case AppLanguage.japanese: return '最新スポーツウェアコレクションを今すぐ';
    case AppLanguage.chinese: return '立即发现最新运动服系列';
    case AppLanguage.mongolian: return 'Шинэ спортын хувцасны цуглуулгийг одоо үзнэ үү';
    default: return '최신 스포츠웨어 컬렉션 지금 만나보세요';
  }}
  String get homeBanner1Btn { switch (language) {
    case AppLanguage.english: return 'Shop Now';
    case AppLanguage.japanese: return '今すぐショッピング';
    case AppLanguage.chinese: return '立即购物';
    case AppLanguage.mongolian: return 'Одоо худалдаж авах';
    default: return '지금 쇼핑하기';
  }}
  String get homeBanner2Subtitle { switch (language) {
    case AppLanguage.english: return 'The most popular 2FIT best items';
    case AppLanguage.japanese: return '一番売れた2FITのベストアイテム';
    case AppLanguage.chinese: return '最畅销的2FIT精选商品';
    case AppLanguage.mongolian: return '2FIT-ийн хамгийн их зарагдсан бараа';
    default: return '가장 많이 팔린 2FIT 베스트 아이템';
  }}
  String get homeBanner2Btn { switch (language) {
    case AppLanguage.english: return 'View Best';
    case AppLanguage.japanese: return 'ベストを見る';
    case AppLanguage.chinese: return '查看热卖';
    case AppLanguage.mongolian: return 'Шилдэгийг үзэх';
    default: return '베스트 보기';
  }}
  String get homeAll { switch (language) {
    case AppLanguage.english: return 'All';
    case AppLanguage.japanese: return '全て';
    case AppLanguage.chinese: return '全部';
    case AppLanguage.mongolian: return 'Бүгд';
    default: return '전체';
  }}

  // ─── 마이페이지 텍스트 ───
  String get mypageLoginToCheck { switch (language) {
    case AppLanguage.english: return 'Login to check your order history';
    case AppLanguage.japanese: return 'ログインして注文履歴を確認してください';
    case AppLanguage.chinese: return '登录后查看订单历史';
    case AppLanguage.mongolian: return 'Захиалгын түүхийг харахын тулд нэвтэрнэ үү';
    default: return '로그인 후 주문 내역을 확인하세요';
  }}
  String get mypageAvailableCoupons { switch (language) {
    case AppLanguage.english: return 'Available Coupons';
    case AppLanguage.japanese: return '利用可能なクーポン';
    case AppLanguage.chinese: return '可用优惠券';
    case AppLanguage.mongolian: return 'Боломжит купон';
    default: return '사용가능 쿠폰';
  }}
  String get mypageNoOrdersSub { switch (language) {
    case AppLanguage.english: return 'Make your first order! Pull down to refresh';
    case AppLanguage.japanese: return '最初の注文をしてみましょう！下へ引っ張って更新';
    case AppLanguage.chinese: return '去下第一个订单吧！下拉刷新';
    case AppLanguage.mongolian: return 'Эхний захиалгаа өгнө үү! Доош татаж шинэчлэх';
    default: return '첫 주문을 해보세요! 아래로 당겨 새로고침';
  }}
  String get mypageAdditionalProduction { switch (language) {
    case AppLanguage.english: return 'Additional Production';
    case AppLanguage.japanese: return '追加制作';
    case AppLanguage.chinese: return '追加生产';
    case AppLanguage.mongolian: return 'Нэмэлт үйлдвэрлэл';
    default: return '추가제작';
  }}
  String get mypageColorGroupEdit { switch (language) {
    case AppLanguage.english: return 'Edit Color·Group Name';
    case AppLanguage.japanese: return 'カラー・団体名を修正';
    case AppLanguage.chinese: return '修改颜色·团体名称';
    case AppLanguage.mongolian: return 'Өнгө·Бүлгийн нэр засах';
    default: return '컬러·단체명 수정';
  }}
  String get mypageCancelledOrderNote { switch (language) {
    case AppLanguage.english: return 'Cancelled orders cannot be re-ordered or modified';
    case AppLanguage.japanese: return 'キャンセルされた注文は追加制作/修正リクエストができません';
    case AppLanguage.chinese: return '已取消的订单无法追加生产/修改';
    case AppLanguage.mongolian: return 'Цуцалсан захиалгад нэмэлт/засвар хийх боломжгүй';
    default: return '취소된 주문은 추가제작/수정 요청이 불가합니다';
  }}
  String get mypageAdditionalNote { switch (language) {
    case AppLanguage.english: return 'Additional production is only available for group custom orders';
    case AppLanguage.japanese: return '追加制作は団体カスタム注文でのみ可能です';
    case AppLanguage.chinese: return '追加生产仅适用于团体定制订单';
    case AppLanguage.mongolian: return 'Нэмэлт үйлдвэрлэл зөвхөн бүлгийн захиалгад боломжтой';
    default: return '추가제작은 단체커스텀 주문에서만 가능합니다';
  }}
  String get mypageNoWishlist { switch (language) {
    case AppLanguage.english: return 'No wishlist items';
    case AppLanguage.japanese: return 'お気に入りがありません';
    case AppLanguage.chinese: return '收藏夹为空';
    case AppLanguage.mongolian: return 'Хүслийн жагсаалт хоосон';
    default: return '찜한 상품이 없습니다';
  }}
  String get mypageNoWishlistSub { switch (language) {
    case AppLanguage.english: return 'Add items you like to your wishlist!';
    case AppLanguage.japanese: return '気に入った商品をお気に入りに追加してください！';
    case AppLanguage.chinese: return '将喜欢的商品添加到收藏夹！';
    case AppLanguage.mongolian: return 'Дуртай бараагаа хүслийн жагсаалтад нэм!';
    default: return '마음에 드는 상품을 찜해보세요!';
  }}
  String get mypageLoginToReview { switch (language) {
    case AppLanguage.english: return 'Login to check your reviews';
    case AppLanguage.japanese: return 'ログインしてレビューを確認してください';
    case AppLanguage.chinese: return '登录后查看您的评价';
    case AppLanguage.mongolian: return 'Нэвтрэн сэтгэгдлийг харах';
    default: return '로그인 후 내 리뷰를 확인할 수 있습니다.';
  }}
  String get mypageNoReviews { switch (language) {
    case AppLanguage.english: return 'No reviews written';
    case AppLanguage.japanese: return '作成したレビューがありません';
    case AppLanguage.chinese: return '暂无评价';
    case AppLanguage.mongolian: return 'Бичсэн сэтгэгдэл байхгүй';
    default: return '작성한 리뷰가 없습니다';
  }}
  String get mypageNoReviewsSub { switch (language) {
    case AppLanguage.english: return 'Write a review for your purchased products!';
    case AppLanguage.japanese: return '購入した商品のレビューを書いてください！';
    case AppLanguage.chinese: return '请为您购买的商品写评价！';
    case AppLanguage.mongolian: return 'Худалдаж авсан бараагийн сэтгэгдэл бичнэ үү!';
    default: return '구매한 상품에 대한 리뷰를 작성해주세요!';
  }}
  String get mypageDelete { switch (language) {
    case AppLanguage.english: return 'Delete';
    case AppLanguage.japanese: return '削除';
    case AppLanguage.chinese: return '删除';
    case AppLanguage.mongolian: return 'Устгах';
    default: return '삭제';
  }}
  String get mypageEditReviewHint { switch (language) {
    case AppLanguage.english: return 'Please edit your review';
    case AppLanguage.japanese: return 'レビューを編集してください';
    case AppLanguage.chinese: return '请编辑您的评价';
    case AppLanguage.mongolian: return 'Сэтгэгдлийг засна уу';
    default: return '리뷰를 수정해주세요';
  }}
  String get mypageAccountSettings { switch (language) {
    case AppLanguage.english: return 'Account Settings';
    case AppLanguage.japanese: return 'アカウント設定';
    case AppLanguage.chinese: return '账户设置';
    case AppLanguage.mongolian: return 'Акаунтын тохиргоо';
    default: return '계정 설정';
  }}
  String get mypageShippingManage { switch (language) {
    case AppLanguage.english: return 'Shipping Address Management';
    case AppLanguage.japanese: return '配送先管理';
    case AppLanguage.chinese: return '配送地址管理';
    case AppLanguage.mongolian: return 'Хүргэлтийн хаягийн удирдлага';
    default: return '배송지 관리';
  }}
  String get mypagePasswordChange { switch (language) {
    case AppLanguage.english: return 'Change Password';
    case AppLanguage.japanese: return 'パスワード変更';
    case AppLanguage.chinese: return '更改密码';
    case AppLanguage.mongolian: return 'Нууц үг өөрчлөх';
    default: return '비밀번호 변경';
  }}
  String get mypageNotificationSettings { switch (language) {
    case AppLanguage.english: return 'Notification Settings';
    case AppLanguage.japanese: return '通知設定';
    case AppLanguage.chinese: return '通知设置';
    case AppLanguage.mongolian: return 'Мэдэгдлийн тохиргоо';
    default: return '알림 설정';
  }}
  String get mypageNotificationCenter { switch (language) {
    case AppLanguage.english: return 'Notification Center';
    case AppLanguage.japanese: return '通知センター';
    case AppLanguage.chinese: return '通知中心';
    case AppLanguage.mongolian: return 'Мэдэгдлийн төв';
    default: return '알림 센터';
  }}
  String get mypageOrderAlarm { switch (language) {
    case AppLanguage.english: return 'Order Notifications';
    case AppLanguage.japanese: return '注文通知';
    case AppLanguage.chinese: return '订单通知';
    case AppLanguage.mongolian: return 'Захиалгын мэдэгдэл';
    default: return '주문 알림';
  }}
  String get mypageEventAlarm { switch (language) {
    case AppLanguage.english: return 'Event/Promotion Notifications';
    case AppLanguage.japanese: return 'イベント/プロモーション通知';
    case AppLanguage.chinese: return '活动/促销通知';
    case AppLanguage.mongolian: return 'Арга хэмжээний мэдэгдэл';
    default: return '이벤트/프로모션 알림';
  }}
  String get mypageNewItemAlarm { switch (language) {
    case AppLanguage.english: return 'New Product Notifications';
    case AppLanguage.japanese: return '新商品通知';
    case AppLanguage.chinese: return '新品通知';
    case AppLanguage.mongolian: return 'Шинэ бараа мэдэгдэл';
    default: return '신상품 알림';
  }}
  String get mypageAppSettings { switch (language) {
    case AppLanguage.english: return 'App Settings';
    case AppLanguage.japanese: return 'アプリ設定';
    case AppLanguage.chinese: return '应用设置';
    case AppLanguage.mongolian: return 'Апп тохиргоо';
    default: return '앱 설정';
  }}
  String get mypageLanguageSettings { switch (language) {
    case AppLanguage.english: return 'Language Settings';
    case AppLanguage.japanese: return '言語設定';
    case AppLanguage.chinese: return '语言设置';
    case AppLanguage.mongolian: return 'Хэлний тохиргоо';
    default: return '언어 설정';
  }}
  String get mypageAppInfo { switch (language) {
    case AppLanguage.english: return 'App Info';
    case AppLanguage.japanese: return 'アプリ情報';
    case AppLanguage.chinese: return '应用信息';
    case AppLanguage.mongolian: return 'Аппын мэдээлэл';
    default: return '앱 정보';
  }}
  String get mypagePrivacyPolicy { switch (language) {
    case AppLanguage.english: return 'Privacy Policy';
    case AppLanguage.japanese: return 'プライバシーポリシー';
    case AppLanguage.chinese: return '隐私政策';
    case AppLanguage.mongolian: return 'Нууцлалын бодлого';
    default: return '개인정보 처리방침';
  }}
  String get mypageTerms { switch (language) {
    case AppLanguage.english: return 'Terms of Service';
    case AppLanguage.japanese: return '利用規約';
    case AppLanguage.chinese: return '服务条款';
    case AppLanguage.mongolian: return 'Үйлчилгээний нөхцөл';
    default: return '이용약관';
  }}
  String get mypageNameLabel { switch (language) {
    case AppLanguage.english: return 'Name';
    case AppLanguage.japanese: return '名前';
    case AppLanguage.chinese: return '姓名';
    case AppLanguage.mongolian: return 'Нэр';
    default: return '이름';
  }}
  String get mypagePhoneLabel { switch (language) {
    case AppLanguage.english: return 'Phone Number';
    case AppLanguage.japanese: return '連絡先';
    case AppLanguage.chinese: return '联系方式';
    case AppLanguage.mongolian: return 'Утас';
    default: return '연락처';
  }}
  String get mypageSave { switch (language) {
    case AppLanguage.english: return 'Save';
    case AppLanguage.japanese: return '保存';
    case AppLanguage.chinese: return '保存';
    case AppLanguage.mongolian: return 'Хадгалах';
    default: return '저장';
  }}
  String get mypageOrderNumber { switch (language) {
    case AppLanguage.english: return 'Order Number';
    case AppLanguage.japanese: return '注文番号';
    case AppLanguage.chinese: return '订单号';
    case AppLanguage.mongolian: return 'Захиалгын дугаар';
    default: return '주문번호';
  }}

  String get mypageOriginalQty { switch (language) {
    case AppLanguage.english: return 'Original Qty';
    case AppLanguage.japanese: return '元の数量';
    case AppLanguage.chinese: return '原数量';
    case AppLanguage.mongolian: return 'Анхны тоо хэмжээ';
    default: return '기존 수량';
  }}
  String get mypageAdditionalGuide { switch (language) {
    case AppLanguage.english: return 'Additional Production Guide';
    case AppLanguage.japanese: return '追加制作案内';
    case AppLanguage.chinese: return '追加生产指南';
    case AppLanguage.mongolian: return 'Нэмэлт үйлдвэрлэлийн заавар';
    default: return '추가제작 안내';
  }}
  String get mypageAdditionalNote1 { switch (language) {
    case AppLanguage.english: return '✅ Additional production available from 1 item';
    case AppLanguage.japanese: return '✅ 1点から追加制作可能です';
    case AppLanguage.chinese: return '✅ 1件起可追加生产';
    case AppLanguage.mongolian: return '✅ 1 ширхэгээс нэмэлт үйлдвэрлэл боломжтой';
    default: return '✅ 1장부터 추가제작 가능합니다';
  }}
  String get mypageAdditionalNote2 { switch (language) {
    case AppLanguage.english: return '✅ All options including color and size can be newly selected';
    case AppLanguage.japanese: return '✅ カラー・サイズなど全てのオプションを新しく選択できます';
    case AppLanguage.chinese: return '✅ 颜色、尺寸等所有选项可重新选择';
    case AppLanguage.mongolian: return '✅ Өнгө·хэмжээ зэрэг бүх сонголтыг шинэчлэн сонгох боломжтой';
    default: return '✅ 색상·사이즈 등 모든 옵션을 새로 선택할 수 있습니다';
  }}
  String get mypageAdditionalNote3 { switch (language) {
    case AppLanguage.english: return '⏰ Applications accepted within 1 week after order completion';
    case AppLanguage.japanese: return '⏰ 本注文完了後1週間以内に申請可能です';
    case AppLanguage.chinese: return '⏰ 订单完成后1周内可申请';
    case AppLanguage.mongolian: return '⏰ Захиалга дууссанаас 1 долоо хоногийн дотор бүртгэх боломжтой';
    default: return '⏰ 본 주문 완료 후 1주일 이내까지만 신청 가능합니다';
  }}
  String get mypageCurrentGroupName { switch (language) {
    case AppLanguage.english: return 'Current Group Name';
    case AppLanguage.japanese: return '現在の団体名';
    case AppLanguage.chinese: return '当前团体名称';
    case AppLanguage.mongolian: return 'Одоогийн бүлгийн нэр';
    default: return '현재 단체명';
  }}
  String get mypageAdminSection { switch (language) {
    case AppLanguage.english: return 'Admin';
    case AppLanguage.japanese: return '管理者';
    case AppLanguage.chinese: return '管理员';
    case AppLanguage.mongolian: return 'Админ';
    default: return '관리자';
  }}
  String get mypageAdditionalSizeHint { switch (language) {
    case AppLanguage.english: return 'e.g. S 1pc, M 2pcs, L 1pc';
    case AppLanguage.japanese: return '例: S 1枚, M 2枚, L 1枚';
    case AppLanguage.chinese: return '例如: S 1件, M 2件, L 1件';
    case AppLanguage.mongolian: return 'Жш: S 1ш, M 2ш, L 1ш';
    default: return '예: S 1장, M 2장, L 1장';
  }}

  // ─── 체크아웃 화면 텍스트 ───
  String get checkoutShippingInfo { switch (language) {
    case AppLanguage.english: return 'Shipping Information';
    case AppLanguage.japanese: return '配送情報';
    case AppLanguage.chinese: return '配送信息';
    case AppLanguage.mongolian: return 'Хүргэлтийн мэдээлэл';
    default: return '배송 정보';
  }}
  String get checkoutShippingMemo { switch (language) {
    case AppLanguage.english: return 'Delivery Note (Optional)';
    case AppLanguage.japanese: return '配送メモ（任意）';
    case AppLanguage.chinese: return '配送备注（可选）';
    case AppLanguage.mongolian: return 'Хүргэлтийн тэмдэглэл (заавал биш)';
    default: return '배송 메모 (선택)';
  }}
  String get checkoutShippingMemoHint { switch (language) {
    case AppLanguage.english: return 'Leave at door';
    case AppLanguage.japanese: return 'ドア前に置いてください';
    case AppLanguage.chinese: return '请放在门口';
    case AppLanguage.mongolian: return 'Хаалганы өмнө тавьна уу';
    default: return '문 앞에 놔주세요';
  }}
  String get checkoutAddressSearch { switch (language) {
    case AppLanguage.english: return 'Search Address (Click)';
    case AppLanguage.japanese: return '住所検索（クリック）';
    case AppLanguage.chinese: return '搜索地址（点击）';
    case AppLanguage.mongolian: return 'Хаяг хайх (дарна уу)';
    default: return '주소 검색 (클릭)';
  }}
  String get checkoutDetailAddressHint { switch (language) {
    case AppLanguage.english: return 'Detailed address (unit/floor etc.)';
    case AppLanguage.japanese: return '詳細住所（号室/階など）';
    case AppLanguage.chinese: return '详细地址（房号/楼层等）';
    case AppLanguage.mongolian: return 'Дэлгэрэнгүй хаяг (тоот/давхар гэх мэт)';
    default: return '상세 주소 (동/호수 등)';
  }}
  String get checkoutDetailAddressHint2 { switch (language) {
    case AppLanguage.english: return 'Search address first';
    case AppLanguage.japanese: return '先に住所を検索してください';
    case AppLanguage.chinese: return '请先搜索地址';
    case AppLanguage.mongolian: return 'Эхлээд хаяг хайна уу';
    default: return '먼저 주소를 검색해주세요';
  }}
  String get checkoutEnglishAddress { switch (language) {
    case AppLanguage.english: return 'Please enter in English. Country is required.';
    case AppLanguage.japanese: return '英語で入力してください。Countryは必須です。';
    case AppLanguage.chinese: return '请用英语输入。Country为必填项。';
    case AppLanguage.mongolian: return 'Англиар оруулна уу. Улс заавал шаардлагатай.';
    default: return '영문 주소로 입력해주세요. Country는 필수입니다.';
  }}
  String get checkoutCouponApply { switch (language) {
    case AppLanguage.english: return 'Apply';
    case AppLanguage.japanese: return '適用';
    case AppLanguage.chinese: return '应用';
    case AppLanguage.mongolian: return 'Хэрэглэх';
    default: return '적용';
  }}
  String get checkoutCouponInvalid { switch (language) {
    case AppLanguage.english: return 'Invalid or expired coupon.';
    case AppLanguage.japanese: return '無効または期限切れのクーポンです。';
    case AppLanguage.chinese: return '优惠券无效或已过期。';
    case AppLanguage.mongolian: return 'Хүчингүй эсвэл хугацаа дууссан купон.';
    default: return '유효하지 않거나 만료된 쿠폰입니다.';
  }}
  String get checkoutCouponApplied { switch (language) {
    case AppLanguage.english: return 'Coupon applied!';
    case AppLanguage.japanese: return 'クーポンが適用されました！';
    case AppLanguage.chinese: return '优惠券已应用！';
    case AppLanguage.mongolian: return 'Купон хэрэглэгдлээ!';
    default: return '쿠폰이 적용되었습니다!';
  }}
  String get checkoutPaymentFree { switch (language) {
    case AppLanguage.english: return 'Free';
    case AppLanguage.japanese: return '無料';
    case AppLanguage.chinese: return '免费';
    case AppLanguage.mongolian: return 'Үнэгүй';
    default: return '무료';
  }}
  String get checkoutNoAddress { switch (language) {
    case AppLanguage.english: return 'Please search for a shipping address.';
    case AppLanguage.japanese: return '配送先住所を検索してください。';
    case AppLanguage.chinese: return '请搜索配送地址。';
    case AppLanguage.mongolian: return 'Хүргэлтийн хаягийг хайна уу.';
    default: return '배송 주소를 검색해주세요.';
  }}
  String get checkoutOrderedItems { switch (language) {
    case AppLanguage.english: return 'Ordered Items';
    case AppLanguage.japanese: return '注文商品';
    case AppLanguage.chinese: return '订购商品';
    case AppLanguage.mongolian: return 'Захиалсан бараа';
    default: return '주문 상품';
  }}
  String get checkoutRecipient { switch (language) {
    case AppLanguage.english: return 'Recipient';
    case AppLanguage.japanese: return 'お届け先';
    case AppLanguage.chinese: return '收件人';
    case AppLanguage.mongolian: return 'Хүлээн авагч';
    default: return '받는 분';
  }}
  String get checkoutAddressLabel { switch (language) {
    case AppLanguage.english: return 'Address';
    case AppLanguage.japanese: return '住所';
    case AppLanguage.chinese: return '地址';
    case AppLanguage.mongolian: return 'Хаяг';
    default: return '주소';
  }}
  String get checkoutPaymentInfo { switch (language) {
    case AppLanguage.english: return 'Payment Information';
    case AppLanguage.japanese: return 'お支払い情報';
    case AppLanguage.chinese: return '支付信息';
    case AppLanguage.mongolian: return 'Төлбөрийн мэдээлэл';
    default: return '결제 정보';
  }}
  String get checkoutDeliveryGuide { switch (language) {
    case AppLanguage.english: return 'Delivery Guide';
    case AppLanguage.japanese: return '配送案内';
    case AppLanguage.chinese: return '配送指南';
    case AppLanguage.mongolian: return 'Хүргэлтийн заавар';
    default: return '배송 안내';
  }}
  String get checkoutDeliveryDays { switch (language) {
    case AppLanguage.english: return 'Ships within 2-4 business days';
    case AppLanguage.japanese: return '営業日2〜4日以内に出荷';
    case AppLanguage.chinese: return '工作日2-4天内发货';
    case AppLanguage.mongolian: return 'Ажлын 2-4 хоногт хүргэлт';
    default: return '영업일 기준 2~4일 이내 출고';
  }}
  String get checkoutKakaoInquiry { switch (language) {
    case AppLanguage.english: return 'Inquiry: KakaoTalk @2FIT';
    case AppLanguage.japanese: return 'お問い合わせ: カカオトーク @2FIT';
    case AppLanguage.chinese: return '咨询: KakaoTalk @2FIT';
    case AppLanguage.mongolian: return 'Лавлагаа: KakaoTalk @2FIT';
    default: return '문의: 카카오톡 채널 @2FIT';
  }}
  String get checkoutProcessing { switch (language) {
    case AppLanguage.english: return 'Processing payment...';
    case AppLanguage.japanese: return '決済処理中...';
    case AppLanguage.chinese: return '处理支付中...';
    case AppLanguage.mongolian: return 'Төлбөр боловсруулж байна...';
    default: return '결제를 처리하고 있습니다...';
  }}
  String get checkoutPleaseWait { switch (language) {
    case AppLanguage.english: return 'Please wait a moment';
    case AppLanguage.japanese: return '少々お待ちください';
    case AppLanguage.chinese: return '请稍候';
    case AppLanguage.mongolian: return 'Түр хүлээнэ үү';
    default: return '잠시만 기다려주세요';
  }}
  String get checkoutPaymentApproved { switch (language) {
    case AppLanguage.english: return 'Payment Approved!';
    case AppLanguage.japanese: return '決済承認完了！';
    case AppLanguage.chinese: return '支付已批准！';
    case AppLanguage.mongolian: return 'Төлбөр баталгаажлаа!';
    default: return '결제 승인 완료!';
  }}
  String get checkoutOrderReceived { switch (language) {
    case AppLanguage.english: return 'Order has been received';
    case AppLanguage.japanese: return 'ご注文を受け付けました';
    case AppLanguage.chinese: return '订单已接受';
    case AppLanguage.mongolian: return 'Захиалга хүлээн авлаа';
    default: return '주문이 접수되었습니다';
  }}
  String get checkoutCardInvalid { switch (language) {
    case AppLanguage.english: return 'Card information is incorrect. Please check again.';
    case AppLanguage.japanese: return 'カード情報が正しくありません。再確認してください。';
    case AppLanguage.chinese: return '信用卡信息不正确，请重新确认。';
    case AppLanguage.mongolian: return 'Картын мэдээлэл буруу байна. Дахин шалгана уу.';
    default: return '카드 정보가 올바르지 않습니다. 다시 확인해주세요.';
  }}
  String get checkoutKakaoPayMethod { switch (language) {
    case AppLanguage.english: return 'KakaoPay';
    case AppLanguage.japanese: return 'カカオペイ';
    case AppLanguage.chinese: return 'Kakao Pay';
    case AppLanguage.mongolian: return 'Kakao Pay';
    default: return '카카오페이';
  }}
  String get checkoutCardMethod { switch (language) {
    case AppLanguage.english: return 'Credit/Debit Card';
    case AppLanguage.japanese: return 'クレジット/デビットカード';
    case AppLanguage.chinese: return '信用卡/借记卡';
    case AppLanguage.mongolian: return 'Кредит/Дебит карт';
    default: return '신용/체크카드';
  }}
  String get checkoutBankMethod { switch (language) {
    case AppLanguage.english: return 'Bank Transfer';
    case AppLanguage.japanese: return '振込';
    case AppLanguage.chinese: return '银行转账';
    case AppLanguage.mongolian: return 'Банкны шилжүүлэг';
    default: return '무통장입금';
  }}
  String get checkoutNaverPayMethod { switch (language) {
    case AppLanguage.english: return 'NaverPay';
    case AppLanguage.japanese: return 'ネイバーペイ';
    case AppLanguage.chinese: return 'NaverPay';
    case AppLanguage.mongolian: return 'NaverPay';
    default: return '네이버페이';
  }}
  String get checkoutNameLabel { switch (language) {
    case AppLanguage.english: return 'Name';
    case AppLanguage.japanese: return '名前';
    case AppLanguage.chinese: return '姓名';
    case AppLanguage.mongolian: return 'Нэр';
    default: return '이름';
  }}
  String get checkoutPhoneLabel { switch (language) {
    case AppLanguage.english: return 'Phone';
    case AppLanguage.japanese: return '電話番号';
    case AppLanguage.chinese: return '电话';
    case AppLanguage.mongolian: return 'Утас';
    default: return '연락처';
  }}
  String get checkoutEmailLabel { switch (language) {
    case AppLanguage.english: return 'Email';
    case AppLanguage.japanese: return 'メール';
    case AppLanguage.chinese: return '邮箱';
    case AppLanguage.mongolian: return 'Имэйл';
    default: return '이메일';
  }}
  String get checkoutTestPayment { switch (language) {
    case AppLanguage.english: return 'Toss Payments · Test Payment';
    case AppLanguage.japanese: return 'トスペイメンツ · テスト決済';
    case AppLanguage.chinese: return 'Toss支付 · 测试支付';
    case AppLanguage.mongolian: return 'Toss Payments · Туршилтын төлбөр';
    default: return '토스페이먼츠  ·  테스트 결제';
  }}
  String get checkoutTestNote { switch (language) {
    case AppLanguage.english: return 'This is a test payment. No actual payment will occur.';
    case AppLanguage.japanese: return 'テスト決済です。実際の決済は発生しません。';
    case AppLanguage.chinese: return '这是测试支付，不会产生实际扣款。';
    case AppLanguage.mongolian: return 'Энэ бол туршилтын төлбөр. Бодит төлбөр хийгдэхгүй.';
    default: return '테스트 결제입니다. 실제 결제가 발생하지 않습니다.';
  }}
  String get checkoutCardNumberLabel { switch (language) {
    case AppLanguage.english: return 'Card Number';
    case AppLanguage.japanese: return 'カード番号';
    case AppLanguage.chinese: return '卡号';
    case AppLanguage.mongolian: return 'Картын дугаар';
    default: return '카드번호';
  }}
  String get checkoutExpiryLabel { switch (language) {
    case AppLanguage.english: return 'Expiry Date';
    case AppLanguage.japanese: return '有効期限';
    case AppLanguage.chinese: return '有效期';
    case AppLanguage.mongolian: return 'Хүчинтэй хугацаа';
    default: return '유효기간';
  }}
  String get checkoutPwLabel { switch (language) {
    case AppLanguage.english: return 'First 2 digits of password';
    case AppLanguage.japanese: return 'パスワード前2桁';
    case AppLanguage.chinese: return '密码前2位';
    case AppLanguage.mongolian: return 'Нууц үгний эхний 2 оронтоо';
    default: return '비밀번호 앞 2자리';
  }}
  String get checkoutBirthLabel { switch (language) {
    case AppLanguage.english: return 'Date of Birth (6 digits)';
    case AppLanguage.japanese: return '生年月日6桁';
    case AppLanguage.chinese: return '出生日期6位';
    case AppLanguage.mongolian: return 'Төрсөн огноо 6 оронтоо';
    default: return '생년월일 6자리';
  }}
  String get checkoutMinOrderNote { switch (language) {
    case AppLanguage.english: return 'Minimum order amount must be';
    case AppLanguage.japanese: return '最低注文金額は';
    case AppLanguage.chinese: return '最低订单金额需达到';
    case AppLanguage.mongolian: return 'Доод захиалгын дүн';
    default: return '최소 주문 금액';
  }}
  String get checkoutItemCount { switch (language) {
    case AppLanguage.english: return 'items';
    case AppLanguage.japanese: return '点';
    case AppLanguage.chinese: return '件';
    case AppLanguage.mongolian: return 'ширхэг';
    default: return '개';
  }}
  String get checkoutDeliveryGuideRow1 { switch (language) {
    case AppLanguage.english: return 'Ships within 2-4 business days';
    case AppLanguage.japanese: return '営業日2〜4日以内に出荷';
    case AppLanguage.chinese: return '工作日2-4天内发货';
    case AppLanguage.mongolian: return 'Ажлын 2-4 хоногт хүргэлт';
    default: return '영업일 기준 2~4일 이내 출고';
  }}

  String get payMethod { switch (language) {
    case AppLanguage.english: return 'Payment Method';
    case AppLanguage.japanese: return '決済手段';
    case AppLanguage.chinese: return '支付方式';
    case AppLanguage.mongolian: return 'Төлбөрийн арга';
    default: return '결제 수단';
  }}

  String get loginAdminEntered { switch (language) {
    case AppLanguage.english: return 'Admin credentials entered';
    case AppLanguage.japanese: return '管理者情報が入力されました';
    case AppLanguage.chinese: return '管理员信息已输入';
    case AppLanguage.mongolian: return 'Админ мэдээлэл оруулсан';
    default: return '관리자 계정이 입력되었습니다';
  }}

  String get loginFailed { switch (language) {
    case AppLanguage.english: return 'Login failed.';
    case AppLanguage.japanese: return 'ログインに失敗しました。';
    case AppLanguage.chinese: return '登录失败。';
    case AppLanguage.mongolian: return 'Нэвтрэх амжилтгүй болсон.';
    default: return '로그인에 실패했습니다.';
  }}

  String get loginEmailRequired { switch (language) {
    case AppLanguage.english: return 'Please enter your email';
    case AppLanguage.japanese: return 'メールを入力してください';
    case AppLanguage.chinese: return '请输入邮箱';
    case AppLanguage.mongolian: return 'Имэйл оруулна уу';
    default: return '이메일을 입력해주세요';
  }}

  String get loginEmailInvalid { switch (language) {
    case AppLanguage.english: return 'Please enter a valid email';
    case AppLanguage.japanese: return '正しいメール形式で入力してください';
    case AppLanguage.chinese: return '请输入有效的邮箱格式';
    case AppLanguage.mongolian: return 'Зөв имэйл хэлбэр оруулна уу';
    default: return '올바른 이메일 형식을 입력해주세요';
  }}

  String get loginPasswordRequired { switch (language) {
    case AppLanguage.english: return 'Please enter your password';
    case AppLanguage.japanese: return 'パスワードを入力してください';
    case AppLanguage.chinese: return '请输入密码';
    case AppLanguage.mongolian: return 'Нууц үг оруулна уу';
    default: return '비밀번호를 입력해주세요';
  }}

  String get loginPasswordTooShort { switch (language) {
    case AppLanguage.english: return 'Password is too short';
    case AppLanguage.japanese: return 'パスワードが短すぎます';
    case AppLanguage.chinese: return '密码太短';
    case AppLanguage.mongolian: return 'Нууц үг хэт богино байна';
    default: return '비밀번호가 너무 짧습니다';
  }}

  String get loginFeature1 { switch (language) {
    case AppLanguage.english: return 'Free shipping over ₩300,000';
    case AppLanguage.japanese: return '30万ウォン以上送料無料';
    case AppLanguage.chinese: return '满30万韩元免运费';
    case AppLanguage.mongolian: return '30万₩-с дээш үнэгүй хүргэлт';
    default: return '30만원 이상 무료배송';
  }}

  String get loginFeature2 { switch (language) {
    case AppLanguage.english: return 'Premium Sportswear';
    case AppLanguage.japanese: return 'プレミアムスポーツウェア';
    case AppLanguage.chinese: return '高端运动服';
    case AppLanguage.mongolian: return 'Премиум спорт хувцас';
    default: return '프리미엄 스포츠웨어';
  }}

  String get loginFeature3 { switch (language) {
    case AppLanguage.english: return 'Group Order Specialist';
    case AppLanguage.japanese: return '団体注文専門';
    case AppLanguage.chinese: return '团体订购专家';
    case AppLanguage.mongolian: return 'Бүлгийн захиалгын мэргэжилтэн';
    default: return '단체 주문 전문';
  }}

  String get signupName { switch (language) {
    case AppLanguage.english: return 'Name *';
    case AppLanguage.japanese: return '名前 *';
    case AppLanguage.chinese: return '姓名 *';
    case AppLanguage.mongolian: return 'Нэр *';
    default: return '이름 *';
  }}

  String get signupPhone { switch (language) {
    case AppLanguage.english: return 'Phone Number';
    case AppLanguage.japanese: return '電話番号';
    case AppLanguage.chinese: return '手机号码';
    case AppLanguage.mongolian: return 'Утасны дугаар';
    default: return '휴대폰 번호';
  }}

  String get signupPasswordHint2 { switch (language) {
    case AppLanguage.english: return 'At least 6 characters';
    case AppLanguage.japanese: return '6文字以上入力してください';
    case AppLanguage.chinese: return '请输入6位以上字符';
    case AppLanguage.mongolian: return '6-аас дээш тэмдэгт оруулна уу';
    default: return '6자 이상 입력해주세요';
  }}

  String get signupPasswordConfirmLabel { switch (language) {
    case AppLanguage.english: return 'Confirm Password *';
    case AppLanguage.japanese: return 'パスワード確認 *';
    case AppLanguage.chinese: return '确认密码 *';
    case AppLanguage.mongolian: return 'Нууц үг баталгаажуулах *';
    default: return '비밀번호 확인 *';
  }}

  String get signupPasswordConfirmHint2 { switch (language) {
    case AppLanguage.english: return 'Enter password again';
    case AppLanguage.japanese: return 'パスワードを再入力してください';
    case AppLanguage.chinese: return '请再次输入密码';
    case AppLanguage.mongolian: return 'Нууц үгийг дахин оруулна уу';
    default: return '비밀번호를 다시 입력해주세요';
  }}

  String get cartItemCount { switch (language) {
    case AppLanguage.english: return 'Order items';
    case AppLanguage.japanese: return 'アイテムを注文';
    case AppLanguage.chinese: return '件商品下单';
    case AppLanguage.mongolian: return 'Захиалах';
    default: return '개 주문하기';
  }}

  String get cartFreeShipAchieved { switch (language) {
    case AppLanguage.english: return '🎉 Free Shipping!';
    case AppLanguage.japanese: return '🎉 送料無料達成!';
    case AppLanguage.chinese: return '🎉 免运费达成！';
    case AppLanguage.mongolian: return '🎉 Үнэгүй хүргэлт!';
    default: return '🎉 무료배송 달성!';
  }}

  String get cartFreeShipProgress { switch (language) {
    case AppLanguage.english: return ' more for free shipping!';
    case AppLanguage.japanese: return 'で送料無料！';
    case AppLanguage.chinese: return '即可免运费！';
    case AppLanguage.mongolian: return 'нэмбэл үнэгүй хүргэлт!';
    default: return '원 더 담으면 무료배송!';
  }}

  String get cartCheckout { switch (language) {
    case AppLanguage.english: return 'Checkout';
    case AppLanguage.japanese: return '決済する';
    case AppLanguage.chinese: return '去结算';
    case AppLanguage.mongolian: return 'Төлөх';
    default: return '결제하기';
  }}

  String get cartFreeShipNote { switch (language) {
    case AppLanguage.english: return 'Over ₩300,000';
    case AppLanguage.japanese: return '30万ウォン以上';
    case AppLanguage.chinese: return '满30万韩元';
    case AppLanguage.mongolian: return '30만₩-с дээш';
    default: return '30만원 이상';
  }}

  String get cartExchangeNote { switch (language) {
    case AppLanguage.english: return '7-day exchange/return';
    case AppLanguage.japanese: return '受け取り後7日以内交換/返品';
    case AppLanguage.chinese: return '收货后7天内可换/退货';
    case AppLanguage.mongolian: return 'Хүлээн авснаас 7 хоногийн дотор солих/буцаах';
    default: return '수령 후 7일 내 교환/반품';
  }}

  String get cartSubtotalAmount { switch (language) {
    case AppLanguage.english: return 'Subtotal:';
    case AppLanguage.japanese: return '小計:';
    case AppLanguage.chinese: return '小计:';
    case AppLanguage.mongolian: return 'Дэд нийт:';
    default: return '소계:';
  }}

  String get cartClearTitle { switch (language) {
    case AppLanguage.english: return 'Clear Cart';
    case AppLanguage.japanese: return 'カートを空にする';
    case AppLanguage.chinese: return '清空购物车';
    case AppLanguage.mongolian: return 'Сагс хоослох';
    default: return '장바구니 비우기';
  }}

  String get cartClearContent { switch (language) {
    case AppLanguage.english: return 'Remove all items from cart?';
    case AppLanguage.japanese: return 'すべての商品をカートから削除しますか？';
    case AppLanguage.chinese: return '确定要清空购物车吗？';
    case AppLanguage.mongolian: return 'Сагсан дахь бүх бараа устгах уу?';
    default: return '모든 상품을 장바구니에서 삭제하겠습니까?';
  }}

  String get cartCancel { switch (language) {
    case AppLanguage.english: return 'Cancel';
    case AppLanguage.japanese: return 'キャンセル';
    case AppLanguage.chinese: return '取消';
    case AppLanguage.mongolian: return 'Цуцлах';
    default: return '취소';
  }}

  String get cartDelete { switch (language) {
    case AppLanguage.english: return 'Delete';
    case AppLanguage.japanese: return '削除';
    case AppLanguage.chinese: return '删除';
    case AppLanguage.mongolian: return 'Устгах';
    default: return '삭제';
  }}

  String get filterTitle { switch (language) {
    case AppLanguage.english: return 'Filter';
    case AppLanguage.japanese: return 'フィルター';
    case AppLanguage.chinese: return '筛选';
    case AppLanguage.mongolian: return 'Шүүлтүүр';
    default: return '필터';
  }}

  String get filterReset2 { switch (language) {
    case AppLanguage.english: return 'Reset';
    case AppLanguage.japanese: return 'リセット';
    case AppLanguage.chinese: return '重置';
    case AppLanguage.mongolian: return 'Шинэчлэх';
    default: return '초기화';
  }}

  String get filterFreeShipOnly { switch (language) {
    case AppLanguage.english: return 'Free Shipping Only';
    case AppLanguage.japanese: return '送料無料のみ';
    case AppLanguage.chinese: return '仅免运费';
    case AppLanguage.mongolian: return 'Зөвхөн үнэгүй хүргэлт';
    default: return '무료배송만';
  }}

  String get sortTitle { switch (language) {
    case AppLanguage.english: return 'Sort';
    case AppLanguage.japanese: return '並び順';
    case AppLanguage.chinese: return '排序';
    case AppLanguage.mongolian: return 'Эрэмбэлэх';
    default: return '정렬';
  }}

  String get viewMode { switch (language) {
    case AppLanguage.english: return 'View Mode';
    case AppLanguage.japanese: return '表示方法';
    case AppLanguage.chinese: return '显示方式';
    case AppLanguage.mongolian: return 'Харах горим';
    default: return '보기 방식';
  }}

  String get productEmpty { switch (language) {
    case AppLanguage.english: return 'No products';
    case AppLanguage.japanese: return '商品がありません';
    case AppLanguage.chinese: return '暂无商品';
    case AppLanguage.mongolian: return 'Бараа байхгүй';
    default: return '상품이 없습니다';
  }}

  String get searchNoResultSimple { switch (language) {
    case AppLanguage.english: return 'No search results';
    case AppLanguage.japanese: return '検索結果なし';
    case AppLanguage.chinese: return '无搜索结果';
    case AppLanguage.mongolian: return 'Хайлтын үр дүн байхгүй';
    default: return '검색 결과 없음';
  }}

  String get productSearchHint { switch (language) {
    case AppLanguage.english: return 'Search products...';
    case AppLanguage.japanese: return '商品名、ブランドで検索';
    case AppLanguage.chinese: return '搜索商品名称、品牌';
    case AppLanguage.mongolian: return 'Бараа, брэнд хайх';
    default: return '상품명, 브랜드, 카테고리 검색';
  }}

  String get filterNewOnly { switch (language) {
    case AppLanguage.english: return 'New';
    case AppLanguage.japanese: return '新商品';
    case AppLanguage.chinese: return '新品';
    case AppLanguage.mongolian: return 'Шинэ';
    default: return '신상품';
  }}

  String get filterSale { switch (language) {
    case AppLanguage.english: return 'Sale';
    case AppLanguage.japanese: return 'セール';
    case AppLanguage.chinese: return '特价';
    case AppLanguage.mongolian: return 'Хямдарсан';
    default: return '세일';
  }}

  String get filterFreeShip { switch (language) {
    case AppLanguage.english: return 'Free Shipping';
    case AppLanguage.japanese: return '送料無料';
    case AppLanguage.chinese: return '免运费';
    case AppLanguage.mongolian: return 'Үнэгүй хүргэлт';
    default: return '무료배송';
  }}

  String get filterResetBtn { switch (language) {
    case AppLanguage.english: return 'Reset Filters';
    case AppLanguage.japanese: return 'フィルターリセット';
    case AppLanguage.chinese: return '重置筛选';
    case AppLanguage.mongolian: return 'Шүүлтүүр шинэчлэх';
    default: return '필터 초기화';
  }}

  String get priceRangeLabel { switch (language) {
    case AppLanguage.english: return 'Price Range';
    case AppLanguage.japanese: return '価格帯';
    case AppLanguage.chinese: return '价格区间';
    case AppLanguage.mongolian: return 'Үнийн хязгаар';
    default: return '가격 범위';
  }}

  String get orderGuide5PlusMake { switch (language) {
    case AppLanguage.english: return 'Custom for teams 5+';
    case AppLanguage.japanese: return '5名以上チームカスタム';
    case AppLanguage.chinese: return '5人以上团队定制';
    case AppLanguage.mongolian: return '5-аас дээш багийн захиалга';
    default: return '5인 이상 팀·단체 맞춤 제작';
  }}

  String get orderGuideDiscount { switch (language) {
    case AppLanguage.english: return '30+ 10%, 50+ 20% discount';
    case AppLanguage.japanese: return '30人↑10%、50人↑20%割引';
    case AppLanguage.chinese: return '30人↑10%，50人↑20%折扣';
    case AppLanguage.mongolian: return '30↑10%, 50↑20% хөнгөлөлт';
    default: return '30인↑ 10%, 50인↑ 20% 할인';
  }}

  String get orderGuideStep1 { switch (language) {
    case AppLanguage.english: return 'Fill Order Form';
    case AppLanguage.japanese: return '注文書記入';
    case AppLanguage.chinese: return '填写订单';
    case AppLanguage.mongolian: return 'Захиалга бөглөх';
    default: return '주문서 작성';
  }}

  String get orderGuideStep1Sub { switch (language) {
    case AppLanguage.english: return 'Select product & custom';
    case AppLanguage.japanese: return '商品選択＆カスタム設定';
    case AppLanguage.chinese: return '选择商品&自定义设置';
    case AppLanguage.mongolian: return 'Бараа сонгох & тохиргоо';
    default: return '상품 선택 & 커스텀 설정';
  }}

  String get orderGuideStep2 { switch (language) {
    case AppLanguage.english: return 'Review Draft';
    case AppLanguage.japanese: return '試案確認';
    case AppLanguage.chinese: return '确认设计稿';
    case AppLanguage.mongolian: return 'Загвар шалгах';
    default: return '시안 확인';
  }}

  String get orderGuideStep2Sub { switch (language) {
    case AppLanguage.english: return 'Draft within 3 biz days';
    case AppLanguage.japanese: return '営業日3日以内に試案送付';
    case AppLanguage.chinese: return '3个工作日内发送设计稿';
    case AppLanguage.mongolian: return '3 ажлын өдрийн дотор';
    default: return '영업일 3일 내 시안 발송';
  }}

  String get orderGuideStep3 { switch (language) {
    case AppLanguage.english: return 'Payment';
    case AppLanguage.japanese: return '決済';
    case AppLanguage.chinese: return '付款';
    case AppLanguage.mongolian: return 'Төлбөр';
    default: return '결제';
  }}

  String get orderGuideStep3Sub { switch (language) {
    case AppLanguage.english: return 'Payment after approval';
    case AppLanguage.japanese: return '承認後決済案内';
    case AppLanguage.chinese: return '批准后付款说明';
    case AppLanguage.mongolian: return 'Зөвшөөрлийн дараа';
    default: return '승인 후 결제 안내';
  }}

  String get orderGuideStep4 { switch (language) {
    case AppLanguage.english: return 'Production';
    case AppLanguage.japanese: return '製作';
    case AppLanguage.chinese: return '生产';
    case AppLanguage.mongolian: return 'Үйлдвэрлэл';
    default: return '제작';
  }}

  String get orderGuideStep4Sub { switch (language) {
    case AppLanguage.english: return '14~21 days';
    case AppLanguage.japanese: return '14〜21日かかります';
    case AppLanguage.chinese: return '需要14~21天';
    case AppLanguage.mongolian: return '14~21 хоног';
    default: return '14~21일 소요';
  }}

  String get orderGuideStep5 { switch (language) {
    case AppLanguage.english: return 'Delivery';
    case AppLanguage.japanese: return '配送';
    case AppLanguage.chinese: return '发货';
    case AppLanguage.mongolian: return 'Хүргэлт';
    default: return '배송';
  }}

  String get orderGuideStep5Sub { switch (language) {
    case AppLanguage.english: return 'Sequential shipping';
    case AppLanguage.japanese: return '順次発送';
    case AppLanguage.chinese: return '按顺序发货';
    case AppLanguage.mongolian: return 'Дараалан илгээх';
    default: return '순차 발송';
  }}

  String get orderGuideCustomerService { switch (language) {
    case AppLanguage.english: return 'Customer Service';
    case AppLanguage.japanese: return 'カスタマーサービス';
    case AppLanguage.chinese: return '客服';
    case AppLanguage.mongolian: return 'Үйлчлүүлэгчийн тусламж';
    default: return '고객센터';
  }}

  String get orderGuideKakao { switch (language) {
    case AppLanguage.english: return 'KakaoTalk @2fitkorea';
    case AppLanguage.japanese: return 'カカオトーク @2fitkorea';
    case AppLanguage.chinese: return '카카오톡 @2fitkorea';
    case AppLanguage.mongolian: return 'Kakao @2fitkorea';
    default: return '카카오톡 @2fitkorea';
  }}

  String get orderGuideTypeTitle { switch (language) {
    case AppLanguage.english: return 'Select Order Type';
    case AppLanguage.japanese: return '注文タイプ選択';
    case AppLanguage.chinese: return '选择订单类型';
    case AppLanguage.mongolian: return 'Захиалгын төрөл сонгох';
    default: return '주문 유형 선택';
  }}

  String get orderGuideTypeSub { switch (language) {
    case AppLanguage.english: return 'Check guide or fill order form';
    case AppLanguage.japanese: return 'ガイドを確認するか注文書を記入';
    case AppLanguage.chinese: return '先查看指南或直接填写订单';
    case AppLanguage.mongolian: return 'Гарын авлага үзэх эсвэл шууд бөглөх';
    default: return '주문 안내를 먼저 확인하거나, 바로 주문서를 작성하세요';
  }}

  String get orderGuideGroupTitle { switch (language) {
    case AppLanguage.english: return 'Group Custom Order';
    case AppLanguage.japanese: return '団体カスタム注文';
    case AppLanguage.chinese: return '团体定制订单';
    case AppLanguage.mongolian: return 'Бүлгийн захиалга';
    default: return '단체 커스텀 주문';
  }}

  String get orderGuideGroupSub { switch (language) {
    case AppLanguage.english: return 'Group benefits for 5+';
    case AppLanguage.japanese: return '5名以上の団体特典';
    case AppLanguage.chinese: return '5人以上团体优惠';
    case AppLanguage.mongolian: return '5-аас дээш бүлгийн давуу тал';
    default: return '5인 이상 단체 혜택';
  }}

  String get orderGuideGroupDesc { switch (language) {
    case AppLanguage.english: return 'Team logo, name/number print, group discount';
    case AppLanguage.japanese: return 'チームロゴ、名前/番号印刷、団体割引';
    case AppLanguage.chinese: return '团队LOGO、姓名/号码印刷、团体折扣';
    case AppLanguage.mongolian: return 'Багийн лого, нэр/дугаар хэвлэх, бүлгийн хөнгөлөлт';
    default: return '팀 로고, 이름/번호 인쇄, 단체 할인 적용';
  }}

  String get orderGuideGroupBadge1 { switch (language) {
    case AppLanguage.english: return 'Team Logo';
    case AppLanguage.japanese: return 'チームロゴ';
    case AppLanguage.chinese: return '团队LOGO';
    case AppLanguage.mongolian: return 'Багийн лого';
    default: return '팀 로고';
  }}

  String get orderGuideGroupBadge2 { switch (language) {
    case AppLanguage.english: return 'Name/Number';
    case AppLanguage.japanese: return '名前/番号';
    case AppLanguage.chinese: return '姓名/号码';
    case AppLanguage.mongolian: return 'Нэр/Дугаар';
    default: return '이름/번호';
  }}

  String get orderGuideGroupBadge3 { switch (language) {
    case AppLanguage.english: return 'Group Discount';
    case AppLanguage.japanese: return '団体割引';
    case AppLanguage.chinese: return '团体折扣';
    case AppLanguage.mongolian: return 'Бүлгийн хөнгөлөлт';
    default: return '단체 할인';
  }}

  String get orderGuideAdditionalNote { switch (language) {
    case AppLanguage.english: return 'Additional production with same options';
    case AppLanguage.japanese: return '既存注文と同じオプションで追加製作';
    case AppLanguage.chinese: return '与原订单相同选项追加生产';
    case AppLanguage.mongolian: return 'Ижил сонголтоор нэмэлт үйлдвэрлэл';
    default: return '기존 주문과 동일한 옵션으로 추가 제작';
  }}

  String get orderGuideAdditional1 { switch (language) {
    case AppLanguage.english: return 'From 1 piece';
    case AppLanguage.japanese: return '1枚から可能';
    case AppLanguage.chinese: return '从1件起可订';
    case AppLanguage.mongolian: return '1-ээс боломжтой';
    default: return '1장부터 가능';
  }}

  String get orderGuideAdditional2 { switch (language) {
    case AppLanguage.english: return 'Within 1 week';
    case AppLanguage.japanese: return '1週間以内';
    case AppLanguage.chinese: return '1周内';
    case AppLanguage.mongolian: return '1 долоо хоногийн дотор';
    default: return '1주일 이내';
  }}

  String get orderGuideAdditional3 { switch (language) {
    case AppLanguage.english: return 'Same Options';
    case AppLanguage.japanese: return '同一オプション';
    case AppLanguage.chinese: return '相同选项';
    case AppLanguage.mongolian: return 'Ижил сонголт';
    default: return '동일 옵션';
  }}

  String get orderGuideAdditionalMin { switch (language) {
    case AppLanguage.english: return 'Minimum Quantity';
    case AppLanguage.japanese: return '最低数量';
    case AppLanguage.chinese: return '最低数量';
    case AppLanguage.mongolian: return 'Хамгийн бага тоо';
    default: return '최소 수량';
  }}

  String get orderGuideAdditionalMinDesc { switch (language) {
    case AppLanguage.english: return '1 piece minimum';
    case AppLanguage.japanese: return '1枚から追加購入可能';
    case AppLanguage.chinese: return '最少1件起追购';
    case AppLanguage.mongolian: return '1-ээс нэмэлт захиалах боломжтой';
    default: return '1장부터 추가구매 가능합니다';
  }}

  String get orderGuideAdditionalDeadline { switch (language) {
    case AppLanguage.english: return 'Application Deadline';
    case AppLanguage.japanese: return '申込期限';
    case AppLanguage.chinese: return '申请截止日';
    case AppLanguage.mongolian: return 'Хугацаа';
    default: return '신청 기한';
  }}

  String get orderGuideAdditionalDeadlineDesc { switch (language) {
    case AppLanguage.english: return 'Within 1 week of main order';
    case AppLanguage.japanese: return '本注文完了後1週間以内';
    case AppLanguage.chinese: return '主订单完成后1周内可申请';
    case AppLanguage.mongolian: return 'Үндсэн захиалгаас 1 долоо хоногийн дотор';
    default: return '본주문 완료 후 1주일 이내까지 가능합니다';
  }}

  String get orderGuideAdditionalOption { switch (language) {
    case AppLanguage.english: return 'Applied Options';
    case AppLanguage.japanese: return '適用オプション';
    case AppLanguage.chinese: return '应用选项';
    case AppLanguage.mongolian: return 'Хэрэглэгдсэн сонголт';
    default: return '적용 옵션';
  }}

  String get orderGuideAdditionalOptionDesc { switch (language) {
    case AppLanguage.english: return 'Same color & design as original order';
    case AppLanguage.japanese: return '既存注文と同じカラー・デザイン';
    case AppLanguage.chinese: return '与原订单相同颜色和设计';
    case AppLanguage.mongolian: return 'Анхны захиалгатай ижил өнгө, дизайн';
    default: return '기존 주문과 동일한 컬러·디자인으로 제작됩니다';
  }}

  String get groupOrderGuideTabOrder { switch (language) {
    case AppLanguage.english: return 'Order Guide';
    case AppLanguage.japanese: return '注文案内';
    case AppLanguage.chinese: return '订购指南';
    case AppLanguage.mongolian: return 'Захиалгын удирдамж';
    default: return '주문 안내';
  }}

  String get groupOrderBenefit1 { switch (language) {
    case AppLanguage.english: return 'Team color + name print';
    case AppLanguage.japanese: return 'チームカラー+団体名印刷';
    case AppLanguage.chinese: return '团队颜色+名称印刷';
    case AppLanguage.mongolian: return 'Багийн өнгө + нэр хэвлэх';
    default: return '팀 컬러 + 단체명 인쇄';
  }}

  String get groupOrderBenefit2 { switch (language) {
    case AppLanguage.english: return 'Name + number print';
    case AppLanguage.japanese: return '名前+番号追加印刷';
    case AppLanguage.chinese: return '姓名+号码额外印刷';
    case AppLanguage.mongolian: return 'Нэр + дугаар нэмж хэвлэх';
    default: return '이름 + 번호 추가 인쇄';
  }}

  String get groupOrderBenefit3 { switch (language) {
    case AppLanguage.english: return '10% group discount';
    case AppLanguage.japanese: return '10%団体割引';
    case AppLanguage.chinese: return '10%团体折扣';
    case AppLanguage.mongolian: return '10% бүлгийн хөнгөлөлт';
    default: return '10% 단체 할인';
  }}

  String get groupOrderBenefit4 { switch (language) {
    case AppLanguage.english: return '20% group discount';
    case AppLanguage.japanese: return '20%団体割引';
    case AppLanguage.chinese: return '20%团体折扣';
    case AppLanguage.mongolian: return '20% бүлгийн хөнгөлөлт';
    default: return '20% 단체 할인';
  }}

  String get groupOrderMinQtyTitle { switch (language) {
    case AppLanguage.english: return 'Minimum Quantity';
    case AppLanguage.japanese: return '最低数量';
    case AppLanguage.chinese: return '最低数量';
    case AppLanguage.mongolian: return 'Хамгийн бага тоо';
    default: return '최소 수량';
  }}

  String get groupOrderCustomOptionTitle { switch (language) {
    case AppLanguage.english: return 'Custom Options';
    case AppLanguage.japanese: return 'カスタムオプション';
    case AppLanguage.chinese: return '自定义选项';
    case AppLanguage.mongolian: return 'Тохиргооны сонголт';
    default: return '커스텀 옵션';
  }}

  String get groupOrderPrintTypeTitle { switch (language) {
    case AppLanguage.english: return 'Print Types';
    case AppLanguage.japanese: return '印刷タイプ';
    case AppLanguage.chinese: return '印刷类型';
    case AppLanguage.mongolian: return 'Хэвлэлийн төрөл';
    default: return '인쇄 타입';
  }}

  String get groupOrderExclusiveTitle { switch (language) {
    case AppLanguage.english: return 'Design Exclusive Use (optional)';
    case AppLanguage.japanese: return 'デザイン独占使用オプション';
    case AppLanguage.chinese: return '设计独家使用选项(可选)';
    case AppLanguage.mongolian: return 'Дизайны онцгой эрхийн сонголт';
    default: return '디자인 독점 사용 옵션 (선택)';
  }}

  String get groupOrderSizeGuideTitle { switch (language) {
    case AppLanguage.english: return 'Size Guide';
    case AppLanguage.japanese: return 'サイズ案内';
    case AppLanguage.chinese: return '尺码指南';
    case AppLanguage.mongolian: return 'Хэмжээний удирдамж';
    default: return '사이즈 안내';
  }}

  String get groupOrderOnlySub { switch (language) {
    case AppLanguage.english: return '5+ people · group discount · custom available';
    case AppLanguage.japanese: return '5名以上・団体割引・カスタム可能';
    case AppLanguage.chinese: return '5人以上·团体折扣·可定制';
    case AppLanguage.mongolian: return '5+ хүн · бүлгийн хөнгөлөлт · захиалгаар';
    default: return '5명 이상 · 단체할인 적용 · 커스텀 제작 가능';
  }}

  String get groupOrderNoProduct { switch (language) {
    case AppLanguage.english: return 'No products registered.\nPlease register a product first.';
    case AppLanguage.japanese: return '商品が登録されていません。\n商品登録タブで登録してください。';
    case AppLanguage.chinese: return '暂无注册商品。\n请先在商品注册选项卡注册。';
    case AppLanguage.mongolian: return 'Бараа бүртгэгдээгүй байна.\nЭхлэж бараа бүртгэнэ үү.';
    default: return '등록된 상품이 없습니다.\n상품 등록 탭에서 먼저 상품을 등록하세요.';
  }}

  String get groupOrderGroupName { switch (language) {
    case AppLanguage.english: return 'Group Name *';
    case AppLanguage.japanese: return '団体名 *';
    case AppLanguage.chinese: return '团体名称 *';
    case AppLanguage.mongolian: return 'Бүлгийн нэр *';
    default: return '단체명 *';
  }}

  String get groupOrderGroupNameHint { switch (language) {
    case AppLanguage.english: return 'e.g. 2024 Marathon Club';
    case AppLanguage.japanese: return '例：2024マラソンクラブ';
    case AppLanguage.chinese: return '例：2024马拉松俱乐部';
    case AppLanguage.mongolian: return 'Жнь: 2024 Марафон клуб';
    default: return '예) 2024 마라톤 클럽';
  }}

  String get groupOrderContact { switch (language) {
    case AppLanguage.english: return 'Contact Person *';
    case AppLanguage.japanese: return '担当者連絡先 *';
    case AppLanguage.chinese: return '负责人联系方式 *';
    case AppLanguage.mongolian: return 'Холбоо барих хүн *';
    default: return '담당자 연락처 *';
  }}

  String get groupOrderMinCount { switch (language) {
    case AppLanguage.english: return 'Quantity * (min. 5)';
    case AppLanguage.japanese: return '注文数量 * (最小5名)';
    case AppLanguage.chinese: return '订购数量 * (最少5人)';
    case AppLanguage.mongolian: return 'Тоо * (хамгийн багадаа 5)';
    default: return '주문 수량 * (최소 5명)';
  }}

  String get groupOrderAddress { switch (language) {
    case AppLanguage.english: return 'Delivery Address *';
    case AppLanguage.japanese: return '配送住所 *';
    case AppLanguage.chinese: return '收货地址 *';
    case AppLanguage.mongolian: return 'Хүргэлтийн хаяг *';
    default: return '배송 주소 *';
  }}

  String get groupOrderRequest { switch (language) {
    case AppLanguage.english: return 'Requests';
    case AppLanguage.japanese: return 'ご要望';
    case AppLanguage.chinese: return '备注';
    case AppLanguage.mongolian: return 'Хүсэлт';
    default: return '요청사항';
  }}

  String get groupOrderRequestHint { switch (language) {
    case AppLanguage.english: return 'Logo position, color changes, etc.';
    case AppLanguage.japanese: return 'ロゴ位置、色変更などのカスタム要望';
    case AppLanguage.chinese: return '标志位置、颜色更改等自定义要求';
    case AppLanguage.mongolian: return 'Лого байршил, өнгө өөрчлөх гэх мэт';
    default: return '로고 위치, 색상 변경 등 커스텀 요청사항';
  }}

  String get groupOrderGroupNameRequired { switch (language) {
    case AppLanguage.english: return 'Please enter group name.';
    case AppLanguage.japanese: return '団体名を入力してください。';
    case AppLanguage.chinese: return '请输入团体名称。';
    case AppLanguage.mongolian: return 'Бүлгийн нэр оруулна уу.';
    default: return '단체명을 입력해주세요.';
  }}

  String get groupOrderContactRequired { switch (language) {
    case AppLanguage.english: return 'Please enter contact info.';
    case AppLanguage.japanese: return '担当者連絡先を入力してください。';
    case AppLanguage.chinese: return '请输入负责人联系方式。';
    case AppLanguage.mongolian: return 'Холбоо барих мэдээлэл оруулна уу.';
    default: return '담당자 연락처를 입력해주세요.';
  }}

  String get genderMale { switch (language) {
    case AppLanguage.english: return 'Male';
    case AppLanguage.japanese: return '男';
    case AppLanguage.chinese: return '男';
    case AppLanguage.mongolian: return 'Эрэгтэй';
    default: return '남';
  }}

  String get genderFemale { switch (language) {
    case AppLanguage.english: return 'Female';
    case AppLanguage.japanese: return '女';
    case AppLanguage.chinese: return '女';
    case AppLanguage.mongolian: return 'Эмэгтэй';
    default: return '여';
  }}

  String get groupFormPeopleLabel { switch (language) {
    case AppLanguage.english: return 'People';
    case AppLanguage.japanese: return '人員';
    case AppLanguage.chinese: return '人员';
    case AppLanguage.mongolian: return 'Хүний тоо';
    default: return '인원';
  }}

  String get groupFormPersonUnit2 { switch (language) {
    case AppLanguage.english: return 'ppl';
    case AppLanguage.japanese: return '名';
    case AppLanguage.chinese: return '人';
    case AppLanguage.mongolian: return 'хүн';
    default: return '명';
  }}

  String get groupFormUnitPrice { switch (language) {
    case AppLanguage.english: return 'Unit Price';
    case AppLanguage.japanese: return '商品単価';
    case AppLanguage.chinese: return '商品单价';
    case AppLanguage.mongolian: return '단위 үнэ';
    default: return '상품 단가';
  }}

  String get groupFormWaistbandExtra { switch (language) {
    case AppLanguage.english: return 'Waistband Extra';
    case AppLanguage.japanese: return 'ウエストバンド追加';
    case AppLanguage.chinese: return '腰带附加';
    case AppLanguage.mongolian: return 'Бүсний нэмэлт';
    default: return '허리밴드 추가';
  }}

  String get groupFormFabricExtra { switch (language) {
    case AppLanguage.english: return 'Fabric Extra';
    case AppLanguage.japanese: return '生地追加';
    case AppLanguage.chinese: return '面料附加';
    case AppLanguage.mongolian: return 'Даавуу нэмэлт';
    default: return '원단 추가';
  }}

  String get groupFormItemTotal { switch (language) {
    case AppLanguage.english: return 'Item Total';
    case AppLanguage.japanese: return '商品合計';
    case AppLanguage.chinese: return '商品总计';
    case AppLanguage.mongolian: return 'Барааны нийт';
    default: return '상품 합계';
  }}

  String get groupFormDiscountWithRate { switch (language) {
    case AppLanguage.english: return 'Discount';
    case AppLanguage.japanese: return '割引';
    case AppLanguage.chinese: return '折扣';
    case AppLanguage.mongolian: return 'Хөнгөлөлт';
    default: return '할인';
  }}

  String get groupFormShippingLabel { switch (language) {
    case AppLanguage.english: return 'Shipping';
    case AppLanguage.japanese: return '送料';
    case AppLanguage.chinese: return '运费';
    case AppLanguage.mongolian: return 'Хүргэлтийн зардал';
    default: return '배송비';
  }}

  String get groupFormShippingFree { switch (language) {
    case AppLanguage.english: return 'Free';
    case AppLanguage.japanese: return '無料';
    case AppLanguage.chinese: return '免费';
    case AppLanguage.mongolian: return 'Үнэгүй';
    default: return '무료';
  }}

  String get groupFormCheckOrder { switch (language) {
    case AppLanguage.english: return 'Review Order';
    case AppLanguage.japanese: return '注文書確認';
    case AppLanguage.chinese: return '确认订单';
    case AppLanguage.mongolian: return 'Захиалга шалгах';
    default: return '주문서 확인하기';
  }}

  String get groupFormCheckAdditional { switch (language) {
    case AppLanguage.english: return 'Review Additional Order';
    case AppLanguage.japanese: return '追加製作注文確認';
    case AppLanguage.chinese: return '确认追加订单';
    case AppLanguage.mongolian: return 'Нэмэлт захиалга шалгах';
    default: return '추가제작 주문 확인하기';
  }}

  String get groupFormNeedQty { switch (language) {
    case AppLanguage.english: return 'Enter quantity first';
    case AppLanguage.japanese: return '数量入力後確認可能';
    case AppLanguage.chinese: return '填写数量后可确认';
    case AppLanguage.mongolian: return 'Тоо оруулсны дараа';
    default: return '수량 입력 후 확인 가능';
  }}

  String get groupFormNeedMin5 { switch (language) {
    case AppLanguage.english: return 'Min. 5 people required';
    case AppLanguage.japanese: return '最低5名以上入力必要';
    case AppLanguage.chinese: return '需要至少5人';
    case AppLanguage.mongolian: return 'Хамгийн багадаа 5 хүн';
    default: return '최소 5인 이상 입력 필요';
  }}

  String get groupFormAdditionalOrder { switch (language) {
    case AppLanguage.english: return 'Additional Production Order';
    case AppLanguage.japanese: return '追加製作注文書';
    case AppLanguage.chinese: return '追加生产订单';
    case AppLanguage.mongolian: return 'Нэмэлт үйлдвэрлэлийн захиалга';
    default: return '추가제작 주문서';
  }}

  String get groupFormGroupOrder { switch (language) {
    case AppLanguage.english: return 'Group Custom Order';
    case AppLanguage.japanese: return '団体カスタム注文';
    case AppLanguage.chinese: return '团体定制订单';
    case AppLanguage.mongolian: return 'Бүлгийн захиалга';
    default: return '단체 맞춤 주문';
  }}

  String get groupFormAdditionalPeriod { switch (language) {
    case AppLanguage.english: return 'Additional: From 1pc | Within 1 week';
    case AppLanguage.japanese: return '追加製作：1枚から全オプション選択可能 | 本注文1週間以内';
    case AppLanguage.chinese: return '追加生产：从1件起所有选项可选 | 主订单1周内';
    case AppLanguage.mongolian: return 'Нэмэлт: 1-ээс | 1 долоо хоногийн дотор';
    default: return '추가제작: 1장부터 모든 옵션 선택 가능 | 본주문 1주일 이내';
  }}

  String get groupFormPeriod { switch (language) {
    case AppLanguage.english: return 'Production: 14-21 days | Min 5';
    case AppLanguage.japanese: return '製作期間：14〜21日 | 最低5名';
    case AppLanguage.chinese: return '生产周期：14~21天 | 最少5人';
    case AppLanguage.mongolian: return 'Үйлдвэрлэл: 14-21 өдөр | Хамгийн багадаа 5';
    default: return '제작 기간: 14~21일 | 최소 5인';
  }}

  String get groupFormAutoConfirmNote { switch (language) {
    case AppLanguage.english: return 'Design auto-confirmed after 3 days per revision without request.';
    case AppLanguage.japanese: return '修正1回につき3日以内に修正要求がなければデザインが自動確定され製作が開始されます。';
    case AppLanguage.chinese: return '每次修改3天内无修改请求则设计自动确认开始生产。';
    case AppLanguage.mongolian: return 'Нэг засвар тутамд 3 хоногийн дотор засвар хүсэлт ирэхгүй бол дизайн автоматаар баталгаажиж үйлдвэрлэл эхэлнэ.';
    default: return '디자인 수정은 1회당 3일 이내 수정 요청이 없으면 자동 확정되어 제작이 시작됩니다.';
  }}

  String get groupFormActualMeasure { switch (language) {
    case AppLanguage.english: return 'Actual Measurement';
    case AppLanguage.japanese: return '実測可能';
    case AppLanguage.chinese: return '可实测';
    case AppLanguage.mongolian: return 'Бодит хэмжилт боломжтой';
    default: return '실측 가능';
  }}

  String get groupFormActualActive { switch (language) {
    case AppLanguage.english: return 'Activate Measurement';
    case AppLanguage.japanese: return '実測活性化';
    case AppLanguage.chinese: return '激活实测';
    case AppLanguage.mongolian: return 'Хэмжилт идэвхжүүлэх';
    default: return '실측 활성화';
  }}

  String get personalFormBuyNow { switch (language) {
    case AppLanguage.english: return 'Buy Now';
    case AppLanguage.japanese: return '今すぐ購入';
    case AppLanguage.chinese: return '立即购买';
    case AppLanguage.mongolian: return 'Яг одоо авах';
    default: return '바로 구매';
  }}

  String get personalFormOrderTitle { switch (language) {
    case AppLanguage.english: return 'Personal Custom Order';
    case AppLanguage.japanese: return '個人カスタム注文';
    case AppLanguage.chinese: return '个人定制订单';
    case AppLanguage.mongolian: return 'Хувийн захиалга';
    default: return '개인 맞춤 주문';
  }}

  String get personalFormPeriod { switch (language) {
    case AppLanguage.english: return 'Production: 14-21 days | Free ship over ₩300K';
    case AppLanguage.japanese: return '製作期間：14〜21日 | 30万ウォン↑送料無料';
    case AppLanguage.chinese: return '生产周期：14~21天 | 满30万韩元免运费';
    case AppLanguage.mongolian: return 'Үйлдвэрлэл: 14-21 өдөр | 300K↑ үнэгүй';
    default: return '제작 기간: 14~21일 | 300,000원↑ 무료배송';
  }}

  String get personalFormAdditionalTitle { switch (language) {
    case AppLanguage.english: return 'Additional Order';
    case AppLanguage.japanese: return '既存注文追加注文';
    case AppLanguage.chinese: return '原订单追加订单';
    case AppLanguage.mongolian: return 'Нэмэлт захиалга';
    default: return '기존 주문 추가 주문';
  }}

  String get personalFormAdditionalDeadline { switch (language) {
    case AppLanguage.english: return 'Within 1 week of original order';
    case AppLanguage.japanese: return '原本注文後1週間以内';
    case AppLanguage.chinese: return '原订单后1周内';
    case AppLanguage.mongolian: return '1 долоо хоногийн дотор';
    default: return '원본 주문 후 1주일 이내';
  }}

  String get personalFormOriginalOrderSection { switch (language) {
    case AppLanguage.english: return '📋 Original Order Info';
    case AppLanguage.japanese: return '📋 元注文情報';
    case AppLanguage.chinese: return '📋 原始订单信息';
    case AppLanguage.mongolian: return '📋 Анхны захиалгын мэдээлэл';
    default: return '📋 원본 주문 정보';
  }}

  String get personalFormOriginalOrderNum { switch (language) {
    case AppLanguage.english: return 'Original Order Number';
    case AppLanguage.japanese: return '原本注文番号';
    case AppLanguage.chinese: return '原始订单号';
    case AppLanguage.mongolian: return 'Анхны захиалгын дугаар';
    default: return '원본 주문번호';
  }}

  String get personalFormOriginalOrderHint { switch (language) {
    case AppLanguage.english: return 'e.g. ORD-2024-001234';
    case AppLanguage.japanese: return '例：ORD-2024-001234';
    case AppLanguage.chinese: return '例：ORD-2024-001234';
    case AppLanguage.mongolian: return 'Жнь: ORD-2024-001234';
    default: return '예: ORD-2024-001234';
  }}

  String get personalFormAdditionalNote { switch (language) {
    case AppLanguage.english: return '⚠️ Additional orders only within 1 week.';
    case AppLanguage.japanese: return '⚠️ 元注文後1週間以内のみ追加注文可能です。';
    case AppLanguage.chinese: return '⚠️ 仅在原订单后1周内可追加订单。';
    case AppLanguage.mongolian: return '⚠️ Нэмэлт захиалга зөвхөн 1 долоо хоногийн дотор.';
    default: return '⚠️ 원본 주문 후 1주일 이내에만 추가 주문이 가능합니다.';
  }}

  String get personalFormDesignSection { switch (language) {
    case AppLanguage.english: return '🖼️ Design Reference';
    case AppLanguage.japanese: return '🖼️ デザインリファレンス';
    case AppLanguage.chinese: return '🖼️ 设计参考';
    case AppLanguage.mongolian: return '🖼️ Дизайны лавлагаа';
    default: return '🖼️ 디자인 레퍼런스';
  }}

  String get personalFormDesignNote { switch (language) {
    case AppLanguage.english: return 'Attach reference images or design files.';
    case AppLanguage.japanese: return '参考画像やデザインファイルがあれば添付してください。';
    case AppLanguage.chinese: return '请附上参考图片或设计文件。';
    case AppLanguage.mongolian: return 'Лавлах зурган эсвэл дизайн файл байвал хавсаргана уу.';
    default: return '참고 이미지나 디자인 파일이 있으면 첨부해주세요.';
  }}

  String get personalFormDesignUrlHint { switch (language) {
    case AppLanguage.english: return 'Add design reference URL or description';
    case AppLanguage.japanese: return 'デザインリファレンスURLまたは説明追加';
    case AppLanguage.chinese: return '添加设计参考URL或说明';
    case AppLanguage.mongolian: return 'Дизайны URL эсвэл тайлбар нэмэх';
    default: return '디자인 레퍼런스 URL 또는 설명 추가';
  }}

  String get personalFormKakaoNote { switch (language) {
    case AppLanguage.english: return '* Send files via KakaoTalk(@2fitkorea) after order.';
    case AppLanguage.japanese: return '* ファイルは注文完了後KakaoTalk(@2fitkorea)で送ってください。';
    case AppLanguage.chinese: return '* 文件请在订单完成后通过KakaoTalk(@2fitkorea)发送。';
    case AppLanguage.mongolian: return '* Файлыг захиалга дууссаны дараа KakaoTalk(@2fitkorea)-р илгээнэ үү.';
    default: return '* 파일은 주문 완료 후 카카오톡(@2fitkorea)으로 전송해 주세요.';
  }}

  String get personalFormDesignDialogTitle { switch (language) {
    case AppLanguage.english: return 'Design Reference';
    case AppLanguage.japanese: return 'デザインリファレンス';
    case AppLanguage.chinese: return '设计参考';
    case AppLanguage.mongolian: return 'Дизайны лавлагаа';
    default: return '디자인 레퍼런스';
  }}

  String get personalFormCancelBtn { switch (language) {
    case AppLanguage.english: return 'Cancel';
    case AppLanguage.japanese: return 'キャンセル';
    case AppLanguage.chinese: return '取消';
    case AppLanguage.mongolian: return 'Цуцлах';
    default: return '취소';
  }}

  String get personalFormSaveBtn { switch (language) {
    case AppLanguage.english: return 'Save';
    case AppLanguage.japanese: return '保存';
    case AppLanguage.chinese: return '保存';
    case AppLanguage.mongolian: return 'Хадгалах';
    default: return '저장';
  }}

  String get personalOrderGuidePrintOpt { switch (language) {
    case AppLanguage.english: return 'Name/Logo Print';
    case AppLanguage.japanese: return '名前/ロゴ印刷';
    case AppLanguage.chinese: return '姓名/标志印刷';
    case AppLanguage.mongolian: return 'Нэр/Лого хэвлэх';
    default: return '이름/로고 인쇄';
  }}

  String get personalOrderGuidePrintOptSub { switch (language) {
    case AppLanguage.english: return 'Personal custom print';
    case AppLanguage.japanese: return '個人カスタム印刷';
    case AppLanguage.chinese: return '个人定制印刷';
    case AppLanguage.mongolian: return 'Хувийн захиалгаар хэвлэх';
    default: return '개인 맞춤 인쇄';
  }}

  String get personalOrderGuideFreeShipLabel { switch (language) {
    case AppLanguage.english: return 'Free Shipping';
    case AppLanguage.japanese: return '送料無料';
    case AppLanguage.chinese: return '免运费';
    case AppLanguage.mongolian: return 'Үнэгүй хүргэлт';
    default: return '무료배송';
  }}

  String get personalOrderGuideAgreement { switch (language) {
    case AppLanguage.english: return 'I have read all order guide information';
    case AppLanguage.japanese: return '注文案内を全て確認しました';
    case AppLanguage.chinese: return '我已阅读所有订购指南';
    case AppLanguage.mongolian: return 'Захиалгын мэдээллийг бүгдийг уншлаа';
    default: return '주문 안내 내용을 모두 확인하였습니다';
  }}

  String get personalOrderGuideWriteBtn { switch (language) {
    case AppLanguage.english: return 'Fill Personal Order Form';
    case AppLanguage.japanese: return '個人注文書を作成する';
    case AppLanguage.chinese: return '填写个人订单';
    case AppLanguage.mongolian: return 'Хувийн захиалга бөглөх';
    default: return '개인 주문서 작성하기';
  }}

  String get personalOrderGuideCheckFirst { switch (language) {
    case AppLanguage.english: return 'Check the guide before filling order form';
    case AppLanguage.japanese: return '案内確認チェック後に注文書を作成できます';
    case AppLanguage.chinese: return '请先查看指南再填写订单';
    case AppLanguage.mongolian: return 'Гарын авлага шалгасны дараа захиалга бөглөнэ';
    default: return '안내를 확인 체크 후 주문서 작성이 가능합니다';
  }}

  String get personalOrderGuideFrom1Person { switch (language) {
    case AppLanguage.english: return 'Available for 1 person';
    case AppLanguage.japanese: return '1人でも可能';
    case AppLanguage.chinese: return '1人也可订购';
    case AppLanguage.mongolian: return '1 хүн ч захиалж болно';
    default: return '1인도 가능';
  }}

  String get personalOrderSelectedProduct { switch (language) {
    case AppLanguage.english: return 'Selected: ';
    case AppLanguage.japanese: return '選択：';
    case AppLanguage.chinese: return '已选：';
    case AppLanguage.mongolian: return 'Сонгосон: ';
    default: return '선택: ';
  }}

  String get personalOrderCustomTitle { switch (language) {
    case AppLanguage.english: return 'Color Change Only';
    case AppLanguage.japanese: return 'カラーのみ変更';
    case AppLanguage.chinese: return '仅改颜色';
    case AppLanguage.mongolian: return 'Зөвхөн өнгө';
    default: return '컬러만 변경';
  }}

  String get personalOrderCustom2Title { switch (language) {
    case AppLanguage.english: return 'Front Name + Color';
    case AppLanguage.japanese: return '前面団体名+カラー';
    case AppLanguage.chinese: return '前面团体名+颜色';
    case AppLanguage.mongolian: return 'Урд нэр + өнгө';
    default: return '앞면 단체명 + 컬러';
  }}

  String get personalOrderCustom3Title { switch (language) {
    case AppLanguage.english: return 'Name + Color + Individual';
    case AppLanguage.japanese: return '団体名+カラー+名前';
    case AppLanguage.chinese: return '团体名+颜色+姓名';
    case AppLanguage.mongolian: return 'Нэр + өнгө + хувь нэмэр';
    default: return '단체명 + 컬러 + 이름';
  }}

  String get personalOrderCustom3Price { switch (language) {
    case AppLanguage.english: return '+₩100,000';
    case AppLanguage.japanese: return '+¥100,000';
    case AppLanguage.chinese: return '+¥100,000';
    case AppLanguage.mongolian: return '+₩100,000';
    default: return '+100,000원';
  }}

  String get personalOrderCustom3Desc { switch (language) {
    case AppLanguage.english: return 'Front + back name print (all custom)';
    case AppLanguage.japanese: return '前面+背面名前印刷（全カスタム）';
    case AppLanguage.chinese: return '正面+背面姓名印刷（全部定制）';
    case AppLanguage.mongolian: return 'Урд + ар нэр хэвлэх';
    default: return '앞면 + 뒷면 이름 인쇄 (모든 커스텀)';
  }}

  String get personalOrderWaistTitle { switch (language) {
    case AppLanguage.english: return 'Waistband Color Change';
    case AppLanguage.japanese: return 'ウエストバンドカラー変更';
    case AppLanguage.chinese: return '腰带颜色更改';
    case AppLanguage.mongolian: return 'Бүс өнгийг солих';
    default: return '허리밴드 컬러 변경';
  }}

  String get personalOrderWaistPrice { switch (language) {
    case AppLanguage.english: return '+₩60,000';
    case AppLanguage.japanese: return '+¥60,000';
    case AppLanguage.chinese: return '+¥60,000';
    case AppLanguage.mongolian: return '+₩60,000';
    default: return '+60,000원';
  }}

  String get personalOrderWaistDesc { switch (language) {
    case AppLanguage.english: return 'Waistband color change ⚠️ No design change';
    case AppLanguage.japanese: return 'ウエストバンドカラー変更 ⚠️ デザイン変更不可';
    case AppLanguage.chinese: return '腰带颜色更改 ⚠️ 不可更改设计';
    case AppLanguage.mongolian: return 'Бүсний өнгө ⚠️ Дизайн өөрчлөхгүй';
    default: return '허리밴드 색상 변경 ⚠️ 디자인 변경 불가';
  }}

  String get personalOrderPriceTitle { switch (language) {
    case AppLanguage.english: return '💰 Option Prices';
    case AppLanguage.japanese: return '💰 オプション別価格';
    case AppLanguage.chinese: return '💰 选项价格';
    case AppLanguage.mongolian: return '💰 Сонголтын үнэ';
    default: return '💰 옵션별 가격';
  }}

  String get personalOrderStepTitle { switch (language) {
    case AppLanguage.english: return 'Color Change Only';
    case AppLanguage.japanese: return 'カラーのみ変更';
    case AppLanguage.chinese: return '仅改颜色';
    case AppLanguage.mongolian: return 'Зөвхөн өнгө';
    default: return '컬러만 변경';
  }}

  String get personalOrderStep2Title { switch (language) {
    case AppLanguage.english: return 'Front Name + Color';
    case AppLanguage.japanese: return '前面団体名+カラー変更';
    case AppLanguage.chinese: return '前面团体名+颜色更改';
    case AppLanguage.mongolian: return 'Урд нэр + өнгө';
    default: return '앞면 단체명 + 컬러 변경';
  }}

  String get personalOrderStep3Title { switch (language) {
    case AppLanguage.english: return 'Front + Back Name Print';
    case AppLanguage.japanese: return '前面+背面名前印刷';
    case AppLanguage.chinese: return '正面+背面姓名印刷';
    case AppLanguage.mongolian: return 'Урд + ар нэр хэвлэх';
    default: return '앞면 + 뒷면 이름 인쇄';
  }}

  String get personalOrderPrintTypeTitle { switch (language) {
    case AppLanguage.english: return '🖨️ Select Print Type';
    case AppLanguage.japanese: return '🖨️ 印刷タイプ選択';
    case AppLanguage.chinese: return '🖨️ 选择印刷类型';
    case AppLanguage.mongolian: return '🖨️ Хэвлэлийн төрөл';
    default: return '🖨️ 인쇄 타입 선택';
  }}

  String get personalOrderPolicyTitle { switch (language) {
    case AppLanguage.english: return '📋 Production & Shipping Policy';
    case AppLanguage.japanese: return '📋 製作・配送ポリシー';
    case AppLanguage.chinese: return '📋 生产与配送政策';
    case AppLanguage.mongolian: return '📋 Үйлдвэрлэл & Хүргэлтийн бодлого';
    default: return '📋 제작 & 배송 정책';
  }}

  String get chatOriginalLabel { switch (language) {
    case AppLanguage.english: return '[Korean]';
    case AppLanguage.japanese: return '[韓国語]';
    case AppLanguage.chinese: return '[韩语]';
    case AppLanguage.mongolian: return '[Солонгос]';
    default: return '[한국어]';
  }}

  String get chatShowOriginal { switch (language) {
    case AppLanguage.english: return 'View Translation';
    case AppLanguage.japanese: return '翻訳を見る';
    case AppLanguage.chinese: return '查看翻译';
    case AppLanguage.mongolian: return 'Орчуулга үзэх';
    default: return '번역 보기';
  }}

  String get chatAutoReplyMsg { switch (language) {
    case AppLanguage.english: return 'Thank you! Our staff will respond shortly. 😊\n\nHours: Weekdays 10:00-18:00 (Lunch 12:00-14:00)\nSupport: ';
    case AppLanguage.japanese: return 'お問い合わせありがとうございます！担当者が確認後すぐに回答いたします。😊\n\n営業時間：平日10:00-18:00（昼休み12:00-14:00）\nお問い合わせ：';
    case AppLanguage.chinese: return '感谢您的咨询！工作人员确认后将尽快回复。😊\n\n营业时间：工作日10:00-18:00（午休12:00-14:00）\n客服：';
    case AppLanguage.mongolian: return 'Асуулга тавьсанд баярлалаа! Ажилтан шалгаад хурдан хариулна. 😊\n\nЦаг: Ажлын өдөр 10:00-18:00\nУтас: ';
    default: return '문의 감사합니다! 담당자가 확인 후 빠르게 답변 드리겠습니다. 😊\n\n운영시간: 평일 10:00-18:00 (점심 12:00-14:00)\n고객센터: ';
  }}

  String get chatOfflineMsg { switch (language) {
    case AppLanguage.english: return 'Hours: Weekdays 10:00-18:00 (Lunch 12:00-14:00)\nSupport: ';
    case AppLanguage.japanese: return '営業時間：平日10:00-18:00（昼休み12:00-14:00）\nお問い合わせ：';
    case AppLanguage.chinese: return '营业时间：工作日10:00-18:00（午休12:00-14:00）\n客服：';
    case AppLanguage.mongolian: return 'Цаг: Ажлын өдөр 10:00-18:00\nУтас: ';
    default: return '운영시간: 평일 10:00-18:00 (점심 12:00-14:00)\n고객센터: ';
  }}

  String get wonUnit2 { return '원'; }

  String get cartFreeShipNone { switch (language) {
    case AppLanguage.english: return 'Free';
    case AppLanguage.japanese: return '無料';
    case AppLanguage.chinese: return '免费';
    case AppLanguage.mongolian: return 'Үнэгүй';
    default: return '무료';
  }}

  String get productCountUnit { switch (language) {
    case AppLanguage.english: return ' products';
    case AppLanguage.japanese: return '商品';
    case AppLanguage.chinese: return '件商品';
    case AppLanguage.mongolian: return 'бараа';
    default: return '개 상품';
  }}

  String get sortRatingLabel { switch (language) {
    case AppLanguage.english: return 'Rating';
    case AppLanguage.japanese: return '評価順';
    case AppLanguage.chinese: return '评分';
    case AppLanguage.mongolian: return 'Үнэлгээ';
    default: return '평점순';
  }}

  String get groupOrderOnlySubmit { switch (language) {
    case AppLanguage.english: return 'Submit Group Order';
    case AppLanguage.japanese: return '団体注文を申し込む';
    case AppLanguage.chinese: return '提交团体订单';
    case AppLanguage.mongolian: return 'Бүлгийн захиалга илгээх';
    default: return '단체주문 신청하기';
  }}

  String get groupOrderOnlyComplete { switch (language) {
    case AppLanguage.english: return 'Group Order Complete!';
    case AppLanguage.japanese: return '団体注文申し込み完了!';
    case AppLanguage.chinese: return '团体订单申请完成！';
    case AppLanguage.mongolian: return 'Бүлгийн захиалга дууслаа!';
    default: return '단체주문 신청 완료!';
  }}

  String get groupOrderOnlyAddMore { switch (language) {
    case AppLanguage.english: return 'Add More Orders';
    case AppLanguage.japanese: return '追加注文する';
    case AppLanguage.chinese: return '继续下单';
    case AppLanguage.mongolian: return 'Нэмж захиалах';
    default: return '추가 주문하기';
  }}

  String get groupOrderProductDescription { switch (language) {
    case AppLanguage.english: return 'Registered products can be selected in the group order tab.';
    case AppLanguage.japanese: return '登録商品は団体注文タブから選択できます。';
    case AppLanguage.chinese: return '已注册商品可在团体订单选项卡中选择。';
    case AppLanguage.mongolian: return 'Бүртгэсэн бараа бүлгийн захиалгын таб дотор сонгоно.';
    default: return '등록된 상품은 단체주문 탭에서 바로 선택할 수 있습니다.';
  }}

  String get groupOrderBasicInfo { switch (language) {
    case AppLanguage.english: return 'Basic Info';
    case AppLanguage.japanese: return '基本情報';
    case AppLanguage.chinese: return '基本信息';
    case AppLanguage.mongolian: return 'Үндсэн мэдээлэл';
    default: return '기본 정보';
  }}

  String get groupOrderSubCategory { switch (language) {
    case AppLanguage.english: return 'Sub Category';
    case AppLanguage.japanese: return 'サブカテゴリー';
    case AppLanguage.chinese: return '子类目';
    case AppLanguage.mongolian: return 'Дэд ангилал';
    default: return '세부 카테고리';
  }}

  String get groupOrderSubCategoryHint { switch (language) {
    case AppLanguage.english: return 'e.g. Singlet Set Unisex';
    case AppLanguage.japanese: return '例：シングレットセット男女兼用';
    case AppLanguage.chinese: return '例：连体衣套装男女通用';
    case AppLanguage.mongolian: return 'Жнь: Шинглет сет';
    default: return '예) 싱글렛세트 남녀공용';
  }}

  String get groupOrderSizeRequired { switch (language) {
    case AppLanguage.english: return 'Enter at least 1 size.';
    case AppLanguage.japanese: return 'サイズを1つ以上入力してください。';
    case AppLanguage.chinese: return '请输入至少1个尺码。';
    case AppLanguage.mongolian: return 'Хамгийн багадаа 1 хэмжээ оруулна уу.';
    default: return '사이즈를 1개 이상 입력하세요.';
  }}

  String get groupOrderColorRequired { switch (language) {
    case AppLanguage.english: return 'Enter at least 1 color.';
    case AppLanguage.japanese: return '色を1つ以上入力してください。';
    case AppLanguage.chinese: return '请输入至少1种颜色。';
    case AppLanguage.mongolian: return 'Хамгийн багадаа 1 өнгө оруулна уу.';
    default: return '색상을 1개 이상 입력하세요.';
  }}

  String get chatShowTranslation { switch (language) {
    case AppLanguage.english: return 'View Translation';
    case AppLanguage.japanese: return '翻訳を見る';
    case AppLanguage.chinese: return '查看翻译';
    case AppLanguage.mongolian: return 'Орчуулга үзэх';
    default: return '번역 보기';
  }}

  String get chatKoreanLabel { switch (language) {
    case AppLanguage.english: return '[Korean]';
    case AppLanguage.japanese: return '[韓国語]';
    case AppLanguage.chinese: return '[韩语]';
    case AppLanguage.mongolian: return '[Солонгос]';
    default: return '[한국어]';
  }}

  // ── 알림 센터 ──
  String get notifCenterTitle { switch (language) {
    case AppLanguage.english: return 'Notifications';
    case AppLanguage.japanese: return '通知';
    case AppLanguage.chinese: return '通知';
    case AppLanguage.mongolian: return 'Мэдэгдэл';
    default: return '알림';
  }}

  String get minuteAgo { switch (language) {
    case AppLanguage.english: return ' min ago';
    case AppLanguage.japanese: return '分前';
    case AppLanguage.chinese: return '分钟前';
    case AppLanguage.mongolian: return ' мин өмнө';
    default: return '분 전';
  }}

  String get hourAgo { switch (language) {
    case AppLanguage.english: return ' hr ago';
    case AppLanguage.japanese: return '時間前';
    case AppLanguage.chinese: return '小时前';
    case AppLanguage.mongolian: return ' цаг өмнө';
    default: return '시간 전';
  }}

  String get dayAgo { switch (language) {
    case AppLanguage.english: return ' day(s) ago';
    case AppLanguage.japanese: return '日前';
    case AppLanguage.chinese: return '天前';
    case AppLanguage.mongolian: return ' өдрийн өмнө';
    default: return '일 전';
  }}

  // ── 상품 카드 ──
  String get freeBadge { switch (language) {
    case AppLanguage.english: return 'FREE';
    case AppLanguage.japanese: return '無料配送';
    case AppLanguage.chinese: return '免运费';
    case AppLanguage.mongolian: return 'ҮНЭГҮЙ';
    default: return '무료배송';
  }}

  String get productWonUnit { return '원'; }


  // ── group_order_form summary row 레이블 ──
  String get groupFormLabelProduct { switch (language) {
    case AppLanguage.english: return 'Product';
    case AppLanguage.japanese: return '商品';
    case AppLanguage.chinese: return '商品';
    case AppLanguage.mongolian: return 'Бүтээгдэхүүн';
    default: return '상품';
  }}

  String get groupFormLabelBasePrice { switch (language) {
    case AppLanguage.english: return 'Base Price';
    case AppLanguage.japanese: return '基本価格';
    case AppLanguage.chinese: return '基本价格';
    case AppLanguage.mongolian: return 'Үндсэн үнэ';
    default: return '기본 가격';
  }}

  String get groupFormLabelBottomLength { switch (language) {
    case AppLanguage.english: return 'Bottom Length';
    case AppLanguage.japanese: return '下衣基本丈';
    case AppLanguage.chinese: return '下装基本长度';
    case AppLanguage.mongolian: return 'Доод хувцасны урт';
    default: return '하의 기본 길이';
  }}

  String get groupFormLabelFabricWeight { switch (language) {
    case AppLanguage.english: return 'Fabric Weight';
    case AppLanguage.japanese: return '生地重量';
    case AppLanguage.chinese: return '面料克重';
    case AppLanguage.mongolian: return 'Даавууны жин';
    default: return '원단 무게';
  }}

  String get groupFormLabelColor { switch (language) {
    case AppLanguage.english: return 'Color';
    case AppLanguage.japanese: return 'カラー';
    case AppLanguage.chinese: return '颜色';
    case AppLanguage.mongolian: return 'Өнгө';
    default: return '색상';
  }}

  String get groupFormLabelGroupDiscount { switch (language) {
    case AppLanguage.english: return 'Group Discount';
    case AppLanguage.japanese: return '団体割引';
    case AppLanguage.chinese: return '团体折扣';
    case AppLanguage.mongolian: return 'Бүлгийн хөнгөлөлт';
    default: return '단체 할인';
  }}

  String get groupFormLabelTotalPayment { switch (language) {
    case AppLanguage.english: return 'Total Payment';
    case AppLanguage.japanese: return '合計決済金額';
    case AppLanguage.chinese: return '总付款金额';
    case AppLanguage.mongolian: return 'Нийт төлбөр';
    default: return '총 결제 금액';
  }}

  // ── dialog row 레이블 ──
  String get groupFormDialogTeamName { switch (language) {
    case AppLanguage.english: return 'Team Name';
    case AppLanguage.japanese: return '団体名';
    case AppLanguage.chinese: return '团体名称';
    case AppLanguage.mongolian: return 'Багийн нэр';
    default: return '단체명';
  }}

  String get groupFormDialogHeadcount { switch (language) {
    case AppLanguage.english: return 'Headcount';
    case AppLanguage.japanese: return '人員';
    case AppLanguage.chinese: return '人数';
    case AppLanguage.mongolian: return 'Хүн тоо';
    default: return '인원';
  }}

  String get groupFormDialogGender { switch (language) {
    case AppLanguage.english: return 'Gender';
    case AppLanguage.japanese: return '性別';
    case AppLanguage.chinese: return '性别';
    case AppLanguage.mongolian: return 'Хүйс';
    default: return '성별';
  }}

  String get groupFormDialogMainColor { switch (language) {
    case AppLanguage.english: return 'Main Color';
    case AppLanguage.japanese: return 'メインカラー';
    case AppLanguage.chinese: return '主色调';
    case AppLanguage.mongolian: return 'Үндсэн өнгө';
    default: return '메인 컬러';
  }}

  String get groupFormDialogBottomColor { switch (language) {
    case AppLanguage.english: return 'Bottom Color';
    case AppLanguage.japanese: return '下衣カラー';
    case AppLanguage.chinese: return '下装颜色';
    case AppLanguage.mongolian: return 'Доод хувцасны өнгө';
    default: return '하의 컬러';
  }}

  String get groupFormDialogFabric { switch (language) {
    case AppLanguage.english: return 'Fabric';
    case AppLanguage.japanese: return '素材';
    case AppLanguage.chinese: return '面料';
    case AppLanguage.mongolian: return 'Даавуу';
    default: return '소재';
  }}

  String get groupFormDialogWeight { switch (language) {
    case AppLanguage.english: return 'Weight';
    case AppLanguage.japanese: return '重量';
    case AppLanguage.chinese: return '克重';
    case AppLanguage.mongolian: return 'Жин';
    default: return '무게';
  }}

  String get groupFormDialogWaistband { switch (language) {
    case AppLanguage.english: return 'Waistband Change';
    case AppLanguage.japanese: return 'ウエストバンド変更';
    case AppLanguage.chinese: return '腰带变更';
    case AppLanguage.mongolian: return 'Бүс солих';
    default: return '허리밴드 변경';
  }}

  String get groupFormDialogDelivery { switch (language) {
    case AppLanguage.english: return 'Delivery Address';
    case AppLanguage.japanese: return '配送先';
    case AppLanguage.chinese: return '配送地址';
    case AppLanguage.mongolian: return 'Хүргэлтийн хаяг';
    default: return '배송지';
  }}

  String get groupFormWaistbandName { switch (language) {
    case AppLanguage.english: return 'Team Name';
    case AppLanguage.japanese: return '団体名';
    case AppLanguage.chinese: return '团体名';
    case AppLanguage.mongolian: return 'Багийн нэр';
    default: return '단체명';
  }}

  String get groupFormWaistbandColor { switch (language) {
    case AppLanguage.english: return 'Color';
    case AppLanguage.japanese: return '色';
    case AppLanguage.chinese: return '颜色';
    case AppLanguage.mongolian: return 'Өнгө';
    default: return '색상';
  }}

  String get groupFormWaistbandNameColor { switch (language) {
    case AppLanguage.english: return 'Name+Color';
    case AppLanguage.japanese: return '団体名+色';
    case AppLanguage.chinese: return '团体名+颜色';
    case AppLanguage.mongolian: return 'Нэр+Өнгө';
    default: return '단체명+색상';
  }}

  String get groupFormColorTop { switch (language) {
    case AppLanguage.english: return 'Top';
    case AppLanguage.japanese: return '上衣';
    case AppLanguage.chinese: return '上装';
    case AppLanguage.mongolian: return 'Дээд хувцас';
    default: return '상의';
  }}

  String get groupFormColorBottom { switch (language) {
    case AppLanguage.english: return 'Bottom';
    case AppLanguage.japanese: return '下衣';
    case AppLanguage.chinese: return '下装';
    case AppLanguage.mongolian: return 'Доод хувцас';
    default: return '하의';
  }}

  String get groupFormMale { switch (language) {
    case AppLanguage.english: return 'M';
    case AppLanguage.japanese: return '男';
    case AppLanguage.chinese: return '男';
    case AppLanguage.mongolian: return 'Эр';
    default: return '남';
  }}

  String get groupFormFemale { switch (language) {
    case AppLanguage.english: return 'F';
    case AppLanguage.japanese: return '女';
    case AppLanguage.chinese: return '女';
    case AppLanguage.mongolian: return 'Эм';
    default: return '여';
  }}

  String get groupFormPersons { switch (language) {
    case AppLanguage.english: return ' people';
    case AppLanguage.japanese: return '人';
    case AppLanguage.chinese: return '人';
    case AppLanguage.mongolian: return ' хүн';
    default: return '명';
  }}

  // ── personal order form 추가 키 ──
  String get personalFormProductNameLabel { switch (language) {
    case AppLanguage.english: return 'Product Name *';
    case AppLanguage.japanese: return '商品名 *';
    case AppLanguage.chinese: return '商品名称 *';
    case AppLanguage.mongolian: return 'Барааны нэр *';
    default: return '상품명 *';
  }}

  String get personalFormOriginalOrderNo { switch (language) {
    case AppLanguage.english: return 'Original Order No.';
    case AppLanguage.japanese: return '元注文番号';
    case AppLanguage.chinese: return '原始订单号';
    case AppLanguage.mongolian: return 'Анхны захиалгын дугаар';
    default: return '원본 주문번호';
  }}

  String get personalFormOriginalOrderRequired { switch (language) {
    case AppLanguage.english: return 'Please enter original order number';
    case AppLanguage.japanese: return '元注文番号を入力してください';
    case AppLanguage.chinese: return '请输入原始订单号';
    case AppLanguage.mongolian: return 'Анхны захиалгын дугаарыг оруулна уу';
    default: return '원본 주문번호를 입력해주세요';
  }}

  // ── cart 추가 키 ──
  String get checkoutTossPayMethod { switch (language) {
    case AppLanguage.english: return 'TossPay';
    case AppLanguage.japanese: return 'トスペイ';
    case AppLanguage.chinese: return 'TossPay';
    case AppLanguage.mongolian: return 'TossPay';
    default: return '토스페이';
  }}

  String get cartProductAmount { switch (language) {
    case AppLanguage.english: return 'Product Amount';
    case AppLanguage.japanese: return '商品金額';
    case AppLanguage.chinese: return '商品金额';
    case AppLanguage.mongolian: return 'Барааны дүн';
    default: return '상품금액';
  }}

  String get cartPayAmount { switch (language) {
    case AppLanguage.english: return 'Total Payment';
    case AppLanguage.japanese: return '決済金額';
    case AppLanguage.chinese: return '结算金额';
    case AppLanguage.mongolian: return 'Нийт төлбөр';
    default: return '결제금액';
  }}

  String get cartShippingInfoRequired { switch (language) {
    case AppLanguage.english: return 'Please fill in all shipping information';
    case AppLanguage.japanese: return '配送情報を全て入力してください';
    case AppLanguage.chinese: return '请填写所有配送信息';
    case AppLanguage.mongolian: return 'Хүргэлтийн мэдээллийг бүрэн оруулна уу';
    default: return '배송 정보를 모두 입력해주세요';
  }}

  String get homeEvent { switch (language) {
    case AppLanguage.english: return 'Events';
    case AppLanguage.japanese: return 'イベント';
    case AppLanguage.chinese: return '活动';
    case AppLanguage.mongolian: return 'Арга хэмжээ';
    default: return '이벤트';
  }}

  // ── mypage 추가 키 ──
  String get mypageSizeChartTitle { switch (language) {
    case AppLanguage.english: return 'Size Chart';
    case AppLanguage.japanese: return 'サイズ表';
    case AppLanguage.chinese: return '尺码表';
    case AppLanguage.mongolian: return 'Хэмжээний хүснэгт';
    default: return '사이즈 조건표';
  }}

  String get mypageSizeAgeLabel { switch (language) {
    case AppLanguage.english: return 'Age';
    case AppLanguage.japanese: return '年齢';
    case AppLanguage.chinese: return '年龄';
    case AppLanguage.mongolian: return 'Нас';
    default: return '나이';
  }}

  String get mypageShippingLabelField { switch (language) {
    case AppLanguage.english: return 'Address Label';
    case AppLanguage.japanese: return '配送先名';
    case AppLanguage.chinese: return '收货地址名称';
    case AppLanguage.mongolian: return 'Хүргэлтийн хаягийн нэр';
    default: return '배송지명';
  }}

  String get mypageShippingLabelHint { switch (language) {
    case AppLanguage.english: return 'Home, Office, Other';
    case AppLanguage.japanese: return '自宅、会社など';
    case AppLanguage.chinese: return '家、公司等';
    case AppLanguage.mongolian: return 'Гэр, Ажил, Бусад';
    default: return '집, 회사, 기타';
  }}

  // ── cart/checkout 추가 키 ──
  String get cartFreeShip { switch (language) {
    case AppLanguage.english: return 'Free';
    case AppLanguage.japanese: return '無料';
    case AppLanguage.chinese: return '免费';
    case AppLanguage.mongolian: return 'Үнэгүй';
    default: return '무료';
  }}

  String get mypageOrderId { switch (language) {
    case AppLanguage.english: return 'Order No.';
    case AppLanguage.japanese: return '注文番号';
    case AppLanguage.chinese: return '订单号';
    case AppLanguage.mongolian: return 'Захиалгын дугаар';
    default: return '주문번호';
  }}

  String get mypagePointsEarned { switch (language) {
    case AppLanguage.english: return 'points earned!';
    case AppLanguage.japanese: return 'ポイントが積立されました！';
    case AppLanguage.chinese: return '积分已累积！';
    case AppLanguage.mongolian: return 'оноо цуглуулагдлаа!';
    default: return '포인트가 적립되었습니다!';
  }}

  String get checkoutPaymentPending { switch (language) {
    case AppLanguage.english: return 'Awaiting Payment';
    case AppLanguage.japanese: return '入金待ち';
    case AppLanguage.chinese: return '待付款';
    case AppLanguage.mongolian: return 'Төлбөр хүлээгдэж байна';
    default: return '입금대기';
  }}


  String get personalFormWaistbandDesign { switch (language) {
    case AppLanguage.english: return 'Waistband Design Change';
    case AppLanguage.japanese: return 'ウエストバンドデザイン変更';
    case AppLanguage.chinese: return '腰带设计变更';
    case AppLanguage.mongolian: return 'Бүсний дизайн өөрчлөх';
    default: return '허리밴드 디자인 변경';
  }}

  String get personalFormMaterialChange { switch (language) {
    case AppLanguage.english: return 'Material/Width/Design Change';
    case AppLanguage.japanese: return '素材・幅・デザイン変更';
    case AppLanguage.chinese: return '材料/宽度/设计变更';
    case AppLanguage.mongolian: return 'Материал/Өргөн/Дизайн өөрчлөх';
    default: return '소재·폭·디자인 변경';
  }}

  String get personalFormTop { switch (language) {
    case AppLanguage.english: return 'Top';
    case AppLanguage.japanese: return 'トップス';
    case AppLanguage.chinese: return '上衣';
    case AppLanguage.mongolian: return 'Дээд хэсэг';
    default: return '상의';
  }}

  String get personalFormBottom { switch (language) {
    case AppLanguage.english: return 'Bottom';
    case AppLanguage.japanese: return 'ボトムス';
    case AppLanguage.chinese: return '下装';
    case AppLanguage.mongolian: return 'Доод хэсэг';
    default: return '하의';
  }}

  String get personalFormQuantity { switch (language) {
    case AppLanguage.english: return 'Quantity';
    case AppLanguage.japanese: return '数量';
    case AppLanguage.chinese: return '数量';
    case AppLanguage.mongolian: return 'Тоо хэмжээ';
    default: return '수량';
  }}

  String get personalFormDeliveryAddress { switch (language) {
    case AppLanguage.english: return 'Delivery Address';
    case AppLanguage.japanese: return '配送先住所';
    case AppLanguage.chinese: return '配送地址';
    case AppLanguage.mongolian: return 'Хүргэлтийн хаяг';
    default: return '배송 주소';
  }}

  String get personalFormAddressHint { switch (language) {
    case AppLanguage.english: return 'Search address to enter';
    case AppLanguage.japanese: return '住所検索から入力してください';
    case AppLanguage.chinese: return '请搜索地址并输入';
    case AppLanguage.mongolian: return 'Хаяг хайлтаас оруулна уу';
    default: return '주소 검색을 눌러 주소를 입력하세요';
  }}

  String get personalFormAddressSearch { switch (language) {
    case AppLanguage.english: return 'Search Address';
    case AppLanguage.japanese: return '住所検索';
    case AppLanguage.chinese: return '地址搜索';
    case AppLanguage.mongolian: return 'Хаяг хайх';
    default: return '주소 검색';
  }}

  String get personalFormDetailAddress { switch (language) {
    case AppLanguage.english: return 'Detail Address (apartment/unit)';
    case AppLanguage.japanese: return '詳細住所（番地/号）';
    case AppLanguage.chinese: return '详细地址（单元/门牌号）';
    case AppLanguage.mongolian: return 'Дэлгэрэнгүй хаяг (байр/тоот)';
    default: return '상세 주소 입력 (동/호수 등)';
  }}

  String get personalFormSelectProductFirst { switch (language) {
    case AppLanguage.english: return 'Please select a product first';
    case AppLanguage.japanese: return '先に商品を選択してください';
    case AppLanguage.chinese: return '请先选择商品';
    case AppLanguage.mongolian: return 'Эхлэн бараа сонгоно уу';
    default: return '상품을 먼저 선택해주세요';
  }}

  String get personalFormSelectColorFirst { switch (language) {
    case AppLanguage.english: return 'Please select a main color';
    case AppLanguage.japanese: return 'メインカラーを選択してください';
    case AppLanguage.chinese: return '请选择主色调';
    case AppLanguage.mongolian: return 'Үндсэн өнгийг сонгоно уу';
    default: return '메인 컬러를 선택해주세요';
  }}

  String get personalFormAddedToCart { switch (language) {
    case AppLanguage.english: return 'Added to cart';
    case AppLanguage.japanese: return 'カートに追加されました';
    case AppLanguage.chinese: return '已添加到购物车';
    case AppLanguage.mongolian: return 'Сагсанд нэмэгдлээ';
    default: return '장바구니에 담겼습니다';
  }}

  String get personalFormEnterName { switch (language) {
    case AppLanguage.english: return 'Please enter your name';
    case AppLanguage.japanese: return 'お名前を入力してください';
    case AppLanguage.chinese: return '请输入姓名';
    case AppLanguage.mongolian: return 'Нэрээ оруулна уу';
    default: return '주문자명을 입력해주세요';
  }}

  String get personalFormEnterPhone { switch (language) {
    case AppLanguage.english: return 'Please enter your phone number';
    case AppLanguage.japanese: return '連絡先を入力してください';
    case AppLanguage.chinese: return '请输入联系电话';
    case AppLanguage.mongolian: return 'Утасны дугаараа оруулна уу';
    default: return '연락처를 입력해주세요';
  }}

  String get personalFormEnterOriginalOrder { switch (language) {
    case AppLanguage.english: return 'Please enter original order number';
    case AppLanguage.japanese: return '元の注文番号を入力してください';
    case AppLanguage.chinese: return '请输入原始订单号';
    case AppLanguage.mongolian: return 'Анхны захиалгын дугаарыг оруулна уу';
    default: return '원본 주문번호를 입력해주세요';
  }}

  String get personalFormSubmitComplete { switch (language) {
    case AppLanguage.english: return 'Order Submitted 🎉';
    case AppLanguage.japanese: return '注文書提出完了 🎉';
    case AppLanguage.chinese: return '订单提交完成 🎉';
    case AppLanguage.mongolian: return 'Захиалга илгээгдлээ 🎉';
    default: return '주문서 제출 완료 🎉';
  }}

  String personalFormSubmitMsg(String name) { switch (language) {
    case AppLanguage.english: return '\$name\'s order has been received.';
    case AppLanguage.japanese: return '\$name 様のご注文を承りました。';
    case AppLanguage.chinese: return '\$name 的订单已收到。';
    case AppLanguage.mongolian: return '\$name-ийн захиалга хүлээн авлаа.';
    default: return '\$name 님의 주문서가 접수되었습니다.';
  }}

  String get personalFormAddressSearchTitle { switch (language) {
    case AppLanguage.english: return 'Search Delivery Address';
    case AppLanguage.japanese: return '配送先住所検索';
    case AppLanguage.chinese: return '搜索配送地址';
    case AppLanguage.mongolian: return 'Хүргэлтийн хаяг хайх';
    default: return '배송지 주소 검색';
  }}

  String get personalFormAddressInputHint { switch (language) {
    case AppLanguage.english: return 'Search by road name, lot number, or building name';
    case AppLanguage.japanese: return '道路名、地番、建物名で検索';
    case AppLanguage.chinese: return '按道路名称、地号或建筑名称搜索';
    case AppLanguage.mongolian: return 'Гудамжны нэр, тоот эсвэл барилгын нэрээр хайх';
    default: return '도로명, 지번, 건물명으로 검색';
  }}

  String get personalFormSearchNoAddress { switch (language) {
    case AppLanguage.english: return 'No search results';
    case AppLanguage.japanese: return '検索結果がありません';
    case AppLanguage.chinese: return '没有搜索结果';
    case AppLanguage.mongolian: return 'Хайлтын үр дүн байхгүй';
    default: return '검색 결과가 없습니다';
  }}

  String get personalFormSearchAddress { switch (language) {
    case AppLanguage.english: return 'Please search for an address';
    case AppLanguage.japanese: return '住所を検索してください';
    case AppLanguage.chinese: return '请搜索地址';
    case AppLanguage.mongolian: return 'Хаяг хайна уу';
    default: return '주소를 검색해주세요';
  }}



  String mypageSelectedColor(String color) { switch (language) {
    case AppLanguage.english: return 'Selected color: $color';
    case AppLanguage.japanese: return '選択された色: $color';
    case AppLanguage.chinese: return '选中颜色: $color';
    case AppLanguage.mongolian: return 'Сонгосон өнгө: $color';
    default: return '선택된 색상: $color';
  }}

  String mypageEditCount(int remaining) { switch (language) {
    case AppLanguage.english: return '$remaining of 2 edits remaining';
    case AppLanguage.japanese: return '全2回中$remaining回残り';
    case AppLanguage.chinese: return '共2次中剩余$remaining次';
    case AppLanguage.mongolian: return '2-оос $remaining удаа үлдлээ';
    default: return '총 2회 중 $remaining회 남음';
  }}

  String mypageSelectedColorLabel(String colorName) { switch (language) {
    case AppLanguage.english: return 'Selected color: $colorName';
    case AppLanguage.japanese: return '選択カラー: $colorName';
    case AppLanguage.chinese: return '选择颜色: $colorName';
    case AppLanguage.mongolian: return 'Сонгосон өнгө: $colorName';
    default: return '선택 컬러: $colorName';
  }}

  String mypageRemainingEdits(int remaining) { switch (language) {
    case AppLanguage.english: return 'Remaining edits: $remaining';
    case AppLanguage.japanese: return '残り修正回数: $remaining回';
    case AppLanguage.chinese: return '剩余修改次数: $remaining次';
    case AppLanguage.mongolian: return 'Үлдсэн засварын тоо: $remaining';
    default: return '남은 수정 횟수: $remaining회';
  }}

  String get mypageChangeIfNeeded { switch (language) {
    case AppLanguage.english: return 'Enter only if change is needed';
    case AppLanguage.japanese: return '変更が必要な場合のみ入力';
    case AppLanguage.chinese: return '仅在需要更改时填写';
    case AppLanguage.mongolian: return 'Зөвхөн өөрчлөлт шаардлагатай бол оруулна уу';
    default: return '변경이 필요한 경우에만 입력';
  }}

  String get mypageOtherRequest { switch (language) {
    case AppLanguage.english: return 'Enter other requests';
    case AppLanguage.japanese: return 'その他のご要望を入力してください';
    case AppLanguage.chinese: return '请输入其他要求';
    case AppLanguage.mongolian: return 'Бусад хүсэлтийг оруулна уу';
    default: return '기타 요청사항을 입력해주세요';
  }}

  String get mypageColorCodeChart { switch (language) {
    case AppLanguage.english: return 'Rib Fabric Color Code Chart';
    case AppLanguage.japanese: return 'リブ生地カラーコード表';
    case AppLanguage.chinese: return '罗纹面料颜色代码表';
    case AppLanguage.mongolian: return 'Рибб даавуун өнгөний кодын хүснэгт';
    default: return '골지 원단 컬러 코드표';
  }}

  String get mypageColorNote { switch (language) {
    case AppLanguage.english: return '* Actual fabric color may differ from screen color.';
    case AppLanguage.japanese: return '* 実際の生地の色と画面の色は異なる場合があります。';
    case AppLanguage.chinese: return '* 实际面料颜色可能与屏幕颜色不同。';
    case AppLanguage.mongolian: return '* Бодит даавуу болон дэлгэцийн өнгө ялгаатай байж болно.';
    default: return '* 실제 원단 색상과 화면 색상은 다를 수 있습니다.';
  }}

  String get mypageStandardFit { switch (language) {
    case AppLanguage.english: return '(Standard body type reference)';
    case AppLanguage.japanese: return '（標準体型基準）';
    case AppLanguage.chinese: return '（标准体型参考）';
    case AppLanguage.mongolian: return '(Стандарт биеийн хэмжээний лавлагаа)';
    default: return '(스탠다드 체형 기준)';
  }}

  String get mypageFitNote { switch (language) {
    case AppLanguage.english: return '※ May not exactly match individual body types.';
    case AppLanguage.japanese: return '※ 個人の体型によって正確に一致しない場合があります。';
    case AppLanguage.chinese: return '※ 可能因个人体型而有所不同。';
    case AppLanguage.mongolian: return '※ Хүний биеийн хэмжээнээс хамааран яг таарахгүй байж болно.';
    default: return '※ 개인 체형에 따라 정확히 일치하지 않을 수 있습니다.';
  }}



  String get mypageDefault { switch (language) {
    case AppLanguage.english: return 'Default';
    case AppLanguage.japanese: return 'デフォルト';
    case AppLanguage.chinese: return '默认';
    case AppLanguage.mongolian: return 'Үндсэн';
    default: return '기본';
  }}

  String get mypageSetDefault { switch (language) {
    case AppLanguage.english: return 'Set as Default';
    case AppLanguage.japanese: return 'デフォルトに設定';
    case AppLanguage.chinese: return '设为默认';
    case AppLanguage.mongolian: return 'Үндсэн болгох';
    default: return '기본 배송지 설정';
  }}

  String get mypageAddNewAddress { switch (language) {
    case AppLanguage.english: return 'Add New Address';
    case AppLanguage.japanese: return '新しい配送先を追加';
    case AppLanguage.chinese: return '添加新地址';
    case AppLanguage.mongolian: return 'Шинэ хаяг нэмэх';
    default: return '새 배송지 추가';
  }}

  String get mypageEnterAddress { switch (language) {
    case AppLanguage.english: return 'Please enter an address';
    case AppLanguage.japanese: return '住所を入力してください';
    case AppLanguage.chinese: return '请输入地址';
    case AppLanguage.mongolian: return 'Хаяг оруулна уу';
    default: return '주소를 입력해주세요';
  }}

  String get mypageEnterRecipient { switch (language) {
    case AppLanguage.english: return 'Please enter recipient name';
    case AppLanguage.japanese: return '受取人名を入力してください';
    case AppLanguage.chinese: return '请输入收件人姓名';
    case AppLanguage.mongolian: return 'Хүлээн авагчийн нэрийг оруулна уу';
    default: return '수령인을 입력해주세요';
  }}

  String get mypageAddressAdd { switch (language) {
    case AppLanguage.english: return 'Add Address';
    case AppLanguage.japanese: return '配送先追加';
    case AppLanguage.chinese: return '添加地址';
    case AppLanguage.mongolian: return 'Хаяг нэмэх';
    default: return '배송지 추가';
  }}

  String get mypageAddressEdit { switch (language) {
    case AppLanguage.english: return 'Edit Address';
    case AppLanguage.japanese: return '配送先修正';
    case AppLanguage.chinese: return '编辑地址';
    case AppLanguage.mongolian: return 'Хаяг засах';
    default: return '배송지 수정';
  }}

  String get mypageAddressSearch { switch (language) {
    case AppLanguage.english: return 'Search Address';
    case AppLanguage.japanese: return '住所検索';
    case AppLanguage.chinese: return '地址搜索';
    case AppLanguage.mongolian: return 'Хаяг хайх';
    default: return '주소 검색';
  }}

  String get mypageSetDefaultAddress { switch (language) {
    case AppLanguage.english: return 'Set as Default Address';
    case AppLanguage.japanese: return 'デフォルト配送先に設定';
    case AppLanguage.chinese: return '设为默认地址';
    case AppLanguage.mongolian: return 'Үндсэн хүргэлтийн хаяг болгох';
    default: return '기본 배송지로 설정';
  }}

  String get mypageAddressComplete { switch (language) {
    case AppLanguage.english: return 'Edit Complete';
    case AppLanguage.japanese: return '修正完了';
    case AppLanguage.chinese: return '修改完成';
    case AppLanguage.mongolian: return 'Засвар дуусгах';
    default: return '수정 완료';
  }}



  String productReviewCountLabel(int count) { switch (language) {
    case AppLanguage.english: return '($count reviews)';
    case AppLanguage.japanese: return '($countレビュー)';
    case AppLanguage.chinese: return '($count条评价)';
    case AppLanguage.mongolian: return '($count үнэлгээ)';
    default: return '($count개 리뷰)';
  }}

  String productPriceWithUnit(String price) { return '$price원'; }

  String get productMaxPrice { return '300,000원+'; }

  String productDiscountLabel(int percent) { switch (language) {
    case AppLanguage.english: return '$percent% OFF';
    case AppLanguage.japanese: return '$percent%OFF';
    case AppLanguage.chinese: return '折扣$percent%';
    case AppLanguage.mongolian: return '$percent% хөнгөлөлт';
    default: return '$percent% 할인';
  }}

  String get productColorExtraNote { switch (language) {
    case AppLanguage.english: return 'K·PP colors included, others +₩20,000';
    case AppLanguage.japanese: return 'K・PP以外 +20,000円';
    case AppLanguage.chinese: return 'K·PP以外颜色 +20,000韩元';
    case AppLanguage.mongolian: return 'K·PP бусад өнгийн нэмэлт +20,000₩';
    default: return 'K·PP 외 +20,000원';
  }}

  String get productColors19 { switch (language) {
    case AppLanguage.english: return '19 colors';
    case AppLanguage.japanese: return '19色';
    case AppLanguage.chinese: return '19种颜色';
    case AppLanguage.mongolian: return '19 өнгө';
    default: return '19가지 색상';
  }}

  String get productKPPFree { switch (language) {
    case AppLanguage.english: return 'K·PP Free';
    case AppLanguage.japanese: return 'K·PP無料';
    case AppLanguage.chinese: return 'K·PP免费';
    case AppLanguage.mongolian: return 'K·PP үнэгүй';
    default: return 'K·PP 무료';
  }}

  String get productColorExtraFull { switch (language) {
    case AppLanguage.english: return '* K(Black), PP(Purple Navy) standard · Other colors +₩20,000';
    case AppLanguage.japanese: return '* K(ブラック)、PP(パープルネイビー)基本色・その他 +20,000円';
    case AppLanguage.chinese: return '* K(黑色)、PP(紫海军蓝)基本色·其他颜色 +20,000韩元';
    case AppLanguage.mongolian: return '* K(Хар), PP(Нил цэнхэр) үндсэн · Бусад өнгө +20,000₩';
    default: return '* K(블랙), PP(퍼플네이비) 기본색상 · 나머지 색상 +20,000원';
  }}

  String get productShorter9 { switch (language) {
    case AppLanguage.english: return '9/10 length';
    case AppLanguage.japanese: return '9分丈';
    case AppLanguage.chinese: return '九分';
    case AppLanguage.mongolian: return '9/10 урт';
    default: return '9부';
  }}

  String get productFabricCompositionNote { switch (language) {
    case AppLanguage.english: return '* Fabric composition by type';
    case AppLanguage.japanese: return '* 生地の種類別成分構成';
    case AppLanguage.chinese: return '* 各面料种类成分说明';
    case AppLanguage.mongolian: return '* Даавууны төрлөөр найрлага';
    default: return '* 원단 종류별 성분 구성';
  }}

  String get productDeliveryTimeNote { switch (language) {
    case AppLanguage.english: return 'Ships within 2-3 days (may vary by stock)';
    case AppLanguage.japanese: return '2〜3日以内発送（在庫により変動あり）';
    case AppLanguage.chinese: return '2-3天内发货（库存情况可能延迟）';
    case AppLanguage.mongolian: return '2-3 хоногт хүргэнэ (нөөцөөс хамааран нэмэгдэж болно)';
    default: return '2~3일 이내 배송 (재고에 따라 기간이 늘어날 수 있음)';
  }}

  String get productLightCool { switch (language) {
    case AppLanguage.english: return 'Light & Cool';
    case AppLanguage.japanese: return '軽くて涼しい';
    case AppLanguage.chinese: return '轻薄透气';
    case AppLanguage.mongolian: return 'Хөнгөн ба сэрүүн';
    default: return '가볍고 시원함';
  }}

  String get productThickFirm { switch (language) {
    case AppLanguage.english: return 'Thick & Firm';
    case AppLanguage.japanese: return '厚みがありしっかり';
    case AppLanguage.chinese: return '厚实挺括';
    case AppLanguage.mongolian: return 'Зузаан ба бат бэх';
    default: return '두툼하고 탄탄함';
  }}

  String get productHexCodeLabel { switch (language) {
    case AppLanguage.english: return '(6-digit HEX code)';
    case AppLanguage.japanese: return '（HEXコード6桁）';
    case AppLanguage.chinese: return '（6位HEX色码）';
    case AppLanguage.mongolian: return '(6 оронтой HEX код)';
    default: return '(HEX 코드 6자리)';
  }}

  String get productUpDown { switch (language) {
    case AppLanguage.english: return '↕';
    case AppLanguage.japanese: return '↕';
    case AppLanguage.chinese: return '↕';
    case AppLanguage.mongolian: return '↕';
    default: return '↕';
  }}

  String productSectionDeleted(String label) { switch (language) {
    case AppLanguage.english: return '$label image deleted';
    case AppLanguage.japanese: return '$label 画像が削除されました';
    case AppLanguage.chinese: return '$label图片已删除';
    case AppLanguage.mongolian: return '$label зураг устгагдлаа';
    default: return '$label 이미지가 삭제되었습니다';
  }}

  String get productAllowedLengthNote { switch (language) {
    case AppLanguage.english: return 'Only certain lengths available for this product';
    case AppLanguage.japanese: return 'この商品は特定の丈のみ選択可能です';
    case AppLanguage.chinese: return '此商品只提供特定长度选择';
    case AppLanguage.mongolian: return 'Энэ бүтээгдэхүүнд зөвхөн тодорхой урт сонгох боломжтой';
    default: return '이 상품은 특정 길이만 선택 가능합니다';
  }}



  String loginProviderLogin(String provider) { switch (language) {
    case AppLanguage.english: return '$provider Login';
    case AppLanguage.japanese: return '$provider ログイン';
    case AppLanguage.chinese: return '$provider 登录';
    case AppLanguage.mongolian: return '$provider нэвтрэх';
    default: return '$provider 로그인';
  }}

  String get loginNameLabel { switch (language) {
    case AppLanguage.english: return 'Name';
    case AppLanguage.japanese: return '名前';
    case AppLanguage.chinese: return '姓名';
    case AppLanguage.mongolian: return 'Нэр';
    default: return '이름';
  }}

  String get loginEmailLabel { switch (language) {
    case AppLanguage.english: return 'Email';
    case AppLanguage.japanese: return 'メール';
    case AppLanguage.chinese: return '邮箱';
    case AppLanguage.mongolian: return 'Имэйл';
    default: return '이메일';
  }}

  String loginContinueWith(String provider) { switch (language) {
    case AppLanguage.english: return 'Continue with $provider';
    case AppLanguage.japanese: return '$provider で続ける';
    case AppLanguage.chinese: return '通过 $provider 继续';
    case AppLanguage.mongolian: return '$provider-ээр үргэлжлүүлэх';
    default: return '$provider로 계속하기';
  }}

  String get loginEmailSent { switch (language) {
    case AppLanguage.english: return 'Email sent';
    case AppLanguage.japanese: return 'メールを送信しました';
    case AppLanguage.chinese: return '邮件已发送';
    case AppLanguage.mongolian: return 'Имэйл илгээгдлээ';
    default: return '이메일을 발송했습니다';
  }}

  String get loginCheckMailbox { switch (language) {
    case AppLanguage.english: return 'Please check your inbox.';
    case AppLanguage.japanese: return 'メールボックスをご確認ください。';
    case AppLanguage.chinese: return '请查看您的邮箱。';
    case AppLanguage.mongolian: return 'Имэйлийн хайрцгаа шалгана уу.';
    default: return '메일함을 확인해주세요.';
  }}

  String get loginForgotDesc { switch (language) {
    case AppLanguage.english: return 'Enter your email address to receive a password reset link.';
    case AppLanguage.japanese: return 'ご登録のメールアドレスを入力してください。パスワードリセットリンクをお送りします。';
    case AppLanguage.chinese: return '请输入您的邮箱地址，我们将发送密码重置链接。';
    case AppLanguage.mongolian: return 'Бүртгэлтэй имэйл хаягаа оруулна уу. Нууц үг солих холбоосыг илгээнэ.';
    default: return '가입하신 이메일 주소를 입력하시면\n비밀번호 재설정 링크를 보내드립니다.';
  }}

  String get loginResetSend { switch (language) {
    case AppLanguage.english: return 'Send Reset Email';
    case AppLanguage.japanese: return 'リセットメール送信';
    case AppLanguage.chinese: return '发送重置邮件';
    case AppLanguage.mongolian: return 'Нууц үг солих имэйл илгээх';
    default: return '재설정 메일 발송';
  }}

  String get loginErrorGeneral { switch (language) {
    case AppLanguage.english: return 'An error occurred.';
    case AppLanguage.japanese: return 'エラーが発生しました。';
    case AppLanguage.chinese: return '发生错误。';
    case AppLanguage.mongolian: return 'Алдаа гарлаа.';
    default: return '오류가 발생했습니다.';
  }}



  String get colorPickerInvalidHex { switch (language) {
    case AppLanguage.english: return 'Please enter a valid HEX code';
    case AppLanguage.japanese: return '正しいHEXコードを入力してください';
    case AppLanguage.chinese: return '请输入有效的HEX色码';
    case AppLanguage.mongolian: return 'Зөв HEX кодыг оруулна уу';
    default: return '올바른 HEX 코드를 입력해주세요';
  }}

  String get colorPickerHexLength { switch (language) {
    case AppLanguage.english: return 'Please enter a 6-digit HEX code';
    case AppLanguage.japanese: return '6桁のHEXコードを入力してください';
    case AppLanguage.chinese: return '请输入6位HEX色码';
    case AppLanguage.mongolian: return '6 оронтой HEX кодыг оруулна уу';
    default: return '6자리 HEX 코드를 입력해주세요';
  }}

  String get colorPickerTitle { switch (language) {
    case AppLanguage.english: return 'Select Color';
    case AppLanguage.japanese: return '色選択';
    case AppLanguage.chinese: return '选择颜色';
    case AppLanguage.mongolian: return 'Өнгө сонгох';
    default: return '색상 선택';
  }}

  String get colorPickerAll { switch (language) {
    case AppLanguage.english: return 'All Colors';
    case AppLanguage.japanese: return '全色';
    case AppLanguage.chinese: return '全部颜色';
    case AppLanguage.mongolian: return 'Бүх өнгө';
    default: return '전체 색상';
  }}

  String get colorPickerTone { switch (language) {
    case AppLanguage.english: return 'Tone Selection';
    case AppLanguage.japanese: return 'トーン選択';
    case AppLanguage.chinese: return '色调选择';
    case AppLanguage.mongolian: return 'Өнгийн тон сонгох';
    default: return '색조 선택';
  }}

  String get colorPickerHexInput { switch (language) {
    case AppLanguage.english: return 'Enter HEX Color Code';
    case AppLanguage.japanese: return 'HEXカラーコード入力';
    case AppLanguage.chinese: return '输入HEX色码';
    case AppLanguage.mongolian: return 'HEX өнгийн код оруулах';
    default: return 'HEX 색상 코드 입력';
  }}

  String get colorPickerHexExample { switch (language) {
    case AppLanguage.english: return 'e.g. #1A1A1A  #FF0090  #ADD8E6';
    case AppLanguage.japanese: return '例: #1A1A1A  #FF0090  #ADD8E6';
    case AppLanguage.chinese: return '例: #1A1A1A  #FF0090  #ADD8E6';
    case AppLanguage.mongolian: return 'Жнь: #1A1A1A  #FF0090  #ADD8E6';
    default: return '예: #1A1A1A  #FF0090  #ADD8E6';
  }}

  String get colorPickerConfirm { switch (language) {
    case AppLanguage.english: return 'Select this color';
    case AppLanguage.japanese: return 'この色で選択';
    case AppLanguage.chinese: return '选择此颜色';
    case AppLanguage.mongolian: return 'Энэ өнгийг сонгох';
    default: return '이 색상으로 선택';
  }}

  String get colorPickerRib19 { switch (language) {
    case AppLanguage.english: return 'Rib 19 Colors';
    case AppLanguage.japanese: return 'リブ19色';
    case AppLanguage.chinese: return '螺纹19色';
    case AppLanguage.mongolian: return 'Rib 19 өнгө';
    default: return '골지 19색';
  }}

  String get colorPickerFullPalette { switch (language) {
    case AppLanguage.english: return 'Full Palette';
    case AppLanguage.japanese: return '全パレット';
    case AppLanguage.chinese: return '全色板';
    case AppLanguage.mongolian: return 'Бүх палитр';
    default: return '전체 팔레트';
  }}

  String get colorPickerHexTab { switch (language) {
    case AppLanguage.english: return 'HEX';
    case AppLanguage.japanese: return 'HEX入力';
    case AppLanguage.chinese: return 'HEX';
    case AppLanguage.mongolian: return 'HEX';
    default: return 'HEX 입력';
  }}

  String get homeShopInfo { switch (language) {
    case AppLanguage.english: return 'Shopping Info';
    case AppLanguage.japanese: return 'ショッピング案内';
    case AppLanguage.chinese: return '购物指南';
    case AppLanguage.mongolian: return 'Дэлгүүрийн мэдээлэл';
    default: return '쇼핑 안내';
  }}

  String get homeOrderService { switch (language) {
    case AppLanguage.english: return 'Order Service';
    case AppLanguage.japanese: return '注文サービス';
    case AppLanguage.chinese: return '订单服务';
    case AppLanguage.mongolian: return 'Захиалгын үйлчилгээ';
    default: return '주문 서비스';
  }}

  String get homeCustomerSupport { switch (language) {
    case AppLanguage.english: return 'Customer Support';
    case AppLanguage.japanese: return 'カスタマーサポート';
    case AppLanguage.chinese: return '客户支持';
    case AppLanguage.mongolian: return 'Харилцагчийн үйлчилгээ';
    default: return '고객 지원';
  }}

  String get homeTermsOfUse { switch (language) {
    case AppLanguage.english: return 'Terms of Use';
    case AppLanguage.japanese: return '利用規約';
    case AppLanguage.chinese: return '使用条款';
    case AppLanguage.mongolian: return 'Үйлчилгээний нөхцөл';
    default: return '이용약관';
  }}

  String get homePrivacyPolicy { switch (language) {
    case AppLanguage.english: return 'Privacy Policy';
    case AppLanguage.japanese: return 'プライバシーポリシー';
    case AppLanguage.chinese: return '隐私政策';
    case AppLanguage.mongolian: return 'Нууцлалын бодлого';
    default: return '개인정보처리방침';
  }}

  String get homePopupDismiss { switch (language) {
    case AppLanguage.english: return 'Don\'t show today';
    case AppLanguage.japanese: return '今日は表示しない';
    case AppLanguage.chinese: return '今天不再显示';
    case AppLanguage.mongolian: return 'Өнөөдөр харуулахгүй';
    default: return '오늘 하루 보지 않기';
  }}

  String get homeCategoryAll { switch (language) {
    case AppLanguage.english: return 'All';
    case AppLanguage.japanese: return '全て';
    case AppLanguage.chinese: return '全部';
    case AppLanguage.mongolian: return 'Бүгд';
    default: return '전체';
  }}

  String get kakaoAddressSearch { switch (language) {
    case AppLanguage.english: return 'Search Address';
    case AppLanguage.japanese: return '住所検索';
    case AppLanguage.chinese: return '搜索地址';
    case AppLanguage.mongolian: return 'Хаяг хайх';
    default: return '주소 검색';
  }}

  String get kakaoAddressRetry { switch (language) {
    case AppLanguage.english: return 'Try again';
    case AppLanguage.japanese: return '再試行';
    case AppLanguage.chinese: return '重试';
    case AppLanguage.mongolian: return 'Дахин оролдох';
    default: return '다시 시도';
  }}

  String get kakaoAddressLoading { switch (language) {
    case AppLanguage.english: return 'Loading address search...';
    case AppLanguage.japanese: return 'カカオ住所検索ロード中...';
    case AppLanguage.chinese: return 'Kakao地址搜索加载中...';
    case AppLanguage.mongolian: return 'Хаяг хайлт ачааллаж байна...';
    default: return '카카오 주소검색 로딩 중...';
  }}

  String get orderGuideNonExchangeable { switch (language) {
    case AppLanguage.english: return '📌 Non-Exchangeable/Non-Refundable Items';
    case AppLanguage.japanese: return '📌 交換/返品不可商品';
    case AppLanguage.chinese: return '📌 不可换货/退货商品';
    case AppLanguage.mongolian: return '📌 Буцаалт/Солилт боломжгүй бараа';
    default: return '📌 교환/환불 불가 상품';
  }}

  String get orderGuideNonExchangeableList { switch (language) {
    case AppLanguage.english: return '• Custom-printed items (name, number, logo)\n• Group order products\n• Hygiene items (underwear)\n• Sale items (unless separately announced)';
    case AppLanguage.japanese: return '• カスタムプリント（名前・番号・ロゴ）商品\n• 団体注文で製作された商品\n• 衛生上着用不可商品（下着類）\n• セール商品（別途告知の場合を除く）';
    case AppLanguage.chinese: return '• 定制印刷（名字、号码、标志）商品\n• 团体订单商品\n• 卫生类商品（内衣等）\n• 促销商品（另有告知除外）';
    case AppLanguage.mongolian: return '• Тусгай хэвлэл (нэр, дугаар, лого) бүтээгдэхүүн\n• Бүлгийн захиалгаар хийсэн бүтээгдэхүүн\n• Эрүүл ахуйн бараа (доод хувцас)\n• Хямдралтай бараа (тусад нь зарласан тохиолдолоос бусад)';
    default: return '• 커스텀 인쇄(이름, 번호, 로고)가 된 상품\n• 단체 주문으로 제작된 상품\n• 위생상 착용 불가 상품 (속옷류)\n• 세일 상품 (별도 고지 시)';
  }}

  String get productListPriceRange { switch (language) {
    case AppLanguage.english: return '500,000+';
    case AppLanguage.japanese: return '50万円以上';
    case AppLanguage.chinese: return '50万以上';
    case AppLanguage.mongolian: return '500,000+';
    default: return '500,000원+';
  }}

  String get productListNoProducts { switch (language) {
    case AppLanguage.english: return 'No products found';
    case AppLanguage.japanese: return '商品がありません';
    case AppLanguage.chinese: return '没有商品';
    case AppLanguage.mongolian: return 'Бараа олдсонгүй';
    default: return '상품이 없습니다';
  }}

  String get customOrderSubmit { switch (language) {
    case AppLanguage.english: return 'Submit Custom Order Inquiry';
    case AppLanguage.japanese: return 'カスタム注文お問い合わせ送信';
    case AppLanguage.chinese: return '提交定制订单咨询';
    case AppLanguage.mongolian: return 'Захиалгын хүсэлт илгээх';
    default: return '커스텀 주문 문의하기';
  }}

  String get customOrderInquiryComplete { switch (language) {
    case AppLanguage.english: return 'Inquiry Received';
    case AppLanguage.japanese: return 'お問い合わせ受付完了';
    case AppLanguage.chinese: return '咨询提交完成';
    case AppLanguage.mongolian: return 'Хүсэлт хүлээн авлаа';
    default: return '문의 접수 완료';
  }}

  String get groupOnlyAddSize { switch (language) {
    case AppLanguage.english: return 'Add size (e.g. XXL)';
    case AppLanguage.japanese: return 'サイズ追加 (例: XXL)';
    case AppLanguage.chinese: return '添加尺码 (例: XXL)';
    case AppLanguage.mongolian: return 'Хэмжээ нэмэх (жнь: XXL)';
    default: return '사이즈 추가 (예: XXL)';
  }}

  String get groupOnlyAdd { switch (language) {
    case AppLanguage.english: return 'Add';
    case AppLanguage.japanese: return '追加';
    case AppLanguage.chinese: return '添加';
    case AppLanguage.mongolian: return 'Нэмэх';
    default: return '추가';
  }}

  String get groupOnlyAddColor { switch (language) {
    case AppLanguage.english: return 'Add color (e.g. Red)';
    case AppLanguage.japanese: return '色追加 (例: レッド)';
    case AppLanguage.chinese: return '添加颜色 (例: 红色)';
    case AppLanguage.mongolian: return 'Өнгө нэмэх (жнь: Улаан)';
    default: return '색상 추가 (예: 레드)';
  }}

  String get groupOnlyRegisterProduct { switch (language) {
    case AppLanguage.english: return 'Register Product';
    case AppLanguage.japanese: return '商品登録';
    case AppLanguage.chinese: return '商品注册';
    case AppLanguage.mongolian: return 'Бараа бүртгэх';
    default: return '상품 등록';
  }}

  String checkoutCouponDiscount(String amount) { switch (language) {
    case AppLanguage.english: return '$amount discount';
    case AppLanguage.japanese: return '$amount割引';
    case AppLanguage.chinese: return '$amount优惠';
    case AppLanguage.mongolian: return '$amount хөнгөлөлт';
    default: return '$amount원 할인';
  }}

  String get checkoutShopContinue { switch (language) {
    case AppLanguage.english: return 'Continue Shopping';
    case AppLanguage.japanese: return 'ショッピングを続ける';
    case AppLanguage.chinese: return '继续购物';
    case AppLanguage.mongolian: return 'Дэлгүүр хийлгэж үргэлжлүүлэх';
    default: return '쇼핑 계속하기';
  }}

  String get mainLanguageSelect { switch (language) {
    case AppLanguage.english: return 'Language / Language Selection';
    case AppLanguage.japanese: return '言語 / 言語選択';
    case AppLanguage.chinese: return '语言 / 语言选择';
    case AppLanguage.mongolian: return 'Хэл / Хэл сонгох';
    default: return 'Language / 언어 선택';
  }}

  String get categoryDetailView { switch (language) {
    case AppLanguage.english: return 'View Details';
    case AppLanguage.japanese: return '詳細を見る';
    case AppLanguage.chinese: return '查看详情';
    case AppLanguage.mongolian: return 'Дэлгэрэнгүй харах';
    default: return '상세보기';
  }}

  String get categoryNoProducts { switch (language) {
    case AppLanguage.english: return 'No products';
    case AppLanguage.japanese: return '商品がありません';
    case AppLanguage.chinese: return '没有商品';
    case AppLanguage.mongolian: return 'Бараа байхгүй';
    default: return '상품이 없습니다';
  }}

  String get groupOrderGuidePriceFormat { switch (language) {
    case AppLanguage.english: return '/item';
    case AppLanguage.japanese: return '/点';
    case AppLanguage.chinese: return '/件';
    case AppLanguage.mongolian: return '/ширхэг';
    default: return '/개';
  }}

  // alias: checkoutDetailAddressHint2
  String get checkoutDetailAddressSearch { switch (language) {
    case AppLanguage.english: return 'Search address first';
    case AppLanguage.japanese: return '先に住所を検索してください';
    case AppLanguage.chinese: return '请先搜索地址';
    case AppLanguage.mongolian: return 'Эхлээд хаяг хайна уу';
    default: return '먼저 주소를 검색해주세요';
  }}

  String get section05Desc { switch (language) {
    case AppLanguage.english: return 'Custom color change for waistband, team logo available.\n* Actual colors may vary depending on monitor settings.';
    case AppLanguage.japanese: return 'ウェストバンドのカラー変更、チームロゴ対応可能。\n* 実際の色はモニター環境により異なる場合があります。';
    case AppLanguage.chinese: return '可更改腰带颜色，可添加队伍Logo。\n* 实际颜色可能因显示器设置而有所不同。';
    case AppLanguage.mongolian: return 'Бүсний өнгийг солих, багийн лого оруулах боломжтой.\n* Жинхэнэ өнгө нь монитороос хамааран ялгаатай байж болно.';
    default: return '허리밴드 원단에 맞춰 칼라변경, 팀 로고적용 가능.\n* 실제 색상은 모니터 환경에 따라 다소 차이가 있을 수 있습니다.';
  }}

  // 싱글렛 세트 단계 텍스트
  String sizeColorGenderLabel(String genderLabel, String length) {
    switch (language) {
      case AppLanguage.english: return 'Size / Color  ($genderLabel · Bottom $length)';
      case AppLanguage.japanese: return 'サイズ / カラー  ($genderLabel · 下半身 $length)';
      case AppLanguage.chinese: return '尺码 / 颜色  ($genderLabel · 下装 $length)';
      case AppLanguage.mongolian: return 'Хэмжээ / Өнгө  ($genderLabel · Доод $length)';
      default: return '사이즈 / 컬러  ($genderLabel · 하의 $length)';
    }
  }
  String step2SizeColorLabel(String length) {
    switch (language) {
      case AppLanguage.english: return 'STEP 2 · Size / Color  (Length: $length)';
      case AppLanguage.japanese: return 'STEP 2 · サイズ / カラー  (丈: $length)';
      case AppLanguage.chinese: return 'STEP 2 · 尺码 / 颜色  (长度: $length)';
      case AppLanguage.mongolian: return 'STEP 2 · Хэмжээ / Өнгө  (Урт: $length)';
      default: return 'STEP 2 · 사이즈 / 컬러  (기장: $length)';
    }
  }
  String get readyMadeProductBuy { switch (language) {
    case AppLanguage.english: return 'Ready-made Purchase';
    case AppLanguage.japanese: return '既製品購入';
    case AppLanguage.chinese: return '成衣购买';
    case AppLanguage.mongolian: return 'Бэлэн барааг худалдан авах';
    default: return '기성품 구매';
  }}
  String get mypageEdit { switch (language) {
    case AppLanguage.english: return 'Edit';
    case AppLanguage.japanese: return '編集';
    case AppLanguage.chinese: return '编辑';
    case AppLanguage.mongolian: return 'Засах';
    default: return '수정';
  }}

  // ── 상품 상세페이지 섹션 헤더 ──────────────────────────────
  String get section02Title { switch (language) {
    case AppLanguage.english: return 'Material & Tech';
    case AppLanguage.japanese: return '素材・テクノロジー';
    case AppLanguage.chinese: return '面料与技术';
    case AppLanguage.mongolian: return 'Материал & Технологи';
    default: return '소재 및 기술';
  }}
  String get section02Sub { switch (language) {
    case AppLanguage.english: return 'Special fabric for peak performance';
    case AppLanguage.japanese: return '最高のパフォーマンスのための特殊生地';
    case AppLanguage.chinese: return '为极致性能打造的特殊面料';
    case AppLanguage.mongolian: return 'Хамгийн өндөр гүйцэтгэлийн тусгай даавуу';
    default: return '최고 성능을 위한 특수 원단';
  }}
  String get section03Title { switch (language) {
    case AppLanguage.english: return 'Smart Pocket Design';
    case AppLanguage.japanese: return 'スマートポケット設計';
    case AppLanguage.chinese: return '智能口袋设计';
    case AppLanguage.mongolian: return 'Ухаалаг халтасны дизайн';
    default: return '스마트 포켓 설계';
  }}
  String get section03Sub { switch (language) {
    case AppLanguage.english: return 'Convenient storage system while running';
    case AppLanguage.japanese: return '走りながらでも便利な収納システム';
    case AppLanguage.chinese: return '跑步时也方便的收纳系统';
    case AppLanguage.mongolian: return 'Гүйхдээ тохиромжтой хадгалах систем';
    default: return '달리면서도 편리한 수납 시스템';
  }}
  String get section05Title { switch (language) {
    case AppLanguage.english: return 'Golgi Fabric Color Guide';
    case AppLanguage.japanese: return 'ゴルジ生地カラーガイド';
    case AppLanguage.chinese: return '罗纹面料颜色指南';
    case AppLanguage.mongolian: return 'Голжи даавуу өнгөний заавар';
    default: return '골지 원단 색상 안내';
  }}
  String get section05Sub { switch (language) {
    case AppLanguage.english: return 'Waistband custom color · Team logo available';
    case AppLanguage.japanese: return 'ウェストバンドカスタムカラー・チームロゴ対応可';
    case AppLanguage.chinese: return '腰带定制颜色·可添加队伍Logo';
    case AppLanguage.mongolian: return 'Бүсний өнгийг захиалгаар солих · Багийн лого боломжтой';
    default: return '허리밴드 원단 맞춤 컬러변경 · 팀 로고적용 가능';
  }}

  // 사이즈 차트 설명 텍스트
  String get sizeChartDesc1 { switch (language) {
    case AppLanguage.english: return 'This size chart is based on standard body type.';
    case AppLanguage.japanese: return 'このサイズ表はスタンダード体型に基づいた推奨サイズです。';
    case AppLanguage.chinese: return '本尺码表为标准体型参考尺码。';
    case AppLanguage.mongolian: return 'Энэхүү хэмжээний хүснэгт нь стандарт биеийн байдалд суурилсан болно.';
    default: return '본 사이즈 조건표는 스텐다드 체형 기반 권장 사이즈입니다.';
  }}
  String get sizeChartDesc2 { switch (language) {
    case AppLanguage.english: return 'May vary by individual body type. Different from other brands.';
    case AppLanguage.japanese: return '個人の体型により異なる場合があり、他社サイズとは異なります。';
    case AppLanguage.chinese: return '因个人体型可能有所不同，与其他品牌尺码有差异。';
    case AppLanguage.mongolian: return 'Хувь хүний биеийн байдлаас хамааран өөрчлөгдөж болно. Бусад брэндийн хэмжээнээс ялгаатай.';
    default: return '개인 체형에 따라 상이할 수 있으며, 타사 사이즈와 다를 수 있습니다.';
  }}

  // 성별 선택 (남/여 단축형)
  String get maleShort { switch (language) {
    case AppLanguage.english: return 'M';
    case AppLanguage.japanese: return '男';
    case AppLanguage.chinese: return '男';
    case AppLanguage.mongolian: return 'Эр';
    default: return '남';
  }}
  String get femaleShort { switch (language) {
    case AppLanguage.english: return 'F';
    case AppLanguage.japanese: return '女';
    case AppLanguage.chinese: return '女';
    case AppLanguage.mongolian: return 'Эм';
    default: return '여';
  }}

  // 성별 버튼 서브라벨 (하의 길이)
  String get maleBottomSub { switch (language) {
    case AppLanguage.english: return 'Bottom 5/10';
    case AppLanguage.japanese: return '下半身 5分';
    case AppLanguage.chinese: return '下装 5分';
    case AppLanguage.mongolian: return 'Доод 5/10';
    default: return '하의 5부';
  }}
  String get femaleBottomSub { switch (language) {
    case AppLanguage.english: return 'Bottom 2.5/10';
    case AppLanguage.japanese: return '下半身 2.5分';
    case AppLanguage.chinese: return '下装 2.5分';
    case AppLanguage.mongolian: return 'Доод 2.5/10';
    default: return '하의 2.5부';
  }}
  String get maleBottomFixed { switch (language) {
    case AppLanguage.english: return 'Male · Bottom 5/10 fixed';
    case AppLanguage.japanese: return '男性・下半身 5分固定';
    case AppLanguage.chinese: return '男性・下装 5分固定';
    case AppLanguage.mongolian: return 'Эрэгтэй · Доод 5/10 тогтсон';
    default: return '남성 · 하의 5부 고정';
  }}
  String get femaleBottomFixed { switch (language) {
    case AppLanguage.english: return 'Female · Bottom 2.5/10 fixed';
    case AppLanguage.japanese: return '女性・下半身 2.5分固定';
    case AppLanguage.chinese: return '女性・下装 2.5分固定';
    case AppLanguage.mongolian: return 'Эмэгтэй · Доод 2.5/10 тогтсон';
    default: return '여성 · 하의 2.5부 고정';
  }}

  // 원단 타입 번역
  String get fabricTypeNormal { switch (language) {
    case AppLanguage.english: return 'Standard (Sewn)';
    case AppLanguage.japanese: return 'スタンダード (縫製)';
    case AppLanguage.chinese: return '普通 (缝制)';
    case AppLanguage.mongolian: return 'Энгийн (оёдол)';
    default: return '일반 (봉제)';
  }}
  String get fabricTypeSeamless { switch (language) {
    case AppLanguage.english: return 'Seamless';
    case AppLanguage.japanese: return 'シームレス (無縫製)';
    case AppLanguage.chinese: return '无缝 (无缝合)';
    case AppLanguage.mongolian: return 'Оёдолгүй (seamless)';
    default: return '심리스 (무봉제)';
  }}

  // 포켓 특성 텍스트
  String get pocketFeature1Title { switch (language) {
    case AppLanguage.english: return 'Anti-Drop Structure';
    case AppLanguage.japanese: return '落下防止構造';
    case AppLanguage.chinese: return '防掉落结构';
    case AppLanguage.mongolian: return 'Унахаас хамгаалах бүтэц';
    default: return '낙하 방지 구조';
  }}
  String get pocketFeature2Title { switch (language) {
    case AppLanguage.english: return 'Slim Pocket';
    case AppLanguage.japanese: return 'スリムポケット';
    case AppLanguage.chinese: return '纤薄口袋';
    case AppLanguage.mongolian: return 'Нарийн халтас';
    default: return '슬림 포켓';
  }}
  String get pocketFeature3Title { switch (language) {
    case AppLanguage.english: return 'Non-Slip Grip';
    case AppLanguage.japanese: return 'ノンスリップグリップ';
    case AppLanguage.chinese: return '防滑抓握';
    case AppLanguage.mongolian: return 'Гулгахаас хамгаалах';
    default: return '논슬립 그립';
  }}

  // 무료배송 (카테고리 화면 배지)
  String get freeShip { switch (language) {
    case AppLanguage.english: return 'Free Ship';
    case AppLanguage.japanese: return '送料無料';
    case AppLanguage.chinese: return '免运费';
    case AppLanguage.mongolian: return 'Үнэгүй';
    default: return '무료배송';
  }}

  // ── 포켓 특성 타일 (4가지) ──────────────────────────────
  String get pocketTile1Title { switch (language) {
    case AppLanguage.english: return 'Thigh · Hip Position';
    case AppLanguage.japanese: return '太もも・お尻の間の位置';
    case AppLanguage.chinese: return '大腿·臀部之间位置';
    case AppLanguage.mongolian: return 'Гуя · Цэрсний хооронд';
    default: return '허벅지 · 엉덩이 사이 위치';
  }}
  String get pocketTile1Desc { switch (language) {
    case AppLanguage.english: return 'Optimal position that does not interfere with movement\nSuitable for running, cycling, triathlon and all sports';
    case AppLanguage.japanese: return '動きを妨げない最適な位置に設計\nランニング・サイクル・トライアスロンなど全競技に最適';
    case AppLanguage.chinese: return '设计在不妨碍运动的最佳位置\n适合跑步、骑行、铁人三项等各类运动';
    case AppLanguage.mongolian: return 'Хөдөлгөөнд саад болохгүй оновчтой байрлалд\nГүйлт, дугуй, триатлон зэрэг бүх тэмцээнд тохиромжтой';
    default: return '움직임을 방해하지 않는 최적의 위치에 설계\n러닝, 싸이클, 트라이애슬론 등 모든 경기에 적합';
  }}
  String get pocketTile2Title { switch (language) {
    case AppLanguage.english: return '45° Rear Entry';
    case AppLanguage.japanese: return '45°後方入口';
    case AppLanguage.chinese: return '45°后方开口';
    case AppLanguage.mongolian: return '45° Арын орц';
    default: return '45° 뒤 방향 입구';
  }}
  String get pocketTile2Desc { switch (language) {
    case AppLanguage.english: return '45° diagonal angle design for natural hand reach\nEasy to put in and take out even while running';
    case AppLanguage.japanese: return '手が自然に届く45度斜め角度設計\n走りながらでも簡単に出し入れできます';
    case AppLanguage.chinese: return '手自然触达的45度斜角设计\n跑步中也能轻松取放';
    case AppLanguage.mongolian: return 'Гарт байгалиасаа хүрэх 45 градусын налуу өнцөг\nГүйхдээ ч амархан гаргаж хийж болно';
    default: return '손이 자연스럽게 닿는 45도 사선 각도 설계\n달리면서도 간편하게 꺼내고 넣을 수 있습니다';
  }}
  String get pocketTile3Title { switch (language) {
    case AppLanguage.english: return 'Secure Smartphone Grip';
    case AppLanguage.japanese: return 'スマートフォン安全固定';
    case AppLanguage.chinese: return '手机安全固定';
    case AppLanguage.mongolian: return 'Ухаалаг гар утас найдвартай бэхлэлт';
    default: return '스마트폰 안전 고정';
  }}
  String get pocketTile3Desc { switch (language) {
    case AppLanguage.english: return 'Secure smartphone without bouncing while running\nFits large smartphones over 6 inches';
    case AppLanguage.japanese: return 'ランニング中も揺れずにスマートフォンを安全に固定\n6インチ以上の大型スマートフォンも収納可能';
    case AppLanguage.chinese: return '跑步时不抖动，安全固定手机\n可容纳6英寸以上大型手机';
    case AppLanguage.mongolian: return 'Гүйхдээ чичиргээгүй гар утсаа найдвартай барина\n6 инчээс дээш том ухаалаг гар утас ч хадгалдаг';
    default: return '러닝 중 흔들림 없이 스마트폰을 안전하게 고정\n6인치 이상 대형 스마트폰도 수납 가능';
  }}
  String get pocketTile4Title { switch (language) {
    case AppLanguage.english: return 'Energy Gel · Pouch Storage';
    case AppLanguage.japanese: return 'エナジージェル・飲料パウチ収納';
    case AppLanguage.chinese: return '能量胶·饮料袋收纳';
    case AppLanguage.mongolian: return 'Энергийн гель · Уусны халтас';
    default: return '에너지젤 · 음료 파우치 수납';
  }}
  String get pocketTile4Desc { switch (language) {
    case AppLanguage.english: return 'Spacious design for energy gels and small pouches\nEasier energy supply during long-distance races';
    case AppLanguage.japanese: return 'エナジージェル・小型パウチが収納できる広い設計\n長距離競技時のエネルギー補給がより便利になります';
    case AppLanguage.chinese: return '可收纳能量胶、小型袋的宽裕设计\n长距离比赛时补充能量更方便';
    case AppLanguage.mongolian: return 'Энергийн гель, жижиг халтас багтаах зай\nУрт зайн тэмцээнд эрчим хүч нөхөх нь илүү хялбар';
    default: return '에너지젤, 소형 파우치 수납 가능한 넉넉한 설계\n장거리 경기 시 에너지 보급이 더욱 편리합니다';
  }}

  // ── 구매 타입 버튼 ──────────────────────────────────────
  String get orderTypeReadyMadeTitle { switch (language) {
    case AppLanguage.english: return 'Ready-made Purchase';
    case AppLanguage.japanese: return '既製品購入';
    case AppLanguage.chinese: return '成衣购买';
    case AppLanguage.mongolian: return 'Бэлэн бараа авах';
    default: return '기성품 구매';
  }}
  String get orderTypeReadyMadeDesc { switch (language) {
    case AppLanguage.english: return 'Buy in-stock items immediately';
    case AppLanguage.japanese: return '在庫商品をすぐに購入';
    case AppLanguage.chinese: return '立即购买现货商品';
    case AppLanguage.mongolian: return 'Нөөц барааг нэн даруй авах';
    default: return '재고 상품 즉시 구매';
  }}
  String get orderTypeReadyMadeTag1 { switch (language) {
    case AppLanguage.english: return 'Fast Delivery';
    case AppLanguage.japanese: return '即日発送';
    case AppLanguage.chinese: return '快速配送';
    case AppLanguage.mongolian: return 'Хурдан хүргэлт';
    default: return '빠른 배송';
  }}
  String get orderTypeReadyMadeTag2 { switch (language) {
    case AppLanguage.english: return 'Immediate Purchase';
    case AppLanguage.japanese: return '即時購入';
    case AppLanguage.chinese: return '立即购买';
    case AppLanguage.mongolian: return 'Шууд худалдан авалт';
    default: return '즉시 구매';
  }}
  String get orderTypeGroupCustomTitle { switch (language) {
    case AppLanguage.english: return 'Group Custom Order';
    case AppLanguage.japanese: return '団体カスタム注文';
    case AppLanguage.chinese: return '团体定制订单';
    case AppLanguage.mongolian: return 'Бүлгийн захиалгат';
    default: return '단체 커스텀 주문';
  }}
  String get orderTypeGroupCustomDesc { switch (language) {
    case AppLanguage.english: return 'Team logo/name/number print, 5+ items';
    case AppLanguage.japanese: return 'チームロゴ/名前/番号印刷、5着以上';
    case AppLanguage.chinese: return '队伍Logo/姓名/号码印刷，5件以上';
    case AppLanguage.mongolian: return 'Багийн лого/нэр/дугаар хэвлэл, 5+';
    default: return '팀 로고/이름/번호 인쇄, 5벌 이상';
  }}
  String get orderTypeGroupCustomTag1 { switch (language) {
    case AppLanguage.english: return 'Group Discount';
    case AppLanguage.japanese: return '団体割引';
    case AppLanguage.chinese: return '团体折扣';
    case AppLanguage.mongolian: return 'Бүлгийн хямдрал';
    default: return '단체 할인';
  }}
  String get orderTypeGroupCustomTag2 { switch (language) {
    case AppLanguage.english: return 'Team Custom Made';
    case AppLanguage.japanese: return 'チームオーダーメイド';
    case AppLanguage.chinese: return '队伍定制';
    case AppLanguage.mongolian: return 'Багийн захиалгат';
    default: return '팀 맞춤 제작';
  }}

  // ── 장바구니 스낵바 ─────────────────────────────────────
  String addedToCartMsg(String? bottomLength) {
    switch (language) {
      case AppLanguage.english:
        return 'Added to cart${bottomLength != null ? " (Bottom: $bottomLength)" : ""}';
      case AppLanguage.japanese:
        return 'カートに追加しました${bottomLength != null ? " (丈: $bottomLength)" : ""}';
      case AppLanguage.chinese:
        return '已加入购物车${bottomLength != null ? " (长度: $bottomLength)" : ""}';
      case AppLanguage.mongolian:
        return 'Сагсанд нэмлээ${bottomLength != null ? " (Урт: $bottomLength)" : ""}';
      default:
        return '장바구니에 담았습니다${bottomLength != null ? " (하의길이: $bottomLength)" : ""}';
    }
  }
  String get viewCartLabel { switch (language) {
    case AppLanguage.english: return 'View Cart';
    case AppLanguage.japanese: return 'カートを見る';
    case AppLanguage.chinese: return '查看购物车';
    case AppLanguage.mongolian: return 'Сагс харах';
    default: return '보러가기';
  }}

  // ── color_picker 버튼 ──────────────────────────────────
  String get selectBtn { switch (language) {
    case AppLanguage.english: return 'Select';
    case AppLanguage.japanese: return '選択';
    case AppLanguage.chinese: return '选择';
    case AppLanguage.mongolian: return 'Сонгох';
    default: return '선택';
  }}
  String get applyBtn { switch (language) {
    case AppLanguage.english: return 'Apply';
    case AppLanguage.japanese: return '適用';
    case AppLanguage.chinese: return '应用';
    case AppLanguage.mongolian: return 'Хэрэглэх';
    default: return '적용';
  }}
  String get goljiQuickRef { switch (language) {
    case AppLanguage.english: return 'Golgi 19-Color Quick Ref';
    case AppLanguage.japanese: return 'ゴルジ19色クイックRef';
    case AppLanguage.chinese: return '罗纹19色快速参照';
    case AppLanguage.mongolian: return 'Голжи 19 өнгө хурдан лавлах';
    default: return '골지 19색 빠른 참조';
  }}
  String get goljiRef { switch (language) {
    case AppLanguage.english: return 'Golgi 19 Colors';
    case AppLanguage.japanese: return 'ゴルジ19色参照';
    case AppLanguage.chinese: return '罗纹19色参照';
    case AppLanguage.mongolian: return 'Голжи 19 өнгө';
    default: return '골지 19색 참조';
  }}

  // ── 하의길이 참조 라벨 ──────────────────────────────────
  String get maleLengthRef { switch (language) {
    case AppLanguage.english: return 'Male Bottom Length Ref';
    case AppLanguage.japanese: return '男性下半身丈参照';
    case AppLanguage.chinese: return '男性下装长度参照';
    case AppLanguage.mongolian: return 'Эрэгтэй доод урт лавлах';
    default: return '남자 하의길이 참조';
  }}
  String get femaleLengthRef { switch (language) {
    case AppLanguage.english: return 'Female Bottom Length Ref';
    case AppLanguage.japanese: return '女性下半身丈参照';
    case AppLanguage.chinese: return '女性下装长度参照';
    case AppLanguage.mongolian: return 'Эмэгтэй доод урт лавлах';
    default: return '여자 하의길이 참조';
  }}

  // ── 공지 팝업 버튼 ──────────────────────────────────────
  String get nextNoticeBtn { switch (language) {
    case AppLanguage.english: return 'Next ›';
    case AppLanguage.japanese: return '次へ ›';
    case AppLanguage.chinese: return '下一条 ›';
    case AppLanguage.mongolian: return 'Дараах ›';
    default: return '다음 공지 ›';
  }}

  // ── 단체 주문서 추가 버튼 ───────────────────────────────
  String get addRowBtn { switch (language) {
    case AppLanguage.english: return 'Add';
    case AppLanguage.japanese: return '追加';
    case AppLanguage.chinese: return '添加';
    case AppLanguage.mongolian: return 'Нэмэх';
    default: return '추가';
  }}

  // ── 장바구니 / 결제 ─────────────────────────────────────
  String get paymentCancelled { switch (language) {
    case AppLanguage.english: return 'Payment cancelled.';
    case AppLanguage.japanese: return 'お支払いがキャンセルされました。';
    case AppLanguage.chinese: return '支付已取消。';
    case AppLanguage.mongolian: return 'Төлбөр цуцлагдлаа.';
    default: return '결제가 취소되었습니다.';
  }}
  String paymentError(String e) { switch (language) {
    case AppLanguage.english: return 'An error occurred: $e';
    case AppLanguage.japanese: return 'エラーが発生しました: $e';
    case AppLanguage.chinese: return '发生错误：$e';
    case AppLanguage.mongolian: return 'Алдаа гарлаа: $e';
    default: return '오류가 발생했습니다: $e';
  }}
  String orderItemsCount(int n) { switch (language) {
    case AppLanguage.english: return 'Order Items ($n)';
    case AppLanguage.japanese: return '注文商品 ($n点)';
    case AppLanguage.chinese: return '订单商品 ($n件)';
    case AppLanguage.mongolian: return 'Захиалсан ($n)';
    default: return '주문 상품 ($n개)';
  }}
  String extraPriceLabel(String price) { switch (language) {
    case AppLanguage.english: return 'Extra +$price';
    case AppLanguage.japanese: return '追加金額 +$price';
    case AppLanguage.chinese: return '附加金额 +$price';
    case AppLanguage.mongolian: return 'Нэмэлт +$price';
    default: return '추가금액 +$price원';
  }}
  String minOrderAmountMsg(String amount) { switch (language) {
    case AppLanguage.english: return 'Minimum order amount is $amount.';
    case AppLanguage.japanese: return '最低注文金額は$amount円以上です。';
    case AppLanguage.chinese: return '最低订单金额为$amount元。';
    case AppLanguage.mongolian: return 'Доод захиалгын хэмжээ $amount байна.';
    default: return '최소 주문 금액 $amount원 이상이어야 합니다.';
  }}
  String currentAmountLabel(String amount) { switch (language) {
    case AppLanguage.english: return 'Current: $amount';
    case AppLanguage.japanese: return '現在 $amount円';
    case AppLanguage.chinese: return '当前 $amount元';
    case AppLanguage.mongolian: return 'Одоо: $amount';
    default: return '현재 $amount원';
  }}
  String get orderCompletedTitle { switch (language) {
    case AppLanguage.english: return 'Order completed';
    case AppLanguage.japanese: return 'ご注文が完了しました';
    case AppLanguage.chinese: return '订单已完成';
    case AppLanguage.mongolian: return 'Захиалга дууслаа';
    default: return '주문이 완료되었습니다';
  }}
  String get buyerLabel { switch (language) {
    case AppLanguage.english: return 'Buyer';
    case AppLanguage.japanese: return '購入者';
    case AppLanguage.chinese: return '购买者';
    case AppLanguage.mongolian: return 'Худалдан авагч';
    default: return '구매자';
  }}
  String get testPaymentNotice { switch (language) {
    case AppLanguage.english: return 'This is a test payment. No actual charge will occur.\nTest card info has been filled in automatically.';
    case AppLanguage.japanese: return 'これはテスト決済です。実際の決済は発生しません。\nテストカード情報が自動入力されています。';
    case AppLanguage.chinese: return '这是测试支付，不会产生实际费用。\n测试卡信息已自动填入。';
    case AppLanguage.mongolian: return 'Энэ нь туршилтын төлбөр юм. Бодит төлбөр гарахгүй.\nТуршилтын картын мэдээлэл автоматаар оруулагдсан.';
    default: return '테스트 결제입니다. 실제 결제가 발생하지 않습니다.\n아래 테스트 카드 정보가 자동 입력되어 있습니다.';
  }}

  // ── 커스텀 주문 화면 ────────────────────────────────────
  String get minQtyHint { switch (language) {
    case AppLanguage.english: return 'Min. 5 items';
    case AppLanguage.japanese: return '最低5着以上';
    case AppLanguage.chinese: return '最少5件';
    case AppLanguage.mongolian: return 'Хамгийн багадаа 5';
    default: return '최소 5벌 이상';
  }}
  String get minQtyError { switch (language) {
    case AppLanguage.english: return 'Please enter at least 5 items';
    case AppLanguage.japanese: return '5着以上を入力してください';
    case AppLanguage.chinese: return '请输入至少5件';
    case AppLanguage.mongolian: return 'Дор хаяж 5 ширхэг оруулна уу';
    default: return '최소 5벌 이상 입력해주세요';
  }}
  String get productSelectTitle { switch (language) {
    case AppLanguage.english: return 'Select Product';
    case AppLanguage.japanese: return '商品選択';
    case AppLanguage.chinese: return '商品选择';
    case AppLanguage.mongolian: return 'Бүтээгдэхүүн сонгох';
    default: return '상품 선택';
  }}
  String get productSelectHint { switch (language) {
    case AppLanguage.english: return 'Please select a product';
    case AppLanguage.japanese: return '商品を選択してください';
    case AppLanguage.chinese: return '请选择商品';
    case AppLanguage.mongolian: return 'Бүтээгдэхүүн сонгоно уу';
    default: return '상품을 선택해주세요';
  }}
  String get colorSelectHint { switch (language) {
    case AppLanguage.english: return 'Please select a color';
    case AppLanguage.japanese: return 'カラーを選択してください';
    case AppLanguage.chinese: return '请选择颜色';
    case AppLanguage.mongolian: return 'Өнгө сонгоно уу';
    default: return '컬러를 선택해주세요';
  }}
  String get customOptionTitle { switch (language) {
    case AppLanguage.english: return 'Custom Options';
    case AppLanguage.japanese: return 'カスタムオプション';
    case AppLanguage.chinese: return '定制选项';
    case AppLanguage.mongolian: return 'Захиалгат сонголт';
    default: return '커스텀 옵션';
  }}
  String get teamLogoPrint { switch (language) {
    case AppLanguage.english: return 'Team Logo Print';
    case AppLanguage.japanese: return 'チームロゴ印刷';
    case AppLanguage.chinese: return '队伍Logo印刷';
    case AppLanguage.mongolian: return 'Багийн лого хэвлэх';
    default: return '팀 로고 인쇄';
  }}
  String get teamLogoFileNotice { switch (language) {
    case AppLanguage.english: return 'File attachment guidance';
    case AppLanguage.japanese: return '別途ファイル添付案内';
    case AppLanguage.chinese: return '附件上传说明';
    case AppLanguage.mongolian: return 'Файл хавсаргах зааварчилгаа';
    default: return '별도 파일 첨부 안내';
  }}
  String get namePrint { switch (language) {
    case AppLanguage.english: return 'Name Print';
    case AppLanguage.japanese: return '名前印刷';
    case AppLanguage.chinese: return '姓名印刷';
    case AppLanguage.mongolian: return 'Нэр хэвлэх';
    default: return '이름 인쇄';
  }}
  String namePrintSubtitle(String price) { switch (language) {
    case AppLanguage.english: return 'Individual name print (+$price/item)';
    case AppLanguage.japanese: return '個人名印刷 (+$price円/個)';
    case AppLanguage.chinese: return '个人姓名印刷 (+$price元/件)';
    case AppLanguage.mongolian: return 'Хувийн нэр хэвлэх (+$price/ш)';
    default: return '개인별 이름 인쇄 (+$price원/개)';
  }}
  String get numberPrint { switch (language) {
    case AppLanguage.english: return 'Number Print';
    case AppLanguage.japanese: return '番号印刷';
    case AppLanguage.chinese: return '号码印刷';
    case AppLanguage.mongolian: return 'Дугаар хэвлэх';
    default: return '등번호 인쇄';
  }}
  String numberPrintSubtitle(String price) { switch (language) {
    case AppLanguage.english: return 'Individual number print (+$price/item)';
    case AppLanguage.japanese: return '個人番号印刷 (+$price円/個)';
    case AppLanguage.chinese: return '个人号码印刷 (+$price元/件)';
    case AppLanguage.mongolian: return 'Хувийн дугаар хэвлэх (+$price/ш)';
    default: return '개인별 번호 인쇄 (+$price원/개)';
  }}
  String get deliveryInfoTitle { switch (language) {
    case AppLanguage.english: return 'Delivery Info';
    case AppLanguage.japanese: return '配送情報';
    case AppLanguage.chinese: return '配送信息';
    case AppLanguage.mongolian: return 'Хүргэлтийн мэдээлэл';
    default: return '배송 정보';
  }}
  String get deliveryAddrHint { switch (language) {
    case AppLanguage.english: return 'e.g. 152 Teheran-ro, Gangnam-gu';
    case AppLanguage.japanese: return '例) ソウル市江南区テヘラン路 152';
    case AppLanguage.chinese: return '例）首尔市江南区德黑兰路 152';
    case AppLanguage.mongolian: return 'Жишээ: Гангнам-гу, Техэран-ро 152';
    default: return '서울시 강남구 역삼동 000-00';
  }}
  String get designRequestTitle { switch (language) {
    case AppLanguage.english: return 'Design Request';
    case AppLanguage.japanese: return 'デザインリクエスト';
    case AppLanguage.chinese: return '设计需求';
    case AppLanguage.mongolian: return 'Дизайны хүсэлт';
    default: return '디자인 요청사항';
  }}
  String get designRequestHint { switch (language) {
    case AppLanguage.english: return 'Please freely enter your desired design or reference';
    case AppLanguage.japanese: return 'ご希望のデザインまたは参考事項を自由にご入力ください';
    case AppLanguage.chinese: return '请自由输入您想要的设计或参考事项';
    case AppLanguage.mongolian: return 'Хүссэн дизайн эсвэл лавлах зүйлийг чөлөөтэй оруулна уу';
    default: return '원하시는 디자인 또는 참고 사항을 자유롭게 입력해주세요';
  }}

  // ── 단체 주문 관련 ───────────────────────────────────────
  String get managerContactNotice { switch (language) {
    case AppLanguage.english: return 'Our manager will contact you.\nFor inquiries, contact KakaoTalk @2FIT';
    case AppLanguage.japanese: return '担当者が確認後ご連絡いたします。\nカカオトーク @2FIT までお問い合わせください。';
    case AppLanguage.chinese: return '负责人确认后将与您联系。\n请通过KakaoTalk @2FIT 咨询。';
    case AppLanguage.mongolian: return 'Менежер шалгаад холбоо барина.\nKakaoTalk @2FIT-д хандана уу.';
    default: return '담당자가 확인 후 연락드립니다.\n카카오톡 채널 @2FIT로 문의하세요.';
  }}
  String get requiredFieldError { switch (language) {
    case AppLanguage.english: return 'This field is required.';
    case AppLanguage.japanese: return '必須入力です。';
    case AppLanguage.chinese: return '此项为必填项。';
    case AppLanguage.mongolian: return 'Заавал бөглөнө үү.';
    default: return '필수 입력입니다.';
  }}
  String get productNameHint { switch (language) {
    case AppLanguage.english: return 'e.g. 2024 Marathon Group Singlet Set';
    case AppLanguage.japanese: return '例) 2024マラソン団体シングレットセット';
    case AppLanguage.chinese: return '例）2024马拉松团体单衫套装';
    case AppLanguage.mongolian: return 'Жишээ: 2024 Марафон бүлгийн сингл сет';
    default: return '예) 2024 마라톤 단체 싱글렛세트';
  }}
  String get salePriceHint { switch (language) {
    case AppLanguage.english: return 'e.g. 89000';
    case AppLanguage.japanese: return '例) 89000';
    case AppLanguage.chinese: return '例）89000';
    case AppLanguage.mongolian: return 'Жишээ: 89000';
    default: return '예) 89000';
  }}
  String get originalPriceLabel { switch (language) {
    case AppLanguage.english: return 'Original Price (before discount, optional)';
    case AppLanguage.japanese: return '定価（割引前、任意）';
    case AppLanguage.chinese: return '原价（折扣前，选填）';
    case AppLanguage.mongolian: return 'Анхны үнэ (хямдралаас өмнө, заавал биш)';
    default: return '정가 (할인 전, 선택)';
  }}
  String get materialHint { switch (language) {
    case AppLanguage.english: return '78% Nylon, 22% Spandex';
    case AppLanguage.japanese: return '78%ナイロン、22%スパンデックス';
    case AppLanguage.chinese: return '78%尼龙，22%氨纶';
    case AppLanguage.mongolian: return '78% Нейлон, 22% Спандекс';
    default: return '78% Nylon, 22% Spandex';
  }}
  String get isNewLabel { switch (language) {
    case AppLanguage.english: return 'New Arrival';
    case AppLanguage.japanese: return '新着';
    case AppLanguage.chinese: return '新品';
    case AppLanguage.mongolian: return 'Шинэ бараа';
    default: return '신상품';
  }}
  String get isSaleLabel { switch (language) {
    case AppLanguage.english: return 'On Sale';
    case AppLanguage.japanese: return 'セール';
    case AppLanguage.chinese: return '促销';
    case AppLanguage.mongolian: return 'Хямдрал';
    default: return '세일';
  }}
  String get isFreeShippingLabel { switch (language) {
    case AppLanguage.english: return 'Free Shipping';
    case AppLanguage.japanese: return '送料無料';
    case AppLanguage.chinese: return '免运费';
    case AppLanguage.mongolian: return 'Үнэгүй хүргэлт';
    default: return '무료배송';
  }}

  // ── 마이페이지 주소 ──────────────────────────────────────
  String get addrLabelHome { switch (language) {
    case AppLanguage.english: return 'Home';
    case AppLanguage.japanese: return '自宅';
    case AppLanguage.chinese: return '家';
    case AppLanguage.mongolian: return 'Гэр';
    default: return '집';
  }}
  String get addrLabelOffice { switch (language) {
    case AppLanguage.english: return 'Office';
    case AppLanguage.japanese: return '会社';
    case AppLanguage.chinese: return '公司';
    case AppLanguage.mongolian: return 'Оффис';
    default: return '회사';
  }}
  String otherItemsCount(int n) { switch (language) {
    case AppLanguage.english: return '+ $n more items';
    case AppLanguage.japanese: return '他$n点の商品';
    case AppLanguage.chinese: return '另外$n件商品';
    case AppLanguage.mongolian: return '+ $n бараа';
    default: return '외 $n개 상품';
  }}
  String totalAmountLabel(String amount) { switch (language) {
    case AppLanguage.english: return 'Total $amount';
    case AppLanguage.japanese: return '合計 $amount円';
    case AppLanguage.chinese: return '总计 $amount元';
    case AppLanguage.mongolian: return 'Нийт $amount';
    default: return '총 $amount원';
  }}
  String reviewSizeColor(String size, String color) { switch (language) {
    case AppLanguage.english: return [if (size.isNotEmpty) 'Size: $size', if (color.isNotEmpty) 'Color: $color'].join(' · ');
    case AppLanguage.japanese: return [if (size.isNotEmpty) 'サイズ: $size', if (color.isNotEmpty) 'カラー: $color'].join(' · ');
    case AppLanguage.chinese: return [if (size.isNotEmpty) '尺码: $size', if (color.isNotEmpty) '颜色: $color'].join(' · ');
    case AppLanguage.mongolian: return [if (size.isNotEmpty) 'Хэмжээ: $size', if (color.isNotEmpty) 'Өнгө: $color'].join(' · ');
    default: return [if (size.isNotEmpty) '사이즈: $size', if (color.isNotEmpty) '색상: $color'].join(' · ');
  }}
  String get modifyWarning { switch (language) {
    case AppLanguage.english: return '⚠️ Color/team name edits are limited to 2 times.\nOnly applicable before production starts.';
    case AppLanguage.japanese: return '⚠️ カラー・団体名の修正は計2回まで可能です。\n製作着手前のみ反映され、製作中の場合は反映が難しい場合があります。';
    case AppLanguage.chinese: return '⚠️ 颜色·团体名修改最多2次。\n仅在制作开始前生效，制作中可能无法反映。';
    case AppLanguage.mongolian: return '⚠️ Өнгө/багийн нэрийг нийт 2 удаа засах боломжтой.\nЗөвхөн үйлдвэрлэл эхлэхээс өмнө хамаарна.';
    default: return '⚠️ 컬러·단체명 수정요청은 총 2회만 가능합니다.\n제작 착수 전에만 반영되며, 이미 제작 중인 경우 반영이 어려울 수 있습니다.';
  }}
  String get adultSizeLabel { switch (language) {
    case AppLanguage.english: return 'Adult';
    case AppLanguage.japanese: return '成人';
    case AppLanguage.chinese: return '成人';
    case AppLanguage.mongolian: return 'Насанд хүрэгч';
    default: return '성인';
  }}
  String get juniorSizeLabel { switch (language) {
    case AppLanguage.english: return 'Junior';
    case AppLanguage.japanese: return 'ジュニア';
    case AppLanguage.chinese: return '少年';
    case AppLanguage.mongolian: return 'Жуниор';
    default: return '주니어';
  }}
  String get recipientLabel { switch (language) {
    case AppLanguage.english: return 'Recipient *';
    case AppLanguage.japanese: return '受取人 *';
    case AppLanguage.chinese: return '收货人 *';
    case AppLanguage.mongolian: return 'Хүлээн авагч *';
    default: return '수령인 *';
  }}
  String get recipientHint { switch (language) {
    case AppLanguage.english: return 'Name';
    case AppLanguage.japanese: return 'お名前';
    case AppLanguage.chinese: return '姓名';
    case AppLanguage.mongolian: return 'Нэр';
    default: return '이름';
  }}
  String get phoneLabel { switch (language) {
    case AppLanguage.english: return 'Phone';
    case AppLanguage.japanese: return '電話番号';
    case AppLanguage.chinese: return '联系方式';
    case AppLanguage.mongolian: return 'Утас';
    default: return '연락처';
  }}
  String get zipLabel { switch (language) {
    case AppLanguage.english: return 'Zip Code';
    case AppLanguage.japanese: return '郵便番号';
    case AppLanguage.chinese: return '邮政编码';
    case AppLanguage.mongolian: return 'Шуудан индекс';
    default: return '우편번호';
  }}
  String get zipHint { switch (language) {
    case AppLanguage.english: return 'Zip code (auto-filled)';
    case AppLanguage.japanese: return '郵便番号（自動入力）';
    case AppLanguage.chinese: return '邮政编码（自动填写）';
    case AppLanguage.mongolian: return 'Шуудан индекс (автоматаар)';
    default: return '우편번호 (자동 입력)';
  }}
  String get addr1Label { switch (language) {
    case AppLanguage.english: return 'Address *';
    case AppLanguage.japanese: return '住所 *';
    case AppLanguage.chinese: return '地址 *';
    case AppLanguage.mongolian: return 'Хаяг *';
    default: return '주소 *';
  }}
  String get addr1Hint { switch (language) {
    case AppLanguage.english: return 'Street or lot number (auto-filled)';
    case AppLanguage.japanese: return '道路名または地番住所（自動入力）';
    case AppLanguage.chinese: return '道路名或地番地址（自动填写）';
    case AppLanguage.mongolian: return 'Гудамж эсвэл тоот (автоматаар)';
    default: return '도로명 또는 지번 주소 (자동 입력)';
  }}
  String get addr2Label { switch (language) {
    case AppLanguage.english: return 'Detailed Address';
    case AppLanguage.japanese: return '詳細住所';
    case AppLanguage.chinese: return '详细地址';
    case AppLanguage.mongolian: return 'Дэлгэрэнгүй хаяг';
    default: return '상세 주소';
  }}
  String get addr2Hint { switch (language) {
    case AppLanguage.english: return 'Apt/Unit number etc.';
    case AppLanguage.japanese: return 'マンション号室など';
    case AppLanguage.chinese: return '门牌/单元号等';
    case AppLanguage.mongolian: return 'Байр/тоот дугаар гэх мэт';
    default: return '상세 주소 (동/호수 등)';
  }}

  // ── 개인 주문서 ─────────────────────────────────────────
  String get printTypeColorOnly { switch (language) {
    case AppLanguage.english: return 'Color Only';
    case AppLanguage.japanese: return 'カラーのみ変更';
    case AppLanguage.chinese: return '仅更改颜色';
    case AppLanguage.mongolian: return 'Зөвхөн өнгө';
    default: return '컬러만 변경';
  }}
  String get printTypeColorOnlyDesc { switch (language) {
    case AppLanguage.english: return 'Keep original design, change color only';
    case AppLanguage.japanese: return '基本デザイン維持、カラーのみ変更';
    case AppLanguage.chinese: return '保持基础设计，仅更改颜色';
    case AppLanguage.mongolian: return 'Үндсэн дизайн хэвээр, зөвхөн өнгө солих';
    default: return '기본 디자인 유지, 색상만 변경';
  }}
  String get printTypeNameFront { switch (language) {
    case AppLanguage.english: return 'Name (Front)';
    case AppLanguage.japanese: return '名前（前面）';
    case AppLanguage.chinese: return '姓名（正面）';
    case AppLanguage.mongolian: return 'Нэр (урд тал)';
    default: return '이름 (앞면)';
  }}
  String get printTypeNameFrontDesc { switch (language) {
    case AppLanguage.english: return 'Team/personal name print on front';
    case AppLanguage.japanese: return '前面にチーム/個人名を印刷';
    case AppLanguage.chinese: return '正面印刷团队/个人名称';
    case AppLanguage.mongolian: return 'Урд талд баг/хувийн нэр хэвлэх';
    default: return '앞면에 팀/개인명 인쇄';
  }}
  String get printTypeNameBoth { switch (language) {
    case AppLanguage.english: return 'Name (Front+Back)';
    case AppLanguage.japanese: return '名前（前後）';
    case AppLanguage.chinese: return '姓名（正反面）';
    case AppLanguage.mongolian: return 'Нэр (урд+ар)';
    default: return '이름 (앞+뒤)';
  }}
  String get printTypeNameBothDesc { switch (language) {
    case AppLanguage.english: return 'Front and back name print';
    case AppLanguage.japanese: return '前面と背面の名前印刷';
    case AppLanguage.chinese: return '正反面姓名印刷';
    case AppLanguage.mongolian: return 'Урд ба ард нэр хэвлэх';
    default: return '앞면 + 뒷면 이름 인쇄';
  }}
  String get mainColorLabel { switch (language) {
    case AppLanguage.english: return 'Main Color';
    case AppLanguage.japanese: return 'メインカラー';
    case AppLanguage.chinese: return '主色';
    case AppLanguage.mongolian: return 'Үндсэн өнгө';
    default: return '메인 컬러';
  }}
  String get waistbandColorLabel { switch (language) {
    case AppLanguage.english: return 'Waistband Color';
    case AppLanguage.japanese: return 'ウェストバンドカラー';
    case AppLanguage.chinese: return '腰带颜色';
    case AppLanguage.mongolian: return 'Бүсний өнгө';
    default: return '허리밴드 컬러';
  }}
  String get waistbandDesignWarning { switch (language) {
    case AppLanguage.english: return '⚠️ Waistband design change costs +60,000 KRW.\nPlease describe details in the notes.';
    case AppLanguage.japanese: return '⚠️ ウェストバンドデザイン変更は+60,000ウォンが追加されます。\nメモ欄に詳細を記載してください。';
    case AppLanguage.chinese: return '⚠️ 腰带设计更改需额外+60,000韩元。\n请在备注栏详细填写。';
    case AppLanguage.mongolian: return '⚠️ Бүсний дизайн өөрчлөлт +60,000 вон нэмэгдэнэ.\nТэмдэглэлд дэлгэрэнгүй бичнэ үү.';
    default: return '⚠️ 허리밴드 디자인 변경 시 +60,000원이 추가됩니다.\n변경 내용을 메모란에 상세히 기재해주세요.';
  }}
  String get ordererNameLabel { switch (language) {
    case AppLanguage.english: return 'Orderer Name';
    case AppLanguage.japanese: return '注文者名';
    case AppLanguage.chinese: return '下单人姓名';
    case AppLanguage.mongolian: return 'Захиалагчийн нэр';
    default: return '주문자명';
  }}
  String get ordererNameHint { switch (language) {
    case AppLanguage.english: return 'e.g. Hong Gil-dong';
    case AppLanguage.japanese: return '例) 홍길동';
    case AppLanguage.chinese: return '例）洪吉童';
    case AppLanguage.mongolian: return 'Жишээ: Ган-Эрдэнэ';
    default: return '예: 홍길동';
  }}
  String get contactLabel { switch (language) {
    case AppLanguage.english: return 'Contact';
    case AppLanguage.japanese: return '連絡先';
    case AppLanguage.chinese: return '联系方式';
    case AppLanguage.mongolian: return 'Холбоо барих';
    default: return '연락처';
  }}
  String get contactHint { switch (language) {
    case AppLanguage.english: return 'e.g. 010-1234-5678';
    case AppLanguage.japanese: return '例) 010-1234-5678';
    case AppLanguage.chinese: return '例）010-1234-5678';
    case AppLanguage.mongolian: return 'Жишээ: 010-1234-5678';
    default: return '예: 010-1234-5678';
  }}
  String get emailLabel { switch (language) {
    case AppLanguage.english: return 'Email (for estimate)';
    case AppLanguage.japanese: return 'メール（見積書受信）';
    case AppLanguage.chinese: return '邮箱（接收报价单）';
    case AppLanguage.mongolian: return 'И-мэйл (тооцоо хүлээн авах)';
    default: return '이메일 (견적서 수신)';
  }}
  String get emailHint { switch (language) {
    case AppLanguage.english: return 'e.g. name@example.com';
    case AppLanguage.japanese: return '例) name@example.com';
    case AppLanguage.chinese: return '例）name@example.com';
    case AppLanguage.mongolian: return 'Жишээ: name@example.com';
    default: return '예: name@example.com';
  }}
  String get otherRequestLabel { switch (language) {
    case AppLanguage.english: return 'Other Requests';
    case AppLanguage.japanese: return 'その他ご要望';
    case AppLanguage.chinese: return '其他要求';
    case AppLanguage.mongolian: return 'Бусад хүсэлт';
    default: return '기타 요청사항';
  }}
  String get otherRequestHint { switch (language) {
    case AppLanguage.english: return 'Waistband design changes, print position/size, other requests';
    case AppLanguage.japanese: return 'ウェストバンドデザイン変更内容、印刷位置・サイズ、その他ご要望をご記入ください。';
    case AppLanguage.chinese: return '腰带设计更改内容、印刷位置/尺寸、其他要求';
    case AppLanguage.mongolian: return 'Бүсний дизайн өөрчлөлт, хэвлэх байршил/хэмжээ, бусад хүсэлт';
    default: return '허리밴드 디자인 변경 내용, 인쇄 위치 및 크기, 기타 요청사항을 기재해주세요.';
  }}
  String get summaryProductLabel { switch (language) {
    case AppLanguage.english: return 'Product';
    case AppLanguage.japanese: return '商品';
    case AppLanguage.chinese: return '商品';
    case AppLanguage.mongolian: return 'Бүтээгдэхүүн';
    default: return '상품';
  }}
  String get summaryNoProduct { switch (language) {
    case AppLanguage.english: return 'No product selected';
    case AppLanguage.japanese: return '商品が選択されていません';
    case AppLanguage.chinese: return '未选择商品';
    case AppLanguage.mongolian: return 'Бүтээгдэхүүн сонгоогүй';
    default: return '선택된 상품 없음';
  }}
  String get summaryPrintTypeLabel { switch (language) {
    case AppLanguage.english: return 'Print Type';
    case AppLanguage.japanese: return '印刷タイプ';
    case AppLanguage.chinese: return '印刷类型';
    case AppLanguage.mongolian: return 'Хэвлэлийн төрөл';
    default: return '인쇄 타입';
  }}
  String summaryQtyLabel(int n) { switch (language) {
    case AppLanguage.english: return '$n items';
    case AppLanguage.japanese: return '$n着';
    case AppLanguage.chinese: return '$n件';
    case AppLanguage.mongolian: return '$n ширхэг';
    default: return '$n개';
  }}
  String get summaryWaistbandDesign { switch (language) {
    case AppLanguage.english: return 'Waistband Design';
    case AppLanguage.japanese: return 'ウェストバンドデザイン';
    case AppLanguage.chinese: return '腰带设计';
    case AppLanguage.mongolian: return 'Бүсний дизайн';
    default: return '허리밴드 디자인';
  }}
  String summaryWaistbandDesignPrice(String price, int qty) { switch (language) {
    case AppLanguage.english: return '+$price × $qty items';
    case AppLanguage.japanese: return '+$price円 × $qty着';
    case AppLanguage.chinese: return '+$price元 × $qty件';
    case AppLanguage.mongolian: return '+$price × $qty ш';
    default: return '+$price원 × $qty개';
  }}
  String get summaryCustomOptions { switch (language) {
    case AppLanguage.english: return 'Custom Options';
    case AppLanguage.japanese: return 'カスタムオプション';
    case AppLanguage.chinese: return '定制选项';
    case AppLanguage.mongolian: return 'Захиалгат сонголт';
    default: return '커스텀 옵션';
  }}
  String get summaryDelivery { switch (language) {
    case AppLanguage.english: return 'Delivery';
    case AppLanguage.japanese: return '配送';
    case AppLanguage.chinese: return '配送';
    case AppLanguage.mongolian: return 'Хүргэлт';
    default: return '배송';
  }}
  String get summaryFreeDelivery { switch (language) {
    case AppLanguage.english: return 'Free shipping 🎉';
    case AppLanguage.japanese: return '送料無料 🎉';
    case AppLanguage.chinese: return '免运费 🎉';
    case AppLanguage.mongolian: return 'Үнэгүй хүргэлт 🎉';
    default: return '무료배송 🎉';
  }}
  String get summaryBasicDelivery { switch (language) {
    case AppLanguage.english: return 'Basic shipping fee';
    case AppLanguage.japanese: return '基本送料';
    case AppLanguage.chinese: return '基本运费';
    case AppLanguage.mongolian: return 'Үндсэн хүргэлтийн хөлс';
    default: return '기본 배송비';
  }}
  String get estimateNotice { switch (language) {
    case AppLanguage.english: return 'Exact amount will be notified via email or KakaoTalk after order confirmation.';
    case AppLanguage.japanese: return '正確な金額は注文書確認後、メールまたはカカオトークでご案内します。';
    case AppLanguage.chinese: return '确切金额将在确认订单后通过邮件或KakaoTalk通知。';
    case AppLanguage.mongolian: return 'Захиалга баталгаажсаны дараа и-мэйл эсвэл KakaoTalk-аар мэдэгдэнэ.';
    default: return '정확한 금액은 주문서 확인 후 이메일 또는 카카오톡으로 안내드립니다.';
  }}
  String get selectProductFirst { switch (language) {
    case AppLanguage.english: return 'Please select a product first';
    case AppLanguage.japanese: return '商品を先に選択してください';
    case AppLanguage.chinese: return '请先选择商品';
    case AppLanguage.mongolian: return 'Эхлээд бүтээгдэхүүн сонгоно уу';
    default: return '상품을 먼저 선택해주세요';
  }}
  String get selectMainColorFirst { switch (language) {
    case AppLanguage.english: return 'Please select main color';
    case AppLanguage.japanese: return 'メインカラーを選択してください';
    case AppLanguage.chinese: return '请选择主色';
    case AppLanguage.mongolian: return 'Үндсэн өнгийг сонгоно уу';
    default: return '메인 컬러를 선택해주세요';
  }}
  String get addrSearchHint { switch (language) {
    case AppLanguage.english: return 'Search by road name, lot number, or building name';
    case AppLanguage.japanese: return '道路名、地番、建物名で検索できます';
    case AppLanguage.chinese: return '可按道路名、地号或建筑名搜索';
    case AppLanguage.mongolian: return 'Гудамж, дугаар эсвэл барилгын нэрээр хайх';
    default: return '도로명주소, 지번주소, 건물명으로 검색 가능합니다';
  }}
  String get viewCartBtn { switch (language) {
    case AppLanguage.english: return 'View Cart';
    case AppLanguage.japanese: return 'カートを見る';
    case AppLanguage.chinese: return '查看购物车';
    case AppLanguage.mongolian: return 'Сагс харах';
    default: return '보러가기';
  }}

  // ── 단체 주문서 상세 (그룹 폼) ─────────────────────────
  String get nameEnabledLabel { switch (language) {
    case AppLanguage.english: return 'Name Active';
    case AppLanguage.japanese: return '名前有効';
    case AppLanguage.chinese: return '姓名启用';
    case AppLanguage.mongolian: return 'Нэр идэвхтэй';
    default: return '이름 활성화';
  }}
  String get nameAvailableLabel { switch (language) {
    case AppLanguage.english: return 'Name Available';
    case AppLanguage.japanese: return '名前可能';
    case AppLanguage.chinese: return '可填姓名';
    case AppLanguage.mongolian: return 'Нэр боломжтой';
    default: return '이름 가능';
  }}
  String get enterQtyFirstMsg { switch (language) {
    case AppLanguage.english: return 'Please enter additional quantity first';
    case AppLanguage.japanese: return '追加製作数量を入力してください';
    case AppLanguage.chinese: return '请先输入追加数量';
    case AppLanguage.mongolian: return 'Нэмэлт тоо хэмжээ оруулна уу';
    default: return '추가 제작 수량을 입력해주세요';
  }}
  String get enterPersonCountFirst { switch (language) {
    case AppLanguage.english: return 'Please enter headcount first';
    case AppLanguage.japanese: return '人数を先に入力してください';
    case AppLanguage.chinese: return '请先输入人数';
    case AppLanguage.mongolian: return 'Эхлээд хүний тоо оруулна уу';
    default: return '인원수를 먼저 입력해주세요';
  }}
  String get allOptionsOrderMsg { switch (language) {
    case AppLanguage.english: return 'Enter headcount, then print type, color, size, etc. will appear in order.';
    case AppLanguage.japanese: return '人数入力後、印刷タイプ・カラー・サイズなど残りの項目が順番に表示されます。';
    case AppLanguage.chinese: return '输入人数后，印刷类型、颜色、尺码等选项将依次显示。';
    case AppLanguage.mongolian: return 'Хүний тоо оруулсны дараа хэвлэх төрөл, өнгө, хэмжээ зэрэг бусад зүйл дараалан харагдана.';
    default: return '인원수 입력 후 인쇄 타입, 색상, 사이즈 등\n나머지 항목들이 순서대로 표시됩니다.';
  }}
  String get allOptionsSelectedBadge { switch (language) {
    case AppLanguage.english: return 'All Options Selected';
    case AppLanguage.japanese: return 'すべてのオプション選択';
    case AppLanguage.chinese: return '所有选项已选';
    case AppLanguage.mongolian: return 'Бүх сонголт хийгдсэн';
    default: return '모든 옵션 선택';
  }}
  String get printType1Label { switch (language) {
    case AppLanguage.english: return '① Color Change Only (Team name unchanged)';
    case AppLanguage.japanese: return '① カラー変更のみ（団体名変更なし）';
    case AppLanguage.chinese: return '① 仅更改颜色（不更改团体名）';
    case AppLanguage.mongolian: return '① Зөвхөн өнгө солих (нэр өөрчлөхгүй)';
    default: return '① 색상변경 (단체명 변경안함)';
  }}
  String get printType2Label { switch (language) {
    case AppLanguage.english: return '② Team Name Change (Front) Only';
    case AppLanguage.japanese: return '② 団体名変更（前面）のみ';
    case AppLanguage.chinese: return '② 仅更改团体名（正面）';
    case AppLanguage.mongolian: return '② Зөвхөн багийн нэр (урд талд)';
    default: return '② 단체명변경(전면) (색상변경안함)';
  }}
  String get printType3Label { switch (language) {
    case AppLanguage.english: return '③ Team Name (Front) + Color Change';
    case AppLanguage.japanese: return '③ 団体名（前面）+ カラー変更';
    case AppLanguage.chinese: return '③ 团体名（正面）+ 颜色变更';
    case AppLanguage.mongolian: return '③ Багийн нэр (урд) + Өнгө солих';
    default: return '③ 단체명변경(전면) + 색상변경';
  }}
  String get printType4Label { switch (language) {
    case AppLanguage.english: return '④ Team Name (Front) + Color + Name (Back)';
    case AppLanguage.japanese: return '④ 団体名（前面）+ カラー + 名前（後面）';
    case AppLanguage.chinese: return '④ 团体名（正面）+ 颜色 + 姓名（背面）';
    case AppLanguage.mongolian: return '④ Багийн нэр (урд) + Өнгө + Нэр (ар)';
    default: return '④ 단체명변경(전면) + 색상변경 + 이름변경(후면)';
  }}
  String get printType3Desc { switch (language) {
    case AppLanguage.english: return 'Same color for top and bottom';
    case AppLanguage.japanese: return '上下同じカラーに変更';
    case AppLanguage.chinese: return '上下同色变更';
    case AppLanguage.mongolian: return 'Дээд доод ижил өнгө';
    default: return '상의·하의 동일 색상으로 변경';
  }}
  String get printType4Desc { switch (language) {
    case AppLanguage.english: return 'Individual name print on back (10+ items)';
    case AppLanguage.japanese: return '後面に個人名印刷（10着以上）';
    case AppLanguage.chinese: return '背面个人姓名印刷（10件以上）';
    case AppLanguage.mongolian: return 'Ар талд хувийн нэр хэвлэх (10+)';
    default: return '후면 개인 이름 인쇄 포함 (10장 이상)';
  }}
  String get qtyRequiredToSelect { switch (language) {
    case AppLanguage.english: return 'Enter at least 1 to select';
    case AppLanguage.japanese: return '1着以上入力後に選択可能です';
    case AppLanguage.chinese: return '输入1件以上才可选择';
    case AppLanguage.mongolian: return '1-ээс дээш тоо оруулсны дараа сонгоно уу';
    default: return '수량을 1장 이상 입력 후 선택 가능합니다';
  }}
  String get summaryInputPrompt { switch (language) {
    case AppLanguage.english: return 'Please enter team name + color + name info';
    case AppLanguage.japanese: return '団体名 + カラー + 名前情報を入力してください';
    case AppLanguage.chinese: return '请输入团体名+颜色+姓名信息';
    case AppLanguage.mongolian: return 'Багийн нэр + Өнгө + Нэр мэдээллийг оруулна уу';
    default: return '단체명 + 컬러 + 이름 정보를 입력해주세요';
  }}
  String get teamNameLabel { switch (language) {
    case AppLanguage.english: return 'Team Name';
    case AppLanguage.japanese: return '団体名';
    case AppLanguage.chinese: return '团体名';
    case AppLanguage.mongolian: return 'Багийн нэр';
    default: return '단체명';
  }}
  String get enterInBasicSection { switch (language) {
    case AppLanguage.english: return 'Enter in Basic Info section';
    case AppLanguage.japanese: return '基本情報セクションで入力';
    case AppLanguage.chinese: return '在基本信息部分输入';
    case AppLanguage.mongolian: return 'Үндсэн мэдээлэл хэсэгт оруулна уу';
    default: return '기본 정보 섹션에서 입력';
  }}
  String get mainColorSummary { switch (language) {
    case AppLanguage.english: return 'Main Color';
    case AppLanguage.japanese: return 'メインカラー';
    case AppLanguage.chinese: return '主色';
    case AppLanguage.mongolian: return 'Үндсэн өнгө';
    default: return '메인 컬러';
  }}
  String get selectInColorSection { switch (language) {
    case AppLanguage.english: return 'Select in Color section';
    case AppLanguage.japanese: return 'カラー選択セクションで選択';
    case AppLanguage.chinese: return '在颜色选择部分选择';
    case AppLanguage.mongolian: return 'Өнгөний хэсэгт сонгоно уу';
    default: return '컬러 선택 섹션에서 선택';
  }}
  String get personalNameLabel { switch (language) {
    case AppLanguage.english: return 'Individual Name';
    case AppLanguage.japanese: return '個人名';
    case AppLanguage.chinese: return '个人姓名';
    case AppLanguage.mongolian: return 'Хувийн нэр';
    default: return '개인 이름';
  }}
  String get enterInPersonSection { switch (language) {
    case AppLanguage.english: return 'Enter in Personnel section';
    case AppLanguage.japanese: return '人員別情報セクションで入力';
    case AppLanguage.chinese: return '在人员信息部分输入';
    case AppLanguage.mongolian: return 'Хүний мэдээлэл хэсэгт оруулна уу';
    default: return '인원별 정보 섹션에서 입력';
  }}
  String get notEnteredLabel { switch (language) {
    case AppLanguage.english: return 'Not entered';
    case AppLanguage.japanese: return '未入力';
    case AppLanguage.chinese: return '未填写';
    case AppLanguage.mongolian: return 'Оруулаагүй';
    default: return '미입력';
  }}
  String get notSelectedLabel { switch (language) {
    case AppLanguage.english: return 'Not selected';
    case AppLanguage.japanese: return '未選択';
    case AppLanguage.chinese: return '未选择';
    case AppLanguage.mongolian: return 'Сонгоогүй';
    default: return '미선택';
  }}
  String get personalEntryLabel { switch (language) {
    case AppLanguage.english: return 'Per person entry';
    case AppLanguage.japanese: return '人員別入力';
    case AppLanguage.chinese: return '按人员输入';
    case AppLanguage.mongolian: return 'Хувь хүний оролт';
    default: return '인원별 입력';
  }}
  String get discountAutoApply { switch (language) {
    case AppLanguage.english: return '※ 5% discount for 30+, 10% for 50+ applied automatically.';
    case AppLanguage.japanese: return '※ 30人以上5%割引、50人以上10%割引が自動適用されます。';
    case AppLanguage.chinese: return '※ 30人以上享5%折扣，50人以上享10%折扣，自动应用。';
    case AppLanguage.mongolian: return '※ 30-аас дээш 5%, 50-аас дээш 10% хямдрал автоматаар хэрэглэгдэнэ.';
    default: return '※ 30인 이상 5% 할인, 50인 이상 10% 할인이 자동 적용됩니다.';
  }}
  String get topColorLabel { switch (language) {
    case AppLanguage.english: return 'Top Color';
    case AppLanguage.japanese: return '上半身カラー';
    case AppLanguage.chinese: return '上装颜色';
    case AppLanguage.mongolian: return 'Дээлний өнгө';
    default: return '상의 컬러';
  }}
  String get fullColorLabel { switch (language) {
    case AppLanguage.english: return 'Full Color (Top & Bottom Same)';
    case AppLanguage.japanese: return '全体カラー（上下同じ）';
    case AppLanguage.chinese: return '全体颜色（上下相同）';
    case AppLanguage.mongolian: return 'Бүтэн өнгө (дээш доош адил)';
    default: return '전체 컬러 (상·하의 동일)';
  }}
  String get bottomAutoLengthNotice { switch (language) {
    case AppLanguage.english: return 'Bottom length: Male auto 5/10 · Female auto 2.5/10';
    case AppLanguage.japanese: return '下半身丈: 男性自動5分・女性自動2.5分適用';
    case AppLanguage.chinese: return '下装长度：男性自动5分，女性自动2.5分';
    case AppLanguage.mongolian: return 'Доод урт: Эрэгтэй автомат 5/10 · Эмэгтэй автомат 2.5/10';
    default: return '하의 기장: 남성 자동 5부 · 여성 자동 2.5부 적용';
  }}
  String get topLabel { switch (language) {
    case AppLanguage.english: return 'Top';
    case AppLanguage.japanese: return '上半身';
    case AppLanguage.chinese: return '上装';
    case AppLanguage.mongolian: return 'Дээл';
    default: return '상의';
  }}
  String get bottomLabel { switch (language) {
    case AppLanguage.english: return 'Bottom';
    case AppLanguage.japanese: return '下半身';
    case AppLanguage.chinese: return '下装';
    case AppLanguage.mongolian: return 'Доод хувцас';
    default: return '하의';
  }}
  String get phantomChartNotice { switch (language) {
    case AppLanguage.english: return '※ Phantom chart: check top/bottom color combination for group orders.';
    case AppLanguage.japanese: return '※ ファントムチャートは団体注文時の上下カラー組み合わせを確認する機能です。';
    case AppLanguage.chinese: return '※ 幻影图表是查看团体订单上下装颜色搭配的功能。';
    case AppLanguage.mongolian: return '※ Phantom chart: бүлгийн захиалгад дээш доош өнгийн хослолыг шалгах.';
    default: return '※ 팬텀차트는 단체주문 시 상·하의 색상 조합을 확인하는 기능입니다.';
  }}
  String get basePrice { switch (language) {
    case AppLanguage.english: return 'Base 70,000 KRW';
    case AppLanguage.japanese: return '基本 70,000ウォン';
    case AppLanguage.chinese: return '基础价 70,000韩元';
    case AppLanguage.mongolian: return 'Суурь 70,000 вон';
    default: return '기본 70,000원';
  }}
  String get weightSelectionHeader { switch (language) {
    case AppLanguage.english: return '⚖️ Weight Selection';
    case AppLanguage.japanese: return '⚖️ 重量選択';
    case AppLanguage.chinese: return '⚖️ 重量选择';
    case AppLanguage.mongolian: return '⚖️ Жин сонгох';
    default: return '⚖️ 무게 선택';
  }}
  String get weight80gDesc { switch (language) {
    case AppLanguage.english: return 'Light and cool';
    case AppLanguage.japanese: return '軽くて涼しい';
    case AppLanguage.chinese: return '轻薄凉爽';
    case AppLanguage.mongolian: return 'Хөнгөн, сэрүүн';
    default: return '가볍고 시원함';
  }}
  String get weight100gDesc { switch (language) {
    case AppLanguage.english: return 'Thick and firm';
    case AppLanguage.japanese: return '厚くてしっかり';
    case AppLanguage.chinese: return '厚实牢固';
    case AppLanguage.mongolian: return 'Зузаан, бат бөх';
    default: return '두툼하고 탄탄함';
  }}
  String get seamlessNotice { switch (language) {
    case AppLanguage.english: return 'Seamless fabric minimizes skin irritation and improves comfort during exercise.';
    case AppLanguage.japanese: return 'シームレス生地は肌への刺激を最小化し、運動中の快適さを向上させます。';
    case AppLanguage.chinese: return '无缝面料最大限度减少皮肤刺激，提升运动舒适感。';
    case AppLanguage.mongolian: return 'Оёдолгүй даавуу арьсны цочролыг багасгаж, дасгал хийх үеийн тайтгамжийг сайжруулна.';
    default: return '심리스(무봉제) 원단은 피부 자극을 최소화하며 운동 중 쾌적함을 향상시킵니다.';
  }}
  String get waistbandChanged { switch (language) {
    case AppLanguage.english: return 'Changed selected';
    case AppLanguage.japanese: return '変更選択済み';
    case AppLanguage.chinese: return '已选更改';
    case AppLanguage.mongolian: return 'Өөрчлөлт сонгосон';
    default: return '변경 선택됨';
  }}
  String get waistbandDefault { switch (language) {
    case AppLanguage.english: return 'Keep default';
    case AppLanguage.japanese: return 'デフォルト維持';
    case AppLanguage.chinese: return '保持默认';
    case AppLanguage.mongolian: return 'Анхдагч хэвээр';
    default: return '기본 유지';
  }}
  String get waistbandChangeNameTitle { switch (language) {
    case AppLanguage.english: return 'Team Name Change';
    case AppLanguage.japanese: return '団体名変更';
    case AppLanguage.chinese: return '更改团体名';
    case AppLanguage.mongolian: return 'Багийн нэр өөрчлөх';
    default: return '단체명 변경';
  }}
  String get waistbandChangeNameDesc { switch (language) {
    case AppLanguage.english: return 'Print team name on waistband';
    case AppLanguage.japanese: return 'ウェストバンドに団体名を印刷';
    case AppLanguage.chinese: return '在腰带上印刷团体名';
    case AppLanguage.mongolian: return 'Бүсэн дээр багийн нэр хэвлэх';
    default: return '허리밴드에 단체명을 인쇄';
  }}
  String get waistbandChangeColorTitle { switch (language) {
    case AppLanguage.english: return 'Color Change';
    case AppLanguage.japanese: return 'カラー変更';
    case AppLanguage.chinese: return '颜色更改';
    case AppLanguage.mongolian: return 'Өнгө солих';
    default: return '색상 변경';
  }}
  String get waistbandChangeColorDesc { switch (language) {
    case AppLanguage.english: return 'Change waistband color to desired color';
    case AppLanguage.japanese: return 'ウェストバンドの色をお好みの色に変更';
    case AppLanguage.chinese: return '将腰带颜色更改为所需颜色';
    case AppLanguage.mongolian: return 'Бүсний өнгийг хүссэн өнгөөр солих';
    default: return '허리밴드 색상을 원하는 색으로 변경';
  }}
  String get waistbandChangeNameColorTitle { switch (language) {
    case AppLanguage.english: return 'Team Name + Color Change';
    case AppLanguage.japanese: return '団体名 + カラー変更';
    case AppLanguage.chinese: return '团体名+颜色更改';
    case AppLanguage.mongolian: return 'Багийн нэр + Өнгө солих';
    default: return '단체명 + 색상 변경';
  }}
  String get waistbandChangeNameColorDesc { switch (language) {
    case AppLanguage.english: return 'Team name print + waistband color change';
    case AppLanguage.japanese: return '団体名印刷 + ウェストバンドカラー変更';
    case AppLanguage.chinese: return '团体名印刷+腰带颜色更改';
    case AppLanguage.mongolian: return 'Багийн нэр хэвлэх + Бүсний өнгө солих';
    default: return '단체명 인쇄 + 허리밴드 색상 변경';
  }}
  String totalPersonCount(int n) { switch (language) {
    case AppLanguage.english: return 'Total $n persons';
    case AppLanguage.japanese: return '合計$n名';
    case AppLanguage.chinese: return '共$n人';
    case AppLanguage.mongolian: return 'Нийт $n хүн';
    default: return '총 $n명';
  }}
  String get nameEntryLabel { switch (language) {
    case AppLanguage.english: return 'Name Entry';
    case AppLanguage.japanese: return '名前入力';
    case AppLanguage.chinese: return '填写姓名';
    case AppLanguage.mongolian: return 'Нэр оруулах';
    default: return '이름 입력';
  }}
  String get actualMeasurementLabel { switch (language) {
    case AppLanguage.english: return 'Actual Measurement';
    case AppLanguage.japanese: return '実測入力';
    case AppLanguage.chinese: return '实测录入';
    case AppLanguage.mongolian: return 'Бодит хэмжилт';
    default: return '실측 입력';
  }}
  // 하의 기장 목록
  String get length9bu { switch (language) {
    case AppLanguage.english: return '9/10 (Ankle)';
    case AppLanguage.japanese: return '9分 (足首上)';
    case AppLanguage.chinese: return '9分 (脚踝)';
    case AppLanguage.mongolian: return '9/10 (Шагай)';
    default: return '9부';
  }}
  String get length5bu { switch (language) {
    case AppLanguage.english: return '5/10 (Knee)';
    case AppLanguage.japanese: return '5分 (膝上)';
    case AppLanguage.chinese: return '5分 (膝盖)';
    case AppLanguage.mongolian: return '5/10 (Өвдөг)';
    default: return '5부';
  }}
  String get length4bu { switch (language) {
    case AppLanguage.english: return '4/10 (Mid Thigh)';
    case AppLanguage.japanese: return '4分 (太ももの真ん中)';
    case AppLanguage.chinese: return '4分 (大腿中部)';
    case AppLanguage.mongolian: return '4/10 (Гуяны дунд)';
    default: return '4부';
  }}
  String get length3bu { switch (language) {
    case AppLanguage.english: return '3/10 (Upper Thigh)';
    case AppLanguage.japanese: return '3分 (太ももの上部)';
    case AppLanguage.chinese: return '3分 (大腿上部)';
    case AppLanguage.mongolian: return '3/10 (Гуяны дээд)';
    default: return '3부';
  }}
  String get length25bu { switch (language) {
    case AppLanguage.english: return '2.5/10 (Just Below Hip)';
    case AppLanguage.japanese: return '2.5分 (お尻のすぐ下)';
    case AppLanguage.chinese: return '2.5分 (臀部下方)';
    case AppLanguage.mongolian: return '2.5/10 (Цэрсний доор)';
    default: return '2.5부';
  }}
  String get lengthShortShort { switch (language) {
    case AppLanguage.english: return 'Short Short';
    case AppLanguage.japanese: return 'ショートショート';
    case AppLanguage.chinese: return '超短';
    case AppLanguage.mongolian: return 'Маш богино';
    default: return '숏쇼트';
  }}
  String get length9buDesc { switch (language) {
    case AppLanguage.english: return 'Above ankle (longest)';
    case AppLanguage.japanese: return '足首より上（最も長い）';
    case AppLanguage.chinese: return '脚踝上方（最长）';
    case AppLanguage.mongolian: return 'Шагайн дээр (хамгийн урт)';
    default: return '발목 위 (가장 긴 기장)';
  }}
  String get length5buDesc { switch (language) {
    case AppLanguage.english: return 'Just above knee (male default)';
    case AppLanguage.japanese: return '膝のすぐ上（男性デフォルト）';
    case AppLanguage.chinese: return '膝盖稍上（男性默认）';
    case AppLanguage.mongolian: return 'Өвдгийн дээр (эрэгтэй анхдагч)';
    default: return '무릎 위 약간 (남성 기본)';
  }}
  String get length4buDesc { switch (language) {
    case AppLanguage.english: return 'Mid thigh';
    case AppLanguage.japanese: return '太ももの真ん中';
    case AppLanguage.chinese: return '大腿中部';
    case AppLanguage.mongolian: return 'Гуяны дунд';
    default: return '허벅지 중간';
  }}
  String get length3buDesc { switch (language) {
    case AppLanguage.english: return 'Upper thigh';
    case AppLanguage.japanese: return '太ももの上部';
    case AppLanguage.chinese: return '大腿上部';
    case AppLanguage.mongolian: return 'Гуяны дээд хэсэг';
    default: return '허벅지 상단';
  }}
  String get length25buDesc { switch (language) {
    case AppLanguage.english: return 'Just below hip (female default)';
    case AppLanguage.japanese: return 'お尻のすぐ下（女性デフォルト）';
    case AppLanguage.chinese: return '臀部正下方（女性默认）';
    case AppLanguage.mongolian: return 'Цэрсний шуудхан доор (эмэгтэй анхдагч)';
    default: return '엉덩이 바로 아래 (여성 기본)';
  }}
  String get lengthShortShortDesc { switch (language) {
    case AppLanguage.english: return 'Shortest length';
    case AppLanguage.japanese: return '最も短い丈';
    case AppLanguage.chinese: return '最短款';
    case AppLanguage.mongolian: return 'Хамгийн богино урт';
    default: return '최단 기장';
  }}
  String get defaultLengthApplied { switch (language) {
    case AppLanguage.english: return 'Applied to all persons';
    case AppLanguage.japanese: return '全員に適用されました';
    case AppLanguage.chinese: return '已应用于所有人员';
    case AppLanguage.mongolian: return 'Бүх хүнд хэрэглэгдлээ';
    default: return '전체 인원에 적용되었습니다';
  }}
  String get defaultLengthHint { switch (language) {
    case AppLanguage.english: return '✅ Selected bottom length will be applied to all members equally';
    case AppLanguage.japanese: return '✅ ここで選択した下半身丈が全員に同様に適用されます';
    case AppLanguage.chinese: return '✅ 此处选择的下装长度将统一应用于所有人员';
    case AppLanguage.mongolian: return '✅ Энд сонгосон доод уртыг бүх гишүүдэд адилхан хэрэглэнэ';
    default: return '✅ 여기서 선택한 하의 기장이 전체 인원에 동일하게 적용됩니다';
  }}
  String get canChangePerPerson { switch (language) {
    case AppLanguage.english: return '• Can be changed individually in the Personnel section.\n• Male auto: 5/10 / Female auto: 2.5/10';
    case AppLanguage.japanese: return '• デフォルト設定後、人員別セクションで個人別変更可能です。\n• 男性自動推奨: 5分 / 女性自動推奨: 2.5分';
    case AppLanguage.chinese: return '• 设置默认后，可在人员信息部分逐人修改。\n• 男性自动推荐: 5分 / 女性自动推荐: 2.5分';
    case AppLanguage.mongolian: return '• Анхдагч тохируулсны дараа хувь хүний хэсэгт тус бүрд өөрчилж болно.\n• Эрэгтэй автомат: 5/10 / Эмэгтэй автомат: 2.5/10';
    default: return '• 기본값 설정 후 인원별 섹션에서 개인별로 변경 가능합니다.\n• 남성 자동 추천: 5부 / 여성 자동 추천: 2.5부';
  }}
  String get uploadImageNotice { switch (language) {
    case AppLanguage.english: return 'Uploaded images are used for reference only.';
    case AppLanguage.japanese: return 'アップロードした画像は制作参照用のみに使用されます。';
    case AppLanguage.chinese: return '上传的图片仅用于制作参考。';
    case AppLanguage.mongolian: return 'Байршуулсан зургийг зөвхөн лавлах зорилгоор ашиглана.';
    default: return '업로드한 이미지는 제작 참조용으로만 활용됩니다.';
  }}
  String get maleGenderLabel { switch (language) {
    case AppLanguage.english: return '남자';
    case AppLanguage.japanese: return '男性';
    case AppLanguage.chinese: return '男性';
    case AppLanguage.mongolian: return 'Эрэгтэй';
    default: return '남자';
  }}
  String get femaleGenderLabel { switch (language) {
    case AppLanguage.english: return '여자';
    case AppLanguage.japanese: return '女性';
    case AppLanguage.chinese: return '女性';
    case AppLanguage.mongolian: return 'Эмэгтэй';
    default: return '여자';
  }}
  String shippingCostLabel(String fee) { switch (language) {
    case AppLanguage.english: return 'Shipping: $fee';
    case AppLanguage.japanese: return '送料: $fee';
    case AppLanguage.chinese: return '运费: $fee';
    case AppLanguage.mongolian: return 'Хүргэлт: $fee';
    default: return '배송비: $fee';
  }}
  String get freeShippingLabel { switch (language) {
    case AppLanguage.english: return 'Free';
    case AppLanguage.japanese: return '無料';
    case AppLanguage.chinese: return '免费';
    case AppLanguage.mongolian: return 'Үнэгүй';
    default: return '무료';
  }}
  String get qtyRequiredToSubmit { switch (language) {
    case AppLanguage.english: return 'Enter at least 1 to submit';
    case AppLanguage.japanese: return '1着以上入力後に提出可能です';
    case AppLanguage.chinese: return '输入1件以上才可提交';
    case AppLanguage.mongolian: return '1-ээс дээш тоо оруулсны дараа илгээнэ';
    default: return '수량을 1장 이상 입력 후 제출 가능합니다';
  }}
  String get minPersonRequired { switch (language) {
    case AppLanguage.english: return 'Minimum 5 persons required';
    case AppLanguage.japanese: return '最低5名以上が必要です';
    case AppLanguage.chinese: return '最少需要5人';
    case AppLanguage.mongolian: return 'Дор хаяж 5 хүн шаардлагатай';
    default: return '최소 5명 이상이어야 제출 가능합니다';
  }}
  String get colorDefaultLabel { switch (language) {
    case AppLanguage.english: return 'Default';
    case AppLanguage.japanese: return 'デフォルト';
    case AppLanguage.chinese: return '默认';
    case AppLanguage.mongolian: return 'Анхдагч';
    default: return '기본';
  }}
  String get orderDeliveryAddrPrompt { switch (language) {
    case AppLanguage.english: return 'Please enter the delivery address after order.';
    case AppLanguage.japanese: return '注文後に配送される住所を入力してください。';
    case AppLanguage.chinese: return '请输入下单后配送的地址。';
    case AppLanguage.mongolian: return 'Захиалгын дараа хүргэх хаягийг оруулна уу.';
    default: return '주문 완료 후 배송될 주소를 입력해주세요.';
  }}
  String get waistbandNameOnly { switch (language) {
    case AppLanguage.english: return 'Team Name';
    case AppLanguage.japanese: return '団体名';
    case AppLanguage.chinese: return '团体名';
    case AppLanguage.mongolian: return 'Багийн нэр';
    default: return '단체명';
  }}
  String get waistbandColorOnly { switch (language) {
    case AppLanguage.english: return 'Color';
    case AppLanguage.japanese: return 'カラー';
    case AppLanguage.chinese: return '颜色';
    case AppLanguage.mongolian: return 'Өнгө';
    default: return '색상';
  }}
  String modifyDaysNotice(int days, int autoDays) { switch (language) {
    case AppLanguage.english: return 'Modifiable within $days days (1 week) after order\nAuto-confirmed after $autoDays days';
    case AppLanguage.japanese: return '注文後$days日（1週間）以内に修正可能\n$autoDays日後に自動確定されます';
    case AppLanguage.chinese: return '下单后$days天（1周）内可修改\n$autoDays天后自动确认';
    case AppLanguage.mongolian: return 'Захиалгын дараа $days хоногийн дотор засах боломжтой\n$autoDays хоногийн дараа автоматаар батлагдана';
    default: return '주문 후 $days일(1주) 이내 수정 가능\n$autoDays일 후 자동 확정됩니다';
  }}
  String get estimateSentNotice { switch (language) {
    case AppLanguage.english: return 'An estimate will be sent to the manager\'s email.\nPayment instructions will follow after review.';
    case AppLanguage.japanese: return '担当者メールに見積書が送信されます。\n確認後、お支払い案内をお送りします。';
    case AppLanguage.chinese: return '报价单将发送至负责人邮箱。\n确认后将提供付款说明。';
    case AppLanguage.mongolian: return 'Менежерийн и-мэйлд тооцоо илгээгдэнэ.\nШалгасны дараа төлбөрийн зааврыг мэдэгдэнэ.';
    default: return '담당자 이메일로 견적서가 발송됩니다.\n확인 후 결제 안내를 드립니다.';
  }}
  String get sizeTableAdultLabel { switch (language) {
    case AppLanguage.english: return 'Adult';
    case AppLanguage.japanese: return '成人';
    case AppLanguage.chinese: return '成人';
    case AppLanguage.mongolian: return 'Насанд хүрэгч';
    default: return '성인';
  }}

  // ── 상품 목록 검색 결과 ──────────────────────────────────
  String searchNoResult(String query) { switch (language) {
    case AppLanguage.english: return 'No results for "$query"';
    case AppLanguage.japanese: return '"$query" の検索結果がありません';
    case AppLanguage.chinese: return '"$query" 无搜索结果';
    case AppLanguage.mongolian: return '"$query" гэсэн хайлт олдсонгүй';
    default: return '"$query" 검색 결과가 없습니다';
  }}
  String get noCategoryProduct { switch (language) {
    case AppLanguage.english: return 'No products in this category';
    case AppLanguage.japanese: return 'このカテゴリの商品がありません';
    case AppLanguage.chinese: return '该分类暂无商品';
    case AppLanguage.mongolian: return 'Энэ ангилалд бараа байхгүй';
    default: return '해당 카테고리의 상품이 없습니다';
  }}

  // ── 하의 기장 가이드 (실제 cm) ──────────────────────────
  String get length9buCm { switch (language) {
    case AppLanguage.english: return '9/10 (≈70~75cm, ankle)';
    case AppLanguage.japanese: return '9分 (約70~75cm, 足首)';
    case AppLanguage.chinese: return '9分 (约70~75cm, 脚踝)';
    case AppLanguage.mongolian: return '9/10 (≈70~75см, шагай)';
    default: return '9부 (약 70~75cm, 발목)';
  }}
  String get length5buCm { switch (language) {
    case AppLanguage.english: return '5/10 (≈55~60cm, knee)';
    case AppLanguage.japanese: return '5分 (約55~60cm, 膝)';
    case AppLanguage.chinese: return '5分 (约55~60cm, 膝盖)';
    case AppLanguage.mongolian: return '5/10 (≈55~60см, өвдөг)';
    default: return '5부 (약 55~60cm, 무릎)';
  }}
  String get length4buCm { switch (language) {
    case AppLanguage.english: return '4/10 (≈45~50cm, mid thigh)';
    case AppLanguage.japanese: return '4分 (約45~50cm, 太もも中)';
    case AppLanguage.chinese: return '4分 (约45~50cm, 大腿中)';
    case AppLanguage.mongolian: return '4/10 (≈45~50см, гуяны дунд)';
    default: return '4부 (약 45~50cm, 허벅지 중간)';
  }}
  String get length3buCm { switch (language) {
    case AppLanguage.english: return '3/10 (≈35~40cm, upper thigh)';
    case AppLanguage.japanese: return '3分 (約35~40cm, 太もも上)';
    case AppLanguage.chinese: return '3分 (约35~40cm, 大腿上)';
    case AppLanguage.mongolian: return '3/10 (≈35~40см, гуяны дээд)';
    default: return '3부 (약 35~40cm, 허벅지 상단)';
  }}
  String get length25buCm { switch (language) {
    case AppLanguage.english: return '2.5/10 (≈30~35cm, hip)';
    case AppLanguage.japanese: return '2.5分 (約30~35cm, お尻)';
    case AppLanguage.chinese: return '2.5分 (约30~35cm, 臀部)';
    case AppLanguage.mongolian: return '2.5/10 (≈30~35см, цэрс)';
    default: return '2.5부 (약 30~35cm, 엉덩이)';
  }}
  String get lengthShortShortCm { switch (language) {
    case AppLanguage.english: return 'Short Short (≈25~30cm, shortest)';
    case AppLanguage.japanese: return 'ショートショート (約25~30cm, 最短)';
    case AppLanguage.chinese: return '超短 (约25~30cm, 最短)';
    case AppLanguage.mongolian: return 'Маш богино (≈25~30см, хамгийн богино)';
    default: return '숏쇼트 (약 25~30cm, 최단)';
  }}
  String get lengthVarianceNote { switch (language) {
    case AppLanguage.english: return '※ Actual length may vary ±2~3cm depending on size.';
    case AppLanguage.japanese: return '※ 実際の丈はサイズにより±2~3cmの差があります。';
    case AppLanguage.chinese: return '※ 实际长度因尺码不同可能有±2~3cm差异。';
    case AppLanguage.mongolian: return '※ Бодит урт хэмжээнээс хамааран ±2~3см ялгаатай байж болно.';
    default: return '※ 실제 기장은 사이즈에 따라 ±2~3cm 차이가 있을 수 있습니다.';
  }}

  // ── group_order_only_screen 추가 번역 키 ─────────────────────
  String get productNameLabel { switch (language) {
    case AppLanguage.english: return 'Product Name *';
    case AppLanguage.japanese: return '商品名 *';
    case AppLanguage.chinese: return '商品名 *';
    case AppLanguage.mongolian: return 'Бүтээгдэхүүний нэр *';
    default: return '상품명 *';
  }}
  String get salePriceLabel { switch (language) {
    case AppLanguage.english: return 'Sale Price *';
    case AppLanguage.japanese: return '販売価格 *';
    case AppLanguage.chinese: return '售价 *';
    case AppLanguage.mongolian: return 'Борлуулах үнэ *';
    default: return '판매가 *';
  }}
  String get sizeSectionLabel { switch (language) {
    case AppLanguage.english: return 'Size';
    case AppLanguage.japanese: return 'サイズ';
    case AppLanguage.chinese: return '尺码';
    case AppLanguage.mongolian: return 'Хэмжээ';
    default: return '사이즈';
  }}
  String get additionalInfoLabel { switch (language) {
    case AppLanguage.english: return 'Additional Info';
    case AppLanguage.japanese: return '追加情報';
    case AppLanguage.chinese: return '附加信息';
    case AppLanguage.mongolian: return 'Нэмэлт мэдээлэл';
    default: return '추가 정보';
  }}
  String get fabricMaterialLabel { switch (language) {
    case AppLanguage.english: return 'Material';
    case AppLanguage.japanese: return '素材';
    case AppLanguage.chinese: return '材质';
    case AppLanguage.mongolian: return 'Материал';
    default: return '소재';
  }}
  String get productDescLabel { switch (language) {
    case AppLanguage.english: return 'Product Description';
    case AppLanguage.japanese: return '商品説明';
    case AppLanguage.chinese: return '商品描述';
    case AppLanguage.mongolian: return 'Бүтээгдэхүүний тайлбар';
    default: return '상품 설명';
  }}
  String get imageUrlLabel { switch (language) {
    case AppLanguage.english: return 'Image URL (one per line)';
    case AppLanguage.japanese: return '画像URL（1行に1つ）';
    case AppLanguage.chinese: return '图片URL（每行一个）';
    case AppLanguage.mongolian: return 'Зургийн URL (мөр бүрт нэг)';
    default: return '이미지 URL (한 줄에 하나씩)';
  }}
  String registFailureMsg(String e) { switch (language) {
    case AppLanguage.english: return 'Registration failed: \$e';
    case AppLanguage.japanese: return '登録失敗: \$e';
    case AppLanguage.chinese: return '注册失败: \$e';
    case AppLanguage.mongolian: return 'Бүртгэл амжилтгүй: \$e';
    default: return '등록 실패: \$e';
  }}
  List<String> get defaultColorList { switch (language) {
    case AppLanguage.english: return ['Black', 'White', 'Navy'];
    case AppLanguage.japanese: return ['ブラック', 'ホワイト', 'ネイビー'];
    case AppLanguage.chinese: return ['黑色', '白色', '藏青色'];
    case AppLanguage.mongolian: return ['Хар', 'Цагаан', 'Цэнхэр'];
    default: return ['블랙', '화이트', '네이비'];
  }}
  List<String> get productCategoryList { switch (language) {
    case AppLanguage.english: return ['Singlet Set', 'Singlet', 'Leggings', 'Tights', 'Shorts', 'Top', 'Other'];
    case AppLanguage.japanese: return ['シングレットセット', 'シングレット', 'レギンス', 'タイツ', 'ショーツ', 'トップス', 'その他'];
    case AppLanguage.chinese: return ['背心套装', '背心', '紧身裤', '打底裤', '短裤', '上衣', '其他'];
    case AppLanguage.mongolian: return ['Сингэлет сет', 'Сингэлет', 'Легинс', 'Колгот', 'Шорт', 'Топ', 'Бусад'];
    default: return ['싱글렛세트', '싱글렛', '레깅스', '타이즈', '반바지', '상의', '기타'];
  }}
  String get defaultCategoryValue { switch (language) {
    case AppLanguage.english: return 'Singlet Set';
    case AppLanguage.japanese: return 'シングレットセット';
    case AppLanguage.chinese: return '背心套装';
    case AppLanguage.mongolian: return 'Сингэлет сет';
    default: return '싱글렛세트';
  }}

  // ── product_detail_screen 섹션 카드 번역 키 ──────────────────
  String get feat1Title { switch (language) {
    case AppLanguage.english: return 'Ultra Light 80g / 90g';
    case AppLanguage.japanese: return '超軽量 80g / 90g';
    case AppLanguage.chinese: return '超轻量 80g / 90g';
    case AppLanguage.mongolian: return 'Маш хөнгөн 80г / 90г';
    default: return '초경량 80g / 90g';
  }}
  String get feat1Desc { switch (language) {
    case AppLanguage.english: return 'Virtually weightless design\nFeel the difference the moment it touches your skin';
    case AppLanguage.japanese: return '着ているのを忘れる超軽量設計\n肌に触れた瞬間、違いを感じられます';
    case AppLanguage.chinese: return '犹如不存在的超轻量设计\n接触皮肤的瞬间即可感受到差异';
    case AppLanguage.mongolian: return 'Өмссөнөө мартах хөнгөн загвар\nАрьстай хүрэх мөчид ялгааг мэдэрнэ';
    default: return '착용감이 없는 듯한 초경량 설계\n피부에 닿는 순간 차이를 느낄 수 있습니다';
  }}
  String get feat2Title { switch (language) {
    case AppLanguage.english: return 'Seamless / Sewn';
    case AppLanguage.japanese: return 'シームレス (無縫製) / 縫製';
    case AppLanguage.chinese: return '无缝 / 缝制';
    case AppLanguage.mongolian: return 'Оёдолгүй / Оёдолтой';
    default: return '심리스 (무봉제) / 봉제';
  }}
  String get feat2Desc { switch (language) {
    case AppLanguage.english: return 'Zero-friction seamless design\nConventional sewn option also available';
    case AppLanguage.japanese: return '肌摩擦ゼロのシームレス設計\n一般縫製方式も選択可能です';
    case AppLanguage.chinese: return '零摩擦无缝设计\n也可选择传统缝制方式';
    case AppLanguage.mongolian: return 'Арьсны үрэлт тэгтэй оёдолгүй загвар\nЭнгийн оёдолтой хувилбарыг ч сонгож болно';
    default: return '피부 마찰 제로의 심리스(무봉제) 설계\n일반 봉제 방식도 선택 가능합니다';
  }}
  String get feat3Title { switch (language) {
    case AppLanguage.english: return 'A-Type Racerback';
    case AppLanguage.japanese: return 'Aタイプ レーサーバック';
    case AppLanguage.chinese: return 'A型背心';
    case AppLanguage.mongolian: return 'A-Хэлбэрийн рэйсербак';
    default: return 'A타입 레이서백';
  }}
  String get feat3Desc { switch (language) {
    case AppLanguage.english: return 'A-back design that maximizes movement\nExercise freely without shoulder strain';
    case AppLanguage.japanese: return '動きを最大化するA型背板デザイン\n肩こりなく自由に運動できます';
    case AppLanguage.chinese: return '最大化动作范围的A型背部设计\n无肩膀紧绷，自由运动';
    case AppLanguage.mongolian: return 'Хөдөлгөөнийг нэмэгдүүлэх A хэлбэрийн нуруун загвар\nМөрний татарсан мэдрэмжгүйгээр чөлөөтэй хөдөл';
    default: return '움직임을 극대화하는 A형 등판 디자인\n어깨 결림 없이 자유롭게 운동하세요';
  }}
  String get feat4Title { switch (language) {
    case AppLanguage.english: return 'Elite Athlete Wear';
    case AppLanguage.japanese: return 'エリート選手着用';
    case AppLanguage.chinese: return '精英运动员着装';
    case AppLanguage.mongolian: return 'Элит тамирчны хувцас';
    default: return '엘리트 선수 착용';
  }}
  String get feat4Desc { switch (language) {
    case AppLanguage.english: return 'Certified wearable at domestic & international competitions\nPerformance wear chosen by professional athletes';
    case AppLanguage.japanese: return '国内外大会公認着用実績\nプロ選手が選ぶパフォーマンスウェア';
    case AppLanguage.chinese: return '国内外比赛认证着装经验\n专业运动员选择的运动服';
    case AppLanguage.mongolian: return 'Дотоод, гадаадын тэмцээнд баталгаажсан хувцас\nМэргэжлийн тамирчдын сонгосон хувцас';
    default: return '국내외 대회 공인 착용 경험\n프로 선수들이 선택한 퍼포먼스 웨어';
  }}
  String get badgeSeamless { switch (language) {
    case AppLanguage.english: return 'Seamless';
    case AppLanguage.japanese: return 'シームレス';
    case AppLanguage.chinese: return '无缝';
    case AppLanguage.mongolian: return 'Оёдолгүй';
    default: return '심리스';
  }}
  String get badgeFastAbsorb { switch (language) {
    case AppLanguage.english: return 'Fast Absorb';
    case AppLanguage.japanese: return '素早い吸収';
    case AppLanguage.chinese: return '快速吸汗';
    case AppLanguage.mongolian: return 'Хурдан шингэлт';
    default: return '빠른 흡수';
  }}
  String get badgeFastDry { switch (language) {
    case AppLanguage.english: return 'Fast Dry';
    case AppLanguage.japanese: return '速乾';
    case AppLanguage.chinese: return '速干';
    case AppLanguage.mongolian: return 'Хурдан хатаалт';
    default: return '빠른 건조';
  }}
  String get badgeUltraLight { switch (language) {
    case AppLanguage.english: return 'Ultra Light';
    case AppLanguage.japanese: return '超軽量';
    case AppLanguage.chinese: return '超轻量';
    case AppLanguage.mongolian: return 'Маш хөнгөн';
    default: return '초경량';
  }}
  String get badgeElite { switch (language) {
    case AppLanguage.english: return 'Elite';
    case AppLanguage.japanese: return 'エリート';
    case AppLanguage.chinese: return '精英';
    case AppLanguage.mongolian: return 'Элит';
    default: return '엘리트';
  }}
  String get techAbsorbTitle { switch (language) {
    case AppLanguage.english: return 'Fast Absorption Tech';
    case AppLanguage.japanese: return '素早い吸収技術';
    case AppLanguage.chinese: return '快速吸汗技术';
    case AppLanguage.mongolian: return 'Хурдан шингэлтийн технологи';
    default: return '빠른 흡수 기술';
  }}
  String get techAbsorbDesc { switch (language) {
    case AppLanguage.english: return 'Special fabric structure using capillary action\nInstantly absorbs sweat to maintain comfort';
    case AppLanguage.japanese: return '毛細管現象を活用した特殊生地構造で\n汗を即座に吸収して快適さを保ちます';
    case AppLanguage.chinese: return '利用毛细管现象的特殊面料结构\n即时吸汗，保持舒适感';
    case AppLanguage.mongolian: return 'Хялгасан судасны үзэгдлийг ашигласан тусгай даавуун бүтэц\nХөлсийг нэн даруй шингээж тавтайг хадгална';
    default: return '모세관 현상을 활용한 특수 원단 구조로\n땀을 즉각적으로 흡수하여 쾌적함을 유지합니다';
  }}
  String get techDryTitle { switch (language) {
    case AppLanguage.english: return 'Fast Drying Tech';
    case AppLanguage.japanese: return '速乾技術';
    case AppLanguage.chinese: return '速干技术';
    case AppLanguage.mongolian: return 'Хурдан хатаалтын технологи';
    default: return '빠른 건조 기술';
  }}
  String get techDryDesc { switch (language) {
    case AppLanguage.english: return 'Disperses absorbed moisture to the fabric surface\n3x faster drying speed than regular cotton';
    case AppLanguage.japanese: return '吸収した水分を生地表面に分散させ\n一般綿素材の3倍の乾燥速度を誇ります';
    case AppLanguage.chinese: return '将吸收的水分分散到面料表面\n干燥速度比普通棉质快3倍';
    case AppLanguage.mongolian: return 'Шингэсэн чийгийг даавуун гадаргуу руу тараана\nЭнгийн даавуунаас 3 дахин хурдан хатдаг';
    default: return '흡수된 수분을 원단 표면으로 분산시켜\n일반 면 소재 대비 3배 빠른 건조 속도를 자랑합니다';
  }}
  String get singletTypeA { switch (language) {
    case AppLanguage.english: return 'A-Type';
    case AppLanguage.japanese: return 'Aタイプ';
    case AppLanguage.chinese: return 'A型';
    case AppLanguage.mongolian: return 'A хэлбэр';
    default: return 'A타입';
  }}
  String get singletTypeADesc { switch (language) {
    case AppLanguage.english: return 'Racerback';
    case AppLanguage.japanese: return 'レーサーバック';
    case AppLanguage.chinese: return '竞速背';
    case AppLanguage.mongolian: return 'Рэйсербак';
    default: return '레이서백';
  }}
  String get singletTypeB { switch (language) {
    case AppLanguage.english: return 'B-Type';
    case AppLanguage.japanese: return 'Bタイプ';
    case AppLanguage.chinese: return 'B型';
    case AppLanguage.mongolian: return 'B хэлбэр';
    default: return 'B타입';
  }}
  String get singletTypeBDesc { switch (language) {
    case AppLanguage.english: return 'Scoop Neck';
    case AppLanguage.japanese: return 'スクープネック';
    case AppLanguage.chinese: return '圆领';
    case AppLanguage.mongolian: return 'Дугуй зах';
    default: return '스쿱넥';
  }}

  // 섬유 혼용율 테이블 데이터
  List<List<String>> get fiberTableData { switch (language) {
    case AppLanguage.english: return [
      ['Singlet · Round Tee', 'Polyester 92%', 'Lycra 8%'],
      ['Golgi Tights', 'Nylon 75%', 'Lycra 25%'],
      ['Crop Top · Triangle · One-Piece\n(Bright/Pearl)', 'Polyester 80%', 'Creora 20%'],
      ['Crop Top · Triangle · One-Piece\n(Aerobright/Pearl)', 'Polyester 78%', 'Creora 22%'],
    ];
    case AppLanguage.japanese: return [
      ['シングレット・ラウンドT', 'ポリエステル 92%', 'ライクラ 8%'],
      ['ゴルジタイツ', 'ナイロン 75%', 'ライクラ 25%'],
      ['クロップトップ・三角・ワンピース\n(ブライト/パール)', 'ポリエステル 80%', 'クレオラ 20%'],
      ['クロップトップ・三角・ワンピース\n(エアロブライト/パール)', 'ポリエステル 78%', 'クレオラ 22%'],
    ];
    case AppLanguage.chinese: return [
      ['背心·圆领T恤', '聚酯纤维 92%', '莱卡 8%'],
      ['罗纹紧身裤', '尼龙 75%', '莱卡 25%'],
      ['短款·三角·连体裤\n(亮色/珍珠)', '聚酯纤维 80%', '可娅 20%'],
      ['短款·三角·连体裤\n(超亮/珍珠)', '聚酯纤维 78%', '可娅 22%'],
    ];
    case AppLanguage.mongolian: return [
      ['Сингэлет · Дугуй захтай', 'Полиэстер 92%', 'Лайкра 8%'],
      ['Голжи хачиг', 'Нейлон 75%', 'Лайкра 25%'],
      ['Кроп топ · Гурвалжин · Нэг хэсэг\n(тод/сувд)', 'Полиэстер 80%', 'Creora 20%'],
      ['Кроп топ · Гурвалжин · Нэг хэсэг\n(Aerobright/сувд)', 'Полиэстер 78%', 'Creora 22%'],
    ];
    default: return [
      ['싱글렛 · 라운드티', '폴리에스터 92%', '라이크라 8%'],
      ['골지 타이즈', '나일론 75%', '라이크라 25%'],
      ['크롭탑 · 삼각 · 원피스\n(브라이트/펄)', '폴리에스터 80%', '크레오라 20%'],
      ['크롭탑 · 삼각 · 원피스\n(에어로브라이트/펄)', '폴리에스터 78%', '크레오라 22%'],
    ];
  }}

  // ── 추가제작 배송 안내 ──────────────────────────────────────────
  String applyLengthToAll(String length) { switch (language) {
    case AppLanguage.english:  return '"$length" Apply to all members';
    case AppLanguage.japanese: return '"$length" 全員に一括適用';
    case AppLanguage.chinese:  return '"$length" 批量应用于所有成员';
    case AppLanguage.mongolian:return '"$length" Бүх гишүүнд нэгэн зэрэг хэрэглэх';
    default: return '"$length" 전체 인원 일괄 적용';
  }}

  // ── group_order_form 섹션 헤더 번역 키 ─────────────────────────
  String get groupFormProductLabel { switch (language) {
    case AppLanguage.english:  return 'Selected Product Design';
    case AppLanguage.japanese: return '選択商品デザイン';
    case AppLanguage.chinese:  return '已选商品设计';
    case AppLanguage.mongolian:return 'Сонгосон бүтээгдэхүүний дизайн';
    default: return '선택 상품 디자인';
  }}
  String get waistbandOption { switch (language) {
    case AppLanguage.english:  return 'Waistband Option';
    case AppLanguage.japanese: return 'ウエストバンドオプション';
    case AppLanguage.chinese:  return '腰带选项';
    case AppLanguage.mongolian:return 'Бүсний сонголт';
    default: return '허리밴드 옵션';
  }}
  String get personInfoTitle { switch (language) {
    case AppLanguage.english:  return 'Individual Member Info';
    case AppLanguage.japanese: return '個人情報入力';
    case AppLanguage.chinese:  return '个人信息输入';
    case AppLanguage.mongolian:return 'Гишүүн тус бүрийн мэдээлэл';
    default: return '인원별 정보 입력';
  }}
  String get basicInfoTitle { switch (language) {
    case AppLanguage.english:  return 'Basic Information';
    case AppLanguage.japanese: return '基本情報';
    case AppLanguage.chinese:  return '基本信息';
    case AppLanguage.mongolian:return 'Үндсэн мэдээлэл';
    default: return '기본 정보';
  }}
  String get refImageTitle { switch (language) {
    case AppLanguage.english:  return 'Bottom Reference Image';
    case AppLanguage.japanese: return 'ボトム参考画像';
    case AppLanguage.chinese:  return '下装参考图片';
    case AppLanguage.mongolian:return 'Доод хэсгийн лавлах зураг';
    default: return '하의 참조 이미지';
  }}
  String get memoTitle { switch (language) {
    case AppLanguage.english:  return 'Special Requests';
    case AppLanguage.japanese: return 'ご要望';
    case AppLanguage.chinese:  return '备注/特殊要求';
    case AppLanguage.mongolian:return 'Тусгай хүсэлт';
    default: return '요청 사항';
  }}

  // ── PC 마이페이지 전용 번역 키 ─────────────────────────────────
  String get userNameSuffix { switch (language) {
    case AppLanguage.english:  return '';
    case AppLanguage.japanese: return 'さん';
    case AppLanguage.chinese:  return '您好';
    case AppLanguage.mongolian:return '';
    default: return '님';
  }}
  String get refresh { switch (language) {
    case AppLanguage.english:  return 'Refresh';
    case AppLanguage.japanese: return '更新';
    case AppLanguage.chinese:  return '刷新';
    case AppLanguage.mongolian:return 'Шинэчлэх';
    default: return '새로고침';
  }}  String get additionalShipNote { switch (language) {
    case AppLanguage.english:  return '🚚 Additional items are shipped separately';
    case AppLanguage.japanese: return '🚚 追加制作品は別途配送されます';
    case AppLanguage.chinese:  return '🚚 追加生产品将单独配送';
    case AppLanguage.mongolian:return '🚚 Нэмэлт бараа тусдаа хүргэгдэнэ';
    default: return '🚚 추가제작 물품은 별도 배송됩니다';
  }}

  // ── 기성품 배송 안내 ──────────────────────────────────────────
  String get readyMadeDeliveryNote { switch (language) {
    case AppLanguage.english:  return '🚚 Delivery: 2–3 days (may vary)';
    case AppLanguage.japanese: return '🚚 配送：2〜3日（変動あり）';
    case AppLanguage.chinese:  return '🚚 配送：2-3天（可能有变动）';
    case AppLanguage.mongolian:return '🚚 Хүргэлт: 2-3 хоног (өөрчлөгдөж болно)';
    default: return '🚚 배송 안내: 2~3일 (변동 가능)';
  }}

  // ── 기성품 소재 안내 ──────────────────────────────────────────
  String get readyMadeFabricNote { switch (language) {
    case AppLanguage.english:  return 'Ready-made: standard (sewn) fabric only';
    case AppLanguage.japanese: return '既製品：一般（縫製）素材のみ対応';
    case AppLanguage.chinese:  return '现货：仅支持普通（缝制）面料';
    case AppLanguage.mongolian:return 'Бэлэн бараа: зөвхөн энгийн (оёдол) даавуу';
    default: return '기성품: 일반(봉제) 소재만 가능';
  }}

  // ── 소재 선택 섹션 타이틀 ──────────────────────────────────────
  String get fabricSelectTitle { switch (language) {
    case AppLanguage.english:  return '🧵 Fabric & Weight';
    case AppLanguage.japanese: return '🧵 素材・重量';
    case AppLanguage.chinese:  return '🧵 面料与重量';
    case AppLanguage.mongolian:return '🧵 Даавуу ба жин';
    default: return '🧵 소재 · 무게';
  }}

  // ── 무게 90g 설명 ──────────────────────────────────────────────
  String get weight90gDesc { switch (language) {
    case AppLanguage.english:  return 'Slightly heavier, more durable';
    case AppLanguage.japanese: return 'やや重め・耐久性アップ';
    case AppLanguage.chinese:  return '稍重，耐用性更强';
    case AppLanguage.mongolian:return 'Арай хүнд, илүү тэсвэртэй';
    default: return '약간 무거움 · 내구성 향상';
  }}

  // ── 기장 선택 카테고리 안내 ──────────────────────────────────────
  String get bottomLengthCategoryNote { switch (language) {
    case AppLanguage.english:  return '※ Bottom length selection available for Singlet, Tights, and Singlet Set only.';
    case AppLanguage.japanese: return '※ 丈選択はシングレット・タイツ・シングレットセットのみ対象です。';
    case AppLanguage.chinese:  return '※ 裤长选择仅适用于连体衣、紧身裤及连体套装。';
    case AppLanguage.mongolian:return '※ Уртын сонголт нь зөвхөн сингэлет, хачиг, сингэлет сетэд хамаарна.';
    default: return '※ 기장 선택은 싱글렛·타이즈·싱글렛 세트에만 해당됩니다.';
  }}

  // ── 디자인 수정 버튼 (주문내역) ──────────────────────────────────
  String get designEditBtn { switch (language) {
    case AppLanguage.english:  return 'Design Edit';
    case AppLanguage.japanese: return 'デザイン修正';
    case AppLanguage.chinese:  return '设计修改';
    case AppLanguage.mongolian:return 'Дизайн засах';
    default: return '디자인 수정';
  }}

  // ── 디자인 수정 횟수 제한 안내 ──────────────────────────────────
  String get designEditLimitNote { switch (language) {
    case AppLanguage.english:  return 'Design edits limited to 2 times.';
    case AppLanguage.japanese: return 'デザイン修正は2回まで可能です。';
    case AppLanguage.chinese:  return '设计修改最多2次。';
    case AppLanguage.mongolian:return 'Дизайн засалт 2 удаа хязгаарлагдана.';
    default: return '디자인 수정은 최대 2회까지 가능합니다.';
  }}

  // ── 3일 내 디자인 확정 안내 ──────────────────────────────────────
  String get sevenDayDesignFinalNote { switch (language) {
    case AppLanguage.english:  return '⚠️ If no revision request is made within 3 days per round, the design is finalized and production begins.';
    case AppLanguage.japanese: return '⚠️ 修正1回につき3日以内に修正依頼がない場合、デザインが確定し製作が開始されます。';
    case AppLanguage.chinese:  return '⚠️ 每次修改3天内未提出修改请求，设计将自动确认并开始制作。';
    case AppLanguage.mongolian:return '⚠️ Нэг засвар тутамд 3 хоногийн дотор засах хүсэлт ирэхгүй бол дизайн баталгаажиж үйлдвэрлэл эхэлнэ.';
    default: return '⚠️ 디자인 수정은 1회당 3일 이내 수정 요청이 없으면 확정되어 제작이 시작됩니다.';
  }}

  // ── 추가제작 주문번호 필수 안내 ──────────────────────────────────
  String get additionalOrderNumRequired { switch (language) {
    case AppLanguage.english:  return '* Order number is required for additional production.';
    case AppLanguage.japanese: return '* 追加制作には注文番号が必要です。';
    case AppLanguage.chinese:  return '* 追加生产需要提供订单号。';
    case AppLanguage.mongolian:return '* Нэмэлт үйлдвэрлэлд захиалгын дугаар шаардлагатай.';
    default: return '* 추가제작에는 기존 주문번호가 필요합니다.';
  }}

  // ── 사이즈 변경 입력 안내 ──────────────────────────────────────
  String get additionalSizeChangeHint { switch (language) {
    case AppLanguage.english:  return 'Enter changed size (e.g. XS→S, XL×2)';
    case AppLanguage.japanese: return '変更サイズを入力 (例: XS→S, XL×2)';
    case AppLanguage.chinese:  return '输入变更尺码（例：XS→S，XL×2）';
    case AppLanguage.mongolian:return 'Өөрчлөгдсөн хэмжээ оруулах (жш: XS→S, XL×2)';
    default: return '변경 사이즈 입력 (예: XS→S, XL×2)';
  }}

  // ── 추가제작 사이즈 변경 섹션 ──────────────────────────────────
  String get additionalSizeChangeLabel { switch (language) {
    case AppLanguage.english:  return 'Size Change (optional)';
    case AppLanguage.japanese: return 'サイズ変更（任意）';
    case AppLanguage.chinese:  return '尺码变更（可选）';
    case AppLanguage.mongolian:return 'Хэмжээний өөрчлөлт (заавал биш)';
    default: return '사이즈 변경 (선택)';
  }}

}