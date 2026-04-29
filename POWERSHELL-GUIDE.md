# 🚀 Binary Mixture System - PowerShell 빠른 시작 가이드

## PowerShell에서 Git 원격 저장소 설정하기

### ⚠️ 문제: `<` 연산자 리다이렉션 오류

PowerShell에서 다음 명령을 실행하면 오류가 발생합니다:
```powershell
git remote add origin <your-repository-url>
```

**오류 메시지:**
```
'<' 연산자는 나중에 사용하도록 예약되어 있습니다.
```

### ✅ 해결 방법

#### 방법 1: 보조 스크립트 사용 (권장!) ⭐
```powershell
.\setup-git-remote.ps1
```
- 대화형 인터페이스로 GitHub/GitLab/Bitbucket 선택 가능
- 사용자명과 저장소명만 입력하면 됨
- 가장 편리한 방법

#### 방법 2: 큰따옴표로 감싸기
```powershell
git remote add origin "https://github.com/username/repo.git"
```
- GitHub 저장소 URL을 큰따옴표로 감싸기
- 예시:
```powershell
git remote add origin "https://github.com/kangeun/binary-mixture.git"
```

#### 방법 3: 변수에 저장
```powershell
$RepoUrl = "https://github.com/username/repo.git"
git remote add origin $RepoUrl
```

#### 방법 4: SSH 사용
```powershell
git remote add origin "git@github.com:username/repo.git"
```

---

## 단계별 설정 가이드

### Step 1: GitHub 저장소 생성
1. https://github.com/new 방문
2. Repository name 입력: `binary-mixture-system`
3. 설명 추가 (선택사항)
4. Public 또는 Private 선택
5. "Create repository" 클릭

### Step 2: Git 사용자 설정
```powershell
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

### Step 3: 원격 저장소 추가
```powershell
# 보조 스크립트 사용 (권장)
.\setup-git-remote.ps1

# 또는 직접 명령 입력
git remote add origin "https://github.com/your-username/binary-mixture-system.git"
```

### Step 4: 설정 확인
```powershell
git remote -v
git config --get remote.origin.url
```

### Step 5: 파일 커밋 및 푸시
```powershell
# 파일 추가
git add "report.tex", "README.md"

# 커밋
git commit -m "docs: Initial commit"

# 첫 푸시
git push -u origin main
```

---

## 🛠️ 완전 자동화 워크플로우

### 방법 A: PowerShell 스크립트 사용
```powershell
# 1. 원격 저장소 설정
.\setup-git-remote.ps1

# 2. 파일 동기화 및 자동 푸시
.\setup_new.ps1
```

### 방법 B: 전체 자동화 배치 파일
다음과 같이 `auto-setup.ps1` 생성:

```powershell
# auto-setup.ps1

Write-Host "Binary Mixture System - 완전 자동 설정" -ForegroundColor Blue
Write-Host ""

# Step 1: Git 사용자 설정
git config --global user.name "Jeong Kangeun"
git config --global user.email "j92724@gmail.com"

# Step 2: 원격 저장소 설정 (대화형)
Write-Host "원격 저장소 설정:" -ForegroundColor Cyan
$RepoUrl = Read-Host "GitHub 저장소 URL 입력 (예: https://github.com/user/repo.git)"
git remote remove origin 2>$null
git remote add origin $RepoUrl

# Step 3: 파일 동기화
Write-Host ""
Write-Host "파일 동기화 중..." -ForegroundColor Cyan
.\setup_new.ps1

Write-Host ""
Write-Host "✓ 설정 완료!" -ForegroundColor Green
```

실행:
```powershell
.\auto-setup.ps1
```

---

## 📋 자주 묻는 질문

### Q1: PowerShell과 Git Bash의 차이?
- **PowerShell**: Windows의 기본 셸, 더 강력한 객체 지향 기능
- **Git Bash**: Git과 함께 설치되는 Unix 스타일 셸
- 둘 다 사용 가능하지만, PowerShell에서는 따옴표 처리 필요

### Q2: 원격 저장소를 바꾸려면?
```powershell
# 기존 원격 제거
git remote remove origin

# 새 원격 추가
git remote add origin "new-url"

# 또는 직접 변경
git remote set-url origin "new-url"
```

### Q3: SSH와 HTTPS 중 어느 것이 나은가?
- **HTTPS**: 간단, 비밀번호 또는 토큰 필요
- **SSH**: 더 안전, SSH 키 설정 필요

### Q4: 푸시 실패 시?
```powershell
# 원격 저장소 확인
git remote -v

# 네트워크 연결 확인
Test-NetConnection github.com -Port 443

# 자격증명 확인
git config --list

# 강제 푸시 (주의!)
git push -f origin main
```

---

## 💡 팁과 트릭

### 1. PowerShell 프로필에 별칭 추가
```powershell
# PowerShell 프로필 편집
notepad $PROFILE

# 다음 추가:
function setup-git { .\setup-git-remote.ps1 }
function setup-project { .\setup_new.ps1 }

# 저장 후 PowerShell 재시작
# 이제 'setup-git' 또는 'setup-project'로 간단하게 실행 가능
```

### 2. 자동 커밋 스크립트
```powershell
# auto-commit.ps1
param([string]$Message = "docs: Update files")

git add "report.tex", "README.md"
git commit -m $Message
git push
```

사용:
```powershell
.\auto-commit.ps1
.\auto-commit.ps1 "refactor: Reorganize content"
```

### 3. Visual Studio Code 활용
```powershell
# 현재 디렉토리에서 VS Code 열기
code .

# Git 탭에서 UI로 커밋 및 푸시 가능
# 단축키: Ctrl+Shift+G
```

---

## 🔗 유용한 링크

- [Git 공식 문서](https://git-scm.com/doc)
- [GitHub 도움말](https://docs.github.com)
- [GitHub SSH 설정](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [PowerShell Git 팁](https://github.com/dahlbyk/posh-git)

---

## 📞 문제 해결

| 문제 | 원인 | 해결 |
|------|------|------|
| `'<' 연산자는 나중에 사용하도록 예약` | PowerShell 리다이렉션 | 따옴표로 URL 감싸기 |
| `fatal: not a git repository` | Git 저장소 미초기화 | `git init` 실행 |
| `fatal: remote origin already exists` | 원격 중복 | `git remote remove origin` |
| `Permission denied (publickey)` | SSH 키 미설정 | HTTPS 사용 또는 SSH 설정 |
| `fatal: The current branch has no upstream` | 추적 분기 미설정 | `git push -u origin main` |

---

## ✨ 최종 권장 워크플로우

```powershell
# 1. 프로젝트 디렉토리 이동
cd "C:\path\to\Binary mixture system"

# 2. 원격 저장소 설정 (첫 번째만)
.\setup-git-remote.ps1

# 3. 파일 수정
# report.tex 또는 README.md 편집...

# 4. 자동 커밋 및 푸시
.\setup_new.ps1

# Done! ✓
```

---

**마지막 업데이트**: 2026-04-24  
**작성자**: Jeong Kangeun  
**용도**: Binary Mixture System 프로젝트
