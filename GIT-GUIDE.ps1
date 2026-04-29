# Binary Mixture System - PowerShell Git Commands Guide
# PowerShell에서 Git 명령을 올바르게 사용하는 방법

# ============================================================================
# IMPORTANT: PowerShell에서 Git 원격 저장소 설정
# ============================================================================

# ❌ 잘못된 방법 (PowerShell에서 < 문자가 리다이렉션으로 해석됨):
# git remote add origin <your-repository-url>

# ✅ 올바른 방법 1: 큰따옴표 사용
git remote add origin "https://github.com/username/repo.git"

# ✅ 올바른 방법 2: 백틱으로 특수문자 이스케이핑
git remote add origin `<your-repository-url`>

# ✅ 올바른 방법 3: 보조 스크립트 사용 (권장!)
.\setup-git-remote.ps1

# ============================================================================
# 자주 사용하는 Git 명령어
# ============================================================================

# 1. 원격 저장소 확인
git remote -v

# 2. 원격 저장소 주소 확인
git config --get remote.origin.url

# 3. 파일 상태 확인
git status

# 4. 특정 파일 스테이징
git add "report.tex"
git add "README.md"

# 5. 모든 변경 커밋
git commit -m "docs: Update project files"

# 6. 현재 분기에 푸시
git push -u origin main

# ============================================================================
# PowerShell에서 Git 설정 - 단계별 가이드
# ============================================================================

# Step 1: GitHub 저장소 생성
# - https://github.com/new 접속
# - Repository name: binary-mixture-system
# - Description: Binary Mixture System Research
# - Public 또는 Private 선택
# - "Create repository" 클릭

# Step 2: 로컬 Git 사용자 설정
git config --global user.name "Jeong Kangeun"
git config --global user.email "your-email@example.com"

# Step 3: 로컬 저장소 초기화 (이미 되어있으면 스킵)
git init

# Step 4: 원격 저장소 추가
# 방법 A: 직접 입력
$RepoUrl = "https://github.com/your-username/binary-mixture-system.git"
git remote add origin $RepoUrl

# 방법 B: 보조 스크립트 사용 (권장!)
.\setup-git-remote.ps1

# Step 5: 파일 추가 및 커밋
git add "report.tex", "README.md"
git commit -m "Initial commit: Add research paper and documentation"

# Step 6: 첫 푸시
git push -u origin main

# ============================================================================
# 문제 해결
# ============================================================================

# 문제: "fatal: not a git repository"
# 해결: git init 실행

# 문제: "fatal: remote origin already exists"
# 해결: git remote remove origin 후 다시 추가

# 문제: "Permission denied (publickey)"
# 해결: SSH 키 설정 또는 HTTPS 사용

# 문제: PowerShell에서 리다이렉션 오류
# 해결: 따옴표로 URL 감싸기 또는 백틱 사용

# ============================================================================
# GitHub Actions을 위한 추가 설정 (선택사항)
# ============================================================================

# .github/workflows/auto-compile.yml 생성하여
# 푸시할 때마다 LaTeX 자동 컴파일 설정 가능

# ============================================================================
# 추천 워크플로우
# ============================================================================

# 1. 파일 수정
# - report.tex 또는 README.md 편집

# 2. 변경사항 확인
git status

# 3. 커밋 전 변경내용 확인
git diff "report.tex"

# 4. 스테이징 및 커밋
git add "report.tex", "README.md"
git commit -m "docs: Update content

- Modified theoretical analysis
- Added new figures
- Updated references"

# 5. 푸시
git push

# ============================================================================
# 유용한 참고자료
# ============================================================================

# - Git 공식 문서: https://git-scm.com/doc
# - GitHub 도움말: https://docs.github.com
# - GitHub Desktop (GUI): https://desktop.github.com
# - Visual Studio Code Git 연동: Ctrl+Shift+G

Write-Host "✓ PowerShell Git Commands Guide loaded" -ForegroundColor Green
Write-Host ""
Write-Host "Git 원격 저장소를 설정하려면:" -ForegroundColor Cyan
Write-Host "  .\setup-git-remote.ps1" -ForegroundColor Yellow
Write-Host ""
