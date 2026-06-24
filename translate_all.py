#!/usr/bin/env python3
"""
한국어 문자열 → context.loc.t(key, 한국어) 자동 변환 스크립트
- 안전하게: const, top-level, switch, logic 등 위험 패턴 제외
- Text('...'), title:'...', hint:'...', label:'...', snackBar Text, 등 처리
"""
import re, hashlib, sys
from pathlib import Path

# ── 키 생성 ─────────────────────────────────────────────────────────────────
def make_key(text: str) -> str:
    clean = re.sub(r'[^가-힣a-zA-Z0-9]', '_', text.strip())
    clean = re.sub(r'_+', '_', clean).strip('_')
    if len(clean) > 40:
        h = hashlib.md5(text.encode()).hexdigest()[:6]
        clean = clean[:34] + '_' + h
    return clean or 'text'

def wrap(text: str) -> str:
    key = make_key(text)
    safe = text.replace("'", "\\'")
    return f"context.loc.t('{key}', '{safe}')"

# ── 라인 분류기 ──────────────────────────────────────────────────────────────
# 이 패턴이 줄에 포함되면 무조건 건너뜀 (이미 번역됨 or 위험)
SKIP_LINE_PATTERNS = [
    r'context\.loc\.t\(',          # already translated
    r'^\s*//',                      # comment
    r'\.loc\.t\(',                  # any .loc.t
    r' loc\.t\(',
    r'//.*[가-힣]',                  # inline comment Korean
    r'== \'[가-힣]',                 # equality check
    r'\' ==',
    r'\"== ',
    r'contains\(\'[가-힣]',         # logic check
    r'startsWith\(\'[가-힣]',
    r'endsWith\(\'[가-힣]',
    r'debugPrint\(',
    r'case \'[가-힣]',              # switch case
    r'log\(',
    r'assert\(',
    r'throw ',
    r'/// ',                        # doc comment
]

def should_skip_line(line: str) -> bool:
    for p in SKIP_LINE_PATTERNS:
        if re.search(p, line):
            return True
    return False

# ── static const / const Map/List 블록 추적용 ──────────────────────────────
# 블록 안에서는 context.loc.t 사용 불가 → 변환 안 함

def process_file(path: str) -> int:
    src = Path(path).read_text(encoding='utf-8')
    lines = src.splitlines(keepends=True)
    result = []
    changed_count = 0
    
    # const/static const 블록 depth 추적
    in_const_block = False
    const_depth = 0
    
    # top-level 함수 추적 (class 밖)
    # 단순화: State class 내부만 context 사용 가능 → class 체크
    brace_depth = 0
    class_brace_start = -1  # State class 시작 brace depth
    in_state_class = False
    
    for line in lines:
        stripped = line.rstrip()
        
        # ── static const / const 블록 감지 ─────────────────────────────────
        # 'static const ' 또는 'const [' 또는 'const {' 가 있으면 블록 시작
        if re.search(r'\bstatic\s+const\b|\bconst\s*[\[\{]', stripped):
            in_const_block = True
            const_depth = stripped.count('{') + stripped.count('[') - stripped.count('}') - stripped.count(']')
        elif in_const_block:
            const_depth += stripped.count('{') + stripped.count('[') - stripped.count('}') - stripped.count(']')
            if const_depth <= 0:
                in_const_block = False
                const_depth = 0
        
        # ── 변환 불필요 조건 ────────────────────────────────────────────────
        if not re.search(r'[가-힣]', stripped):
            result.append(line)
            continue
        
        if should_skip_line(stripped):
            result.append(line)
            continue
        
        if in_const_block:
            result.append(line)
            continue
        
        # ── 실제 변환 ───────────────────────────────────────────────────────
        new_line = transform_line(stripped)
        
        if new_line != stripped:
            changed_count += 1
            # 들여쓰기 유지
            indent = len(line) - len(line.lstrip())
            result.append(line[:indent] + new_line.lstrip() + '\n')
        else:
            result.append(line)
    
    new_src = ''.join(result)
    if new_src != src:
        Path(path).write_text(new_src, encoding='utf-8')
        print(f"  ✓ {path.split('/')[-1]}  ({changed_count} lines changed)")
    else:
        print(f"  — {path.split('/')[-1]}  (no changes)")
    return changed_count

