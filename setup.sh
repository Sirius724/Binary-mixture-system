#!/bin/bash

# Binary Mixture System - Automated Setup and Git Push Script
# This script generates project files and commits them to git

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="report.tex"
README_FILE="README.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Binary Mixture System - Setup Script${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Not in a git repository. Initializing git...${NC}"
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}\n"
else
    echo -e "${GREEN}✓ Git repository detected${NC}\n"
fi

# Check if files already exist
echo -e "${BLUE}Checking project files...${NC}"

if [ -f "$PROJECT_DIR/$REPORT_FILE" ]; then
    echo -e "${GREEN}✓ $REPORT_FILE exists${NC}"
else
    echo -e "${RED}✗ $REPORT_FILE not found${NC}"
fi

if [ -f "$PROJECT_DIR/$README_FILE" ]; then
    echo -e "${GREEN}✓ $README_FILE exists${NC}"
else
    echo -e "${RED}✗ $README_FILE not found${NC}"
fi

echo -e "\n"

# Add files to git staging area
echo -e "${BLUE}Adding files to git staging area...${NC}"
git add "$REPORT_FILE" "$README_FILE" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Files added successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Some files might not have been added${NC}"
fi

echo -e "\n"

# Check git status
echo -e "${BLUE}Git status:${NC}"
git status --short

echo -e "\n"

# Commit changes
echo -e "${BLUE}Committing changes...${NC}"
COMMIT_MESSAGE="docs: Add report.tex and README.md for Binary Mixture System project

- Added LaTeX research paper template (report.tex)
- Added comprehensive project documentation (README.md)
- Initial project structure for binary mixture system research
- Generated on: $TIMESTAMP"

if git commit -m "$COMMIT_MESSAGE"; then
    echo -e "${GREEN}✓ Changes committed successfully${NC}"
else
    echo -e "${YELLOW}⚠️  No changes to commit or commit failed${NC}"
fi

echo -e "\n"

# Push to remote repository
echo -e "${BLUE}Pushing to remote repository...${NC}"

# Check if remote exists
if git remote -v | grep -q 'origin'; then
    echo -e "${GREEN}✓ Remote 'origin' found${NC}"
    
    # Get current branch name
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo -e "${BLUE}Current branch: $BRANCH${NC}"
    
    # Attempt to push
    if git push -u origin "$BRANCH"; then
        echo -e "${GREEN}✓ Successfully pushed to origin/$BRANCH${NC}"
    else
        echo -e "${RED}✗ Failed to push. Please check your remote configuration.${NC}"
        echo -e "${YELLOW}You can push manually with: git push -u origin $BRANCH${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No remote repository configured${NC}"
    echo -e "${YELLOW}To add a remote repository, use:${NC}"
    echo -e "${YELLOW}   git remote add origin <repository-url>${NC}"
    echo -e "${YELLOW}Then push with:${NC}"
    echo -e "${YELLOW}   git push -u origin main${NC}"
fi

echo -e "\n"

# Display summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Project files:${NC}"
echo -e "  • $REPORT_FILE - LaTeX research paper"
echo -e "  • $README_FILE - Project documentation"
echo -e "\n${GREEN}Next steps:${NC}"
echo -e "  1. Edit report.tex with your research content"
echo -e "  2. Update README.md with specific project details"
echo -e "  3. Create additional directories for data and results"
echo -e "  4. Run this script again to commit new changes"
echo -e "\n"

exit 0
