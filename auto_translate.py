#!/usr/bin/env python3
"""
자동 번역 래핑 스크립트
- 한국어 문자열 리터럴을 context.loc.t('key', '한국어') 패턴으로 변환
- const Text(...) → const 제거
- top-level / static const 내부 문자열은 한국어 직접 유지
"""
import re, sys, hashlib

def make_key(text):
    """한국어 → snake_case key + 짧은 해시"""
    clean = re.sub(r'[^가-힣a-zA-Z0-9]', '_', text.strip())
    clean = re.sub(r'_+', '_', clean).strip('_')
    # 40자 이상이면 짧은 해시 suffix
    if len(clean) > 40:
        h = hashlib.md5(text.encode()).hexdigest()[:6]
        clean = clean[:34] + '_' + h
    return clean

def wrap(text):
    key = make_key(text)
    return f"context.loc.t('{key}', '{text}')"

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()
    
    original = src
    
    # ── 패턴 1: 이미 context.loc.t로 래핑된 것 건너뜀 ──────────────────────
    # (정규식에서 lookahead로 처리)
    
    # ── 패턴 2: Text('한국어') → Text(context.loc.t('key','한국어'))
    # const Text('한국어') → Text(context.loc.t('key','한국어'))  (const 제거)
    
    def replace_text_widget(m):
        indent = m.group(1)
        const_kw = m.group(2)  # 'const ' or ''
        quote = m.group(3)     # ' or "
        text = m.group(4)
        other_quote = '"' if quote == "'" else "'"
        # 이미 context.loc.t 포함이면 스킵
        if 'context.loc.t' in text or 'loc.t(' in text:
            return m.group(0)
        # 한국어 없으면 스킵
        if not re.search(r'[가-힣]', text):
            return m.group(0)
        # $ 보간 있으면 스킵 (복잡)
        if '$' in text:
            return m.group(0)
        key = make_key(text)
        safe_text = text.replace("'", "\\'")
        return f"{indent}Text(context.loc.t('{key}', '{safe_text}')"
    
    # Text('한국어') — 인용부호 내부에 $ 없는 것만
    src = re.sub(
        r'([ \t]*)(const )?Text\((\'|")([^\'\"$\n]+?)\3\)',
        lambda m: replace_text_widget_simple(m),
        src
    )
    
    # ── 패턴 3: title: '한국어' / subtitle: / label: / hint: / hintText: / tooltip: / semanticsLabel: / heroTag:
    props = ['title', 'subtitle', 'label', 'hint', 'hintText', 'tooltip', 'semanticsLabel',
             'helperText', 'errorText', 'prefixText', 'suffixText', 'counterText',
             'message', 'text', 'placeholder', 'value']
    for prop in props:
        src = re.sub(
            rf"({prop}:\s*)(\'|\")((?:(?!\2)[^$\n])*[가-힣](?:(?!\2)[^$\n])*)\2(?!\s*\))",
            lambda m, p=prop: replace_named_prop(m, p),
            src
        )
    
    if src != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(src)
        changed = sum(1 for a,b in zip(original.splitlines(), src.splitlines()) if a!=b)
        print(f"  Saved {path.split('/')[-1]}  (~{changed} lines changed)")
    else:
        print(f"  No changes: {path.split('/')[-1]}")

def replace_text_widget_simple(m):
    const_kw = m.group(2)  # 'const ' or None
    q = m.group(3)
    text = m.group(4)
    if 'context.loc.t' in text or 'loc.t(' in text:
        return m.group(0)
    if not re.search(r'[가-힣]', text):
        return m.group(0)
    if '$' in text:
        return m.group(0)
    indent = m.group(1) or ''
    key = make_key(text)
    safe = text.replace("'", "\\'")
    # Remove 'const ' if present since context.loc.t is runtime
    return f"{indent}Text(context.loc.t('{key}', '{safe}'))"

def replace_named_prop(m, prop):
    prefix = m.group(1)
    q = m.group(2)
    text = m.group(3)
    if 'context.loc.t' in text or 'loc.t(' in text:
        return m.group(0)
    if not re.search(r'[가-힣]', text):
        return m.group(0)
    if '$' in text:
        return m.group(0)
    key = make_key(text)
    safe = text.replace("'", "\\'")
    return f"{prefix}context.loc.t('{key}', '{safe}')"

if __name__ == '__main__':
    for p in sys.argv[1:]:
        process_file(p)
