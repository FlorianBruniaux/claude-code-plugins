# Migration Script: $ARGUMENTS syntax (v2.1.19 breaking change)
#
# Purpose: Update custom commands from old dot notation to new bracket syntax
# Breaking Change: $ARGUMENTS.0 → $ARGUMENTS[0] (introduced in Claude Code v2.1.19)
#
# Usage:
#   .\migrate-arguments-syntax.ps1           # Preview changes
#   .\migrate-arguments-syntax.ps1 -Apply    # Apply changes
#
# Safety: Creates backups before modifying files

param(
    [switch]$Apply
)

# Configuration
$BackupDir = Join-Path $env:USERPROFILE ".claude\backups\arguments-migration-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Directories to scan
$ScanDirs = @(
    (Join-Path $env:USERPROFILE ".claude\commands"),
    (Join-Path $env:USERPROFILE ".claude\skills"),
    ".claude\commands",
    ".claude\skills"
)

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  Claude Code v2.1.19 - `$ARGUMENTS Syntax Migration      ║" -ForegroundColor Blue
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "Breaking Change: " -NoNewline -ForegroundColor Yellow
Write-Host "`$ARGUMENTS.N → `$ARGUMENTS[N]"
Write-Host ""

# Check if any scan directories exist
$foundDirs = $false
foreach ($dir in $ScanDirs) {
    if (Test-Path $dir) {
        $foundDirs = $true
        break
    }
}

if (-not $foundDirs) {
    Write-Host "✓ No custom commands/skills directories found" -ForegroundColor Green
    Write-Host "  Nothing to migrate."
    exit 0
}

# Find files with old syntax
Write-Host "Scanning for files with old `$ARGUMENTS.N syntax..."
Write-Host ""

$affectedFiles = @()
foreach ($dir in $ScanDirs) {
    if (-not (Test-Path $dir)) {
        continue
    }

    # Find .md files with $ARGUMENTS.N pattern
    Get-ChildItem -Path $dir -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match '\$ARGUMENTS\.[0-9]') {
            $affectedFiles += $_.FullName
        }
    }
}

# Report findings
if ($affectedFiles.Count -eq 0) {
    Write-Host "✓ No files need migration" -ForegroundColor Green
    Write-Host "  All custom commands already use the new syntax."
    exit 0
}

Write-Host "Found $($affectedFiles.Count) file(s) with old syntax:" -ForegroundColor Yellow
Write-Host ""

# Preview changes
foreach ($file in $affectedFiles) {
    Write-Host "📄 $file" -ForegroundColor Blue

    # Show occurrences
    $lineNum = 0
    Get-Content $file | ForEach-Object {
        $lineNum++
        if ($_ -match '\$ARGUMENTS\.[0-9]') {
            Write-Host "   Line ${lineNum}: $_" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Apply changes if requested
if ($Apply) {
    Write-Host "Creating backups in: $BackupDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

    foreach ($file in $affectedFiles) {
        # Create backup
        $fileName = Split-Path $file -Leaf
        $backupPath = Join-Path $BackupDir $fileName
        Copy-Item $file $backupPath
        Write-Host "✓ Backed up: $fileName" -ForegroundColor Green

        # Apply migration
        $content = Get-Content $file -Raw
        $newContent = $content -replace '\$ARGUMENTS\.([0-9])', '$ARGUMENTS[$1]'
        Set-Content -Path $file -Value $newContent -NoNewline

        Write-Host "✓ Migrated: $file" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✓ Migration Complete                                    ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backups saved to: $BackupDir"
    Write-Host ""
    Write-Host "Changes applied:"
    Write-Host "  • `$ARGUMENTS.0 → `$ARGUMENTS[0]"
    Write-Host "  • `$ARGUMENTS.1 → `$ARGUMENTS[1]"
    Write-Host "  • etc."
    Write-Host ""
    Write-Host "You can also use shorthand: `$0, `$1, `$2, ..."

} else {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "DRY RUN MODE - No changes applied" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To apply these changes, run:"
    Write-Host "  .\migrate-arguments-syntax.ps1 -Apply" -ForegroundColor Green
    Write-Host ""
    Write-Host "This will:"
    Write-Host "  1. Create backups in %USERPROFILE%\.claude\backups\"
    Write-Host "  2. Update all files to new bracket syntax"
    Write-Host "  3. Preserve original files in backup directory"
}

Write-Host ""
Write-Host "Documentation: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md#2119"
