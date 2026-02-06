---
name: memory-share
description: 저장된 메모리를 Git 커밋하여 팀원과 공유하거나, 다른 프로젝트로 내보냅니다
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "[--push] [--export <path>] [--import <path>]"
---

# Memory Share - 메모리 공유

저장된 메모리를 Git으로 커밋하여 팀원과 공유하거나, 다른 프로젝트로 내보내기/가져오기합니다.

## 인자 파싱

- (기본): 새로운/변경된 메모리를 Git에 커밋
- `--push`: 커밋 후 push까지 실행
- `--export <path>`: 메모리를 다른 위치로 내보내기
- `--import <path>`: 외부 메모리를 가져오기
- `--to-global`: 프로젝트 메모리를 전역(`~/.claude/memories/`)으로 복사

## 동작

### Git 공유 (기본)

```bash
# 새로운/변경된 메모리 파일 확인
git status .claude/memories/ --porcelain

# 커밋
git add .claude/memories/ -A
git commit -m "memory: <변경 요약>"
```

커밋 메시지 자동 생성:
- 새로 추가된 메모리 파일 수와 카테고리를 요약
- 예: `memory: add 3 memories (2 bugfix, 1 pattern)`

`--push` 사용 시:
```bash
git push
```

### 내보내기 (`--export`)

```bash
# 특정 경로로 메모리 복사
cp -r .claude/memories/ $EXPORT_PATH/
```

### 가져오기 (`--import`)

```bash
# 외부 메모리를 프로젝트로 복사
cp -r $IMPORT_PATH/*.md .claude/memories/
```

중복 파일 확인: 같은 이름의 파일이 있으면 사용자에게 확인.

### 전역으로 복사 (`--to-global`)

```bash
# 프로젝트 메모리를 전역으로
cp -r .claude/memories/**/*.md ~/.claude/memories/
```

## 출력 형식

### Git 공유

```
📤 메모리 공유
━━━━━━━━━━━━━━━━━━━━━━━━

새로운 메모리:
  + bugfix/2026-02-06-useeffect-loop.md (johyunduk)
  + pattern/2026-02-06-api-response.md (kimdev)

변경된 메모리:
  ~ setup/2026-02-01-docker-setup.md (johyunduk)

커밋: memory: add 2 memories, update 1 (bugfix, pattern, setup)

팀원이 받으려면: git pull
```

### 가져오기

```
📥 메모리 가져오기: /path/to/memories
━━━━━━━━━━━━━━━━━━━━━━━━

가져온 메모리:
  + decision/2026-01-30-auth-strategy.md
  + snippet/2026-01-28-fetch-wrapper.md

건너뜀 (이미 존재):
  - bugfix/2026-02-06-useeffect-loop.md

총 2개 가져옴, 1개 건너뜀
```

## .gitignore 관리

프로젝트의 `.gitignore`에서 `.claude/memories/local/`만 제외되도록 확인:

```
# .gitignore에 추가 (없으면)
.claude/memories/local/
```

이렇게 하면:
- `.claude/memories/` - Git으로 공유됨 (팀 지식)
- `.claude/memories/local/` - 개인만 사용 (gitignored)

## 사용 예시

```
/memory-share                              # 새 메모리 커밋
/memory-share --push                       # 커밋 + 푸시
/memory-share --export ~/backup/memories   # 백업
/memory-share --import ../other-project/.claude/memories  # 다른 프로젝트에서 가져오기
/memory-share --to-global                  # 전역 메모리로 복사
```
