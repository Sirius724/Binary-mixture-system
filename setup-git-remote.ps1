# Binary Mixture System - Git Remote Configuration Helper
# PowerShell용 원격 저장소 설정 스크립트
# Usage: .\setup-git-remote.ps1

param(
    [string]$RepositoryUrl
)

# Color and formatting
$ErrorActionPreference = "Continue"

# Functions
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

# Main
Write-Header "Git Remote Configuration Helper"

# Check if already initialized
$CurrentRemote = git config --get remote.origin.url 2>$null

if ($CurrentRemote) {
    Write-Success "Remote already configured: $CurrentRemote"
    Write-Host ""
    
    $Response = Read-Host "Do you want to change it? (y/n)"
    if ($Response -ne "y") {
        Write-Info "Keeping current remote"
        exit 0
    }
}

# Get repository URL
if ([string]::IsNullOrEmpty($RepositoryUrl)) {
    Write-Info "Choose a platform:"
    Write-Host "  1. GitHub (https://github.com)"
    Write-Host "  2. GitLab (https://gitlab.com)"
    Write-Host "  3. Bitbucket (https://bitbucket.org)"
    Write-Host "  4. Other/Custom"
    Write-Host ""
    
    $Platform = Read-Host "Select (1-4)"
    
    Write-Host ""
    
    switch ($Platform) {
        "1" {
            Write-Info "GitHub selected"
            $Username = Read-Host "Enter GitHub username"
            $RepoName = Read-Host "Enter repository name"
            $RepositoryUrl = "https://github.com/$Username/$RepoName.git"
        }
        "2" {
            Write-Info "GitLab selected"
            $Username = Read-Host "Enter GitLab username"
            $RepoName = Read-Host "Enter repository name"
            $RepositoryUrl = "https://gitlab.com/$Username/$RepoName.git"
        }
        "3" {
            Write-Info "Bitbucket selected"
            $Username = Read-Host "Enter Bitbucket username"
            $RepoName = Read-Host "Enter repository name"
            $RepositoryUrl = "https://bitbucket.org/$Username/$RepoName.git"
        }
        "4" {
            $RepositoryUrl = Read-Host "Enter complete repository URL"
        }
        default {
            Write-Error "Invalid selection"
            exit 1
        }
    }
}

Write-Host ""
Write-Info "Repository URL: $RepositoryUrl"
Write-Host ""

# Confirm
$Confirm = Read-Host "Is this correct? (y/n)"
if ($Confirm -ne "y") {
    Write-Warning "Setup cancelled"
    exit 0
}

Write-Host ""

# Remove existing remote if present
if ($CurrentRemote) {
    Write-Info "Removing existing remote..."
    git remote remove origin
}

# Add new remote
Write-Info "Adding new remote..."
try {
    git remote add origin $RepositoryUrl
    Write-Success "Remote added successfully"
}
catch {
    Write-Error "Failed to add remote: $_"
    exit 1
}

Write-Host ""

# Verify
$VerifyUrl = git config --get remote.origin.url
if ($VerifyUrl -eq $RepositoryUrl) {
    Write-Success "Remote verified: $VerifyUrl"
}
else {
    Write-Error "Remote verification failed"
    exit 1
}

Write-Host ""

# Next steps
Write-Info "Next steps:"
Write-Host "  1. Run setup script to commit changes:"
Write-Host "     .\setup_new.ps1"
Write-Host ""
Write-Host "  2. Or push manually:"
Write-Host "     git push -u origin main"
Write-Host ""

Write-Success "Remote configuration complete!"
Write-Host ""

exit 0
