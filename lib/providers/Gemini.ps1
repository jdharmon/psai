function Get-PsaiGeminiResponse {
    param (
        [string]$Query,
        [string]$Context
    )

    $config = Get-PsaiGeminiConfig
    if (-not $config.ApiKey) {
        throw "Missing Gemini API key. Set PSAI_GEMINI_KEY or GEMINI_API_KEY."
    }

    $systemPrompt = Get-PsaiSystemPrompt -Context $Context
    $body = @{
        contents = @(
            @{
                role = "user"
                parts = @(
                    @{ text = $Query }
                )
            }
        )
        systemInstruction = @{
            parts = @(
                @{ text = $systemPrompt }
            )
        }
        generationConfig = @{
            temperature = 0.0
            maxOutputTokens = 100
            thinkingConfig = @{
                thinkingBudget = 0
            }
        }
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Content-Type" = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $config.Url -Headers $headers -Body $body -ErrorAction Stop
    } catch {
        $message = $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $message = $_.ErrorDetails.Message
        }
        throw "Gemini API request failed: $message"
    }

    if ($response.error -and $response.error.message) {
        throw "Gemini API error: $($response.error.message)"
    }

    if (
        $response.candidates -and
        $response.candidates[0].content -and
        $response.candidates[0].content.parts -and
        $response.candidates[0].content.parts[0].text
    ) {
        return ConvertFrom-PsaiSuggestionText -Text $response.candidates[0].content.parts[0].text
    }

    throw "Malformed Gemini API response."
}
