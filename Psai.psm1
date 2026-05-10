. "$PSScriptRoot/lib/Utils.ps1"
. "$PSScriptRoot/lib/Context.ps1"
. "$PSScriptRoot/lib/providers/OpenAI.ps1"

function Invoke-PsaiSuggestion {
    param ([string]$Query)
    
    # Use direct console output to bypass PSReadLine swallowing
    [console]::WriteLine("`n[psai] Thinking about: '$Query'...")
    
    try {
        $context = Get-PsaiContext
        [console]::WriteLine("[psai] Context gathered. Contacting AI at $env:PSAI_OPENAI_URL...")
        
        $suggestion = Get-PsaiOpenAIResponse -Query $Query -Context $context

        if ($suggestion) {
            [console]::WriteLine("[psai] Success! Updating terminal.")
            $buffer = ""
            $cursor = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete(0, $buffer.Length)
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($suggestion)
        } else {
            [console]::WriteLine("[psai] Warning: AI returned an empty response.")
        }
    } catch {
        [console]::WriteLine("[psai] ERROR: $($_.Exception.Message)")
    }
}

# Trigger: Enter key interception
Set-PSReadLineKeyHandler -Key 'Enter' -BriefDescription 'AI Enter Trigger' -LongDescription 'Intercepts # comments' -ScriptBlock {
    $buffer = ""
    $cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)
    
    # HEARTBEAT: This will print EVERY time you press Enter while Psai is loaded
    # [console]::WriteLine("`n[psai-debug] Buffer length: $($buffer.Length) | Content: '$buffer'")

    # Simplified check: Just look for # at the start of the trimmed string
    $trimmed = $buffer.TrimStart()
    if ($trimmed.StartsWith('#')) {
        # Extract everything after the #
        $query = $trimmed.Substring(1).Trim()
        if ($query) {
            Invoke-PsaiSuggestion -Query $query
            return # Stop here so we don't execute the comment
        }
    }
    
    # Normal execution if no match
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Export-ModuleMember -Function Invoke-PsaiSuggestion