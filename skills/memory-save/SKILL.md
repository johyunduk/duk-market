---
name: memory-save
description: 세션에서 얻은 지식, 결정사항, 버그 수정, 패턴 등을 마크다운 메모리 파일로 저장합니다
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "<카테고리> <내용>"
---

# Memory Save - 지식 저장

세션에서 얻은 지식을 마크다운 파일로 저장합니다.
저장된 메모리는 Git으로 공유할 수 있어 팀원 간 지식 공유가 가능합니다.

## 인자 파싱

`$ARGUMENTS` 형식:
- `<category> <content>` - 카테고리와 내용 지정
- `<content>` - 카테고리 자동 분류

카테고리:
- `decision` - 아키텍처/설계 결정사항
- `bugfix` - 버그 수정 기록과 원인
- `pattern` - 코드 패턴, 관례
- `setup` - 환경 설정, 설치 절차
- `pitfall` - 주의사항, 실수하기 쉬운 것
- `snippet` - 유용한 코드 스니펫
- `til` - Today I Learned (오늘 배운 것)

## 저장 위치

메모리 파일 저장 위치:
- **프로젝트 공유**: `.claude/memories/` (Git에 커밋하여 팀 공유)
- **개인 메모**: `.claude/memories/local/` (`.gitignore`에 추가)
- **전역 메모**: `~/.claude/memories/` (모든 프로젝트에서 사용)

## 저장 형식

각 메모리는 개별 마크다운 파일로 저장합니다:

**파일 경로**: `.claude/memories/<category>/<YYYY-MM-DD>-<slug>.md`

**파일 내용**:
```markdown
---
category: <category>
tags: [tag1, tag2]
author: <git user.name>
date: <YYYY-MM-DD HH:mm>
project: <프로젝트 이름>
session: <세션 ID (있으면)>
---

# <제목>

<내용>

## 관련 파일
- `path/to/file.ts` - 설명

## 컨텍스트
<이 메모리가 생긴 배경/상황>
```

## 동작 절차

### 1단계: 저장 디렉토리 확인

```bash
# 프로젝트 메모리 디렉토리 생성
mkdir -p .claude/memories/{decision,bugfix,pattern,setup,pitfall,snippet,til}
```

### 2단계: 메모리 내용 구성

사용자의 `$ARGUMENTS`를 분석하여:
1. 카테고리가 명시되지 않았으면 내용에서 자동 분류
2. 제목을 slug로 변환 (예: "React 렌더링 최적화" → `react-rendering-optimization`)
3. 태그를 내용에서 추출
4. `git config user.name`으로 작성자 기록

### 3단계: 파일 생성

마크다운 파일을 생성합니다.

### 4단계: 확인 출력

```
💾 메모리 저장 완료
━━━━━━━━━━━━━━━━━━━━━━━━

카테고리: bugfix
제목:    React useEffect 무한 루프 해결
태그:    react, hooks, useEffect
파일:    .claude/memories/bugfix/2026-02-06-react-useeffect-infinite-loop.md
작성자:  johyunduk

💡 팀과 공유하려면: git add .claude/memories/ && git commit -m "memory: ..."
   또는: /memory-share
```

## 사용 예시

```
/memory-save bugfix useEffect 의존성 배열에 객체를 넣으면 매번 새 참조라 무한 루프 발생. useMemo로 감싸서 해결
/memory-save pattern 이 프로젝트에서는 API 응답을 항상 { data, error, meta } 형태로 통일
/memory-save setup Docker compose 실행 전에 .env.local 파일 필요. TEMPLATE.env 복사 후 수정
/memory-save 오늘 알게된 건데 Next.js에서 서버 컴포넌트는 useState를 쓸 수 없다
```
