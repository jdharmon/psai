function Get-PsaiOpenAIResponse {
    param (
        [string]$Query,
        [string]$Context
    )

    $url = if ($env:PSAI_OPENAI_URL) { $env:PSAI_OPENAI_URL } else { "https://api.openai.com/v1/chat/completions" }
    $apiKey = if ($env:PSAI_OPENAI_API_KEY) { $env:PSAI_OPENAI_API_KEY } else { $env:OPENAI_API_KEY }
    $model = if ($env:PSAI_OPENAI_MODEL) { $env:PSAI_OPENAI_MODEL } else { "gpt-4o" }

    $systemPrompt = Get-PsaiSystemPrompt -Context $Context

    # Combine system instructions and user query into a single User message
    $combinedPrompt = "$systemPrompt`n`nUSER REQUEST: $Query"

    $body = @{
        model = $model
        messages = @(
            @{ role = "user"; content = $combinedPrompt }
        )
        temperature = 0.0
        max_tokens = 100
    } | ConvertTo-Json

    $headers = @{
        "Content-Type" = "application/json"
    }
    if ($apiKey) {
        $headers["Authorization"] = "Bearer $apiKey"
    }

    $response = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop
    
    if ($response.choices) {
        $rawText = $response.choices[0].message.content.Trim()
        
        # Sanitization: Strip backticks and conversational fluff
        $rawText = $rawText -replace '^```(powershell|pwsh)?\s*', ''
        $rawText = $rawText -replace '\s*```$', ''
        $rawText = $rawText -replace '(?i)^(here is your command:|the command is:|sure, here you go:)', ''
        
        return $rawText.Trim()
    }
    
    throw "Malformed API response."
}