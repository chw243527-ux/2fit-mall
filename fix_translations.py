import re

def apply_replacements(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    for old, new in replacements:
        count = content.count(old)
        if count > 0:
            content = content.replace(old, new)
            print(f"  [{count}x] Replaced in {filepath.split('/')[-1]}: {old[:60]!r}")
        else:
            print(f"  [!] NOT FOUND in {filepath.split('/')[-1]}: {old[:60]!r}")
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  -> Saved {filepath.split('/')[-1]}")
    return content

# ─── group_order_form_screen.dart ─────────────────────────────────────────
form_path = '/home/user/webapp/lib/screens/orders/group_order_form_screen.dart'
form_replacements = [
    # L924: 단체 커스텀 주문 (conditional expression — wrap each branch)
    (
        "_isAdditional ? '추가 제작 주문' : '단체 커스텀 주문'",
        "_isAdditional ? context.loc.t('추가_제작_주문', '추가 제작 주문') : context.loc.t('단체_커스텀_주문', '단체 커스텀 주문')"
    ),
    # L934
    (
        "'아래 폼을 작성하여 주문을 완료해 주세요.'",
        "context.loc.t('아래_폼을_작성하여_주문을_완료', '아래 폼을 작성하여 주문을 완료해 주세요.')"
    ),
    # L985-988
    (
        "_headerChip(Icons.check_circle_rounded, '허리밴드 디자인·색상 변경 무료')",
        "_headerChip(Icons.check_circle_rounded, context.loc.t('허리밴드_디자인색상_변경_무료', '허리밴드 디자인·색상 변경 무료'))"
    ),
    (
        "_headerChip(Icons.attach_file_rounded,  '로고 AI 원본파일 필수 (AI/EPS/SVG)')",
        "_headerChip(Icons.attach_file_rounded, context.loc.t('로고_AI_원본파일_필수', '로고 AI 원본파일 필수 (AI/EPS/SVG)'))"
    ),
    (
        "_headerChip(Icons.photo_camera_outlined, '앞·뒤 사진 첨부 제작 가능')",
        "_headerChip(Icons.photo_camera_outlined, context.loc.t('앞뒤_사진_첨부_제작_가능', '앞·뒤 사진 첨부 제작 가능'))"
    ),
    (
        "_headerChip(Icons.lock_outlined,         '1년 독점 사용권 무료 제공')",
        "_headerChip(Icons.lock_outlined, context.loc.t('1년_독점_사용권_무료_제공', '1년 독점 사용권 무료 제공'))"
    ),
    # L1157
    (
        "'아래 모든 선택사항은 전체 인원에게 동일하게 적용됩니다.\\n개인별로 다르게 선택할 수 없습니다.'",
        "context.loc.t('아래_모든_선택사항은_전체_인원_6c13d5', '아래 모든 선택사항은 전체 인원에게 동일하게 적용됩니다.\\n개인별로 다르게 선택할 수 없습니다.')"
    ),
    # L1684
    (
        "'심리스(무봉제) 선택 시 +10,000원이 추가됩니다.'",
        "context.loc.t('심리스무봉제_선택_시_10000원_추가', '심리스(무봉제) 선택 시 +10,000원이 추가됩니다.')"
    ),
    # L1709: icon comparison (keep as is — it's a logic expression, not display text, no need to translate)
    # L1729: subtitle text
    (
        "t == '일반 봉제' ? '봉제선 있음 · 내구성 우수' : '봉제선 없음 · 착용감 우수'",
        "t == '일반 봉제' ? context.loc.t('봉제선_있음_내구성_우수', '봉제선 있음 · 내구성 우수') : context.loc.t('봉제선_없음_착용감_우수', '봉제선 없음 · 착용감 우수')"
    ),
    # L2714
    (
        "'선택한 길이는 성별에 따라 전원에게 동일하게 적용됩니다.'",
        "context.loc.t('선택한_길이는_성별에_따라_전원', '선택한 길이는 성별에 따라 전원에게 동일하게 적용됩니다.')"
    ),
    # L3047
    (
        "_dotRow('앞면·뒷면 디자인을 모두 첨부하시면 더욱 정확하게 제작됩니다.', Colors.purple.shade600),",
        "_dotRow(context.loc.t('앞면뒷면_디자인을_모두_첨부', '앞면·뒷면 디자인을 모두 첨부하시면 더욱 정확하게 제작됩니다.'), Colors.purple.shade600),"
    ),
    # L3762: title with interpolation — wrap just the static part, keep interpolation
    (
        "title: '인원별 사이즈 (총 $_totalCount명)',",
        "title: context.loc.t('인원별_사이즈_총_N명', '인원별 사이즈 (총 \${_totalCount}명)').replaceAll('\${_totalCount}', '\$_totalCount'),"
    ),
    # L4304
    (
        "hintText: _nameEnabled ? '이름 입력' : '10명 이상 시 입력',",
        "hintText: _nameEnabled ? context.loc.t('이름_입력', '이름 입력') : context.loc.t('10명_이상_시_입력', '10명 이상 시 입력'),"
    ),
    # L4391
    (
        "            '성별을 먼저 선택해 주세요',",
        "            context.loc.t('성별을_먼저_선택해_주세요', '성별을 먼저 선택해 주세요'),"
    ),
    # L4396
    (
        "      '위 남/여 버튼으로 성별을 선택하면 사이즈 입력이 활성화됩니다.'",
        "      context.loc.t('위_남여_버튼으로_성별을_선택', '위 남/여 버튼으로 성별을 선택하면 사이즈 입력이 활성화됩니다.')"
    ),
    # L5169
    (
        "_sumRow('기본 단가', '${_fmt(_basePrice)}원/인'),",
        "_sumRow(context.loc.t('기본_단가', '기본 단가'), '${_fmt(_basePrice)}원/인'),"
    ),
    # L5176
    (
        "_sumRow('인원당 단가 합계', '${_fmt(_unitPrice)}원/인', isSub: true),",
        "_sumRow(context.loc.t('인원당_단가_합계', '인원당 단가 합계'), '${_fmt(_unitPrice)}원/인', isSub: true),"
    ),
    # L5179
    (
        "_sumRow('총 인원', '$_totalCount명'),",
        "_sumRow(context.loc.t('총_인원', '총 인원'), '$_totalCount명'),"
    ),
    # L5181
    (
        "_sumRow('상품 합계', '${_fmt(_subTotal)}원'),",
        "_sumRow(context.loc.t('상품_합계', '상품 합계'), '${_fmt(_subTotal)}원'),"
    ),
    # L5199
    (
        "_sumRow('최종 결제금액', '${_fmt(_finalPrice)}원',",
        "_sumRow(context.loc.t('최종_결제금액', '최종 결제금액'), '${_fmt(_finalPrice)}원',"
    ),
    # L5223
    (
        "          '주문 내용을 모두 확인하였으며 구매에 동의합니다.'",
        "          context.loc.t('주문_내용을_모두_확인하였으며', '주문 내용을 모두 확인하였으며 구매에 동의합니다.')"
    ),
    # L5257
    (
        "              '주문하기',",
        "              context.loc.t('주문하기', '주문하기'),"
    ),
    # L5324
    (
        "                    '수령 후 3일 이내 교환·환불 가능',",
        "                    context.loc.t('수령_후_3일_이내_교환환불_가능', '수령 후 3일 이내 교환·환불 가능'),"
    ),
    # L5357
    (
        "                        '의류 자체 불량 외 교환·환불 불가',",
        "                        context.loc.t('의류_자체_불량_외_교환환불_불가', '의류 자체 불량 외 교환·환불 불가'),"
    ),
    # L5367
    (
        "                    '커스텀 제작 특성상 옷 자체의 하자가 아닌 경우\\n교환·환불이 불가합니다.'",
        "                    context.loc.t('커스텀_제작_특성상_옷_자체_하자', '커스텀 제작 특성상 옷 자체의 하자가 아닌 경우\\n교환·환불이 불가합니다.')"
    ),
]

apply_replacements(form_path, form_replacements)
print("Done group_order_form_screen.dart")

# ─── group_custom_order_screen.dart ───────────────────────────────────────
custom_path = '/home/user/webapp/lib/screens/orders/group_custom_order_screen.dart'
custom_replacements = [
    (
        "hasColor ? _selectedColor! : '색상을 선택하세요',",
        "hasColor ? _selectedColor! : context.loc.t('색상을_선택하세요', '색상을 선택하세요'),"
    ),
    (
        "                  '더 많은 색상 보기 · HEX 코드 직접 입력',",
        "                  context.loc.t('더_많은_색상_보기_HEX_코드_입력', '더 많은 색상 보기 · HEX 코드 직접 입력'),"
    ),
    (
        "                            '사이즈 입력 안내',",
        "                            context.loc.t('사이즈_입력_안내', '사이즈 입력 안내'),"
    ),
    (
        "                        '• 성인: S, M, L, XL, 2XL, 3XL',",
        "                        context.loc.t('성인_사이즈_목록', '• 성인: S, M, L, XL, 2XL, 3XL'),"
    ),
    (
        "                        '• 주니어: J-S, J-M, J-L, J-XL (앞에 J- 를 붙여주세요)',",
        "                        context.loc.t('주니어_사이즈_목록', '• 주니어: J-S, J-M, J-L, J-XL (앞에 J- 를 붙여주세요)'),"
    ),
    (
        "                    hint: '예) M, L, J-M',",
        "                    hint: context.loc.t('사이즈_예시_M_L_JM', '예) M, L, J-M'),"
    ),
    (
        "                          hint: '예) M, J-M',",
        "                          hint: context.loc.t('사이즈_예시_M_JM', '예) M, J-M'),"
    ),
]
apply_replacements(custom_path, custom_replacements)
print("Done group_custom_order_screen.dart")
