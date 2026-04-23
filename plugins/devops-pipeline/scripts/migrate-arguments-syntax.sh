#!/bin/bash
# Migration Script: $ARGUMENTS syntax (v2.1.19 breaking change)
#
# Purpose: Update custom commands from old dot notation to new bracket syntax
# Breaking Change: $ARGUMENTS.0 → $ARGUMENTS[0] (introduced in Claude Code v2.1.19)
#
# Usage:
#   ./migrate-arguments-syntax.sh           # Preview changes
#   ./migrate-arguments-syntax.sh --apply   # Apply changes
#
# Safety: Creates backups before modifying files

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APPLY_CHANGES=false
BACKUP_DIR="$HOME/.claude/backups/arguments-migration-$(date +%Y%m%d-%H%M%S)"

# Directories to scan
SCAN_DIRS=(
    "$HOME/.claude/commands"
    "$HOME/.claude/skills"
    ".claude/commands"
    ".claude/skills"
)

# Parse arguments
if [[ "${1:-}" == "--apply" ]]; then
    APPLY_CHANGES=true
fi

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Claude Code v2.1.19 - \$ARGUMENTS Syntax Migration      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Breaking Change:${NC} \$ARGUMENTS.N → \$ARGUMENTS[N]"
echo ""

# Check if any scan directories exist
found_dirs=false
for dir in "${SCAN_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        found_dirs=true
        break
    fi
done

if [[ "$found_dirs" == "false" ]]; then
    echo -e "${GREEN}✓ No custom commands/skills directories found${NC}"
    echo "  Nothing to migrate."
    exit 0
fi

# Find files with old syntax
echo "Scanning for files with old \$ARGUMENTS.N syntax..."
echo ""

affected_files=()
for dir in "${SCAN_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        continue
    fi

    # Find .md files with $ARGUMENTS.N pattern
    while IFS= read -r file; do
        if grep -q '\$ARGUMENTS\.[0-9]' "$file"; then
            affected_files+=("$file")
        fi
    done < <(find "$dir" -type f -name "*.md" 2>/dev/null || true)
done

# Report findings
if [[ ${#affected_files[@]} -eq 0 ]]; then
    echo -e "${GREEN}✓ No files need migration${NC}"
    echo "  All custom commands already use the new syntax."
    exit 0
fi

echo -e "${YELLOW}Found ${#affected_files[@]} file(s) with old syntax:${NC}"
echo ""

# Preview changes
for file in "${affected_files[@]}"; do
    echo -e "${BLUE}📄 $file${NC}"

    # Show occurrences
    grep -n '\$ARGUMENTS\.[0-9]' "$file" | while IFS=: read -r line_num line_content; do
        echo -e "   ${YELLOW}Line $line_num:${NC} $line_content"
    done
    echo ""
done

# Apply changes if requested
if [[ "$APPLY_CHANGES" == "true" ]]; then
    echo -e "${YELLOW}Creating backups in: $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"

    for file in "${affected_files[@]}"; do
        # Create backup
        backup_path="$BACKUP_DIR/$(basename "$file")"
        cp "$file" "$backup_path"
        echo -e "${GREEN}✓${NC} Backed up: $(basename "$file")"

        # Apply migration (macOS-compatible sed)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' 's/\$ARGUMENTS\.\([0-9]\)/\$ARGUMENTS[\1]/g' "$file"
        else
            # Linux
            sed -i 's/\$ARGUMENTS\.\([0-9]\)/\$ARGUMENTS[\1]/g' "$file"
        fi

        echo -e "${GREEN}✓${NC} Migrated: $file"
    done

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Migration Complete                                    ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Backups saved to: $BACKUP_DIR"
    echo ""
    echo "Changes applied:"
    echo "  • \$ARGUMENTS.0 → \$ARGUMENTS[0]"
    echo "  • \$ARGUMENTS.1 → \$ARGUMENTS[1]"
    echo "  • etc."
    echo ""
    echo "You can also use shorthand: \$0, \$1, \$2, ..."

else
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}DRY RUN MODE - No changes applied${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "To apply these changes, run:"
    echo -e "  ${GREEN}./migrate-arguments-syntax.sh --apply${NC}"
    echo ""
    echo "This will:"
    echo "  1. Create backups in ~/.claude/backups/"
    echo "  2. Update all files to new bracket syntax"
    echo "  3. Preserve original files in backup directory"
fi

echo ""
echo "Documentation: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md#2119"
