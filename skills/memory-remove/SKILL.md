---
name: memory-remove
description: 저장된 메모리를 삭제합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "<파일명 또는 검색어>"
---

# Memory Remove - 메모리 삭제

저장된 메모리 파일을 삭제합니다.

## 인자 파싱

- `$0`: 삭제할 메모리 파일명, 경로, 또는 검색어
- `--category` 또는 `-c`: 카테고리 전체 삭제
- `--before <date>`: 특정 날짜 이전 메모리 삭제
- `--force` 또는 `-f`: 확인 없이 삭제

## 동작

### 1단계: 삭제 대상 찾기

인자에 따라:
- 정확한 파일 경로 → 해당 파일
- 검색어 → `.claude/memories/`에서 파일명과 내용 검색하여 후보 표시
- `--category` → 해당 카테고리 디렉토리의 모든 파일
- `--before` → 해당 날짜 이전의 모든 파일

### 2단계: 삭제 확인

`--force`가 아닌 경우 삭제 전 확인:

```
🗑️ 삭제 대상:
  1. bugfix/2026-02-06-useeffect-loop.md (johyunduk)
     "React useEffect 무한 루프 해결"

정말 삭제하시겠습니까?
```

### 3단계: 삭제 실행

```bash
rm "$MEMORY_FILE"
```

### 4단계: 확인

```
✅ 메모리 삭제 완료
   삭제: bugfix/2026-02-06-useeffect-loop.md
   💡 Git에서도 제거하려면: /memory-share
```

## 사용 예시

```
/memory-remove useeffect-loop                   # 파일명으로 삭제
/memory-remove -c til                           # TIL 카테고리 전체 삭제
/memory-remove --before 2026-01-01              # 오래된 메모리 정리
/memory-remove .claude/memories/bugfix/file.md  # 정확한 경로로 삭제
```
