Write-Host "`n=== Claude Code Health Check ===" -ForegroundColor Cyan
Write-Host "`n--- Node & npm ---"
node --version
npm --version

Write-Host "`n--- Claude Installation ---"
where.exe claude
if ($?) { Write-Host "✓ Claude found in PATH" -ForegroundColor Green }
else { Write-Host "✗ Claude not in PATH" -ForegroundColor Red }

Write-Host "`n--- Running Claude Doctor ---"
try {
    claude doctor
    Write-Host "✓ Claude doctor completed" -ForegroundColor Green
} catch {
    Write-Host "✗ Claude doctor failed: $_" -ForegroundColor Red
}

Write-Host "`n--- API Key Status ---"
if ($env:ANTHROPIC_API_KEY) {
    Write-Host "✓ ANTHROPIC_API_KEY is set" -ForegroundColor Green
} else {
    Write-Host "✗ ANTHROPIC_API_KEY not set" -ForegroundColor Red
}

Write-Host "`n--- MCP Servers ---"
claude mcp list

Write-Host "`n--- Config Location ---"
$configPath = "$env:USERPROFILE\.claude.json"
if (Test-Path $configPath) {
    Write-Host "✓ Config found at: $configPath" -ForegroundColor Green
} else {
    Write-Host "⚠ No config file at: $configPath" -ForegroundColor Yellow
}

Write-Host "`n=== Health Check Complete ===" -ForegroundColor Cyan
