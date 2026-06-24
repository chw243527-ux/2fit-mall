#!/usr/bin/env python3
"""나머지 미번역 파일 일괄 처리 스크립트"""
import re, hashlib
from pathlib import Path

def make_key(text: str) -> str:
    clean = re.sub(r'[^가-힣a-zA-Z0-9]', '_', text.strip())
    clean = re.sub(r'_+', '_', clean).strip('_')
    if len(clean) > 40:
        h = hashlib.md5(text.encode()).hexdigest()[:6]
        clean = clean[:34] + '_' + h
    return clean or 'text'

def w(text: str) -> str:
    key = make_key(text)
    safe = text.replace("'", "\\'")
    return f"context.loc.t('{key}', '{safe}')"

def process(path: str, replacements: list):
    p = Path(path)
    if not p.exists():
        print(f"  [SKIP] {path}")
        return
    src = p.read_text(encoding='utf-8')
    orig = src
    count = 0
    for old, new in replacements:
        if not old or not new or old == new:
            continue
        if old in src:
            n = src.count(old)
            src = src.replace(old, new)
            count += n
        else:
            print(f"  [!] NOT FOUND: {old[:70]!r}")
    if src != orig:
        p.write_text(src, encoding='utf-8')
        print(f"✓ {path} ({count} replacements)")
    else:
        print(f"  (no changes) {path}")


# ─── group_order_test_screen.dart ───────────────────────────────────────────
process('lib/screens/orders/group_order_test_screen.dart', [
    ("_sectionTitle('빠른 프리셋', Icons.flash_on_rounded)",
     f"_sectionTitle({w('빠른 프리셋')}, Icons.flash_on_rounded)"),
    ("_sectionTitle('커스텀 주문 생성', Icons.tune_rounded)",
     f"_sectionTitle({w('커스텀 주문 생성')}, Icons.tune_rounded)"),
    ("_sectionTitle('결과 로그', Icons.list_alt_rounded)",
     f"_sectionTitle({w('결과 로그')}, Icons.list_alt_rounded)"),
    (
        "'• 생성된 주문은 로그인 유저 ID로 저장 → 마이페이지에서 즉시 확인 가능\\n• 기성품/단체주문 둘 다 생성 가능 · 상태(배송중/완료 등) 선택 가능\\n• 주문번호 TEST_GRP_ / TEST_PERS_ 로 시작 → 상단 🗑 버튼으로 일괄 삭제',",
        "context.loc.t('생성된_주문_로그인_유저_ID_마이페이지_확인', '• 생성된 주문은 로그인 유저 ID로 저장 → 마이페이지에서 즉시 확인 가능\\n• 기성품/단체주문 둘 다 생성 가능 · 상태(배송중/완료 등) 선택 가능\\n• 주문번호 TEST_GRP_ / TEST_PERS_ 로 시작 → 상단 🗑 버튼으로 일괄 삭제'),"
    ),
    ("_chip(p.orderType == 'personal' ? '기성품' : '단체', p.color)",
     f"_chip(p.orderType == 'personal' ? {w('기성품')} : {w('단체')}, p.color)"),
    ("_toggleBtn('기성품 (personal)', _customOrderType == 'personal',",
     f"_toggleBtn({w('기성품 (personal)')}, _customOrderType == 'personal',"),
    ("_toggleBtn('단체주문 (group)', _customOrderType == 'group',",
     f"_toggleBtn({w('단체주문 (group)')}, _customOrderType == 'group',"),
    ("Expanded(child: _field('팀명 / 구매자명', _teamNameCtrl)),",
     f"Expanded(child: _field({w('팀명 / 구매자명')}, _teamNameCtrl)),"),
    ("Expanded(child: _field('담당자', _managerCtrl)),",
     f"Expanded(child: _field({w('담당자')}, _managerCtrl)),"),
    ("Expanded(child: _field('연락처', _phoneCtrl, keyboard: TextInputType.phone)),",
     f"Expanded(child: _field({w('연락처')}, _phoneCtrl, keyboard: TextInputType.phone)),"),
    ("Expanded(child: _field('이메일', _emailCtrl, keyboard: TextInputType.emailAddress)),",
     f"Expanded(child: _field({w('이메일')}, _emailCtrl, keyboard: TextInputType.emailAddress)),"),
    ("Expanded(child: _dropdown('색상', _customColor,",
     f"Expanded(child: _dropdown({w('색상')}, _customColor,"),
    ("Expanded(child: _dropdown('결제수단', _customPay,",
     f"Expanded(child: _dropdown({w('결제수단')}, _customPay,"),
    ("_dropdown('원단', _customFabric,",
     f"_dropdown({w('원단')}, _customFabric,"),
])


