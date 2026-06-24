#!/usr/bin/env python3
"""mypage_screen.dart 미번역 한국어 문자열 일괄 번역"""
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

path = 'lib/screens/mypage/mypage_screen.dart'
src = Path(path).read_text(encoding='utf-8')
orig = src

replacements = [
    # L1788, L3706: 현금영수증 미등록
    (": '미등록 — 결제 시 자동 발행',",
     f": {w('미등록 — 결제 시 자동 발행')},"),
    
    # L1990-2000: row() 레이블
    ("row('상호', AppConstants.companyName)",
     f"row({w('상호')}, AppConstants.companyName)"),
    ("row('대표자', AppConstants.ceoName)",
     f"row({w('대표자')}, AppConstants.ceoName)"),
    ("row('사업자등록번호', AppConstants.businessRegNumber)",
     f"row({w('사업자등록번호')}, AppConstants.businessRegNumber)"),
    ("row('전화번호', AppConstants.customerServicePhone)",
     f"row({w('전화번호')}, AppConstants.customerServicePhone)"),
    ("row('주소', AppConstants.companyAddress, multiLine: true)",
     f"row({w('주소')}, AppConstants.companyAddress, multiLine: true)"),
    
    # L2021-2029: row() 레이블
    ("row('봉사료', '0원')",
     f"row({w('봉사료')}, '0원')"),
    ("row('결제수단', o.paymentMethod.isNotEmpty ? o.paymentMethod : '-')",
     f"row({w('결제수단')}, o.paymentMethod.isNotEmpty ? o.paymentMethod : '-')"),
    ("row('구매자', o.userName.isNotEmpty ? o.userName : '-')",
     f"row({w('구매자')}, o.userName.isNotEmpty ? o.userName : '-')"),
    ("row('상품명', itemSummary, multiLine: true)",
     f"row({w('상품명')}, itemSummary, multiLine: true)"),
    ("row('거래일시\\n(취소일시)', fmtDateTime(o.createdAt), multiLine: true)",
     f"row({w('거래일시\\n(취소일시)')}, fmtDateTime(o.createdAt), multiLine: true)"),
    
    # L2044, L2050
    ("'본 거래확인서는 세금계산서 대용으로 사용할 수 없습니다.',",
     f"{w('본 거래확인서는 세금계산서 대용으로 사용할 수 없습니다.')},"),
    ("'현금영수증 문의: 126-1-1',",
     f"{w('현금영수증 문의: 126-1-1')},"),
    
    # L2196-2204: row() 레이블
    ("row('발행일시', fmtDateTime(o.createdAt))",
     f"row({w('발행일시')}, fmtDateTime(o.createdAt))"),
    ("row('승인번호', approvalNum,",
     f"row({w('승인번호')}, approvalNum,"),
    ("row('용도', cashReceiptType)",
     f"row({w('용도')}, cashReceiptType)"),
    ("row('발행정보', o.cashReceiptNum!)",
     f"row({w('발행정보')}, o.cashReceiptNum!)"),
    
    # L2218, L2225, L2242, L2251
    ("'현금영수증 승인번호는 국세청에서\\n익일 13시 이후 확인됩니다.',",
     f"{w('현금영수증 승인번호는 국세청에서\\n익일 13시 이후 확인됩니다.')},"),
    # L2225 same as L2050 — already replaced
    ("'현금영수증 번호가 등록되지 않았습니다.',",
     f"{w('현금영수증 번호가 등록되지 않았습니다.')},"),
    ("'마이페이지 → 현금영수증 번호 등록 후\\n결제하시면 자동으로 발급됩니다.',",
     f"{w('마이페이지 → 현금영수증 번호 등록 후\\n결제하시면 자동으로 발급됩니다.')},"),
    
    # L4144
    (": '  — 5장 이상 주문 시 무료',",
     f": {w('  — 5장 이상 주문 시 무료')},"),
    
    # L4777-4781: sectionBox / detailRow
    ("sectionBox('주문자 정보', [",
     f"sectionBox({w('주문자 정보')}, ["),
    ("detailRow(Icons.person_outline, '이름', o.userName.isNotEmpty ? o.userName : '-'),",
     f"detailRow(Icons.person_outline, {w('이름')}, o.userName.isNotEmpty ? o.userName : '-'),"),
    ("detailRow(Icons.phone_outlined, '연락처', o.userPhone.isNotEmpty ? o.userPhone : '-'),",
     f"detailRow(Icons.phone_outlined, {w('연락처')}, o.userPhone.isNotEmpty ? o.userPhone : '-'),"),
    ("detailRow(Icons.email_outlined, '이메일', o.userEmail.isNotEmpty ? o.userEmail : '-'),",
     f"detailRow(Icons.email_outlined, {w('이메일')}, o.userEmail.isNotEmpty ? o.userEmail : '-'),"),
    ("detailRow(Icons.location_on_outlined, '배송지', o.userAddress.isNotEmpty ? o.userAddress : '-'),",
     f"detailRow(Icons.location_on_outlined, {w('배송지')}, o.userAddress.isNotEmpty ? o.userAddress : '-'),"),
    
    # L5045-5053
    ("sectionBox('결제 정보', [",
     f"sectionBox({w('결제 정보')}, ["),
    ("detailRow(Icons.payments_outlined, '결제방법', o.paymentMethod.isNotEmpty ? o.paymentMethod : '-'),",
     f"detailRow(Icons.payments_outlined, {w('결제방법')}, o.paymentMethod.isNotEmpty ? o.paymentMethod : '-'),"),
    ("detailRow(Icons.local_shipping_outlined, '배송비',",
     f"detailRow(Icons.local_shipping_outlined, {w('배송비')},"),
    ("detailRow(Icons.receipt_long_rounded, '현금영수증', o.cashReceiptNum!),",
     f"detailRow(Icons.receipt_long_rounded, {w('현금영수증')}, o.cashReceiptNum!),"),
    ("detailRow(Icons.notes_outlined, '메모', o.memo!),",
     f"detailRow(Icons.notes_outlined, {w('메모')}, o.memo!),"),
    
    # L5202
    ("'수정 완료 디자인을 확정하시겠습니까?\\n\\n확정 후에는 디자인 수정 요청이 불가하며, 즉시 제작이 시작됩니다.',",
     f"{w('수정 완료 디자인을 확정하시겠습니까?\\n\\n확정 후에는 디자인 수정 요청이 불가하며, 즉시 제작이 시작됩니다.')},"),
    
    # L5271-5276: changeItems label 값
    ("changeItems.add({'label': '색상', 'value': colorName!});",
     f"changeItems.add({{'label': {w('색상')}, 'value': colorName!}});"),
    ("changeItems.add({'label': '단체명', 'value': teamName!});",
     f"changeItems.add({{'label': {w('단체명')}, 'value': teamName!}});"),
    ("changeItems.add({'label': '원단', 'value': fabricName!});",
     f"changeItems.add({{'label': {w('원단')}, 'value': fabricName!}});"),
    ("changeItems.add({'label': '인쇄 방식', 'value': printType!});",
     f"changeItems.add({{'label': {w('인쇄 방식')}, 'value': printType!}});"),
    ("changeItems.add({'label': '추가 메모', 'value': memo!});",
     f"changeItems.add({{'label': {w('추가 메모')}, 'value': memo!}});"),
    
    # L5576
    ("'이미지를 탭하면 핀치줌으로 확대확인할 수 있습니다. 이상이 없으면 아래 디자인 확정하기를 눌러 제작을 시작해 주세요.',",
     f"{w('이미지를 탭하면 핀치줌으로 확대확인할 수 있습니다. 이상이 없으면 아래 디자인 확정하기를 눌러 제작을 시작해 주세요.')},"),
    
    # L5670
    ("'수정 완료 디자인',",
     f"{w('수정 완료 디자인')},"),
    
    # L5837-5841: printType Map 값
    ("0: '디자인 유지 + 색상 변경',",
     f"0: {w('디자인 유지 + 색상 변경')},"),
    ("1: '디자인 유지 + 단체명 + 색상 변경',",
     f"1: {w('디자인 유지 + 단체명 + 색상 변경')},"),
    ("2: '디자인 변경 + 단체명 + 색상 변경',",
     f"2: {w('디자인 변경 + 단체명 + 색상 변경')},"),
    ("3: '디자인 유지 + 색상변경 + 단체명 + 이름(후면)',",
     f"3: {w('디자인 유지 + 색상변경 + 단체명 + 이름(후면)')},"),
    ("4: '디자인 변경 + 색상변경 + 단체명 + 이름(후면)',",
     f"4: {w('디자인 변경 + 색상변경 + 단체명 + 이름(후면)')},"),
    
    # L6039: _sectionLabel
    ("_sectionLabel(Icons.palette_outlined, '색상', purple),",
     f"_sectionLabel(Icons.palette_outlined, {w('색상')}, purple),"),
    
    # L6414
    ("'원하시는 색상의 HEX 코드를 6자리로 입력하세요.\\n예) 빨강: FF0000 / 파랑: 0000FF / 노랑: FFFF00',",
     f"{w('원하시는 색상의 HEX 코드를 6자리로 입력하세요.\\n예) 빨강: FF0000 / 파랑: 0000FF / 노랑: FFFF00')},"),
    
    # L6427-6432: 추가 색상 Map
    ("{'name': '코발트블루', 'hex': '0047AB'},",
     f"{{'name': {w('코발트블루')}, 'hex': '0047AB'}},"),
    ("{'name': '라벤더',    'hex': 'E6CCFF'},",
     f"{{'name': {w('라벤더')}, 'hex': 'E6CCFF'}},"),
    ("{'name': '카멜',      'hex': 'C19A6B'},",
     f"{{'name': {w('카멜')}, 'hex': 'C19A6B'}},"),
    ("{'name': '민트',      'hex': '26C9A0'},",
     f"{{'name': {w('민트')}, 'hex': '26C9A0'}},"),
    ("{'name': '버건디',    'hex': '6D0E19'},",
     f"{{'name': {w('버건디')}, 'hex': '6D0E19'}},"),
    ("{'name': '골드',      'hex': 'D4AF37'},",
     f"{{'name': {w('골드')}, 'hex': 'D4AF37'}},"),
    
    # L6491
    ("_sectionLabel(Icons.texture_rounded, '원단', Color(0xFF757575)),",
     f"_sectionLabel(Icons.texture_rounded, {w('원단')}, Color(0xFF757575)),"),
    
    # L6505
    ("_currentFabric.isNotEmpty ? _currentFabric : '정보 없음',",
     f"_currentFabric.isNotEmpty ? _currentFabric : {w('정보 없음')},"),
    
    # L6527
    ("_sectionLabel(Icons.print_rounded, '인쇄타입', Color(0xFF757575)),",
     f"_sectionLabel(Icons.print_rounded, {w('인쇄타입')}, Color(0xFF757575)),"),
    
    # L6541
    ("_currentPrintType.isNotEmpty ? _currentPrintType : '정보 없음',",
     f"_currentPrintType.isNotEmpty ? _currentPrintType : {w('정보 없음')},"),
    
    # L6564
    ("_sectionLabel(Icons.groups_outlined, '단체명', Color(0xFF2E7D32)),",
     f"_sectionLabel(Icons.groups_outlined, {w('단체명')}, Color(0xFF2E7D32)),"),
    
    # L6674
    ("_sectionLabel(Icons.chat_bubble_outline_rounded, '추가 요청사항', Color(0xFF616161)),",
     f"_sectionLabel(Icons.chat_bubble_outline_rounded, {w('추가 요청사항')}, Color(0xFF616161)),"),
    
    # L6925
    ("'구매를 확정하시겠습니까?\\n\\n확정 후에는 교환/반품 신청이 어려울 수 있습니다.',",
     f"{w('구매를 확정하시겠습니까?\\n\\n확정 후에는 교환/반품 신청이 어려울 수 있습니다.')},"),
    
    # L6989-6997: 교환/반품 사유
    ("'색상, 사이즈를 바꾸고 싶어요',",
     f"{w('색상, 사이즈를 바꾸고 싶어요')},"),
    ("'다른 이유가 있어요',",
     f"{w('다른 이유가 있어요')},"),
    ("'상품 정보와 실제 상품이 달라요',",
     f"{w('상품 정보와 실제 상품이 달라요')},"),
    ("'구성품, 부속품이 없어요',",
     f"{w('구성품, 부속품이 없어요')},"),
    ("'파손된 상품을 받았어요',",
     f"{w('파손된 상품을 받았어요')},"),
    ("'주문한 상품과 다른 상품을 받았어요',",
     f"{w('주문한 상품과 다른 상품을 받았어요')},"),
    ("'상품에 문제가 있어요',",
     f"{w('상품에 문제가 있어요')},"),
    
    # L7151: labels 리스트
    ("final labels = ['교환 사유', '수거 방법', _shippingBySelf ? '비용 결제' : '신청 확인'];",
     f"final labels = [{w('교환 사유')}, {w('수거 방법')}, _shippingBySelf ? {w('비용 결제')} : {w('신청 확인')}];"),
    
    # L7232
    ("'· 이유를 자세히 알려주면 더 빠르게 교환할 수 있어요.\\n· 사진은 3장까지 올릴 수 있어요. (각 10MB 이하)',",
     f"{w('· 이유를 자세히 알려주면 더 빠르게 교환할 수 있어요.\\n· 사진은 3장까지 올릴 수 있어요. (각 10MB 이하)')},"),
    
    # L7344
    ("'· 사진은 최대 3장, 각 10MB 이하',",
     f"{w('· 사진은 최대 3장, 각 10MB 이하')},"),
    
    # L7399
    ("subLabel: '택배사가 2~5일 이내 방문 예정',",
     f"subLabel: {w('택배사가 2~5일 이내 방문 예정')},"),
    
    # L7469
    ("'교환 요청이 확인되면 2~5일 이내 택배사가 방문할 예정이에요.\\n아래 주소가 맞는지 확인해주세요.',",
     f"{w('교환 요청이 확인되면 2~5일 이내 택배사가 방문할 예정이에요.\\n아래 주소가 맞는지 확인해주세요.')},"),
    
    # L7495
    ("subLabel: '운송장 번호를 고객센터에 전달해주세요',",
     f"subLabel: {w('운송장 번호를 고객센터에 전달해주세요')},"),
    
    # L7656
    ("_confirmRow('교환 사유', _selectedReason ?? ''),",
     f"_confirmRow({w('교환 사유')}, _selectedReason ?? ''),"),
    
    # L7795
    ("final msgs = ['사유를 선택해주세요.', '수거 방법을 선택해주세요.', '결제수단을 선택해주세요.'];",
     f"final msgs = [{w('사유를 선택해주세요.')}, {w('수거 방법을 선택해주세요.')}, {w('결제수단을 선택해주세요.')}];"),
    
    # L7848: label 변수
    ("final label = widget.isReturn ? '반품' : '교환';",
     f"final label = widget.isReturn ? {w('반품')} : {w('교환')};"),
]

count = 0
for old, new in replacements:
    if not old or not new:
        continue
    if old in src:
        n = src.count(old)
        src = src.replace(old, new)
        count += n
    else:
        print(f"  [!] NOT FOUND: {old[:80]!r}")

if src != orig:
    Path(path).write_text(src, encoding='utf-8')
    print(f"✓ Saved {path} ({count} replacements)")
else:
    print("No changes made")
