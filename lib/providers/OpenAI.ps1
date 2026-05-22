function Get-PsaiOpenAIResponse {
    param (
        [string]$Query,
        [string]$Context
    )

    $config = Get-PsaiOpenAIConfig
    $url = $config.Url
    $apiKey = $config.ApiKey
    $model = $config.Model

    if (-not $apiKey -and $url -eq "https://api.openai.com/v1/chat/completions") {
        throw "Missing OpenAI API key. Set PSAI_OPENAI_KEY or OPENAI_API_KEY."
    }

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
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Content-Type" = "application/json"
    }
    if ($apiKey) {
        $headers["Authorization"] = "Bearer $apiKey"
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop
    } catch {
        $message = $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $message = $_.ErrorDetails.Message
        }
        throw "OpenAI API request failed: $message"
    }
    
    if ($response.error -and $response.error.message) {
        throw "OpenAI API error: $($response.error.message)"
    }

    if ($response.choices -and $response.choices[0].message.content) {
        return ConvertFrom-PsaiSuggestionText -Text $response.choices[0].message.content
    }
    
    throw "Malformed OpenAI API response."
}