# ─── privacy_policy_screen.dart ─────────────────────────────────────────────
process('lib/screens/policy/privacy_policy_screen.dart', [
    ("'제1조 (수집하는 개인정보 항목)',",
     f"{w('제1조 (수집하는 개인정보 항목)')},"),
    (
        "'2FIT MALL은 회원가입 및 서비스 이용을 위해 아래와 같은 개인정보를 수집합니다.\\n\\n'\n                '• 필수항목: 이름, 이메일 주소, 비밀번호, 휴대폰 번호\\n'\n                '• 선택항목: 마케팅 수신 동의\\n'\n                '• 자동수집: 서비스 이용기록, 접속 로그, 쿠키, IP 주소',",
        "context.loc.t('개인정보_수집_항목_내용', '2FIT MALL은 회원가입 및 서비스 이용을 위해 아래와 같은 개인정보를 수집합니다.\\n\\n• 필수항목: 이름, 이메일 주소, 비밀번호, 휴대폰 번호\\n• 선택항목: 마케팅 수신 동의\\n• 자동수집: 서비스 이용기록, 접속 로그, 쿠키, IP 주소'),"
    ),
    ("'제2조 (개인정보의 수집 및 이용목적)',",
     f"{w('제2조 (개인정보의 수집 및 이용목적)')},"),
    (
        "'• 회원가입 및 본인 확인\\n'\n                '• 서비스 제공 및 계약 이행\\n'\n                '• 주문/배송/결제 처리\\n'\n                '• 주문 확인·배송 안내 카카오 알림톡 발송\\n'\n                '• 고객 문의 및 불만 처리\\n'\n                '• 마케팅 및 광고 활용 (동의 시)',",
        "context.loc.t('개인정보_이용목적_내용', '• 회원가입 및 본인 확인\\n• 서비스 제공 및 계약 이행\\n• 주문/배송/결제 처리\\n• 주문 확인·배송 안내 카카오 알림톡 발송\\n• 고객 문의 및 불만 처리\\n• 마케팅 및 광고 활용 (동의 시)'),"
    ),
    ("'제3조 (개인정보 보유 및 이용기간)',",
     f"{w('제3조 (개인정보 보유 및 이용기간)')},"),
    (
        "'회원 탈퇴 시 즉시 삭제합니다. 단, 관련 법령에 따라 아래 기간 동안 보관합니다.\\n\\n'\n                '• 계약/청약철회 기록: 5년 (전자상거래법)\\n'\n                '• 소비자 불만/분쟁처리 기록: 3년\\n'\n                '• 접속 로그: 3개월 (통신비밀보호법)',",
        "context.loc.t('개인정보_보유기간_내용', '회원 탈퇴 시 즉시 삭제합니다. 단, 관련 법령에 따라 아래 기간 동안 보관합니다.\\n\\n• 계약/청약철회 기록: 5년 (전자상거래법)\\n• 소비자 불만/분쟁처리 기록: 3년\\n• 접속 로그: 3개월 (통신비밀보호법)'),"
    ),
    ("'제4조 (개인정보 제3자 제공)',",
     f"{w('제4조 (개인정보 제3자 제공)')},"),
    (
        "'2FIT MALL은 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. '\n                '단, 아래의 경우 최소한의 정보를 제공합니다.\\n\\n'\n                '• 배송 처리: 택배사에 수령인·주소·연락처 제공\\n'\n                '• 결제 처리: 토스페이먼츠에 결제 정보 제공\\n'\n                '• 알림톡 발송: SOLAPI를 통해 주문·배송 정보 발송',",
        "context.loc.t('개인정보_제3자_제공_내용', '2FIT MALL은 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 단, 아래의 경우 최소한의 정보를 제공합니다.\\n\\n• 배송 처리: 택배사에 수령인·주소·연락처 제공\\n• 결제 처리: 토스페이먼츠에 결제 정보 제공\\n• 알림톡 발송: SOLAPI를 통해 주문·배송 정보 발송'),"
    ),
    ("'제5조 (개인정보처리 위탁)',",
     f"{w('제5조 (개인정보처리 위탁)')},"),
    (
        "'• Firebase (Google): 회원 인증 및 데이터 저장\\n'\n                '• 토스페이먼츠: 결제 처리\\n'\n                '• SOLAPI: 카카오 알림톡 발송 (주문확인·배송안내)\\n'\n                '• EmailJS: 이메일 발송 서비스\\n'\n                '• Cloudflare: 웹 서비스 호스팅\\n'\n                '• 택배사: 배송 처리',",
        "context.loc.t('개인정보_위탁_내용', '• Firebase (Google): 회원 인증 및 데이터 저장\\n• 토스페이먼츠: 결제 처리\\n• SOLAPI: 카카오 알림톡 발송 (주문확인·배송안내)\\n• EmailJS: 이메일 발송 서비스\\n• Cloudflare: 웹 서비스 호스팅\\n• 택배사: 배송 처리'),"
    ),
    ("'제6조 (이용자의 권리)',",
     f"{w('제6조 (이용자의 권리)')},"),
    (
        "'이용자는 언제든지 아래 권리를 행사할 수 있습니다.\\n\\n'\n                '• 개인정보 열람 요청\\n'\n                '• 오류 정정 요청\\n'\n                '• 삭제 요청 (회원 탈퇴)\\n'\n                '• 처리 정지 요청\\n\\n'\n                '문의: chw243527@gmail.com',",
        "context.loc.t('개인정보_이용자_권리_내용', '이용자는 언제든지 아래 권리를 행사할 수 있습니다.\\n\\n• 개인정보 열람 요청\\n• 오류 정정 요청\\n• 삭제 요청 (회원 탈퇴)\\n• 처리 정지 요청\\n\\n문의: chw243527@gmail.com'),"
    ),
    ("'제7조 (개인정보 보호책임자)',",
     f"{w('제7조 (개인정보 보호책임자)')},"),
    (
        "'• 회사명: 주식회사 2FIT Korea\\n'\n                '• 대표자: 최혜원\\n'\n                '• 사업장 주소: 전북 남원시 오들1길 97, 205-303\\n'\n                '• 책임자 이메일: chw243527@gmail.com\\n'\n                '• 고객센터: 010-7227-6914\\n\\n'\n                '본 방침은 2025년 3월 21일부터 적용됩니다.',",
        "context.loc.t('개인정보_보호책임자_내용', '• 회사명: 주식회사 2FIT Korea\\n• 대표자: 최혜원\\n• 사업장 주소: 전북 남원시 오들1길 97, 205-303\\n• 책임자 이메일: chw243527@gmail.com\\n• 고객센터: 010-7227-6914\\n\\n본 방침은 2025년 3월 21일부터 적용됩니다.'),"
    ),
    ("'제8조 (쿠키 및 자동수집 장치)',",
     f"{w('제8조 (쿠키 및 자동수집 장치)')},"),
    (
        "'서비스 이용 편의를 위해 쿠키를 사용할 수 있으며, 브라우저 설정을 통해 거부할 수 있습니다. 쿠키 거부 시 일부 서비스 이용이 제한될 수 있습니다.',",
        "context.loc.t('서비스_이용_편의_쿠키_사용_브라우저_거부_제한', '서비스 이용 편의를 위해 쿠키를 사용할 수 있으며, 브라우저 설정을 통해 거부할 수 있습니다. 쿠키 거부 시 일부 서비스 이용이 제한될 수 있습니다.'),"
    ),
])


