#!/usr/bin/env python3
"""잔여 항목 처리: order_guide example 값 + checkout $ 보간 + 기타"""
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


# ─── order_guide_screen.dart: example 값 번역 적용 ──────────────────────────
# f['example']! → 동적 번역 적용 (context.loc.t)
process('lib/screens/orders/order_guide_screen.dart', [
    # example 값도 번역 처리 (동적 번역으로 _buildFormCard 내 example 텍스트 처리)
    # L789: child: Text(f['example']! ...) → context.loc.t
    (
        "child: Text(f['example']!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))",
        "child: Text(context.loc.t('order_example_${f[\\'example\\']!.replaceAll(\\' \\', \\'_\\').replaceAll(\\'/\\', \\'_\\')}', f['example']!), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))"
    ),
])


# ─── checkout_screen.dart: $ 보간 포함 텍스트 처리 ────────────────────────────
# '저장된 배송지 ${savedList.length}개' → Text에서 직접 loc.t 불가, 
# 실용적으로: '저장된 배송지 ' + ... + '개' 형태로 바꾸거나, 그냥 번역 키 안에 포함
# 단순하게 처리: prefix 번역 + 숫자 + suffix 번역
p = Path('lib/screens/orders/checkout_screen.dart')
src = p.read_text(encoding='utf-8')
orig = src

# '저장된 배송지 ${savedList.length}개' — $ 포함, 번역 패턴으로 분리
src = src.replace(
    "'저장된 배송지 ${savedList.length}개'",
    "context.loc.t('저장된_배송지', '저장된 배송지') + ' ${savedList.length}' + context.loc.t('개', '개')"
)

# '팀원 명단 (${persons.length}명)' — $ 포함
src = src.replace(
    "Text('팀원 명단 (${persons.length}명)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)))",
    "Text('${context.loc.t(\\'팀원_명단\\', \\'팀원 명단\\')} (${persons.length}${context.loc.t(\\'명\\', \\'명\\')})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)))"
)

# '• 입금자명을 반드시 "$customerName"으로 입력해 주세요.\n...' — $ 포함
src = src.replace(
    "'• 입금자명을 반드시 \"$customerName\"으로 입력해 주세요.\\n'\n                                '• 입금 확인 후 주문이 처리됩니다 (영업일 기준 1일 이내).\\n'\n                                '• 기한 내 미입금 시 주문이 자동 취소됩니다.',",
    "context.loc.t('입금_안내_주의사항', '• 입금자명을 반드시 \"$customerName\"으로 입력해 주세요.\\n• 입금 확인 후 주문이 처리됩니다 (영업일 기준 1일 이내).\\n• 기한 내 미입금 시 주문이 자동 취소됩니다.'),"
)

if src != orig:
    p.write_text(src, encoding='utf-8')
    print(f"✓ lib/screens/orders/checkout_screen.dart ($ interpolation handled)")
else:
    print("  (no changes) checkout_screen.dart")


print("\n✅ 잔여 항목 처리 완료!")
