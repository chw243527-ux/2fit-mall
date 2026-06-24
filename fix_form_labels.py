#!/usr/bin/env python3
"""
group_order_form_screen.dart 미번역 텍스트 수정:
1. Text(t, ...) — fabricType 표시 ('일반 봉제', '심리스 (무봉제)')
2. Text(gender, ...) — 성별 뱃지 ('남성', '여성')  
3. Text(label, ...) — 하의 길이 옵션 버튼 (9부/5부 등)
4. sumRow 미번역 ('주머니 추가', '↳ 심리스...', '↳ 타이즈 9부...' 등)
5. 스냅바 미번역 ('최소 $minQty명 이상...')
6. 공유 snack 메시지들
"""

file_path = 'lib/screens/orders/group_order_form_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

replacements = [
    # ── 1. fabricType 버튼에서 Text(t) → context.loc.t() ──
    # "Text(t, style: TextStyle(" → loc.t로 표시
    (
        '                  Text(t, style: TextStyle(\n                    fontSize: 13, fontWeight: FontWeight.w800,\n                    color: isSel ? Colors.white : Colors.black87,\n                  )),',
        '                  Text(context.loc.t(t, t), style: TextStyle(\n                    fontSize: 13, fontWeight: FontWeight.w800,\n                    color: isSel ? Colors.white : Colors.black87,\n                  )),'
    ),

    # ── 2. 성별 뱃지 Text(gender) → context.loc.t() ──
    (
        '          child: Text(gender,\n              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: genderColor)),',
        '          child: Text(context.loc.t(gender, gender),\n              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: genderColor)),'
    ),

    # ── 3. 하의 길이 버튼 Text(label) → context.loc.t() ──
    (
        '                  Text(label,\n                      style: TextStyle(\n                          fontWeight: FontWeight.w800, fontSize: 13,\n                          color: isSel ? Colors.white : Colors.black87)),',
        '                  Text(context.loc.t(label, label),\n                      style: TextStyle(\n                          fontWeight: FontWeight.w800, fontSize: 13,\n                          color: isSel ? Colors.white : Colors.black87)),'
    ),

    # ── 4. sumRow: '주머니 추가' ──
    (
        "          _sumRow('주머니 추가', '+${_fmt(_pocketPrice)}원/인',\n              valueColor: const Color(0xFFE65100)),",
        "          _sumRow(context.loc.t('주머니_추가', '주머니 추가'), '+${_fmt(_pocketPrice)}원/인',\n              valueColor: const Color(0xFFE65100)),"
    ),

    # ── 5. sumRow: '  ↳ 심리스(무봉제) 추가' ──
    (
        "          _sumRow('  ↳ 심리스(무봉제) 추가', '+${_fmt(_fabricExtra)}원/인',\n              valueColor: const Color(0xFFE65100)),",
        "          _sumRow('  ↳ ' + context.loc.t('심리스무봉제_추가', '심리스(무봉제) 추가'), '+${_fmt(_fabricExtra)}원/인',\n              valueColor: const Color(0xFFE65100)),"
    ),

    # ── 6. sumRow: '  ↳ 타이즈 9부 추가' ──
    (
        "          _sumRow('  ↳ 타이즈 9부 추가', '+${_fmt(_tights9Price)}원/인',\n              valueColor: const Color(0xFFE65100)),",
        "          _sumRow('  ↳ ' + context.loc.t('타이즈_9부_추가', '타이즈 9부 추가'), '+${_fmt(_tights9Price)}원/인',\n              valueColor: const Color(0xFFE65100)),"
    ),

    # ── 7. 스냅바: '최소 $minQty명 이상 주문 가능합니다.' ──
    (
        "      _showSnack('최소 $minQty명 이상 주문 가능합니다.');",
        "      _showSnack(context.loc.t('최소_minQty명_이상_주문_가능', '최소 ') + minQty.toString() + context.loc.t('명_이상_주문_가능합니다', '명 이상 주문 가능합니다.'));"
    ),

    # ── 8. 스냅바: '${i + 1}번 인원의 성별을 선택해 주세요.' ──
    (
        "      _showSnack('${i + 1}번 인원의 성별을 선택해 주세요.');",
        "      _showSnack((i + 1).toString() + context.loc.t('번_인원의_성별을_선택해_주세요', '번 인원의 성별을 선택해 주세요.'));"
    ),

    # ── 9. 스냅바: '${i + 1}번 인원의 상의 사이즈를 입력해 주세요.' ──
    (
        "        _showSnack('${i + 1}번 인원의 상의 사이즈를 입력해 주세요.');",
        "        _showSnack((i + 1).toString() + context.loc.t('번_인원의_상의_사이즈를_입력해_주세요', '번 인원의 상의 사이즈를 입력해 주세요.'));"
    ),

    # ── 10. 스냅바: '${i + 1}번 인원의 사이즈를 입력해 주세요.' ──
    (
        "        _showSnack('${i + 1}번 인원의 사이즈를 입력해 주세요.');",
        "        _showSnack((i + 1).toString() + context.loc.t('번_인원의_사이즈를_입력해_주세요', '번 인원의 사이즈를 입력해 주세요.'));"
    ),

    # ── 11. 스냅바: '장바구니에 담았습니다.' ──
    (
        "              Expanded(child: Text('장바구니에 담았습니다. ($_totalCount명 / ${_fmt(_finalPrice)}원)')),",
        "              Expanded(child: Text(context.loc.t('장바구니에_담았습니다', '장바구니에 담았습니다.') + ' ($_totalCount명 / ${_fmt(_finalPrice)}원)')),",
    ),

    # ── 12. 스냅바: '\"${profile.profileName}\" 사이즈가 적용되었습니다.' ──
    (
        '                _showSnack(\'"\${profile.profileName}" 사이즈가 적용되었습니다.\');',
        '                _showSnack(\'"\${profile.profileName}" \' + context.loc.t(\'사이즈가_적용되었습니다\', \'사이즈가 적용되었습니다.\'));'
    ),

    # ── 13. '총 ${colors.length}가지 기성 색상 • 탭하여 선택' ──
    (
        "            '총 ${colors.length}가지 기성 색상 • 탭하여 선택',",
        "            context.loc.t('총_색상_탭선택', '총 ') + '\${colors.length}' + context.loc.t('가지_기성_색상_탭하여_선택', '가지 기성 색상 • 탭하여 선택'),"
    ),

    # ── 14. '위 사이즈에 해당하지 않으면...' ──
    (
        '              "위 사이즈에 해당하지 않으면 \'상세치수 입력\'을 선택해 주세요.",',
        '              context.loc.t(\'위_사이즈에_해당하지_않으면_상세치수\', "위 사이즈에 해당하지 않으면 \'상세치수 입력\'을 선택해 주세요."),'
    ),

    # ── 15. '선택: $_waistbandOptionLabel' ──
    (
        "              Text('선택: $_waistbandOptionLabel',",
        "              Text(context.loc.t('선택', '선택: ') + _waistbandOptionLabel,"
    ),

    # ── 16. gender label 'K (블랙)' or '커스텀' in color area
    # 확장색상 display name
    (
        "                _mainColorName  = '확장 ($hexStr)';",
        "                _mainColorName  = context.loc.t('확장_색상', '확장') + ' ($hexStr)';"
    ),

    # ── 17. 커스텀 컬러 이름 ──
    (
        "        _mainColorName  = '커스텀 (#${v.toUpperCase()})';",
        "        _mainColorName  = context.loc.t('커스텀_색상', '커스텀') + ' (#${v.toUpperCase()})';"
    ),

    # ── 18. gender: '남성' parameter (the parameter is used in _buildGenderLengthRow → Text(gender) which we already wrap)
    # Actually this is fine because we wrap Text(gender) with loc.t above

    # ── 19. sumRow: 허리밴드 waistband label
    (
        "          _sumRow('허리밴드 ${_waistbandOptionLabel}',\n              '+${_fmt(_waistbandExtra)}원',",
        "          _sumRow(context.loc.t('허리밴드', '허리밴드 ') + _waistbandOptionLabel,\n              '+${_fmt(_waistbandExtra)}원',"
    ),

    # ── 20. 재봉방법 banner Text
    (
        '            Text(context.loc.t(\'재봉방법\', \'재봉방법: \'), style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),\n            Text(_fabricType, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.teal.shade800)),',
        '            Text(context.loc.t(\'재봉방법\', \'재봉방법: \'), style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),\n            Text(context.loc.t(_fabricType, _fabricType), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.teal.shade800)),'
    ),

    # ── 21. '이미지 선택 오류: $e' ──
    (
        "      _showSnack('이미지 선택 오류: $e');",
        "      _showSnack(context.loc.t('이미지_선택_오류', '이미지 선택 오류: ') + e.toString());"
    ),

    # ── 22. '파일 선택 오류: $e\\nAI·SVG·PDF·EPS 파일만 첨부 가능합니다.' ──
    (
        "      _showSnack('파일 선택 오류: $e\\nAI·SVG·PDF·EPS 파일만 첨부 가능합니다.');",
        "      _showSnack(context.loc.t('파일_선택_오류', '파일 선택 오류: ') + e.toString() + context.loc.t('_AI_SVG_PDF_EPS_파일만_첨부', '\\nAI·SVG·PDF·EPS 파일만 첨부 가능합니다.'));"
    ),

    # ── 23. '· $_lightnessLabel' ──
    (
        "                      Text('· $_lightnessLabel',",
        "                      Text('· ' + _lightnessLabel,"
    ),

    # ── 24. description: '단체 직접 주문' ──
    # This is an internal DB value, skip

    # ── 25. size: '단체', color fallback '기본' ── DB값, skip
]

count = 0
for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        count += 1
    else:
        print(f"⚠️  NOT FOUND: {old[:80]}...")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"\n✅ group_order_form_screen.dart: {count}/{len(replacements)} 항목 수정 완료")