# ─── terms_of_service_screen.dart ───────────────────────────────────────────
process('lib/screens/policy/terms_of_service_screen.dart', [
    ("_InfoRow('회사명', '주식회사 2FIT Korea'),",
     f"_InfoRow({w('회사명')}, '주식회사 2FIT Korea'),"),
    ("_InfoRow('대표자', '최혜원'),",
     f"_InfoRow({w('대표자')}, '최혜원'),"),
    ("_InfoRow('사업장 주소', '전북 남원시 오들1길 97, 205-303'),",
     f"_InfoRow({w('사업장 주소')}, '전북 남원시 오들1길 97, 205-303'),"),
    ("_InfoRow('사업자등록번호', '787-19-02539'),",
     f"_InfoRow({w('사업자등록번호')}, '787-19-02539'),"),
    ("_InfoRow('통신판매업신고', '심사 중'),",
     f"_InfoRow({w('통신판매업신고')}, {w('심사 중')}),"),
    ("_InfoRow('고객센터', '010-7227-6914'),",
     f"_InfoRow({w('고객센터')}, '010-7227-6914'),"),
    ("_InfoRow('이메일', 'chw243527@gmail.com'),",
     f"_InfoRow({w('이메일')}, 'chw243527@gmail.com'),"),
    ("_InfoRow('운영시간', '평일 10:00 ~ 18:00 (점심 12:00~14:00)'),",
     f"_InfoRow({w('운영시간')}, {w('평일 10:00 ~ 18:00 (점심 12:00~14:00)')}),"),
    ("'제1조 (목적)',",
     f"{w('제1조 (목적)')},"),
    (
        "'본 약관은 주식회사 2FIT Korea(이하 \"회사\")가 운영하는 2FIT MALL 쇼핑몰 서비스의 이용조건 및 절차, 회사와 이용자 간의 권리·의무 관계를 규정함을 목적으로 합니다.',",
        "context.loc.t('이용약관_제1조_목적_내용', '본 약관은 주식회사 2FIT Korea(이하 \"회사\")가 운영하는 2FIT MALL 쇼핑몰 서비스의 이용조건 및 절차, 회사와 이용자 간의 권리·의무 관계를 규정함을 목적으로 합니다.'),"
    ),
    ("'제2조 (회원가입)',",
     f"{w('제2조 (회원가입)')},"),
    (
        "'• 만 14세 이상 이용 가능합니다.\\n'\n                '• 타인의 정보 도용 가입은 금지됩니다.\\n'\n                '• 허위 정보 제공 시 서비스 이용이 제한될 수 있습니다.',",
        "context.loc.t('이용약관_제2조_내용', '• 만 14세 이상 이용 가능합니다.\\n• 타인의 정보 도용 가입은 금지됩니다.\\n• 허위 정보 제공 시 서비스 이용이 제한될 수 있습니다.'),"
    ),
    ("'제3조 (서비스 이용)',",
     f"{w('제3조 (서비스 이용)')},"),
    (
        "'• 서비스는 연중무휴 24시간 제공을 원칙으로 합니다.\\n'\n                '• 시스템 정기점검, 천재지변 등 불가피한 경우 서비스가 중단될 수 있습니다.\\n'\n                '• 주문 완료 후 카카오 알림톡으로 주문확인·배송 안내를 발송합니다.',",
        "context.loc.t('이용약관_제3조_내용', '• 서비스는 연중무휴 24시간 제공을 원칙으로 합니다.\\n• 시스템 정기점검, 천재지변 등 불가피한 경우 서비스가 중단될 수 있습니다.\\n• 주문 완료 후 카카오 알림톡으로 주문확인·배송 안내를 발송합니다.'),"
    ),
    ("'제4조 (구매 및 결제)',",
     f"{w('제4조 (구매 및 결제)')},"),
    (
        "'• 결제 수단: 신용카드, 가상계좌, 계좌이체, 간편결제 (토스페이먼츠)\\n'\n                '• 주문 완료 후 결제 확인 시 배송이 시작됩니다.\\n'\n                '• 단순 변심에 의한 반품은 수령 후 7일 이내 가능합니다.\\n'\n                '• 상품 하자의 경우 수령 후 3개월 이내 교환/환불이 가능합니다.',",
        "context.loc.t('이용약관_제4조_내용', '• 결제 수단: 신용카드, 가상계좌, 계좌이체, 간편결제 (토스페이먼츠)\\n• 주문 완료 후 결제 확인 시 배송이 시작됩니다.\\n• 단순 변심에 의한 반품은 수령 후 7일 이내 가능합니다.\\n• 상품 하자의 경우 수령 후 3개월 이내 교환/환불이 가능합니다.'),"
    ),
    ("'제5조 (교환 및 환불)',",
     f"{w('제5조 (교환 및 환불)')},"),
    (
        "'• 교환/환불은 수령 후 7일 이내 신청 가능합니다.\\n'\n                '• 단체복/맞춤제작 상품은 교환·환불이 불가합니다.\\n'\n                '• 상품 불량/오배송의 경우 100% 교환 또는 환불 처리합니다.\\n'\n                '• 환불은 결제 취소 후 3~5 영업일 내 처리됩니다.\\n'\n                '• 반품 배송비는 구매자 부담이며, 상품 불량 시 회사가 부담합니다.',",
        "context.loc.t('이용약관_제5조_내용', '• 교환/환불은 수령 후 7일 이내 신청 가능합니다.\\n• 단체복/맞춤제작 상품은 교환·환불이 불가합니다.\\n• 상품 불량/오배송의 경우 100% 교환 또는 환불 처리합니다.\\n• 환불은 결제 취소 후 3~5 영업일 내 처리됩니다.\\n• 반품 배송비는 구매자 부담이며, 상품 불량 시 회사가 부담합니다.'),"
    ),
    ("'제6조 (배송)',",
     f"{w('제6조 (배송)')},"),
    (
        "'• 주문 확인 후 1~3 영업일 이내 발송합니다.\\n'\n                '• 단체복 맞춤제작은 제작 기간(7~14일)이 소요됩니다.\\n'\n                '• 배송비는 상품 페이지에 표시된 금액에 따릅니다.\\n'\n                '• 배송 시작 시 카카오 알림톡으로 운송장 번호를 안내합니다.',",
        "context.loc.t('이용약관_제6조_내용', '• 주문 확인 후 1~3 영업일 이내 발송합니다.\\n• 단체복 맞춤제작은 제작 기간(7~14일)이 소요됩니다.\\n• 배송비는 상품 페이지에 표시된 금액에 따릅니다.\\n• 배송 시작 시 카카오 알림톡으로 운송장 번호를 안내합니다.'),"
    ),
    ("'제7조 (금지행위)',",
     f"{w('제7조 (금지행위)')},"),
    (
        "'• 타인의 계정 무단 사용\\n'\n                '• 서비스 운영 방해\\n'\n                '• 허위 리뷰 작성\\n'\n                '• 불법 콘텐츠 유포',",
        "context.loc.t('이용약관_제7조_내용', '• 타인의 계정 무단 사용\\n• 서비스 운영 방해\\n• 허위 리뷰 작성\\n• 불법 콘텐츠 유포'),"
    ),
    ("'제8조 (면책조항)',",
     f"{w('제8조 (면책조항)')},"),
    (
        "'천재지변, 전쟁 등 불가항력으로 인한 서비스 중단에 대해 회사는 책임을 지지 않습니다.',",
        "context.loc.t('천재지변_전쟁_등_불가항력_서비스_중단_회사_책임', '천재지변, 전쟁 등 불가항력으로 인한 서비스 중단에 대해 회사는 책임을 지지 않습니다.'),"
    ),
    ("'제9조 (준거법 및 관할법원)',",
     f"{w('제9조 (준거법 및 관할법원)')},"),
    (
        "'본 약관은 대한민국 법률에 따라 규율되며, 서비스 이용과 관련한 분쟁은 회사 소재지 관할 법원(전주지방법원 남원지원)을 전속 관할로 합니다.',",
        "context.loc.t('이용약관_제9조_내용', '본 약관은 대한민국 법률에 따라 규율되며, 서비스 이용과 관련한 분쟁은 회사 소재지 관할 법원(전주지방법원 남원지원)을 전속 관할로 합니다.'),"
    ),
])


