#!/usr/bin/env python3
"""
product_detail_screen.dart 미번역 한국어 문자열 일괄 번역
"""
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

path = 'lib/screens/products/product_detail_screen.dart'
src = Path(path).read_text(encoding='utf-8')
orig = src

# ── 내부 로직 값 (DB 키/필터/enum 등) - 번역 안 함 ─────────────────────────
# _singletGender = '남' / '여' — 내부 enum 값, DB 저장 값
# _selectedFabricType = '일반원단' / '심리스' — 내부 enum 값  
# (이미 이전 세션에서 처리됨)

# ── 일반 Text/label 치환 ───────────────────────────────────────────────────
replacements = [
    # L57, L61 - 내부 enum값이므로 스킵 (주석 있음)
    
    # L675
    ("'※ 모든 착상 이미지는 AI 생성 이미지입니다',",
     f"{w('※ 모든 착상 이미지는 AI 생성 이미지입니다')},"),
    
    # L685
    ("'▶ 디자인 이미지를 반드시 확인해주세요 [확인 필수]',",
     f"{w('▶ 디자인 이미지를 반드시 확인해주세요 [확인 필수]')},"),
    
    # L1022
    ("_toptenTabChip('기성품', true, activeColor: Colors.teal),",
     f"_toptenTabChip({w('기성품')}, true, activeColor: Colors.teal),"),
    
    # L1029
    ("_toptenTabChip('단체전용', true, activeColor: Color(0xFF6A1B9A)),",
     f"_toptenTabChip({w('단체전용')}, true, activeColor: Color(0xFF6A1B9A)),"),
    
    # L1032 (second occurrence)
    # already replaced above - L1022 replaces all occurrences of '기성품' in that pattern
    
    # L1325
    ("'화면에 표시된 색상은 모니터 환경에 따라 실제 제품과 약간의 차이가 있을 수 있습니다.',",
     f"{w('화면에 표시된 색상은 모니터 환경에 따라 실제 제품과 약간의 차이가 있을 수 있습니다.')},"),
    
    # L1375
    (": '4,000원 (300,000원 이상 구매시 무료)',",
     f": {w('4,000원 (300,000원 이상 구매시 무료)')},"),
    
    # L1384
    ("'(도서산간 배송시 3,000원 추가)',",
     f"{w('(도서산간 배송시 3,000원 추가)')},"),
    
    # L1486-1489: 탭 데이터 (('상품정보', 0, key)) — 첫 번째 인자만 번역
    ("('상품정보', 0, _keyInfo),",
     f"({w('상품정보')}, 0, _keyInfo),"),
    ("('사이즈',   1, _keySize),",
     f"({w('사이즈')}, 1, _keySize),"),
    ("('세탁',     2, _keyWashing),",
     f"({w('세탁')}, 2, _keyWashing),"),
    ("('리뷰',     3, _keyReview),",
     f"({w('리뷰')}, 3, _keyReview),"),
    
    # L1568: materialText = '...' — 내부 데이터값, 번역 적용
    ("materialText = '상의: 폴리에스터 92% / 라이크라 8%\\n하의: 나일론 75% / 라이크라 25%';",
     f"materialText = {w('상의: 폴리에스터 92% / 라이크라 8%\\n하의: 나일론 75% / 라이크라 25%')};"),
    
    # L1596
    ("text: '골지원단 19가지 기본 색상 중 원하는 색상으로 자유롭게 제작 가능',",
     f"text: {w('골지원단 19가지 기본 색상 중 원하는 색상으로 자유롭게 제작 가능')},"),
    
    # L1630
    ("'19가지 기본 색상 외에도 제작 가능',",
     f"{w('19가지 기본 색상 외에도 제작 가능')},"),
    
    # L1635
    ("'원하시는 색상이 있다면 주문 시 별도로 알려주세요.',",
     f"{w('원하시는 색상이 있다면 주문 시 별도로 알려주세요.')},"),
    
    # L1698
    ("labelSub: '제품 설명',",
     f"labelSub: {w('제품 설명')},"),
    
    # L1715
    ("labelSub: '제품 기본 정보',",
     f"labelSub: {w('제품 기본 정보')},"),
    
    # L1717-1722: 제품 정보 튜플 첫 번째 원소
    ("('제품명', product.localizedName(_lang)),",
     f"({w('제품명')}, product.localizedName(_lang)),"),
    ("('분류', product.subCategory),",
     f"({w('분류')}, product.subCategory),"),
    ("('상품코드', productCode),",
     f"({w('상품코드')}, productCode),"),
    ("('시즌', 'SS26'),",
     f"({w('시즌')}, 'SS26'),"),
    ("('하의길이', bottomLengthValue),",
     f"({w('하의길이')}, bottomLengthValue),"),
    
    # L1730
    ("labelSub: '소재 정보',",
     f"labelSub: {w('소재 정보')},"),
    
    # L1746
    ("labelSub: '색상 안내',",
     f"labelSub: {w('색상 안내')},"),
    
    # L1823-1848: 색상 Map 키 — 이미 이전 세션에서 처리됐음 (static const이면 한국어 직접)
    # L2007-2013: 세탁 안내 텍스트 — static const _washingTips에 있을 가능성
    # → 아래에서 처리
    
    # L2021: Icon+label 튜플
    ("(Icons.water_drop_outlined,      '찬물 세탁',    '30°C 이하 찬물 사용 권장'),",
     f"(Icons.water_drop_outlined, {w('찬물 세탁')}, {w('30°C 이하 찬물 사용 권장')}),"),
    
    # L2142
    ("'재고는 조기 소진될 수 있으며, 소비자 부주의로 인한 제품 손상은 보상이 되지 않으므로 위의 세탁 방법을 반드시 준수 바랍니다.',",
     f"{w('재고는 조기 소진될 수 있으며, 소비자 부주의로 인한 제품 손상은 보상이 되지 않으므로 위의 세탁 방법을 반드시 준수 바랍니다.')},"),
    
    # L2376: 내부 label 값
    ("final label = isTaiz ? '타이즈' : '기성품';",
     f"final label = isTaiz ? {w('타이즈')} : {w('기성품')};"),
    
    # L2500-2502: 이미 loc 사용 OK
    
    # L2957
    (": '19가지 색상 중 자유롭게 선택하세요',",
     f": {w('19가지 색상 중 자유롭게 선택하세요')},"),
    
    # L2984
    ("'하의 색상 선택은 장바구니 / 바로구매 버튼을 눌러 진행하세요',",
     f"{w('하의 색상 선택은 장바구니 / 바로구매 버튼을 눌러 진행하세요')},"),
    
    # L3096-3098
    ("_fabricTypeBtn('일반원단', '기본 기능성 원단', Icons.layers_outlined),",
     f"_fabricTypeBtn({w('일반원단')}, {w('기본 기능성 원단')}, Icons.layers_outlined),"),
    ("_fabricTypeBtn('심리스', '봉제선 없는 심리스', Icons.auto_awesome_outlined),",
     f"_fabricTypeBtn({w('심리스')}, {w('봉제선 없는 심리스')}, Icons.auto_awesome_outlined),"),
    
    # L3327
    ("_buildAdminImageSection('s2_length', '하의길이 참조 이미지', isAdmin),",
     f"_buildAdminImageSection('s2_length', {w('하의길이 참조 이미지')}, isAdmin),"),
    
    # L3351
    ("'왼쪽부터',",
     f"{w('왼쪽부터')},"),
    
    # L3403
    ("'주머니 추가 불가',",
     f"{w('주머니 추가 불가')},"),
    
    # L3427
    ("'9부 · 5부 · 4부 · 3부까지 적용 가능',",
     f"{w('9부 · 5부 · 4부 · 3부까지 적용 가능')},"),
    
    # L3449
    ("'9부 · 5부 · 4부 · 3부 · 2.5부 · 숏사각까지 적용 가능',",
     f"{w('9부 · 5부 · 4부 · 3부 · 2.5부 · 숏사각까지 적용 가능')},"),
    
    # L3965
    ("'디자인 이미지',",
     f"{w('디자인 이미지')},"),
    
    # L3982
    ("onTap: () => _pickAndUploadImages('design', '디자인 이미지', imgs),",
     f"onTap: () => _pickAndUploadImages('design', {w('디자인 이미지')}, imgs),"),
    
    # L4253
    ("korSub: '고성능 스포츠 소재와 기술이 만든\\n최상위 퍼포먼스 웨어',",
     f"korSub: {w('고성능 스포츠 소재와 기술이 만든\\n최상위 퍼포먼스 웨어')},"),
    
    # L4265
    ("child: _buildAdminImageSection('s1', '섹션1 메인 배너', isAdmin),",
     f"child: _buildAdminImageSection('s1', {w('섹션1 메인 배너')}, isAdmin),"),
    
    # L4295
    ("korSub: '고급 원단과 기능성 소재로 완성한\\n쾌적하고 지속 가능한 착용감',",
     f"korSub: {w('고급 원단과 기능성 소재로 완성한\\n쾌적하고 지속 가능한 착용감')},"),
    
    # L4319
    ("child: _buildAdminImageSection('s2_fabric_extra', '원단 추가 이미지', isAdmin),",
     f"child: _buildAdminImageSection('s2_fabric_extra', {w('원단 추가 이미지')}, isAdmin),"),
    
    # L4396
    ("child: _buildAdminImageSection('s2_fiber', '소재혼용율 이미지', isAdmin),",
     f"child: _buildAdminImageSection('s2_fiber', {w('소재혼용율 이미지')}, isAdmin),"),
    
    # L4548
    ("korSub: '실용적인 수납 설계와 방수 기능으로\\n운동 중에도 완벽한 편의성',",
     f"korSub: {w('실용적인 수납 설계와 방수 기능으로\\n운동 중에도 완벽한 편의성')},"),
    
    # L4558
    ("child: _buildAdminImageSection('s3', '섹션3 포켓 특성', isAdmin),",
     f"child: _buildAdminImageSection('s3', {w('섹션3 포켓 특성')}, isAdmin),"),
    
    # L4664
    ("child: _buildAdminImageSection('s6', '섹션6 사이즈 차트', isAdmin),",
     f"child: _buildAdminImageSection('s6', {w('섹션6 사이즈 차트')}, isAdmin),"),
    
    # L4718
    ("'투핏 사이즈 조건표 기준',",
     f"{w('투핏 사이즈 조건표 기준')},"),
    
    # L4798
    ("'제품 이미지와 색상은 모니터의 상태에 따라 다소 다르게 보일 수 있습니다.',",
     f"{w('제품 이미지와 색상은 모니터의 상태에 따라 다소 다르게 보일 수 있습니다.')},"),
    
    # L4812
    ("'측정 위치에 따라 1~2cm 정도의 오차가 발생할 수 있습니다.',",
     f"{w('측정 위치에 따라 1~2cm 정도의 오차가 발생할 수 있습니다.')},"),
    
    # L4826
    ("'제품 생산 시기 및 생산지에 따라서 동일 상품 간 컬러 및 혼용률 차이가 발생할 수 있습니다.',",
     f"{w('제품 생산 시기 및 생산지에 따라서 동일 상품 간 컬러 및 혼용률 차이가 발생할 수 있습니다.')},"),
    
    # L4843
    # Already replaced L4664 - same call
    
    # L4866
    ("'올바른 세탁으로 제품을 오래, 깨끗하게',",
     f"{w('올바른 세탁으로 제품을 오래, 깨끗하게')},"),
    
    # L5166
    ("'장바구니',",
     f"{w('장바구니')},"),
    
    # L5188
    ("'바로구매',",
     f"{w('바로구매')},"),
    
    # L5477
    ("description: '기성 디자인 그대로 단체 수량으로 주문',",
     f"description: {w('기성 디자인 그대로 단체 수량으로 주문')},"),
    
    # L6374
    ("'남성 → 하의 5부 자동 적용\\n여성 → 하의 2.5부 자동 적용',",
     f"{w('남성 → 하의 5부 자동 적용\\n여성 → 하의 2.5부 자동 적용')},"),
    
    # L6487
    (": '사이즈 · 색상 · 수량 선택',",
     f": {w('사이즈 · 색상 · 수량 선택')},"),
    
    # L6780
    (": '사이즈를 선택하고 장바구니에 담습니다',",
     f": {w('사이즈를 선택하고 장바구니에 담습니다')},"),
    
    # L7275
    ("'옵션을 선택하고 추가하면 한 번에 담을 수 있어요',",
     f"{w('옵션을 선택하고 추가하면 한 번에 담을 수 있어요')},"),
    
    # L7304
    ("_sectionTitle('성별 선택', required: true),",
     f"_sectionTitle({w('성별 선택')}, required: true),"),
    
    # L7318
    ("'남성 → 5부 자동선택  •  여성 → 2.5부 자동선택',",
     f"{w('남성 → 5부 자동선택  •  여성 → 2.5부 자동선택')},"),
    
    # L7419
    ("_sectionTitle('하의 기장 선택', required: true),",
     f"_sectionTitle({w('하의 기장 선택')}, required: true),"),
    
    # L7459
    ("_sectionTitle('상의 사이즈', required: true),",
     f"_sectionTitle({w('상의 사이즈')}, required: true),"),
    
    # L7462
    ("_sizeSectionLabel('성인', Icons.person_outline_rounded, Color(0xFF1A1A2E)),",
     f"_sizeSectionLabel({w('성인')}, Icons.person_outline_rounded, Color(0xFF1A1A2E)),"),
    
    # L7475
    ("_sizeSectionLabel('주니어', Icons.child_care_rounded, Color(0xFF1565C0)),",
     f"_sizeSectionLabel({w('주니어')}, Icons.child_care_rounded, Color(0xFF1565C0)),"),
    
    # L7501
    ("_sectionTitle('하의 사이즈', required: true),",
     f"_sectionTitle({w('하의 사이즈')}, required: true),"),
    
    # L7504
    ("_sizeSectionLabel('성인', Icons.person_outline_rounded, Color(0xFF5C6BC0)),",
     f"_sizeSectionLabel({w('성인')}, Icons.person_outline_rounded, Color(0xFF5C6BC0)),"),
    
    # L7517: 이미 L7475에서 처리됨 (같은 패턴)
    
    # L7544
    ("_sectionTitle('사이즈', required: true),",
     f"_sectionTitle({w('사이즈')}, required: true),"),
    
    # L7550
    ("_sizeSectionLabel('성인', Icons.person_outline_rounded, Color(0xFF1A1A2E)),",
     f"_sizeSectionLabel({w('성인')}, Icons.person_outline_rounded, Color(0xFF1A1A2E)),"),
    
    # L7624
    ("'목록에 없는 사이즈는 채팅 문의를 통해 별도 주문 가능합니다.',",
     f"{w('목록에 없는 사이즈는 채팅 문의를 통해 별도 주문 가능합니다.')},"),
    
    # L7629
    ("\"⚠️ 단, 별도 주문 시 제작 소요 기간이 최소 1주일 이상 걸리며,\\n    경우에 따라 더 길어질 수 있습니다.\",",
     f"{w('⚠️ 단, 별도 주문 시 제작 소요 기간이 최소 1주일 이상 걸리며,\\n    경우에 따라 더 길어질 수 있습니다.')},"),
    
    # L7642
    ("_sectionTitle('주머니 옵션', required: false),",
     f"_sectionTitle({w('주머니 옵션')}, required: false),"),
    
    # L7657
    ("'기본 옵션: 주머니 포함\\n주머니 제거 선택 시 10,000원 할인됩니다.',",
     f"{w('기본 옵션: 주머니 포함\\n주머니 제거 선택 시 10,000원 할인됩니다.')},"),
    
    # L7737
    ("_sectionTitle('하의 색상', required: true),",
     f"_sectionTitle({w('하의 색상')}, required: true),"),
    
    # L7752
    ("_sectionTitle('수량', required: false),",
     f"_sectionTitle({w('수량')}, required: false),"),
    
    # L7880
    ("_optionChip('주머니 제거', Color(0xFF6A1B9A)),",
     f"_optionChip({w('주머니 제거')}, Color(0xFF6A1B9A)),"),
    
    # L7992
    ("'위에서 옵션을 선택하고 추가해주세요',",
     f"{w('위에서 옵션을 선택하고 추가해주세요')},"),
    
    # L8038
    (": '바로구매',",
     f": {w('바로구매')},"),
    
    # L8176
    ("'품절',",
     f"{w('품절')},"),
    
    # L8902-8906 _sortBtn labels
    ("_sortBtn('최신순', 'latest'),",
     f"_sortBtn({w('최신순')}, 'latest'),"),
    ("_sortBtn('평점 높은순', 'highest'),",
     f"_sortBtn({w('평점 높은순')}, 'highest'),"),
    ("_sortBtn('평점 낮은순', 'lowest'),",
     f"_sortBtn({w('평점 낮은순')}, 'lowest'),"),
    
    # L9645
    ("_sheetSectionTitle(Icons.info_outline_rounded, '단체 주문 안내', Color(0xFF1565C0)),",
     f"_sheetSectionTitle(Icons.info_outline_rounded, {w('단체 주문 안내')}, Color(0xFF1565C0)),"),
    
    # L9652
    ("content: '단체 커스텀 제작은 최소 5명부터 가능합니다.',",
     f"content: {w('단체 커스텀 제작은 최소 5명부터 가능합니다.')},"),
    
    # L9660
    ("content: '주문 확정 후 14~21일 소요됩니다.\\n• 디자인 수정: 1회당 3일 이내 수정 요청 없을 시 확정 후 제작 시작\\n(시즌/물량에 따라 변동될 수 있습니다)',",
     f"content: {w('주문 확정 후 14~21일 소요됩니다.\\n• 디자인 수정: 1회당 3일 이내 수정 요청 없을 시 확정 후 제작 시작\\n(시즌/물량에 따라 변동될 수 있습니다)')},"),
    
    # L9681
    ("_sheetSectionTitle(null, '사이즈 안내', Color(0xFF1A1A1A), emoji: '📏'),",
     f"_sheetSectionTitle(null, {w('사이즈 안내')}, Color(0xFF1A1A1A), emoji: '📏'),"),
    
    # L9732
    ("'주문 양식에 키와 체중을 입력해주세요',",
     f"{w('주문 양식에 키와 체중을 입력해주세요')},"),
    
    # L9744
    ("_sheetSectionTitle(null, '교환·환불 정책', Color(0xFFE65100), emoji: '⚠️'),",
     f"_sheetSectionTitle(null, {w('교환·환불 정책')}, Color(0xFFE65100), emoji: '⚠️'),"),
    
    # L9801
    ("'주문 안내 내용을 모두 확인하였습니다',",
     f"{w('주문 안내 내용을 모두 확인하였습니다')},"),
    
    # L9965: headers list — 각 항목 번역
    ("final headers = ['사이즈', '가슴(cm)', '허리(cm)', '엉덩이(cm)', '키(cm)'];",
     f"final headers = [{w('사이즈')}, {w('가슴(cm)')}, {w('허리(cm)')}, {w('엉덩이(cm)')}, {w('키(cm)')}];"),
    
    # L10315
    ("'등록된 이미지가 없습니다.',",
     f"{w('등록된 이미지가 없습니다.')},"),
]

