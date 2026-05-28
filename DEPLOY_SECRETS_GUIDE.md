# 2FIT MALL — 배포 Secrets 설정 가이드

> **최종 수정**: 2026-05-28  
> 배포 플랫폼: **Cloudflare Pages** (GitHub Actions 자동 배포) + **GitHub Pages** (수동)

---

## 목차
1. [GitHub Repository Secrets 설정](#1-github-repository-secrets-설정)
2. [Cloudflare API 토큰 발급](#2-cloudflare-api-토큰-발급)
3. [Cloudflare 계정 ID 확인](#3-cloudflare-계정-id-확인)
4. [GitHub Pages 토큰 발급 (수동 배포용)](#4-github-pages-토큰-발급-수동-배포용)
5. [배포 흐름 확인](#5-배포-흐름-확인)
6. [자주 발생하는 오류 해결](#6-자주-발생하는-오류-해결)

---

## 1. GitHub Repository Secrets 설정

GitHub Actions 워크플로우가 사용하는 Secrets 를 등록합니다.

### 경로
```
GitHub 저장소 → Settings → Secrets and variables → Actions → New repository secret
```

### 필수 Secrets 목록

| Secret 이름               | 설명                                  | 발급 방법             |
|--------------------------|--------------------------------------|--------------------|
| `CLOUDFLARE_API_TOKEN`   | Cloudflare Pages 배포 권한 토큰         | [섹션 2](#2-cloudflare-api-토큰-발급) 참조 |
| `CLOUDFLARE_ACCOUNT_ID`  | Cloudflare 계정 식별자                  | [섹션 3](#3-cloudflare-계정-id-확인) 참조  |

> ⚠️ Secrets는 등록 후 값을 다시 볼 수 없습니다. 안전한 곳에 별도 보관하세요.

---

## 2. Cloudflare API 토큰 발급

### 단계별 가이드

**① Cloudflare 대시보드 접속**
```
https://dash.cloudflare.com/profile/api-tokens
```

**② "Create Token" 클릭**

**③ 템플릿 선택: "Edit Cloudflare Workers"**  
(또는 Custom token 으로 직접 설정)

**④ Custom Token 권한 설정 (권장)**

| 섹션 | 권한 |
|------|------|
| Account | Cloudflare Pages — **Edit** |
| Account | Account Settings — **Read** |

> `Zone` 권한은 필요 없습니다.

**⑤ Account Resources**
- Include: `All accounts` 또는 특정 계정 선택

**⑥ "Continue to summary" → "Create Token" 클릭**

**⑦ 토큰 값 복사** (이 화면에서만 표시됨!)

**⑧ GitHub Secrets 에 등록**
- Name: `CLOUDFLARE_API_TOKEN`
- Value: 복사한 토큰 값

### 토큰 권한 최소화 (보안 강화)
```
Cloudflare Pages:Edit
  → 배포(Upload), 프로젝트 생성/수정 가능

Account Settings:Read  
  → 계정 ID 조회용 (선택사항)
```

---

## 3. Cloudflare 계정 ID 확인

### 방법 1: 대시보드에서 확인 (가장 빠름)
```
1. https://dash.cloudflare.com 로그인
2. 우측 사이드바 하단 "Account ID" 복사
   (또는 임의 도메인 → Overview 페이지 우측)
```

### 방법 2: API로 확인
```bash
curl -X GET "https://api.cloudflare.com/client/v4/accounts" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  | python3 -m json.tool | grep '"id"' | head -1
```

**GitHub Secrets 에 등록**
- Name: `CLOUDFLARE_ACCOUNT_ID`  
- Value: 확인한 계정 ID (32자리 hex 문자열)

---

## 4. GitHub Pages 토큰 발급 (수동 배포용)

`deploy.sh` 스크립트로 GitHub Pages에 직접 배포할 때 필요합니다.

### Personal Access Token (classic) 발급

```
1. GitHub → Settings → Developer settings
   → Personal access tokens → Tokens (classic)
   → Generate new token (classic)

2. 권한 설정:
   ☑ repo          (전체 저장소 접근)
   ☑ workflow      (Actions 트리거)

3. 만료 기간: 90일 또는 사용자 지정

4. "Generate token" → 값 복사 (ghp_xxx...)
```

### 사용법 (deploy.sh 실행 시)
```bash
# 환경변수로 전달 (코드에 토큰을 절대 하드코딩하지 마세요!)
TOKEN=ghp_xxxxxxxxxxxx ./deploy.sh
```

---

## 5. 배포 흐름 확인

### Cloudflare Pages 자동 배포 (메인)
```
git push origin main
    ↓
GitHub Actions 트리거
    ↓
Flutter 3.32.2 빌드 (ubuntu-latest)
    ↓
Patch (캐시 버스팅)
    ↓
wrangler pages deploy → twofit-mall.pages.dev
    ↓
Cloudflare 자동으로 2fit-mall.co.kr 반영
```

### Cloudflare Pages 프로젝트 설정 확인
```
https://dash.cloudflare.com → Pages → twofit-mall

확인 사항:
  ✅ 프로젝트 이름: twofit-mall
  ✅ 커스텀 도메인: 2fit-mall.co.kr (DNS → Cloudflare 네임서버)
  ✅ Production 브랜치: main
```

### GitHub Pages 수동 배포 (보조)
```bash
# 로컬에서 실행 (Flutter 설치 필요)
cd /path/to/project
TOKEN=ghp_xxx ./deploy.sh
```

---

## 6. 자주 발생하는 오류 해결

### ❌ `Authentication error` — Cloudflare 배포 실패
```
원인: CLOUDFLARE_API_TOKEN 이 잘못되었거나 권한 부족
해결:
  1. Cloudflare 대시보드에서 토큰 유효성 확인
  2. 토큰에 "Cloudflare Pages:Edit" 권한 있는지 확인
  3. GitHub Secrets 에서 토큰 값 재등록
```

### ❌ `Project not found` — 프로젝트 이름 오류
```
원인: Cloudflare Pages에 'twofit-mall' 프로젝트가 없음
해결:
  1. Cloudflare Pages 대시보드에서 프로젝트 실제 이름 확인
  2. deploy.yml 의 CF_PROJECT 값 수정:
     env:
       CF_PROJECT: 실제-프로젝트-이름
```

### ❌ Flutter 빌드 실패 — 패키지 버전 충돌
```
원인: pubspec.lock 과 pub 캐시 불일치
해결 방법 1: Actions 수동 실행 시 'skip_cache: true' 선택
해결 방법 2: 로컬에서 flutter pub upgrade 후 pubspec.lock 커밋
```

### ❌ Flutter 버전 불일치
```
원인: deploy.yml 의 FLUTTER_VERSION 이 실제와 다름
해결:
  로컬에서 확인: flutter --version
  deploy.yml 수정:
    env:
      FLUTTER_VERSION: '실제버전'  # 예: 3.32.2
```

### ❌ `canvaskit` 렌더러 오류 (모바일에서 빈 화면)
```
원인: canvaskit 다운로드 실패 (네트워크 제한 환경)
현재 설정: flutter_bootstrap.js 에서 자동 감지 모드 사용
  → 크롬/엣지: canvaskit, 사파리/삼성브라우저: html 자동 선택
  → 문제 지속 시 flutter_bootstrap.js 를 html 고정으로 변경:
     _flutter.loader.load({ renderer: "html" });
```

### ❌ 배포 후 이전 버전이 보임 (캐시 문제)
```
원인: CDN/브라우저 캐시
해결:
  1. 강력 새로고침: Ctrl+Shift+R (Windows) / Cmd+Shift+R (Mac)
  2. Cloudflare 대시보드 → Caching → Purge Everything
  3. main.dart.js?v=빌드번호 패치가 정상 적용됐는지 확인
     → Actions 로그에서 "[1/3] main.dart.js 캐시 버스팅" 단계 확인
```

---

## 빠른 참조

| 항목 | 값 / 경로 |
|------|----------|
| Cloudflare 프로젝트 | `twofit-mall` |
| 기본 배포 URL | `https://twofit-mall.pages.dev` |
| 커스텀 도메인 | `https://2fit-mall.co.kr` |
| GitHub 저장소 | `chw243527-ux/2fit-mall` |
| GitHub Pages 브랜치 | `gh-pages` |
| Firebase 프로젝트 | `fit-mall` |
| Flutter 버전 | `3.32.2` (stable) |
| 빌드 출력 | `build/web/` |
