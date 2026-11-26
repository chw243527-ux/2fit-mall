#!/usr/bin/env python3
"""Refactor the six priority customer-facing purple UI elements to NEXTR sky blue.

This script is intentionally narrow: it does not touch admin-only colors, product
color palettes, payment-provider colors, semantic status colors, or Excel styles.

Usage:
    python3 tools/refactor_nextr_skyblue.py --check
    python3 tools/refactor_nextr_skyblue.py --apply
"""
from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Each replacement is an exact source snippet. The expected count protects against
# accidentally changing unrelated purple UI if the source changes later.
REPLACEMENTS: list[tuple[str, str, str, int]] = [
    (
        "web/index.html",
        "background:#6C63FF;color:white;border:none;",
        "background:#6FAFC8;color:white;border:none;",
        1,
    ),
    (
        "lib/screens/home/home_screen.dart",
        "colors: [AppColors.primaryLight, Color(0xFF9C27B0)]",
        "colors: [AppColors.primaryLight, AppColors.accent]",
        2,
    ),
    (
        "lib/screens/home/home_screen.dart",
        "? const Color(0xFF9C27B0).withValues(alpha: 0.35)",
        "? AppColors.accent.withValues(alpha: 0.35)",
        1,
    ),
    (
        "lib/screens/home/home_screen.dart",
        "          color: const Color(0xFFF3E5F5),\n          borderRadius: BorderRadius.circular(8),\n        ),\n        child: Row(mainAxisSize: MainAxisSize.min, children: [",
        "          color: AppColors.accentLight,\n          borderRadius: BorderRadius.circular(8),\n        ),\n        child: Row(mainAxisSize: MainAxisSize.min, children: [",
        1,
    ),
    (
        "lib/screens/products/product_detail_screen.dart",
        "color: const Color(0xFF6C63FF),\n                  label: context.loc.t('링크_복사', '링크 복사'),",
        "color: AppColors.accent,\n                  label: context.loc.t('링크_복사', '링크 복사'),",
        1,
    ),
    (
        "lib/screens/mypage/mypage_screen.dart",
        "colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)]",
        "colors: [AppColors.accentLight, AppColors.accentLight]",
        1,
    ),
    (
        "lib/screens/mypage/mypage_screen.dart",
        "color: const Color(0xFF7B1FA2)\n                                  .withValues(alpha: 0.25)",
        "color: AppColors.accent.withValues(alpha: 0.25)",
        1,
    ),
    (
        "lib/screens/mypage/mypage_screen.dart",
        "color: const Color(0xFF7B1FA2),\n                                    borderRadius: BorderRadius.circular(8),",
        "color: AppColors.accent,\n                                    borderRadius: BorderRadius.circular(8),",
        1,
    ),
    (
        "lib/screens/mypage/mypage_screen.dart",
        "color: Color(0xFF7B1FA2))),",
        "color: AppColors.accent))),",
        2,
    ),
    (
        "lib/screens/mypage/mypage_screen.dart",
        "color: const Color(0xFF7B1FA2),\n                                    borderRadius: BorderRadius.circular(12),",
        "color: AppColors.accent,\n                                    borderRadius: BorderRadius.circular(12),",
        1,
    ),
    (
        "lib/screens/orders/group_custom_order_screen.dart",
        "color: const Color(0xFFF3E5F5)",
        "color: AppColors.accentLight",
        3,
    ),
    (
        "lib/screens/orders/group_custom_order_screen.dart",
        "color: sel ? const Color(0xFFF3E5F5) : Colors.white",
        "color: sel ? AppColors.accentLight : Colors.white",
        2,
    ),
    (
        "lib/widgets/address_search_widget.dart",
        "color: const Color(0xFFF3E5F5),\n              child: Text(",
        "color: AppColors.accentLight,\n              child: Text(",
        1,
    ),
    (
        "lib/widgets/overseas_rate_sheet.dart",
        "color: const Color(0xFFF3E5F5),\n                borderRadius: BorderRadius.circular(10),\n                border: Border.all(\n                    color: const Color(0xFF9C27B0).withValues(alpha: 0.25)),",
        "color: AppColors.accentLight,\n                borderRadius: BorderRadius.circular(10),\n                border: Border.all(\n                    color: AppColors.accent.withValues(alpha: 0.25)),",
        1,
    ),
]


def validate_and_transform(apply: bool) -> int:
    errors: list[str] = []
    source_by_path: dict[Path, str] = {}
    transformed_by_path: dict[Path, str] = {}

    for rel, old, new, expected in REPLACEMENTS:
        path = ROOT / rel
        if not path.exists():
            errors.append(f"missing file: {rel}")
            continue
        if path not in source_by_path:
            source_by_path[path] = path.read_text(encoding="utf-8")
            transformed_by_path[path] = source_by_path[path]
        text = transformed_by_path[path]
        count = text.count(old)
        if count != expected:
            errors.append(
                f"{rel}: expected {expected} match(es), found {count}\n"
                f"  snippet: {old!r}"
            )
            continue
        transformed_by_path[path] = text.replace(old, new)

    if errors:
        print("Refactor aborted; source did not match expected patterns:")
        print("\n".join(f"- {error}" for error in errors))
        return 1

    print(f"Validated {len(REPLACEMENTS)} exact replacements across {len(source_by_path)} files.")
    if not apply:
        print("Check only: no files changed. Run with --apply to write changes.")
        return 0

    for path, new_text in transformed_by_path.items():
        path.write_text(new_text, encoding="utf-8")
        print(f"updated {path.relative_to(ROOT)}")
    print("Applied sky-blue refactor. Review with: git diff --check && git diff")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="validate all exact matches without changing files")
    mode.add_argument("--apply", action="store_true", help="validate and apply the refactor")
    args = parser.parse_args()
    return validate_and_transform(apply=args.apply)


if __name__ == "__main__":
    raise SystemExit(main())