def transform_line(line: str) -> str:
    """한 줄에서 한국어 문자열 리터럴을 context.loc.t 로 변환"""
    original = line
    
    # ── 1. const Text('한국어') → Text(context.loc.t(...)) ─────────────────
    line = re.sub(
        r'\bconst\s+Text\(\s*\'((?:[^\'$\n])*[가-힣](?:[^\'$\n])*)\'\s*\)',
        lambda m: f"Text({wrap(m.group(1))})",
        line
    )
    line = re.sub(
        r'\bconst\s+Text\(\s*\"((?:[^\"$\n])*[가-힣](?:[^\"$\n])*)\"\s*\)',
        lambda m: f"Text({wrap(m.group(1))})",
        line
    )
    
    # ── 2. Text('한국어') → Text(context.loc.t(...)) ────────────────────────
    # $ 보간 없는 것만
    line = re.sub(
        r'\bText\(\s*\'((?:[^\'$\n])*[가-힣](?:[^\'$\n])*)\'\s*\)',
        lambda m: f"Text({wrap(m.group(1))})",
        line
    )
    line = re.sub(
        r'\bText\(\s*\"((?:[^\"$\n])*[가-힣](?:[^\"$\n])*)\"\s*\)',
        lambda m: f"Text({wrap(m.group(1))})",
        line
    )
    
    # ── 3. 특정 named param: '한국어' → context.loc.t(...) ─────────────────
    NAMED_PROPS = [
        'title', 'subtitle', 'label', 'hint', 'hintText',
        'tooltip', 'semanticsLabel', 'helperText', 'errorText',
        'prefixText', 'suffixText', 'counterText', 'message',
        'placeholder', 'labelText', 'text', 'buttonText',
        'content',  # e.g. content: '...'
    ]
    for prop in NAMED_PROPS:
        # prop: '한국어'  ($ 없는 것만)
        line = re.sub(
            rf'(\b{prop}:\s*)\'((?:[^\'$\n])*[가-힣](?:[^\'$\n])*)\'',
            lambda m: f"{m.group(1)}{wrap(m.group(2))}",
            line
        )
        line = re.sub(
            rf'(\b{prop}:\s*)\"((?:[^\"$\n])*[가-힣](?:[^\"$\n])*)\"',
            lambda m: f"{m.group(1)}{wrap(m.group(2))}",
            line
        )
    
    # ── 4. _showSnack('한국어') ────────────────────────────────────────────
    line = re.sub(
        r"(_showSnack\(\s*)'((?:[^'$\n])*[가-힣](?:[^'$\n])*)'",
        lambda m: f"{m.group(1)}{wrap(m.group(2))}",
        line
    )
    
    # ── 5. SnackBar(content: Text('한국어')) — 이미 Text() 처리됨 ───────────
    
    # ── 6. 독립 문자열 인자: ('한국어', ...) 또는 ('한국어') ─────────────────
    # 함수 호출 내 첫번째 인자가 한국어 문자열인 경우
    # 예: row('상호', ...) / _statsKpiCard('총 매출', ...) 등
    # 단, context.loc.t 이미 있으면 스킵 (lookahead)
    line = re.sub(
        r"(?<!\.)(?<![A-Za-z0-9_])'((?:[^'$\n])*[가-힣](?:[^'$\n]*))'\s*,(?!\s*context\.loc)",
        lambda m: handle_standalone_str(m),
        line
    )
    
    return line

def handle_standalone_str(m: re.Match) -> str:
    text = m.group(1)
    # 이미 변환됐거나 $ 포함이면 그대로
    if 'context.loc.t' in text or '$' in text:
        return m.group(0)
    if not re.search(r'[가-힣]', text):
        return m.group(0)
    return f"{wrap(text)},"

# ── 메인 ─────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    files = sys.argv[1:]
    total = 0
    for f in files:
        total += process_file(f)
    print(f"\n총 {total} 라인 변환")
