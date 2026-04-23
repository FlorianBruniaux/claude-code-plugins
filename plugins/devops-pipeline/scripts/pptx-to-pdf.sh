#!/bin/bash
# pptx-to-pdf.sh — Convert PPTX files to PDF using Keynote (macOS)
#
# Usage:
#   ./pptx-to-pdf.sh                    # convert all PPTX in current dir (recursive)
#   ./pptx-to-pdf.sh ~/Downloads/Prose  # convert all PPTX in target folder (recursive)
#
# Requirements: macOS + Keynote installed
# Output: PDF created alongside each PPTX (same folder, same name)
#
# Key gotcha: open via shell BEFORE AppleScript export.
# Using AppleScript's own open command causes Keynote error -1719 ("Index non valable")
# because Keynote doesn't always register the document in its internal list.
# The shell open + sleep pattern is more reliable.

TARGET="${1:-.}"

echo "Scanning: $TARGET"
echo ""

count=0
failed=0

find "$TARGET" -name "*.pptx" | sort | while IFS= read -r pptx; do
  dir=$(dirname "$pptx")
  base=$(basename "$pptx" .pptx)
  pdf="$dir/$base.pdf"

  if [ -f "$pdf" ]; then
    echo "  skip (exists): $base"
    continue
  fi

  echo "→ $base"

  # Open via shell (more reliable than AppleScript open for PPTX import)
  open -a "Keynote" "$pptx"
  sleep 8

  osascript << EOF
tell application "Keynote"
  set docCount to count of documents
  if docCount > 0 then
    set doc to document 1
    set pdfFile to POSIX file "$pdf"
    export doc to pdfFile as PDF
    close doc saving no
  end if
end tell
EOF

  if [ -f "$pdf" ]; then
    size=$(du -sh "$pdf" | cut -f1)
    echo "  ✓ $size  $(basename "$pdf")"
    count=$((count + 1))
  else
    echo "  ✗ FAILED: $base"
    failed=$((failed + 1))
  fi

  sleep 1
done

echo ""
echo "=== Summary ==="
find "$TARGET" -name "*.pdf" | sort | while IFS= read -r f; do
  echo "  $(du -sh "$f" | cut -f1)  $(basename "$f")"
done