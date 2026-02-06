---
name: memory-summary
description: 현재 세션에서 수행한 작업을 자동 요약하여 메모리로 저장합니다
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "[--auto]"
---

# Memory Summary - 세션 요약 저장

현재 세션에서 수행한 작업을 분석하고 요약하여 메모리로 저장합니다.

## 동작

### 1단계: 세션 작업 분석

현재 세션에서 변경된 내용을 수집:

```bash
# Git에서 세션 중 변경된 파일 확인
git diff --name-only
git diff --cached --name-only

# 최근 커밋 확인 (세션 중 생성된 것)
git log --oneline --since="today" --author="$(git config user.name)"
```

### 2단계: 요약 생성

수집된 정보를 분석하여 요약:

- **무엇을 했는지**: 변경된 파일, 추가된 기능, 수정된 버그
- **왜 했는지**: 커밋 메시지에서 의도 추출
- **어떻게 했는지**: 핵심 구현 방법
- **배운 점**: 세션에서 발견한 인사이트

### 3단계: 메모리 파일 생성

`.claude/memories/session/` 디렉토리에 세션 요약 저장:

**파일**: `.claude/memories/session/YYYY-MM-DD-<summary-slug>.md`

```markdown
---
category: session
tags: [session-summary, ...]
author: <git user.name>
date: YYYY-MM-DD HH:mm
project: <프로젝트 이름>
---

# 세션 요약: <제목>

## 수행한 작업
- 작업 1 설명
- 작업 2 설명

## 변경된 파일
- `file1.ts` - 변경 내용
- `file2.ts` - 변경 내용

## 핵심 결정사항
- 결정 1과 이유
- 결정 2와 이유

## 배운 점
- 인사이트 1
- 인사이트 2

## 다음에 할 일
- TODO 1
- TODO 2
```

### 4단계: 출력

```
📋 세션 요약 저장 완료
━━━━━━━━━━━━━━━━━━━━━━━━

제목:     Gemini CLI 연동 플러그인 추가
작업:     5개 파일 생성, 2개 파일 수정
배운 점:  2개
TODO:     3개

파일: .claude/memories/session/2026-02-06-gemini-plugin.md

💡 다음 세션에서 /memory-recall session으로 이전 작업 확인 가능
```

## 사용 예시

```
/memory-summary                 # 현재 세션 요약 저장
```
