. "$PSScriptRoot/lib/Utils.ps1"
. "$PSScriptRoot/lib/Context.ps1"
. "$PSScriptRoot/lib/providers/OpenAI.ps1"
. "$PSScriptRoot/lib/providers/Gemini.ps1"

$ActivityName = "PowerShell AI"

function Invoke-PsaiSuggestion {
    param ([string]$Query)

    
    
    try {
        Write-Progress -Activity $ActivityName -Status "Gathering context..."
        $context = Get-PsaiContext

        $provider = Resolve-PsaiProvider

        Write-Progress -Activity $ActivityName -Status "Contacting $provider provider..."
        $suggestion = switch ($provider) {
            "openai" { Get-PsaiOpenAIResponse -Query $Query -Context $context }
            "gemini" { Get-PsaiGeminiResponse -Query $Query -Context $context }
        }

        if ($suggestion) {
            Write-Progress -Activity $ActivityName -Status "Success! Updating terminal."
            $buffer = ""
            $cursor = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete(0, $buffer.Length)
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($suggestion)
        } else {
            Write-Progress -Activity $ActivityName -Status "Warning: AI returned an empty response."
        }
    } catch {
        Write-Progress -Activity $ActivityName -Status "ERROR: $($_.Exception.Message)"
    } finally {
        Write-Progress -Activity $ActivityName -Completed
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
