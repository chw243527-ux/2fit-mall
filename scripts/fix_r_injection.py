#!/usr/bin/env python3
"""
fix_r_injection.py
──────────────────
잘못된 r 주입 위치를 정확히 찾아 제거하고 올바른 body { 뒤에 재삽입한다.

핵심 로직:
  - `final r = Responsive.of(context);` 줄을 탐색
  - 해당 줄 위로 거슬러 올라가 해당 r이 어느 '여는 {' 뒤에 있는지 확인
  - 파라미터 목록 여는 { : `Widget/..._name({` 패턴 (닫는 }) 없이 열린 상태)
  - Body { : `) {` 또는 `=> {` 또는 단독으로 끝나는 `{` (파라미터 닫힌 후)
  - 잘못된 위치(파라미터 목록 안) → 제거
  - 올바른 body { 위치 찾아 다음 줄에 삽입 (이미 없을 경우에만)
"""

import re
import sys
import shutil
from pathlib import Path

R_INJECT = "    final r = Responsive.of(context);\n"
# SliverPersistentHeaderDelegate build 메서드는 ctx 사용
R_INJECT_CTX = "    final r = Responsive.of(ctx);\n"

def is_r_inject_line(line: str) -> bool:
    stripped = line.strip()
    return (stripped == "final r = Responsive.of(context);" or
            stripped == "final r = Responsive.of(ctx);")

def get_indent(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]

def find_matching_close(lines, open_idx, open_char="{", close_char="}"):
    """open_idx 줄에서 open_char가 시작된다고 가정하고 matching close 위치 반환"""
    depth = 0
    for i in range(open_idx, len(lines)):
        for ch in lines[i]:
            if ch == open_char:
                depth += 1
            elif ch == close_char:
                depth -= 1
                if depth == 0:
                    return i
    return -1

def analyze_r_injection(lines, r_line_idx):
    """
    r_line_idx 번째 줄의 r 주입이 올바른지(body { 뒤) 아닌지(param { 뒤) 판단.
    
    반환값:
      'bad'  → 파라미터 목록 안에 삽입됨
      'good' → body 안에 올바르게 삽입됨
      'ctx_ok' → ctx 기반 올바른 삽입
    """
    # r_line_idx 위로 첫 번째로 의미있는 여는 { 를 찾는다
    # depth counting으로 현재 r이 속한 { 블록의 시작을 찾는다
    depth = 0
    for i in range(r_line_idx - 1, -1, -1):
        line = lines[i]
        # 역방향으로 { } 카운트
        for ch in reversed(line):
            if ch == "}":
                depth += 1
            elif ch == "{":
                if depth == 0:
                    # 이 { 가 r이 속한 블록의 시작
                    return classify_opening_brace(lines, i, line)
                depth -= 1
    return 'unknown'

def classify_opening_brace(lines, line_idx, line):
    """
    주어진 줄의 마지막 { 가 param list 여는 { 인지 body { 인지 판단.
    
    판단 기준:
      - `Widget/Type _methodName({`  → param list (BAD)
      - `) {`  → body (GOOD)
      - `{` 만 있는 줄 또는 `=> {` → body (GOOD)
      - `build(BuildContext ctx, ...)` 같은 줄 끝 { → body (GOOD, but ctx)
    """
    stripped = line.rstrip()
    
    # 파라미터 목록 여는 패턴: 함수명 다음에 ({ 로 끝남
    # 예: `Widget _topIcon({`, `  Widget _foo({`, `String _bar({`
    # 정규식: 줄이 타입/키워드 + 공백 + 식별자 + `({` 로 끝남
    if re.search(r'\w+\s*\(\s*\{\s*$', stripped):
        # 하지만 `) {` 이 아니고 `({` 형태이면 param list
        # `) {` 형태면 body
        if re.search(r'\)\s*\{\s*$', stripped):
            # `) {` 도 있지만 `({` 도 있는 경우 — `) {` 우선
            return 'good'
        return 'bad'
    
    # `) {` 로 끝나면 body
    if re.search(r'\)\s*\{\s*$', stripped):
        return 'good'
    
    # `=> {` 로 끝나면 body
    if re.search(r'=>\s*\{\s*$', stripped):
        return 'good'
    
    # 줄 전체가 `{` 이면 body (class/if/for 등)
    if stripped.endswith('{') and not re.search(r'\(\s*\{', stripped):
        return 'good'
    
    return 'unknown'

def find_body_open_brace(lines, bad_r_idx):
    """
    bad_r_idx 위로 올라가 잘못된 r이 속한 param { 를 찾고,
    그 param 목록의 closing } 다음에 오는 `) {` (body brace)를 찾는다.
    
    반환: body { 가 있는 라인 인덱스, 없으면 -1
    """
    # 1단계: bad_r 위로 올라가서 param-list 여는 { 위치 찾기
    depth = 0
    param_open_idx = -1
    for i in range(bad_r_idx - 1, -1, -1):
        line = lines[i]
        for ch in reversed(line):
            if ch == "}":
                depth += 1
            elif ch == "{":
                if depth == 0:
                    param_open_idx = i
                    break
                depth -= 1
        if param_open_idx >= 0:
            break
    
    if param_open_idx < 0:
        return -1
    
    # 2단계: param_open_idx 에서 시작하여 matching } 찾기 (forward)
    # 이 { 는 param list의 { 이므로 closing } 을 찾으면 된다
    depth = 0
    param_close_idx = -1
    for i in range(param_open_idx, len(lines)):
        for ch in lines[i]:
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    param_close_idx = i
                    break
        if param_close_idx >= 0:
            break
    
    if param_close_idx < 0:
        return -1
    
    # 3단계: param_close_idx 이후 `) {` 패턴 찾기 (보통 같은 줄 또는 다음 줄)
    for i in range(param_close_idx, min(param_close_idx + 5, len(lines))):
        line = lines[i].rstrip()
        if re.search(r'\)\s*\{\s*$', line):
            return i
        # `}) {` 패턴
        if re.search(r'\}\)\s*\{\s*$', line):
            return i
    
    return -1

