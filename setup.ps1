# Binary Mixture System - Automated Setup and Git Push Script (PowerShell)
# This script generates project files and commits them to git

# Configuration
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportFile = "report.tex"
$ReadmeFile = "README.md"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Color function
function Write-ColorOutput {
    param(
        [Parameter(Position = 0)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type,
        
        [Parameter(Position = 1)]
        [string]$Message
    )
    
    switch ($Type) {
        'Info' { Write-Host "🔵 $Message" -ForegroundColor Blue }
        'Success' { Write-Host "✅ $Message" -ForegroundColor Green }
        'Warning' { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        'Error' { Write-Host "❌ $Message" -ForegroundColor Red }
    }
}

# Header
Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host "Binary Mixture System - Setup Script" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

# Check if we're in a git repository
if (-not (git rev-parse --git-dir 2>$null)) {
    Write-ColorOutput Warning "Not in a git repository. Initializing git..."
    git init | Out-Null
    Write-ColorOutput Success "Git repository initialized"
    Write-Host ""
} else {
    Write-ColorOutput Success "Git repository detected"
    Write-Host ""
}

# Check if files exist
Write-ColorOutput Info "Checking project files..."

$ReportExists = Test-Path "$ProjectDir\$ReportFile"
$ReadmeExists = Test-Path "$ProjectDir\$ReadmeFile"

if ($ReportExists) {
    Write-ColorOutput Success "$ReportFile exists"
} else {
    Write-ColorOutput Error "$ReportFile not found"
}

if ($ReadmeExists) {
    Write-ColorOutput Success "$ReadmeFile exists"
} else {
    Write-ColorOutput Error "$ReadmeFile not found"
}

Write-Host ""

# Add files to git staging area
Write-ColorOutput Info "Adding files to git staging area..."

git add "$ReportFile" "$ReadmeFile" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput Success "Files added successfully"
} else {
    Write-ColorOutput Warning "Some files might not have been added"
}

Write-Host ""

# Check git status
Write-ColorOutput Info "Git status:"
Write-Host ""
git status --short
Write-Host ""

# Commit changes
Write-ColorOutput Info "Committing changes..."

$CommitMessage = @"
docs: Add report.tex and README.md for Binary Mixture System project

- Added LaTeX research paper template (report.tex)
- Added comprehensive project documentation (README.md)
- Initial project structure for binary mixture system research
- Generated on: $Timestamp
"@

$CommitResult = git commit -m $CommitMessage 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput Success "Changes committed successfully"
} else {
    Write-ColorOutput Warning "No changes to commit or commit failed"
}

Write-Host ""

# Push to remote repository
Write-ColorOutput Info "Pushing to remote repository..."

# Check if remote exists
$RemoteExists = git remote -v 2>$null | Select-String "origin" -Quiet

if ($RemoteExists) {
    Write-ColorOutput Success "Remote 'origin' found"
    
    # Get current branch name
    $Branch = git rev-parse --abbrev-ref HEAD
    Write-ColorOutput Info "Current branch: $Branch"
    
    # Attempt to push
    $PushResult = git push -u origin $Branch 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Success "Successfully pushed to origin/$Branch"
    } else {
        Write-ColorOutput Error "Failed to push. Please check your remote configuration."
        Write-ColorOutput Warning "You can push manually with: git push -u origin $Branch"
        Write-Host ""
        Write-Host $PushResult
    }
} else {
    Write-ColorOutput Warning "No remote repository configured"
    Write-ColorOutput Info "To add a remote repository, use:"
    Write-Host "   git remote add origin <repository-url>"
    Write-ColorOutput Info "Then push with:"
    Write-Host "   git push -u origin main"
}

Write-Host ""

# Display summary
Write-Host "========================================" -ForegroundColor Blue
Write-Host "Setup Complete!" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue

Write-ColorOutput Success "Project files:"
Write-Host "  • $ReportFile - LaTeX research paper"
Write-Host "  • $ReadmeFile - Project documentation"

Write-Host ""
Write-ColorOutput Success "Next steps:"
Write-Host "  1. Edit $ReportFile with your research content"
Write-Host "  2. Update $ReadmeFile with specific project details"
Write-Host "  3. Create additional directories for data and results"
Write-Host "  4. Run this script again to commit new changes"
Write-Host ""