# ─── checkout_screen.dart ───────────────────────────────────────────────────
process('lib/screens/orders/checkout_screen.dart', [
    ("infoRow(Icons.group_work_rounded, '단체명', teamName)",
     f"infoRow(Icons.group_work_rounded, {w('단체명')}, teamName)"),
    ("infoRow(Icons.person_outline_rounded, '담당자', manager)",
     f"infoRow(Icons.person_outline_rounded, {w('담당자')}, manager)"),
    ("infoRow(Icons.phone_outlined, '연락처', phone)",
     f"infoRow(Icons.phone_outlined, {w('연락처')}, phone)"),
    ("infoRow(Icons.email_outlined, '이메일', email)",
     f"infoRow(Icons.email_outlined, {w('이메일')}, email)"),
    ("infoRow(Icons.location_on_outlined, '배송 주소', fullAddress)",
     f"infoRow(Icons.location_on_outlined, {w('배송 주소')}, fullAddress)"),
    ("infoRow(Icons.print_rounded, '인쇄타입', printLabel, color: Color(0xFF4A148C))",
     f"infoRow(Icons.print_rounded, {w('인쇄타입')}, printLabel, color: Color(0xFF4A148C))"),
    ("infoRow(Icons.palette_outlined, '색상', mainColor)",
     f"infoRow(Icons.palette_outlined, {w('색상')}, mainColor)"),
    ("infoRow(Icons.texture_rounded, '원단', fabric)",
     f"infoRow(Icons.texture_rounded, {w('원단')}, fabric)"),
    ("infoRow(Icons.style_rounded, '허리밴드', waistband)",
     f"infoRow(Icons.style_rounded, {w('허리밴드')}, waistband)"),
    ("infoRow(Icons.star_rounded, '독점 디자인', '1년간 동일 디자인/색상 미판매 · 1년 후 2FIT몰 단독 판매', color: Color(0xFF6A1B9A))",
     f"infoRow(Icons.star_rounded, {w('독점 디자인')}, {w('1년간 동일 디자인/색상 미판매 · 1년 후 2FIT몰 단독 판매')}, color: Color(0xFF6A1B9A))"),
    ("infoRow(Icons.notes_rounded, '메모', memo)",
     f"infoRow(Icons.notes_rounded, {w('메모')}, memo)"),
    (
        "final printTypeLabels = ['색상변경 (단체명 없음)', '단체명 변경 (전면)', '단체명 + 색상 변경', '디자인 + 단체명 + 색상', '디자인 + 색상 + 단체명 + 이름(후면)'];",
        f"final printTypeLabels = [{w('색상변경 (단체명 없음)')}, {w('단체명 변경 (전면)')}, {w('단체명 + 색상 변경')}, {w('디자인 + 단체명 + 색상')}, {w('디자인 + 색상 + 단체명 + 이름(후면)')}];"
    ),
    (
        "printType < printTypeLabels.length ? printTypeLabels[printType] : '알 수 없음'",
        f"printType < printTypeLabels.length ? printTypeLabels[printType] : {w('알 수 없음')}"
    ),
    ("'무통장입금 시 반드시 담당자 이름으로 입금해 주세요',",
     f"{w('무통장입금 시 반드시 담당자 이름으로 입금해 주세요')},"),
    (
        "'• 입금자명이 주문자명과 다를 경우 입금 확인이 지연될 수 있습니다.\\n• 주문 완료 후 표시되는 계좌로 24시간 이내 입금해 주세요.',",
        "context.loc.t('입금자명_주문자명_다를_경우_지연_24시간', '• 입금자명이 주문자명과 다를 경우 입금 확인이 지연될 수 있습니다.\\n• 주문 완료 후 표시되는 계좌로 24시간 이내 입금해 주세요.'),"
    ),
    ("'무통장입금 안내',",
     f"{w('무통장입금 안내')},"),
    ("'입금 계좌',",
     f"{w('입금 계좌')},"),
    ("_infoRow('은행', _bankName, isBold: true),",
     f"_infoRow({w('은행')}, _bankName, isBold: true),"),
    ("_infoRow('계좌번호', _accountNo, isBold: true, highlight: true),",
     f"_infoRow({w('계좌번호')}, _accountNo, isBold: true, highlight: true),"),
    ("_infoRow('예금주', _accountHolder),",
     f"_infoRow({w('예금주')}, _accountHolder),"),
    ("_infoRow('입금기한', _depositDeadline),",
     f"_infoRow({w('입금기한')}, _depositDeadline),"),
    ("'입금 시 주의사항',",
     f"{w('입금 시 주의사항')},"),
])