def already_has_r_inject(lines, body_brace_idx):
    """body_brace_idx 다음 줄에 이미 r 주입이 있는지 확인"""
    next_idx = body_brace_idx + 1
    if next_idx < len(lines):
        if is_r_inject_line(lines[next_idx]):
            return True
        # 빈 줄 건너뛰고 확인
        if lines[next_idx].strip() == "" and next_idx + 1 < len(lines):
            if is_r_inject_line(lines[next_idx + 1]):
                return True
    return False

def fix_file(filepath: str, dry_run: bool = False) -> int:
    """파일을 분석하고 잘못된 r 주입을 수정. 수정 개수 반환."""
    path = Path(filepath)
    if not path.exists():
        print(f"파일 없음: {filepath}")
        return 0
    
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    
    bad_indices = []  # 제거할 r 주입 라인 인덱스
    insert_positions = {}  # {삽입할 body_brace_idx: r_inject_str}
    
    for i, line in enumerate(lines):
        if not is_r_inject_line(line):
            continue
        
        result = analyze_r_injection(lines, i)
        
        if result == 'bad':
            print(f"  [BAD]  L{i+1}: {line.rstrip()}")
            bad_indices.append(i)
            
            # 올바른 body { 찾기
            body_idx = find_body_open_brace(lines, i)
            if body_idx >= 0:
                print(f"         → body {{ at L{body_idx+1}: {lines[body_idx].rstrip()}")
                if not already_has_r_inject(lines, body_idx):
                    # r inject 문자열 결정 (ctx or context)
                    ctx_in_body = "ctx" in lines[body_idx]
                    inject_str = R_INJECT_CTX if ctx_in_body else R_INJECT
                    insert_positions[body_idx] = inject_str
                    print(f"         → 재삽입 예정: {inject_str.rstrip()}")
                else:
                    print(f"         → 이미 올바른 r 주입 있음, 재삽입 불필요")
            else:
                print(f"         → body {{ 위치를 찾지 못함! 수동 확인 필요")
        elif result == 'good':
            pass  # 올바른 위치
        elif result == 'ctx_ok':
            pass
        else:
            print(f"  [UNK]  L{i+1}: {line.rstrip()} (분류 불가)")
    
    if not bad_indices and not insert_positions:
        print(f"  수정 불필요 (이미 올바름)")
        return 0
    
    print(f"\n  제거할 라인 수: {len(bad_indices)}")
    print(f"  삽입할 위치 수: {len(insert_positions)}")
    
    if dry_run:
        print("  [DRY RUN] 실제 수정은 하지 않음")
        return len(bad_indices)
    
    # 백업
    backup_path = path.with_suffix(path.suffix + ".bak")
    shutil.copy2(path, backup_path)
    print(f"  백업: {backup_path}")
    
    # 뒤에서부터 처리 (인덱스 변화 방지)
    all_bad_set = set(bad_indices)
    
    # 새 라인 목록 구성
    new_lines = []
    for i, line in enumerate(lines):
        if i in all_bad_set:
            # 잘못된 r 주입 라인 제거
            # 바로 다음이 빈 줄이면 함께 제거 (깔끔하게)
            # (아래 루프에서 처리)
            continue
        
        # 잘못된 r 다음 빈 줄도 제거
        if i > 0 and (i - 1) in all_bad_set and line.strip() == "":
            continue
        
        new_lines.append((i, line))
    
    # 삽입 처리: body_brace_idx 이후에 r 주입 삽입
    # bad 라인들이 제거되면서 인덱스가 바뀌므로, 원본 인덱스 기준으로 처리
    # new_lines 는 (orig_idx, line) 튜플 리스트
    
    final_lines = []
    for orig_i, line in new_lines:
        final_lines.append(line)
        if orig_i in insert_positions:
            final_lines.append(insert_positions[orig_i])
    
    path.write_text("".join(final_lines), encoding="utf-8")
    print(f"  저장 완료: {filepath}")
    return len(bad_indices)

def main():
    files = [
        "lib/screens/main_screen.dart",
        "lib/screens/products/product_detail_screen.dart",
        "lib/screens/home/home_screen.dart",
    ]
    
    dry_run = "--dry-run" in sys.argv
    if dry_run:
        print("=== DRY RUN MODE ===\n")
    
    total = 0
    for f in files:
        print(f"\n{'='*60}")
        print(f"파일: {f}")
        print('='*60)
        count = fix_file(f, dry_run=dry_run)
        total += count
    
    print(f"\n{'='*60}")
    print(f"총 수정: {total}개")

if __name__ == "__main__":
    main()
