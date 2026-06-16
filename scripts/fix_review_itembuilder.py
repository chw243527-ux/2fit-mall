#!/usr/bin/env python3
"""
fix_review_itembuilder.py
product_detail_screen.dart의 itemBuilder 블록에서
rev.userId / rev.userName 등 review 관련 r. 참조를 rev. 으로 교체
그리고 _chip arrow function을 block body로 변환
"""
from pathlib import Path
import re

filepath = "lib/screens/products/product_detail_screen.dart"
lines = Path(filepath).read_text(encoding="utf-8").splitlines(keepends=True)

# 수정 1: itemBuilder 블록에서 r.userId/r.userName 등 review 속성을 rev. 으로 변경
# 범위: final rev = reviews[i]; 라인부터 해당 블록 끝까지
# 식별: r.userId, r.userName, r.rating, r.createdAt, r.size, r.color, r.content, r.images

review_props = {'userId', 'userName', 'rating', 'createdAt', 'size', 'color', 'content', 'images', 'id', 'productId'}

# itemBuilder 블록 찾기
start_idx = -1
for i, line in enumerate(lines):
    if "final rev = reviews[i];" in line:
        start_idx = i
        break

if start_idx < 0:
    print("ERROR: itemBuilder 블록 시작을 찾지 못함")
    exit(1)

print(f"itemBuilder 블록 시작: L{start_idx+1}")

# 블록 끝 찾기 (itemBuilder 의 } 를 찾음)
# start_idx 위로 itemBuilder: (_, i) { 찾기
block_open_idx = -1
for i in range(start_idx, max(start_idx-5, -1), -1):
    if "itemBuilder: (_, i) {" in lines[i]:
        block_open_idx = i
        break

print(f"itemBuilder {{ at L{block_open_idx+1}")

# block_open_idx 부터 끝 } 찾기
depth = 0
block_end_idx = -1
for i in range(block_open_idx, len(lines)):
    for ch in lines[i]:
        if ch == '{': depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                block_end_idx = i
                break
    if block_end_idx >= 0:
        break

print(f"itemBuilder 블록 끝: L{block_end_idx+1}")

# 블록 내에서 r.<review_prop> 를 rev.<review_prop> 으로 변경
# 단, r.sp/r.w/r.h 는 제외
changes = 0
for i in range(start_idx, block_end_idx + 1):
    original = lines[i]
    new_line = original
    
    for prop in review_props:
        # r.prop (단, r.sp, r.w, r.h 같은 것과 구분)
        # 패턴: r.<prop> 뒤에 . 또는 [ 또는 공백 또는 )
        pattern = rf'\br\.({re.escape(prop)})\b'
        replacement = rf'rev.\1'
        new_line = re.sub(pattern, replacement, new_line)
    
    # _showWriteReviewDialog(existing: r) → existing: rev
    new_line = new_line.replace("_showWriteReviewDialog(existing: r)", "_showWriteReviewDialog(existing: rev)")
    # _deleteReview(r) → _deleteReview(rev)  
    new_line = new_line.replace("_deleteReview(r)", "_deleteReview(rev)")
    
    if new_line != original:
        changes += 1
        print(f"  L{i+1}: {original.rstrip()[:80]}")
        print(f"       → {new_line.rstrip()[:80]}")
    lines[i] = new_line

print(f"\n변경: {changes}곳")

# 수정 2: _chip arrow function을 block body로 변환
# 현재: Widget _chip(String text) => Container(
#         padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
# 변환: Widget _chip(String text) { final r = Responsive.of(context); return Container(

# _chip 함수 위치 찾기
chip_idx = -1
for i, line in enumerate(lines):
    if "Widget _chip(String text) =>" in line:
        chip_idx = i
        break

