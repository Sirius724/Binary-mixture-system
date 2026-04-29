# Binary Mixture System - Automated Setup, Commit and Git Push Script (PowerShell)
# This script synchronizes project files with git repository
# Usage: .\setup.ps1

# ============================================================================
# CONFIGURATION
# ============================================================================

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportFile = "report.tex"
$ReadmeFile = "README.md"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$GitUserName = $env:GIT_USER_NAME ?? "Jeong Kangeun"
$GitUserEmail = $env:GIT_USER_EMAIL ?? "kangeun.j@gmail.com"

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host $Text -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Error {
    param([string]$Text)
    Write-Host "✗ $Text" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠️  $Text" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ️  $Text" -ForegroundColor Cyan
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

Write-Header "Binary Mixture System - Git Automation Script"

# Step 1: Check if we're in the right directory
if (-not (Test-Path "$ProjectDir\$ReportFile") -or -not (Test-Path "$ProjectDir\$ReadmeFile")) {
    Write-Error "Required files not found in project directory!"
    Write-Info "Expected: $ReportFile and $ReadmeFile"
    exit 1
}

Write-Success "Project files detected"
Write-Host ""

# Step 2: Initialize or verify git repository
Write-Info "Checking git repository..."

$GitInit = git rev-parse --git-dir 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Not in a git repository. Initializing..."
    git init | Out-Null
    git config user.name $GitUserName | Out-Null
    git config user.email $GitUserEmail | Out-Null
    Write-Success "Git repository initialized"
}
else {
    Write-Success "Git repository detected"
    $CurrentUser = git config user.name
    $CurrentEmail = git config user.email
    Write-Info "Current git user: $CurrentUser <$CurrentEmail>"
}

Write-Host ""

# Step 3: Create .gitignore if it doesn't exist
$GitIgnorePath = "$ProjectDir\.gitignore"
if (-not (Test-Path $GitIgnorePath)) {
    Write-Info "Creating .gitignore..."
    @"
# LaTeX
*.aux
*.log
*.out
*.pdf
*.dvi
*.synctex.gz
*.fls
*.fdb_latexmk

# Python
__pycache__/
*.py[cod]
*`$py.class
*.so
.Python
env/
venv/

# IDE
.vscode/
.idea/
*.swp
*.swo

# System
.DS_Store
.env
"@ | Out-File -FilePath $GitIgnorePath -Encoding UTF8
    Write-Success ".gitignore created"
}

Write-Host ""

# Step 4: Check file status
Write-Info "File status:"
git status --short
Write-Host ""

# Step 5: Add files to staging area
Write-Info "Adding files to staging area..."
git add $ReportFile $ReadmeFile 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Success "Files staged successfully"
}
else {
    Write-Warning "Some files might not have been staged"
}

Write-Host ""

# Step 6: Create and execute commit
Write-Info "Preparing commit..."

$CommitMessage = @"
docs: Update report.tex and README.md with latest research

- Updated report.tex with statistical field theory analysis
- Enhanced README.md with theoretical framework and methods
- Added critical phenomena analysis and scaling laws
- Included computational validation proposals
- Generated on: $Timestamp
"@

Write-Info "Commit message:"
Write-Host $CommitMessage
Write-Host ""

# Check if there are changes to commit
$GitStatus = git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Warning "No changes to commit"
}
else {
    $CommitResult = git commit -m $CommitMessage 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Changes committed successfully"
    }
    else {
        Write-Error "Commit failed"
        exit 1
    }
}

Write-Host ""

# Step 7: Handle git push
Write-Info "Checking remote repository configuration..."

$RemoteUrl = git config --get remote.origin.url 2>$null

if ([string]::IsNullOrEmpty($RemoteUrl)) {
    Write-Warning "No remote repository configured"
    Write-Host ""
    Write-Host "To add a remote repository:"
    Write-Host "  git remote add origin <repository-url>"
    Write-Host ""
    Write-Host "Example with GitHub:"
    Write-Host "  git remote add origin https://github.com/username/binary-mixture-system.git"
    Write-Host ""
}
else {
    Write-Success "Remote configured: $RemoteUrl"
    Write-Host ""
}

# Step 8: Perform git push
Write-Info "Pushing to remote repository..."

$Branch = git rev-parse --abbrev-ref HEAD
Write-Info "Current branch: $Branch"

if (-not [string]::IsNullOrEmpty($RemoteUrl)) {
    # Attempt to push
    $PushResult = git push -u origin $Branch 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Successfully pushed to origin/$Branch"
    }
    else {
        Write-Warning "Push failed - attempting alternative method..."
        
        $PushAltResult = git push --set-upstream origin $Branch 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Created new tracking branch and pushed"
        }
        else {
            Write-Error "Unable to push. Please check:"
            Write-Host "  • Remote URL: $RemoteUrl"
            Write-Host "  • Network connectivity"
            Write-Host "  • Git credentials/SSH keys"
            Write-Host "  • Repository permissions"
        }
    }
}
else {
    Write-Warning "Remote not configured - skipping push"
    Write-Info "Configure remote with: git remote add origin <url>"
}

Write-Host ""

# Step 9: Display summary
Write-Header "Setup Complete!"

Write-Success "Project files synchronized"
Write-Host ""
Write-Host "Summary:"
Write-Host "  • Repository: $(Get-Location)"
Write-Host "  • Branch: $Branch"
if (-not [string]::IsNullOrEmpty($RemoteUrl)) {
    Write-Host "  • Remote: origin → $RemoteUrl"
}
Write-Host "  • Files updated: $ReportFile, $ReadmeFile"
Write-Host "  • Timestamp: $Timestamp"
Write-Host ""

Write-Info "Next steps:"
Write-Host "  1. Make changes to report.tex or README.md"
Write-Host "  2. Run this script again to commit and push"
Write-Host "  3. Or use git manually:"
Write-Host "     git add <files>"
Write-Host "     git commit -m '<message>'"
Write-Host "     git push origin $Branch"
Write-Host ""

Write-Success "All done!"
Write-Host ""

exit 0
