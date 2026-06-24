#!/usr/bin/env python3
"""group_order_form_screen.dart 미번역 한국어 문자열 일괄 번역"""
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

path = 'lib/screens/orders/group_order_form_screen.dart'
src = Path(path).read_text(encoding='utf-8')
orig = src

replacements = [
    # L73: sizeType 초기값 — 내부 enum, 번역 스킵 (주석 있음)
    
    # L158-162: 밝기 레이블 함수 반환값
    ("return '매우 진하게';",  f"return {w('매우 진하게')};"),
    ("return '진하게';",       f"return {w('진하게')};"),
    ("return '기본';",         f"return {w('기본')};"),
    ("return '밝게';",         f"return {w('밝게')};"),
    ("return '매우 밝게';",    f"return {w('매우 밝게')};"),
    
    # L229: waistband 기본값 표시
    ("if (_waistbandOptions.isEmpty) return '기본 (변경없음)';",
     f"if (_waistbandOptions.isEmpty) return {w('기본 (변경없음)')};"),
    
    # L418, L423: _showSnack
    ("_showSnack('로그인 후 사이즈 프로필을 불러올 수 있습니다.');",
     f"_showSnack({w('로그인 후 사이즈 프로필을 불러올 수 있습니다.')});"),
    ("_showSnack('저장된 사이즈 프로필이 없습니다. 마이페이지에서 먼저 저장해 주세요.');",
     f"_showSnack({w('저장된 사이즈 프로필이 없습니다. 마이페이지에서 먼저 저장해 주세요.')});"),
    
    # L532: default profile name
    ("TextEditingController(text: '내 사이즈')",
     f"TextEditingController(text: {w('내 사이즈')})"),
    # L568
    ("nameCtrl.text.trim().isEmpty ? '내 사이즈' : nameCtrl.text.trim()",
     f"nameCtrl.text.trim().isEmpty ? {w('내 사이즈')} : nameCtrl.text.trim()"),
    
    # L617
    ("_showSnack('최소 \$minQty명 이상 주문 가능합니다.');",
     ""),   # $보간 포함 — 별도처리
    
    # L621-667 snack messages ($ 없는 것)
    ("_showSnack('색상을 선택해 주세요.');",
     f"_showSnack({w('색상을 선택해 주세요.')});"),
    ("_showSnack('단체명을 입력해 주세요.');",
     f"_showSnack({w('단체명을 입력해 주세요.')});"),
    ("_showSnack('연락처를 입력해 주세요.');",
     f"_showSnack({w('연락처를 입력해 주세요.')});"),
    ("_showSnack('배송 주소를 입력해 주세요.');",
     f"_showSnack({w('배송 주소를 입력해 주세요.')});"),
    ("_showSnack('상세주소를 입력해 주세요.');",
     f"_showSnack({w('상세주소를 입력해 주세요.')});"),
    ("_showSnack('남성 하의 길이를 선택해 주세요.');",
     f"_showSnack({w('남성 하의 길이를 선택해 주세요.')});"),
    ("_showSnack('여성 하의 길이를 선택해 주세요.');",
     f"_showSnack({w('여성 하의 길이를 선택해 주세요.')});"),
    ("_showSnack('디자인 요청 사항을 입력해 주세요.');",
     f"_showSnack({w('디자인 요청 사항을 입력해 주세요.')});"),
    
    # L682-684: product object 생성 — 내부 data value, DB저장값이므로 스킵
    
    # L845: title 변수
    ("final title = _isAdditional ? '추가 제작 주문서' : '단체 주문서';",
     f"final title = _isAdditional ? {w('추가 제작 주문서')} : {w('단체 주문서')};"),
    
    # L1179-1215: printType 옵션 Map
    ("'title': '디자인 유지 + 색상 변경',",
     f"'title': {w('디자인 유지 + 색상 변경')},"),
    ("'desc': '2FIT 로고 적용(전면) + 색상 변경 (단체명 인쇄 없음)',",
     f"'desc': {w('2FIT 로고 적용(전면) + 색상 변경 (단체명 인쇄 없음)')},"),
    ("'condLabel': '5명↑',",
     f"'condLabel': {w('5명↑')},"),
    ("'title': '디자인 유지 + 단체명 + 색상 변경',",
     f"'title': {w('디자인 유지 + 단체명 + 색상 변경')},"),
    ("'desc': '기존 디자인 유지 + 단체명(전면) + 색상 변경',",
     f"'desc': {w('기존 디자인 유지 + 단체명(전면) + 색상 변경')},"),
    ("'title': '디자인 변경 + 단체명 + 색상 변경',",
     f"'title': {w('디자인 변경 + 단체명 + 색상 변경')},"),
    ("'desc': '새 디자인 변경 + 단체명(전면) + 색상 변경',",
     f"'desc': {w('새 디자인 변경 + 단체명(전면) + 색상 변경')},"),
    ("'title': '디자인 유지 + 색상변경 + 단체명 + 이름(후면)',",
     f"'title': {w('디자인 유지 + 색상변경 + 단체명 + 이름(후면)')},"),
    ("'desc': '기존 디자인 유지 + 색상 변경 + 단체명(전면) + 개인 이름(후면·등)',",
     f"'desc': {w('기존 디자인 유지 + 색상 변경 + 단체명(전면) + 개인 이름(후면·등)')},"),
    ("'condLabel': '10명↑',",
     f"'condLabel': {w('10명↑')},"),
    ("'title': '디자인 변경 + 색상변경 + 단체명 + 이름(후면)',",
     f"'title': {w('디자인 변경 + 색상변경 + 단체명 + 이름(후면)')},"),
    ("'desc': '새 디자인 변경 + 색상 변경 + 단체명(전면) + 개인 이름(후면·등)',",
     f"'desc': {w('새 디자인 변경 + 색상 변경 + 단체명(전면) + 개인 이름(후면·등)')},"),
    
    # L1749-1750: waistband 옵션 Map
    ("{'id': 1, 'label': '디자인 변경', 'sub': '무료', 'icon': Icons.brush_outlined},",
     f"{{'id': 1, 'label': {w('디자인 변경')}, 'sub': {w('무료')}, 'icon': Icons.brush_outlined}},"),
    ("{'id': 2, 'label': '색상 변경',   'sub': '무료', 'icon': Icons.palette_outlined},",
     f"{{'id': 2, 'label': {w('색상 변경')}, 'sub': {w('무료')}, 'icon': Icons.palette_outlined}},"),
    
    # L1772
    ("'허리밴드 디자인·색상 변경 전부 무료',",
     f"{w('허리밴드 디자인·색상 변경 전부 무료')},"),
    
    # L2096
    ("'포인트 색상 또는 전체 색상이 선택한 색상으로 변경됩니다.',",
     f"{w('포인트 색상 또는 전체 색상이 선택한 색상으로 변경됩니다.')},"),
    
    # L2117
    ("'골지 느낌의 선택한 색상으로 제작됩니다.',",
     f"{w('골지 느낌의 선택한 색상으로 제작됩니다.')},"),
    
    # L2158-2160: Tab 텍스트
    ("Tab(text: '기성 19색'),",  f"Tab(text: {w('기성 19색')}),"),
    ("Tab(text: '추가 색상'),",  f"Tab(text: {w('추가 색상')}),"),
    ("Tab(text: 'HEX 입력'),",  f"Tab(text: {w('HEX 입력')}),"),
    
    # L2568, L2669, L2682: setState hex error
    ("setState(() => _hexError = '올바른 HEX 코드를 입력하세요');",
     f"setState(() => _hexError = {w('올바른 HEX 코드를 입력하세요')});"),
    ("setState(() => _hexError = 'HEX 코드는 6자리입니다 (예: FF6B35)');",
     f"setState(() => _hexError = {w('HEX 코드는 6자리입니다 (예: FF6B35)')});"),
    
    # L2604
    ("'원하시는 색상의 HEX 코드를 6자리로 입력하세요.\\n예) 빨강: FF0000 / 파랑: 0000FF / 노랑: FFFF00',",
     f"{w('원하시는 색상의 HEX 코드를 6자리로 입력하세요.\\n예) 빨강: FF0000 / 파랑: 0000FF / 노랑: FFFF00')},"),
    
    # L2617-2622: 추가 색상 Map (name 키값이지만 UI 표시용)
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
    
    # L2764, L2788, L2909, L2930: 안내 텍스트
    ("'숏사각(숏쇼츠) 선택 시 주머니 추가가 불가합니다.',",
     f"{w('숏사각(숏쇼츠) 선택 시 주머니 추가가 불가합니다.')},"),
    ("'타이즈 9부 선택 시 인당 +20,000원이 추가됩니다.',",
     f"{w('타이즈 9부 선택 시 인당 +20,000원이 추가됩니다.')},"),
    ("'여성 숏사각(숏쇼츠) 선택 시 주머니 추가가 불가합니다.',",
     f"{w('여성 숏사각(숏쇼츠) 선택 시 주머니 추가가 불가합니다.')},"),
    ("'주머니 선택 시 인원당 +10,000원이 추가됩니다.',",
     f"{w('주머니 선택 시 인원당 +10,000원이 추가됩니다.')},"),
    
    # L3002: 선택 불가 / +10,000원/인
    ("Text(disabled ? '선택 불가' : '+10,000원/인',",
     f"Text(disabled ? {w('선택 불가')} : {w('+10,000원/인')},"),
    
    # L3049, L3051: _dotRow
    ("_dotRow('지원 형식: PNG · JPG · PDF · AI · PSD · SVG 등', Colors.purple.shade600),",
     f"_dotRow({w('지원 형식: PNG · JPG · PDF · AI · PSD · SVG 등')}, Colors.purple.shade600),"),
    ("_dotRow('파일이 여러 개일 경우 ZIP으로 압축 후 업로드해 주세요.', Colors.purple.shade600),",
     f"_dotRow({w('파일이 여러 개일 경우 ZIP으로 압축 후 업로드해 주세요.')}, Colors.purple.shade600),"),
    
    # L3095
    ("'로고 인쇄 품질을 위해 AI 원본 파일(벡터)을 첨부해 주세요.\\nAI · EPS · SVG · PDF 권장 / JPG·PNG는 품질 저하 가능',",
     f"{w('로고 인쇄 품질을 위해 AI 원본 파일(벡터)을 첨부해 주세요.\\nAI · EPS · SVG · PDF 권장 / JPG·PNG는 품질 저하 가능')},"),
    
    # L3434
    ("'로고 인쇄 품질을 위해 AI 원본 파일(벡터)을 첨부해 주세요.\\nAI · SVG · PDF · EPS 파일만 첨부 가능합니다.',",
     f"{w('로고 인쇄 품질을 위해 AI 원본 파일(벡터)을 첨부해 주세요.\\nAI · SVG · PDF · EPS 파일만 첨부 가능합니다.')},"),
    
    # L3543 (same as L3095 text)
    
    # L3683
    ("'로고를 첨부하실 경우 AI 원본 파일(벡터 파일)이 필요합니다.\\n(JPG·PNG 등 래스터 이미지로는 로고 인쇄 품질 보장이 어렵습니다.)',",
     f"{w('로고를 첨부하실 경우 AI 원본 파일(벡터 파일)이 필요합니다.\\n(JPG·PNG 등 래스터 이미지로는 로고 인쇄 품질 보장이 어렵습니다.)')},"),
    
    # L3805, L3823: 조건부 레이블
    ("isConfirmed ? '디자인 확정 이미지' : '주문 당시 디자인 이미지'",
     f"isConfirmed ? {w('디자인 확정 이미지')} : {w('주문 당시 디자인 이미지')}"),
    ("isConfirmed ? '수정 완료' : '수정 전'",
     f"isConfirmed ? {w('수정 완료')} : {w('수정 전')}"),
    
    # L3982: ?? fallback
    ("_maleLengthSel ?? '미선택'",
     f"_maleLengthSel ?? {w('미선택')}"),
    ("_femaleLengthSel ?? '미선택'",
     f"_femaleLengthSel ?? {w('미선택')}"),
    
    # L4034, L4045, L4573: headers 리스트
    ("final adultHeaders = ['사이즈', '키(cm)', '몸무게(kg)', '가슴(cm)', '허리(cm)'];",
     f"final adultHeaders = [{w('사이즈')}, {w('키(cm)')}, {w('몸무게(kg)')}, {w('가슴(cm)')}, {w('허리(cm)')}];"),
    ("final juniorHeaders = ['사이즈', '키(cm)', '몸무게(kg)', '가슴(cm)', '허리(cm)'];",
     f"final juniorHeaders = [{w('사이즈')}, {w('키(cm)')}, {w('몸무게(kg)')}, {w('가슴(cm)')}, {w('허리(cm)')}];"),
    ("final headers = ['사이즈', '키(cm)', '몸무게(kg)', '가슴(cm)', '허리(cm)'];",
     f"final headers = [{w('사이즈')}, {w('키(cm)')}, {w('몸무게(kg)')}, {w('가슴(cm)')}, {w('허리(cm)')}];"),
    
    # L4294: message tooltip
    ("message: _nameEnabled ? '' : '10명 이상일 때 이름 입력 가능',",
     f"message: _nameEnabled ? '' : {w('10명 이상일 때 이름 입력 가능')},"),
    
    # L4332, L4334: _genderBtn labels
    ("_genderBtn('남', isMale, Colors.blue, () => setState(() => p.gender = 'male')),",
     f"_genderBtn({w('남')}, isMale, Colors.blue, () => setState(() => p.gender = 'male')),"),
    ("_genderBtn('여', isFemale, Colors.pink, () => setState(() => p.gender = 'female')),",
     f"_genderBtn({w('여')}, isFemale, Colors.pink, () => setState(() => p.gender = 'female')),"),
    
    # L4411, L4413: _sizeTypeBtn
    ("_sizeTypeBtn('성인', p, Colors.indigo),",
     f"_sizeTypeBtn({w('성인')}, p, Colors.indigo),"),
    ("_sizeTypeBtn('주니어', p, Colors.teal),",
     f"_sizeTypeBtn({w('주니어')}, p, Colors.teal),"),
    
    # L4436: label
    ("label: _isBottomOnly ? '사이즈 *' : '하의 사이즈 *',",
     f"label: _isBottomOnly ? {w('사이즈 *')} : {w('하의 사이즈 *')},"),
    
    # L4486: lenLabel
    ("final lenLabel = lenSel ?? '미선택 (위에서 선택해 주세요)';",
     f"final lenLabel = lenSel ?? {w('미선택 (위에서 선택해 주세요)')};"),
    
    # L4700-4708: _measureField labels
    ("Expanded(child: _measureField(p.heightCtrl, '키', 'cm', Icons.height_rounded)),",
     f"Expanded(child: _measureField(p.heightCtrl, {w('키')}, 'cm', Icons.height_rounded)),"),
    ("Expanded(child: _measureField(p.weightCtrl, '몸무게', 'kg', Icons.monitor_weight_outlined)),",
     f"Expanded(child: _measureField(p.weightCtrl, {w('몸무게')}, 'kg', Icons.monitor_weight_outlined)),"),
    ("Expanded(child: _measureField(p.waistCtrl, '허리', 'cm', Icons.radio_button_unchecked)),",
     f"Expanded(child: _measureField(p.waistCtrl, {w('허리')}, 'cm', Icons.radio_button_unchecked)),"),
    ("Expanded(child: _measureField(p.thighCtrl, '허벅지', 'cm', Icons.airline_seat_legroom_normal_rounded)),",
     f"Expanded(child: _measureField(p.thighCtrl, {w('허벅지')}, 'cm', Icons.airline_seat_legroom_normal_rounded)),"),
    
    # L4793: _inputField
    ("_inputField('단체명 *', _teamNameCtrl, '단체명을 입력해 주세요'),",
     f"_inputField({w('단체명 *')}, _teamNameCtrl, {w('단체명을 입력해 주세요')}),"),
    
    # L4815, L4819: 인쇄 안내
    ("text: '인쇄 안내: ',",
     f"text: {w('인쇄 안내: ')},"),
    ("text: '현재 전면 단체명 인쇄 옵션이 선택되어 있습니다.\\n위 단체명 입력칸에 입력한 단체명으로 전면에 단체명이 인쇄됩니다.',",
     f"text: {w('현재 전면 단체명 인쇄 옵션이 선택되어 있습니다.\\n위 단체명 입력칸에 입력한 단체명으로 전면에 단체명이 인쇄됩니다.')},"),
    
    # L4828-4831: _inputField
    ("_inputField('담당자 이름', _managerNameCtrl, '담당자 이름'),",
     f"_inputField({w('담당자 이름')}, _managerNameCtrl, {w('담당자 이름')}),"),
    ("_inputField('연락처 *', _phoneCtrl, '010-0000-0000',",
     f"_inputField({w('연락처 *')}, _phoneCtrl, '010-0000-0000',"),
    ("_inputField('이메일', _emailCtrl, 'example@email.com',",
     f"_inputField({w('이메일')}, _emailCtrl, 'example@email.com',"),
    
    # L4883: address hint
    ("_address.isEmpty ? '주소 검색 (카카오)' : _address,",
     f"_address.isEmpty ? {w('주소 검색 (카카오)')} : _address,"),
    
    # L4958-4985: 독점 디자인 텍스트
    ("text: '1년 독점 디자인 소유  ',",
     f"text: {w('1년 독점 디자인 소유  ')},"),
    ("text: '(선택 · 무료)  ',",
     f"text: {w('(선택 · 무료)  ')},"),
    ("text: '무료 제공\\n',",
     f"text: {w('무료 제공')},"),
    ("text: '· 1년간 해당 디자인을 타인에게 배포하지 않습니다.\\n',",
     f"text: {w('· 1년간 해당 디자인을 타인에게 배포하지 않습니다.')},"),
    ("text: '· 별도 이야기 없으면 매년 2월 1일 홈페이지에 업로드 됩니다.\\n',",
     f"text: {w('· 별도 이야기 없으면 매년 2월 1일 홈페이지에 업로드 됩니다.')},"),
    ("text: '· 같은 디자인 희망 시 색상만 변경 가능 (같은 색상 제작 불가)',",
     f"text: {w('· 같은 디자인 희망 시 색상만 변경 가능 (같은 색상 제작 불가)')},"),
    
    # L5183-5196: sumRow 레이블
    ("'배송비',",
     f"{w('배송비')},"),
    ("? '무료 (5장 이상)'",
     f"? {w('무료 (5장 이상)')}"),
    ("_sumRow('1년 독점 디자인', '무료',",
     f"_sumRow({w('1년 독점 디자인')}, {w('무료')},"),
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
