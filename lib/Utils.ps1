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

function ConvertFrom-PsaiSuggestionText {
    param ([AllowNull()][string]$Text)

    if (-not $Text) {
        return ""
    }

    $cleanText = $Text.Trim()
    $cleanText = $cleanText -replace '^```(powershell|pwsh)?\s*', ''
    $cleanText = $cleanText -replace '\s*```$', ''
    $cleanText = $cleanText -replace '(?i)^(here is your command:|the command is:|sure, here you go:)', ''

    return $cleanText.Trim()
}

function Get-PsaiOpenAIConfig {
    $url = if ($env:PSAI_OPENAI_URL) { $env:PSAI_OPENAI_URL } else { "https://api.openai.com/v1/chat/completions" }
    $apiKey = if ($env:PSAI_OPENAI_KEY) { $env:PSAI_OPENAI_KEY } else { $env:OPENAI_API_KEY }
    $model = if ($env:PSAI_OPENAI_MODEL) { $env:PSAI_OPENAI_MODEL } else { "gpt-4o" }

    return @{
        Url = $url
        ApiKey = $apiKey
        Model = $model
        IsConfigured = [bool]($apiKey -or $env:PSAI_OPENAI_URL)
    }
}

function Get-PsaiGeminiConfig {
    $apiKey = if ($env:PSAI_GEMINI_KEY) { $env:PSAI_GEMINI_KEY } else { $env:GEMINI_API_KEY }
    $model = if ($env:PSAI_GEMINI_MODEL) { $env:PSAI_GEMINI_MODEL } else { "gemini-2.5-flash" }
    $urlTemplate = if ($env:PSAI_GEMINI_URL) {
        $env:PSAI_GEMINI_URL
    } else {
        "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    }

    $escapedModel = [System.Uri]::EscapeDataString($model)
    $escapedKey = if ($apiKey) { [System.Uri]::EscapeDataString($apiKey) } else { "" }
    $url = $urlTemplate.Replace("{model}", $escapedModel).Replace("{key}", $escapedKey)

    return @{
        Url = $url
        ApiKey = $apiKey
        Model = $model
        IsConfigured = [bool]$apiKey
    }
}

function Resolve-PsaiProvider {
    $provider = $env:PSAI_PROVIDER

    if ($provider) {
        switch ($provider.ToLowerInvariant()) {
            "openai" { return "openai" }
            "gemini" { return "gemini" }
            default { throw "Invalid PSAI_PROVIDER '$provider'. Use 'openai' or 'gemini'." }
        }
    }

    if ((Get-PsaiOpenAIConfig).IsConfigured) {
        return "openai"
    }

    if ((Get-PsaiGeminiConfig).IsConfigured) {
        return "gemini"
    }

    throw "No Psai provider configured. Set PSAI_OPENAI_KEY or PSAI_GEMINI_KEY, or set PSAI_PROVIDER to 'openai' or 'gemini'."
}