# ─── order_guide_screen.dart ────────────────────────────────────────────────
process('lib/screens/orders/order_guide_screen.dart', [
    ("'주문 안내 내용을 모두 확인했습니다.',",
     f"{w('주문 안내 내용을 모두 확인했습니다.')},"),
    ("'주문 안내',",
     f"{w('주문 안내')},"),
    (
        "onGuideCheckChanged != null && !guideChecked ? '확인 후 작성 가능' : '주문서 작성',",
        f"onGuideCheckChanged != null && !guideChecked ? {w('확인 후 작성 가능')} : {w('주문서 작성')},"
    ),
    (
        "{'icon': Icons.search_rounded, 'title': '상품 선택', 'desc': '원하는 상품과 카테고리 선택'},",
        f"{{'icon': Icons.search_rounded, 'title': {w('상품 선택')}, 'desc': {w('원하는 상품과 카테고리 선택')}}},"
    ),
    (
        "{'icon': Icons.tune_rounded, 'title': '옵션 선택', 'desc': '사이즈, 컬러, 커스텀 옵션 선택'},",
        f"{{'icon': Icons.tune_rounded, 'title': {w('옵션 선택')}, 'desc': {w('사이즈, 컬러, 커스텀 옵션 선택')}}},"
    ),
    (
        "{'icon': Icons.assignment_rounded, 'title': '주문서 작성', 'desc': '주문자 정보 및 배송지 입력'},",
        f"{{'icon': Icons.assignment_rounded, 'title': {w('주문서 작성')}, 'desc': {w('주문자 정보 및 배송지 입력')}}},"
    ),
    (
        "{'icon': Icons.payment_rounded, 'title': '결제', 'desc': '다양한 결제 수단 지원'},",
        f"{{'icon': Icons.payment_rounded, 'title': {w('결제')}, 'desc': {w('다양한 결제 수단 지원')}}},"
    ),
    (
        "{'icon': Icons.local_shipping_rounded, 'title': '제작 & 배송', 'desc': '커스텀 14~21일 소요'},",
        f"{{'icon': Icons.local_shipping_rounded, 'title': {w('제작 & 배송')}, 'desc': {w('커스텀 14~21일 소요')}}},"
    ),
    (
        "{'icon': Icons.check_circle_rounded, 'title': '수령', 'desc': '배송 완료 후 검수'},",
        f"{{'icon': Icons.check_circle_rounded, 'title': {w('수령')}, 'desc': {w('배송 완료 후 검수')}}},"
    ),
    ("'단체 주문서',",
     f"{w('단체 주문서')},"),
    (
        "_buildPolicyItem(Icons.cancel_outlined, '취소', AppColors.error, '결제 후 1시간 이내 취소 가능\\n커스텀 제작 시작 후 취소 불가'),",
        f"_buildPolicyItem(Icons.cancel_outlined, {w('취소')}, AppColors.error, {w('결제 후 1시간 이내 취소 가능\\n커스텀 제작 시작 후 취소 불가')}),"
    ),
    (
        "_buildPolicyItem(Icons.swap_horiz_rounded, '교환', AppColors.info, '수령 후 7일 이내 교환 가능\\n착용 흔적이 없는 상품에 한함'),",
        f"_buildPolicyItem(Icons.swap_horiz_rounded, {w('교환')}, AppColors.info, {w('수령 후 7일 이내 교환 가능\\n착용 흔적이 없는 상품에 한함')}),"
    ),
    (
        "_buildPolicyItem(Icons.replay_rounded, '환불', AppColors.warning, '수령 후 7일 이내 환불 가능\\n커스텀 제작 상품은 환불 불가'),",
        f"_buildPolicyItem(Icons.replay_rounded, {w('환불')}, AppColors.warning, {w('수령 후 7일 이내 환불 가능\\n커스텀 제작 상품은 환불 불가')}),"
    ),
    (
        "_buildInfoRow(Icons.local_shipping_rounded, '배송 방법', '택배 (한진택배)', AppColors.primary),",
        f"_buildInfoRow(Icons.local_shipping_rounded, {w('배송 방법')}, {w('택배 (한진택배)')}, AppColors.primary),"
    ),
    (
        "_buildInfoRow(Icons.attach_money_rounded, '배송비', '4,000원 (30만원 이상 무료배송)', AppColors.success),",
        f"_buildInfoRow(Icons.attach_money_rounded, {w('배송비')}, {w('4,000원 (30만원 이상 무료배송)')}, AppColors.success),"
    ),
    (
        "_buildInfoRow(Icons.access_time_rounded, '일반 배송', '결제 완료 후 2~3 영업일', AppColors.info),",
        f"_buildInfoRow(Icons.access_time_rounded, {w('일반 배송')}, {w('결제 완료 후 2~3 영업일')}, AppColors.info),"
    ),
    (
        "_buildInfoRow(Icons.design_services_rounded, '커스텀 제작', '주문 확정 후 14~21일', AppColors.warning),",
        f"_buildInfoRow(Icons.design_services_rounded, {w('커스텀 제작')}, {w('주문 확정 후 14~21일')}, AppColors.warning),"
    ),
    (
        "_buildInfoRow(Icons.groups_rounded, '단체 주문', '주문 확인 후 10~21 영업일', AppColors.accent),",
        f"_buildInfoRow(Icons.groups_rounded, {w('단체 주문')}, {w('주문 확인 후 10~21 영업일')}, AppColors.accent),"
    ),
    (
        "'※ 도서/산간 지역은 추가 배송비가 발생할 수 있습니다.\\n※ 배송 관련 문의는 고객센터로 연락해주세요.',",
        "context.loc.t('도서_산간_지역_추가_배송비_배송_관련_문의_고객', '※ 도서/산간 지역은 추가 배송비가 발생할 수 있습니다.\\n※ 배송 관련 문의는 고객센터로 연락해주세요.'),"
    ),
    (
        "{'q': '사이즈 변경이 가능한가요?', 'a': '커스텀 제작 시작 전까지 변경 가능합니다. 주문 후 1시간 이내 고객센터로 연락해주세요.'},",
        f"{{'q': {w('사이즈 변경이 가능한가요?')}, 'a': {w('커스텀 제작 시작 전까지 변경 가능합니다. 주문 후 1시간 이내 고객센터로 연락해주세요.')}}},"
    ),
    (
        "{'q': '커스텀 인쇄 색상 선택이 가능한가요?', 'a': '네, 주문서 작성 시 원하는 인쇄 색상을 기재해주세요. 기본 색상(흰색, 검정)은 무료이며 특수 색상은 추가 비용이 발생합니다.'},",
        f"{{'q': {w('커스텀 인쇄 색상 선택이 가능한가요?')}, 'a': {w('네, 주문서 작성 시 원하는 인쇄 색상을 기재해주세요. 기본 색상(흰색, 검정)은 무료이며 특수 색상은 추가 비용이 발생합니다.')}}},"
    ),
    (
        "{'q': '단체 주문 최소 수량은 몇 개인가요?', 'a': '최소 5개부터 단체 주문이 가능합니다.'},",
        f"{{'q': {w('단체 주문 최소 수량은 몇 개인가요?')}, 'a': {w('최소 5개부터 단체 주문이 가능합니다.')}}},"
    ),
    (
        "{'q': '팀 로고 파일은 어떻게 보내나요?', 'a': '주문 완료 후 카카오톡(@2fit-mall)으로 AI/PNG 형식 파일을 전송해주세요.'},",
        f"{{'q': {w('팀 로고 파일은 어떻게 보내나요?')}, 'a': {w('주문 완료 후 카카오톡(@2fit-mall)으로 AI/PNG 형식 파일을 전송해주세요.')}}},"
    ),
    (
        "_additionalGuideRow('🚚', '배송', '추가구매 물품은 별도 배송됩니다'),",
        f"_additionalGuideRow('🚚', {w('배송')}, {w('추가구매 물품은 별도 배송됩니다')}),"
    ),
    (
        "'⚠️ 추가구매는 마이페이지 > 기존 주문내역에서 신청하실 수 있습니다.',",
        "context.loc.t('추가구매_마이페이지_기존_주문내역_신청', '⚠️ 추가구매는 마이페이지 > 기존 주문내역에서 신청하실 수 있습니다.'),"
    ),
])


