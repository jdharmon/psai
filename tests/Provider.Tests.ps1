$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/Utils.ps1"
. "$PSScriptRoot/../lib/providers/Gemini.ps1"

$envNames = @(
    "PSAI_PROVIDER",
    "PSAI_OPENAI_KEY",
    "OPENAI_API_KEY",
    "PSAI_OPENAI_URL",
    "PSAI_OPENAI_MODEL",
    "PSAI_GEMINI_KEY",
    "GEMINI_API_KEY",
    "PSAI_GEMINI_URL",
    "PSAI_GEMINI_MODEL"
)
$originalEnv = @{}
foreach ($name in $envNames) {
    $originalEnv[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

function Clear-PsaiTestEnv {
    foreach ($name in $envNames) {
        [Environment]::SetEnvironmentVariable($name, $null, "Process")
    }
}

function Restore-PsaiTestEnv {
    foreach ($name in $envNames) {
        [Environment]::SetEnvironmentVariable($name, $originalEnv[$name], "Process")
    }
}

function Assert-Equal {
    param (
        [object]$Actual,
        [object]$Expected,
        [string]$Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
}

function Assert-True {
    param (
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-ThrowsLike {
    param (
        [scriptblock]$ScriptBlock,
        [string]$ExpectedMessage,
        [string]$Message
    )

    try {
        & $ScriptBlock
    } catch {
        if ($_.Exception.Message -like $ExpectedMessage) {
            return
        }
        throw "$Message Expected error like '$ExpectedMessage', got '$($_.Exception.Message)'."
    }

    throw "$Message Expected an error."
}

try {
    Clear-PsaiTestEnv
    $env:PSAI_PROVIDER = "openai"
    $env:PSAI_OPENAI_KEY = "openai-key"
    $env:PSAI_GEMINI_KEY = "gemini-key"
    Assert-Equal (Resolve-PsaiProvider) "openai" "PSAI_PROVIDER=openai should select OpenAI."

    Clear-PsaiTestEnv
    $env:PSAI_PROVIDER = "gemini"
    $env:PSAI_OPENAI_KEY = "openai-key"
    $env:PSAI_GEMINI_KEY = "gemini-key"
    Assert-Equal (Resolve-PsaiProvider) "gemini" "PSAI_PROVIDER=gemini should select Gemini."

    Clear-PsaiTestEnv
    $env:PSAI_OPENAI_KEY = "openai-key"
    $env:PSAI_GEMINI_KEY = "gemini-key"
    Assert-Equal (Resolve-PsaiProvider) "openai" "Automatic selection should prefer OpenAI."

    Clear-PsaiTestEnv
    $env:PSAI_GEMINI_KEY = "gemini-key"
    Assert-Equal (Resolve-PsaiProvider) "gemini" "Automatic selection should select Gemini when only Gemini is configured."

    Clear-PsaiTestEnv
    $env:PSAI_OPENAI_URL = "http://localhost:11434/v1/chat/completions"
    $env:PSAI_GEMINI_KEY = "gemini-key"
    Assert-Equal (Resolve-PsaiProvider) "openai" "Automatic selection should treat a custom OpenAI URL as OpenAI configuration."

    Clear-PsaiTestEnv
    $env:PSAI_PROVIDER = "bogus"
    Assert-ThrowsLike { Resolve-PsaiProvider } "*Invalid PSAI_PROVIDER 'bogus'*" "Invalid provider should fail clearly."

    Clear-PsaiTestEnv
    Assert-ThrowsLike { Resolve-PsaiProvider } "*No Psai provider configured*" "Missing provider configuration should fail clearly."

    Clear-PsaiTestEnv
    $env:PSAI_GEMINI_KEY = "gemini-key"
    $env:PSAI_GEMINI_MODEL = "gemini-test"
    function Invoke-RestMethod {
        [CmdletBinding()]
        param (
            [string]$Method,
            [string]$Uri,
            [hashtable]$Headers,
            [string]$Body
        )

        $script:LastGeminiUri = $Uri
        $script:LastGeminiHeaders = $Headers
        $script:LastGeminiBody = $Body
        return [pscustomobject]@{
            candidates = @(
                [pscustomobject]@{
                    content = [pscustomobject]@{
                        parts = @(
                            [pscustomobject]@{
                                text = @'
```powershell
Get-ChildItem
```
'@
                            }
                        )
                    }
                }
            )
        }
    }

    $result = Get-PsaiGeminiResponse -Query "list files" -Context "Current Directory: /tmp"
    Assert-Equal $result "Get-ChildItem" "Gemini responses should be sanitized."
    Assert-True ($script:LastGeminiUri -like "*models/gemini-test:generateContent?key=gemini-key") "Gemini URL should include model and key."
    Assert-Equal $script:LastGeminiHeaders["Content-Type"] "application/json" "Gemini request should use JSON content type."

    $json = $script:LastGeminiBody | ConvertFrom-Json
    Assert-Equal $json.contents[0].role "user" "Gemini contents should contain a user role."
    Assert-Equal $json.contents[0].parts[0].text "list files" "Gemini contents.parts should preserve the query."
    Assert-True ($json.systemInstruction.parts[0].text -like "*Current Directory: /tmp*") "Gemini systemInstruction.parts should include context."
    Assert-Equal $json.generationConfig.temperature 0.0 "Gemini temperature should be deterministic."
    Assert-Equal $json.generationConfig.maxOutputTokens 100 "Gemini max output should be capped."
    Assert-Equal $json.generationConfig.thinkingConfig.thinkingBudget 0 "Gemini thinking budget should be disabled."

    function Invoke-RestMethod {
        [CmdletBinding()]
        param (
            [string]$Method,
            [string]$Uri,
            [hashtable]$Headers,
            [string]$Body
        )

        return [pscustomobject]@{
            error = [pscustomobject]@{
                message = "quota exceeded"
            }
        }
    }
    Assert-ThrowsLike { Get-PsaiGeminiResponse -Query "x" -Context "y" } "*Gemini API error: quota exceeded*" "Gemini API errors should fail clearly."

    function Invoke-RestMethod {
        [CmdletBinding()]
        param (
            [string]$Method,
            [string]$Uri,
            [hashtable]$Headers,
            [string]$Body
        )

        return [pscustomobject]@{
            candidates = @()
        }
    }
    Assert-ThrowsLike { Get-PsaiGeminiResponse -Query "x" -Context "y" } "*Malformed Gemini API response*" "Malformed Gemini responses should fail clearly."

    "Provider.Tests.ps1 passed"
} finally {
    Restore-PsaiTestEnv
}