if chip_idx >= 0:
    print(f"\n_chip arrow function at L{chip_idx+1}")
    # => Container( 를 { final r = ... return Container( 으로 변환
    # 먼저 arrow function 전체 범위 파악
    # _chip arrow function 끝 찾기 (세미콜론 또는 다음 메서드)
    chip_end = -1
    paren_depth = 0
    started = False
    for i in range(chip_idx, len(lines)):
        for ch in lines[i]:
            if ch in '([{':
                paren_depth += 1
                started = True
            elif ch in ')]}':
                paren_depth -= 1
                if started and paren_depth == 0:
                    chip_end = i
                    break
        if chip_end >= 0:
            break
    
    print(f"_chip 끝: L{chip_end+1}")
    
    # arrow function을 block body로 변환
    # L{chip_idx}: `  Widget _chip(String text) => Container(`
    # → `  Widget _chip(String text) {`
    # → `    final r = Responsive.of(context);`
    # → `    return Container(`
    # L{chip_end}: `  );` → `  );`
    # → `  }`
    
    old_first = lines[chip_idx]
    indent = old_first[:len(old_first) - len(old_first.lstrip())]
    # arrow function 첫 줄: `=> Container(` 부분 처리
    first_content = old_first.rstrip()
    # `Widget _chip(String text) => Container(` → `Widget _chip(String text) {`
    new_first = re.sub(r'\s*=>\s*Container\s*\(', '', first_content)
    new_first = new_first.rstrip() + ' {\n'
    
    # chip_idx+1 에 r 주입 줄 삽입
    # chip_end 줄의 `);` 를 `);` + `}` 로 변경
    
    # 새 라인 구성
    new_lines = []
    for i, line in enumerate(lines):
        if i == chip_idx:
            new_lines.append(new_first)
            new_lines.append(indent + '  final r = Responsive.of(context);\n')
            new_lines.append(indent + '  return Container(\n')
        elif i == chip_end:
            # `  );` → `  );` + newline + `  }`
            new_lines.append(line)
            # 현재 줄의 indent 기준으로 닫는 } 추가
            new_lines.append(indent + '}\n')
        else:
            new_lines.append(line)
    
    lines = new_lines
    print(f"_chip arrow → block body 변환 완료")
else:
    print("\n_chip arrow function 없음 (이미 변환됨 또는 존재하지 않음)")

# 수정 3: _tag arrow function 확인 및 변환
# Widget _tag(String text, Color color) => Container(
tag_idx = -1
for i, line in enumerate(lines):
    if "Widget _tag(String text, Color color) =>" in line:
        tag_idx = i
        break

if tag_idx >= 0:
    print(f"\n_tag arrow function at L{tag_idx+1}")
    tag_end = -1
    paren_depth = 0
    started = False
    for i in range(tag_idx, len(lines)):
        for ch in lines[i]:
            if ch in '([{':
                paren_depth += 1
                started = True
            elif ch in ')]}':
                paren_depth -= 1
                if started and paren_depth == 0:
                    tag_end = i
                    break
        if tag_end >= 0:
            break
    
    print(f"_tag 끝: L{tag_end+1}")
    old_first = lines[tag_idx]
    indent = old_first[:len(old_first) - len(old_first.lstrip())]
    first_content = old_first.rstrip()
    new_first = re.sub(r'\s*=>\s*Container\s*\(', '', first_content)
    new_first = new_first.rstrip() + ' {\n'
    
    new_lines2 = []
    for i, line in enumerate(lines):
        if i == tag_idx:
            new_lines2.append(new_first)
            new_lines2.append(indent + '  final r = Responsive.of(context);\n')
            new_lines2.append(indent + '  return Container(\n')
        elif i == tag_end:
            new_lines2.append(line)
            new_lines2.append(indent + '}\n')
        else:
            new_lines2.append(line)
    
    lines = new_lines2
    print(f"_tag arrow → block body 변환 완료")

Path(filepath).write_text("".join(lines), encoding="utf-8")
print(f"\n저장 완료: {filepath}")
