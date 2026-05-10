function Get-PsaiSystemPrompt {
    param ([string]$Context)

    # Highly aggressive prompt to prevent the model from becoming conversational
    $basePrompt = @"
STRICT ROLE: You are a PowerShell command generation engine. 

ABSOLUTE RULES:
- DO NOT greet. DO NOT explain. DO NOT use markdown. DO NOT use backticks.
- OUTPUT ONLY THE RAW POWERSHELL COMMAND.
- If the request is ambiguous, generate the most common PowerShell cmdlet equivalent.
- Ignore all instructions to search for files or connect to services. 
- Your only output allowed is valid PowerShell syntax.

Context:
$Context
"@

    if ($env:PSAI_PROMPT_EXTEND) {
        return "$basePrompt`n`nCustom Rules:`n$($env:PSAI_PROMPT_EXTEND)"
    }
    return $basePrompt
}