# PreToolUse hook - Block commands containing secrets
# Place in: .claude\hooks\security-check.ps1
# Register in: .claude\settings.json (with -ExecutionPolicy Bypass)

$inputJson = [Console]::In.ReadToEnd() | ConvertFrom-Json
$tool = $inputJson.tool_name

if ($tool -eq "Bash") {
    $command = $inputJson.tool_input.command

    # Check for common secret patterns
    $patterns = @(
        "password=",
        "PASSWORD=",
        "secret=",
        "SECRET=",
        "api_key=",
        "API_KEY=",
        "apikey=",
        "token=",
        "TOKEN=",
        "aws_access_key",
        "AWS_ACCESS_KEY",
        "aws_secret",
        "AWS_SECRET",
        "private_key",
        "PRIVATE_KEY"
    )

    foreach ($pattern in $patterns) {
        if ($command -match [regex]::Escape($pattern)) {
            Write-Output "{`"decision`": `"block`", `"reason`": `"Potential secret detected: $pattern`"}"
            exit 2
        }
    }

    # Check for hardcoded API keys
    if ($command -match "(sk-[a-zA-Z0-9]{20,}|pk_[a-zA-Z0-9]{20,}|[a-f0-9]{32,})") {
        Write-Output "{`"decision`": `"block`", `"reason`": `"Potential API key or hash detected`"}"
        exit 2
    }
}

# Allow the command
exit 0