# ─── group_order_only_screen.dart ───────────────────────────────────────────
process('lib/screens/orders/group_order_only_screen.dart', [
    ("sub: '단체전용',",
     f"sub: {w('단체전용')},"),
    ("sub: '컬러·로고·마킹',",
     f"sub: {w('컬러·로고·마킹')},"),
    ("_isGridView ? '그리드' : '리스트',",
     f"_isGridView ? {w('그리드')} : {w('리스트')},"),
])


# ─── size_profile_screen.dart ────────────────────────────────────────────────
process('lib/screens/mypage/size_profile_screen.dart', [
    (
        "final headers = ['사이즈', '키(cm)', '몸무게(kg)', '가슴(cm)', '허리(cm)'];",
        f"final headers = [{w('사이즈')}, {w('키(cm)')}, {w('몸무게(kg)')}, {w('가슴(cm)')}, {w('허리(cm)')}];"
    ),
])


# ─── group_order_landing_screen.dart ────────────────────────────────────────
process('lib/screens/orders/group_order_landing_screen.dart', [
    (
        "            '단체주문하기',\n            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),",
        f"            {w('단체주문하기')},\n            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),"
    ),
    (
        "            '단체주문하기',\n            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),",
        f"            {w('단체주문하기')},\n            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),"
    ),
    ("'카카오톡 채널: @2fit-mall',",
     f"{w('카카오톡 채널: @2fit-mall')},"),
    ("'이메일: chw243527@gmail.com',",
     f"{w('이메일: chw243527@gmail.com')},"),
    ("'운영시간: 평일 10:00 ~ 18:00',",
     f"{w('운영시간: 평일 10:00 ~ 18:00')},"),
])

print("\n✅ 모든 파일 처리 완료!")
