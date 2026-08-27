# 2FIT MALL 스타일 정규화 보고서

## 적용 범위

반복적으로 사용되던 브랜드, 배경, 텍스트, 테두리, 상태 색상을 `AppColors` 토큰으로 통일했다. 대상은 `lib/screens`와 `lib/widgets`이며 총 41개 파일을 정리했다.

공통 `ThemeData`에는 버튼, 입력창, 카드, 대화상자, 칩, 체크박스, 라디오, 스위치, 스낵바, 플로팅 버튼의 스타일을 반영했다.

## 색상 기준

| 목적 | 공통 토큰 |
|---|---|
| 브랜드 기본 | `AppColors.primary` |
| 보조 브랜드 | `AppColors.primaryLight` |
| 주요 강조 | `AppColors.accent` |
| 성공 | `AppColors.success` |
| 오류 | `AppColors.error` |
| 경고 | `AppColors.warning` |
| 안내 | `AppColors.info` |
| 본문·보조 텍스트 | `AppColors.textPrimary`, `AppColors.textSecondary` |
| 배경·표면·테두리 | `AppColors.background`, `AppColors.surface`, `AppColors.surfaceGray`, `AppColors.border` |

상태색은 의미 전달을 위해 유지했고, 투명도는 `withValues(alpha: ...)`로 표현했다. 사용자 지정 색상 선택기와 상품 색상 견본처럼 사용자가 직접 선택하거나 상품 데이터를 시각화하는 색상은 브랜드 토큰으로 강제하지 않았다.

## 검증 결과

```text
Flutter analyze: 신규 error 0건
Flutter Web release build: 성공
Flutter test: 54개 통과
```

분석 결과에 남은 항목은 기존 info/warning 수준이며, 이번 스타일 변경으로 새 컴파일 오류는 발생하지 않았다.

## 운영 반영

현재 변경사항은 로컬 작업 공간에 반영되어 있다. 운영 사이트에 적용하려면 변경 파일을 검토한 뒤 GitHub `main` 브랜치에 커밋하고 GitHub Actions 성공 여부를 확인해야 한다.
