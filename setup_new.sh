#!/bin/bash

# Binary Mixture System - Automated Setup, Commit and Git Push Script
# This script synchronizes project files with git repository
# Usage: bash setup.sh

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="report.tex"
README_FILE="README.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
GIT_USER_NAME="${GIT_USER_NAME:-Jeong Kangeun}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-kangeun.j@gmail.com}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# FUNCTIONS
# ============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

print_header "Binary Mixture System - Git Automation Script"

# Step 1: Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/$REPORT_FILE" ] || [ ! -f "$PROJECT_DIR/$README_FILE" ]; then
    print_error "Required files not found in project directory!"
    print_info "Expected: $REPORT_FILE and $README_FILE"
    exit 1
fi

print_success "Project files detected"
echo ""

# Step 2: Initialize or verify git repository
print_info "Checking git repository..."

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_warning "Not in a git repository. Initializing..."
    git init
    git config user.name "$GIT_USER_NAME"
    git config user.email "$GIT_USER_EMAIL"
    print_success "Git repository initialized"
else
    print_success "Git repository detected"
    CURRENT_USER=$(git config user.name)
    CURRENT_EMAIL=$(git config user.email)
    print_info "Current git user: $CURRENT_USER <$CURRENT_EMAIL>"
fi

echo ""

# Step 3: Create .gitignore if it doesn't exist
if [ ! -f "$PROJECT_DIR/.gitignore" ]; then
    print_info "Creating .gitignore..."
    cat > "$PROJECT_DIR/.gitignore" << 'EOF'
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
*$py.class
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
EOF
    print_success ".gitignore created"
fi

echo ""

# Step 4: Check file status
print_info "File status:"
git status --short

echo ""

# Step 5: Add files to staging area
print_info "Adding files to staging area..."
git add "$REPORT_FILE" "$README_FILE" 2>/dev/null

if [ $? -eq 0 ]; then
    print_success "Files staged successfully"
else
    print_warning "Some files might not have been staged"
fi

echo ""

# Step 6: Create and execute commit
print_info "Preparing commit..."

COMMIT_MESSAGE="docs: Update report.tex and README.md with latest research

- Updated report.tex with statistical field theory analysis
- Enhanced README.md with theoretical framework and methods
- Added critical phenomena analysis and scaling laws
- Included computational validation proposals
- Generated on: $TIMESTAMP"

print_info "Commit message:"
echo "$COMMIT_MESSAGE"
echo ""

# Check if there are changes to commit
if git diff --cached --quiet; then
    print_warning "No changes to commit"
else
    if git commit -m "$COMMIT_MESSAGE"; then
        print_success "Changes committed successfully"
    else
        print_error "Commit failed"
        exit 1
    fi
fi

echo ""

# Step 7: Handle git push
print_info "Checking remote repository configuration..."

REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null)

if [ -z "$REMOTE_URL" ]; then
    print_warning "No remote repository configured"
    echo ""
    echo "To add a remote repository:"
    echo "  git remote add origin <repository-url>"
    echo ""
    echo "Example with GitHub:"
    echo "  git remote add origin https://github.com/username/binary-mixture-system.git"
    echo ""
else
    echo -e "${GREEN}✓ Remote configured: $REMOTE_URL${NC}"
    echo ""
fi

# Step 8: Perform git push
print_info "Pushing to remote repository..."

BRANCH=$(git rev-parse --abbrev-ref HEAD)
print_info "Current branch: $BRANCH"

if [ -n "$REMOTE_URL" ]; then
    # Check if branch exists on remote
    if git push -u origin "$BRANCH" 2>/dev/null; then
        print_success "Successfully pushed to origin/$BRANCH"
    else
        print_warning "Push failed - attempting alternative method..."
        
        if git push --set-upstream origin "$BRANCH"; then
            print_success "Created new tracking branch and pushed"
        else
            print_error "Unable to push. Please check:"
            echo "  • Remote URL: $REMOTE_URL"
            echo "  • Network connectivity"
            echo "  • Git credentials/SSH keys"
            echo "  • Repository permissions"
        fi
    fi
else
    print_warning "Remote not configured - skipping push"
    print_info "Configure remote with: git remote add origin <url>"
fi

echo ""

# Step 9: Display summary
print_header "Setup Complete!"

print_success "Project files synchronized"
echo ""
echo "Summary:"
echo "  • Repository: $(pwd)"
echo "  • Branch: $BRANCH"
if [ -n "$REMOTE_URL" ]; then
    echo "  • Remote: origin → $REMOTE_URL"
fi
echo "  • Files updated: $REPORT_FILE, $README_FILE"
echo "  • Timestamp: $TIMESTAMP"
echo ""

print_info "Next steps:"
echo "  1. Make changes to report.tex or README.md"
echo "  2. Run this script again to commit and push"
echo "  3. Or use git manually:"
echo "     git add <files>"
echo "     git commit -m '<message>'"
echo "     git push origin $BRANCH"
echo ""

print_success "All done!"
echo ""

exit 0