# 세탁 안내 텍스트 (L2007-2013) — 일반 List 항목
washing_lines = [
    ('세제를 풀어 놓은 물에 담가 두지 마시고 세탁 시 수축 및 변형 방지를 위해 찬물 세탁을 권장합니다.',
     '세제를_풀어_놓은_물에_담가_두지_마시고'),
    ('땀과 물에 젖었을 경우 즉시 세탁하십시오.',
     '땀과_물에_젖었을_경우_즉시_세탁'),
    ('세탁 시 지퍼나 단추를 잠근 상태에서 세탁하여 주십시오.',
     '세탁_시_지퍼나_단추를_잠근_상태'),
    ('흰색 제품과 유색 제품은 반드시 구분하여 별도 세탁하십시오.',
     '흰색_제품과_유색_제품은_반드시'),
    ('이염 방지를 위해 색상이 있는 옷은 단독 세탁 권장 드리며, 염소, xs백 제품은 사용하지 않는 것을 권장 드립니다.',
     '이염_방지를_위해_색상이_있는_옷'),
    ('탈수 시 약하게 짜시고 탈수 후 뭉친 상태로 두시면 이염이 될 수 있으니 바로 건조하여 주십시오.',
     '탈수_시_약하게_짜시고_탈수_후'),
    ('열풍 건조는 제품 수축의 원인이 될 수 있으므로 열풍 건조를 하지 마십시오.',
     '열풍_건조는_제품_수축의_원인'),
]

for text, key in washing_lines:
    safe = text.replace("'", "\\'")
    replacements.append(
        (f"'{text}',",
         f"context.loc.t('{key}', '{safe}'),")
    )

# 적용
count = 0
for old, new in replacements:
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
