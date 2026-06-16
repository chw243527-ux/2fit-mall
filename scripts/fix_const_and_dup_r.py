#!/usr/bin/env python3
"""
fix_const_and_dup_r.py
──────────────────────
1. "Not a constant expression" 에러:
   r.sp/r.w/r.h 를 포함하는 const 블록(const Row/Column/etc) 에서 const 제거

2. "'r' is already declared" 에러:
   같은 스코프 내 중복 r 선언 제거

처리 대상 파일: product_detail_screen.dart, home_screen.dart, main_screen.dart
"""
import re
import sys
from pathlib import Path

def remove_const_for_line(lines, error_idx):
    """
    error_idx 기준으로 위로 스캔하며 가장 가까운 const 키워드를 찾아 제거.
    const WidgetName( 또는 const [ 형태.
    반환: 수정된 라인 인덱스 or -1
    """
    for j in range(error_idx, max(error_idx - 50, -1), -1):
        line = lines[j]
        # const 가 있는 줄 찾기
        if re.search(r'\bconst\b', line):
            original = line
            # const 제거 (공백 포함)
            new_line = re.sub(r'\bconst\b\s*', '', line)
            if new_line != original:
                lines[j] = new_line
                return j
    return -1

def fix_duplicate_r(lines, dup_idx):
    """
    dup_idx 에 있는 이중 r 선언 중 하나 제거.
    Responsive.of(context) 쪽을 제거 (다른 r이 더 구체적이기 때문).
    단, 전후 맥락 확인 필요.
    """
    # dup_idx 줄의 내용
    line = lines[dup_idx]
    stripped = line.strip()
    
    # 만약 r = Responsive.of 이면 제거
    if 'final r = Responsive.of(context)' in line or 'final r = Responsive.of(ctx)' in line:
        lines[dup_idx] = ''
        # 다음 줄이 빈 줄이면 함께 제거
        if dup_idx + 1 < len(lines) and lines[dup_idx + 1].strip() == '':
            lines[dup_idx + 1] = ''
        return True
    return False

def find_all_const_issues(filepath):
    """
    파일 전체에서 const 블록 안에 r.sp/r.w/r.h 가 있는 경우를 찾아 수정.
    접근: r.sp/r.w/r.h 를 사용하는 줄을 찾고, 위로 스캔하여 해당 스코프를 
    열고 있는 const 가 있는지 확인.
    """
    lines = list(Path(filepath).read_text(encoding="utf-8").splitlines(keepends=True))
    
    # 모든 r.sp/r.w/r.h 사용 라인 찾기
    issues = []
    for i, line in enumerate(lines):
        if re.search(r'\br\.(sp|w|h)\(', line):
            # 위로 스캔하여 같은 depth의 const 찾기
            depth = 0
            for j in range(i, max(i - 80, -1), -1):
                l = lines[j]
                # 역방향 bracket counting
                for ch in reversed(l):
                    if ch in ')]}':
                        depth += 1
                    elif ch in '([{':
                        if depth > 0:
                            depth -= 1
                        else:
                            # depth 0에서 여는 bracket — 이 줄이 스코프 시작
                            if re.search(r'\bconst\b', l):
                                issues.append((i, j))
                            break
                else:
                    continue
                break
    
    return issues

def process_file(filepath):
    print(f"\n{'='*60}")
    print(f"처리: {filepath}")
    
    lines = list(Path(filepath).read_text(encoding="utf-8").splitlines(keepends=True))
    total_const_removed = 0
    total_dup_removed = 0
    
    # 반복하여 처리 (한 번에 모두 처리할 수 없을 수 있음)
    max_iterations = 10
    for iteration in range(max_iterations):
        changed = 0
        
        # r.sp/r.w/r.h 를 포함하는데 위에 const 가 있는 경우
        i = 0
        while i < len(lines):
            line = lines[i]
            if re.search(r'\br\.(sp|w|h)\(', line):
                # 위로 스캔하여 const 찾기 (depth 0 기준)
                depth = 0
                found_const_at = -1
                for j in range(i - 1, max(i - 80, -1), -1):
                    l = lines[j]
                    for ch in reversed(l.rstrip()):
                        if ch in ')]}':
                            depth += 1
                        elif ch in '([{':
                            if depth > 0:
                                depth -= 1
                            else:
                                # 이 { 또는 ( 가 현재 r 사용의 스코프 경계
                                if re.search(r'\bconst\b', l):
                                    found_const_at = j
                                break
                    if found_const_at >= 0:
                        break
                    # depth가 많이 음수가 되면 스코프를 벗어남
                    if depth < -3:
                        break
                
                if found_const_at >= 0:
                    original = lines[found_const_at]
                    new_line = re.sub(r'\bconst\b\s*', '', original, count=1)
                    if new_line != original:
                        lines[found_const_at] = new_line
                        print(f"  [const제거] L{found_const_at+1}: {original.rstrip()[:70]}")
                        print(f"               → {new_line.rstrip()[:70]}")
                        changed += 1
                        total_const_removed += 1
            i += 1
        
        # 중복 r 선언 찾기
        # 같은 스코프에 r=Responsive 와 r=other 가 함께 있는 경우
        i = 0
        while i < len(lines):
            line = lines[i]
            if 'final r = Responsive.of(context)' in line or 'final r = Responsive.of(ctx)' in line:
                # 다음 20줄 안에 또 다른 final r = (Responsive 아닌) 찾기
                for j in range(i + 1, min(i + 20, len(lines))):
                    if re.search(r'\bfinal\s+r\s*=\s*(?!Responsive)', lines[j]):
                        # 중복 — Responsive 줄 제거
                        print(f"  [dup r제거] L{i+1}: {line.rstrip()[:70]}")
                        lines[i] = ''
                        # 다음 줄이 빈 줄이면 함께 제거
                        if i + 1 < len(lines) and lines[i + 1].strip() == '':
                            lines[i + 1] = ''
                        changed += 1
                        total_dup_removed += 1
                        break
            i += 1
        
        if changed == 0:
            print(f"  iteration {iteration+1}: 변경 없음, 완료")
            break
        else:
            print(f"  iteration {iteration+1}: {changed}건 수정")
    
    print(f"  const 제거: {total_const_removed}건, 중복 r 제거: {total_dup_removed}건")
    
    Path(filepath).write_text("".join(lines), encoding="utf-8")
    return total_const_removed + total_dup_removed

def main():
    files = [
        "lib/screens/products/product_detail_screen.dart",
        "lib/screens/home/home_screen.dart",
        "lib/screens/main_screen.dart",
    ]
    total = 0
    for f in files:
        total += process_file(f)
    print(f"\n전체 수정: {total}건")

if __name__ == "__main__":
    main()
