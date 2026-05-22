# Psai 🤖🐚

**Psai** is an intelligent, interactive CLI assistant for PowerShell. It allows you to transform natural language descriptions into executable PowerShell commands directly within your terminal session. By intercepting comments, Psai streamlines your workflow, allowing you to stay in the flow without searching for syntax.

---

## Features ✨

| Feature | Description |
|---|---|
| **Comment Trigger** | Type a query starting with `#` and press Enter to get an AI suggestion. |
| **Context-Aware** | Uses your current directory, terminal history, and system info to ground suggestions. |
| **Buffer Injection** | Suggestions are injected directly into your terminal line via `PSReadLine`. |
| **Extensible** | Supports OpenAI-compatible providers and Gemini Developer API. |

---

## Installation 🛠️

To install and use Psai in your current session:

1. **Clone the repository:**
   ```powershell
   git clone <repository-url>
   cd psai
   ```

2. **Import the module:**
   ```powershell
   Import-Module ./Psai.psd1 -Force
   ```

---

## Configuration ⚙️

Psai relies on environment variables for API communication. `PSAI_PROVIDER` is optional. When it is not set, Psai automatically selects OpenAI first when OpenAI configuration exists, then Gemini when Gemini configuration exists.

| Environment Variable | Description |
|---|---|
| `PSAI_PROVIDER` | Optional provider override. Use `openai` or `gemini`. |
| `PSAI_OPENAI_KEY` | OpenAI API key. Falls back to `OPENAI_API_KEY`. |
| `PSAI_OPENAI_URL` | OpenAI-compatible completion endpoint. Defaults to `https://api.openai.com/v1/chat/completions`. |
| `PSAI_OPENAI_MODEL` | OpenAI model name. Defaults to `gpt-4o`. |
| `PSAI_GEMINI_KEY` | Gemini API key. Falls back to `GEMINI_API_KEY`. |
| `PSAI_GEMINI_MODEL` | Gemini model name. Defaults to `gemini-2.5-flash`. |
| `PSAI_GEMINI_URL` | Optional Gemini `generateContent` endpoint template. Defaults to the Gemini Developer API URL. |

### OpenAI setup

```powershell
$env:PSAI_OPENAI_KEY = "your-openai-key"
# Optional:
$env:PSAI_PROVIDER = "openai"
$env:PSAI_OPENAI_MODEL = "gpt-4o"
```

### Gemini setup

```powershell
$env:PSAI_GEMINI_KEY = "your-gemini-key"
# Optional:
$env:PSAI_PROVIDER = "gemini"
$env:PSAI_GEMINI_MODEL = "gemini-2.5-flash"
```

---

## How to Use 🚀

Psai integrates seamlessly with your typing flow:

1. Type a request starting with `#` in your PowerShell terminal.
   - *Example:* `# find all logs modified in the last 24 hours`
2. Press **Enter**.
3. Psai will display a "Thinking..." status and then replace your comment with the suggested command.
4. Review the command and press **Enter** again to execute it.

---

## Implementation Details 🏗️

* **Key Interception**: Psai uses `Set-PSReadLineKeyHandler` to intercept the `Enter` key, allowing it to process comments before the shell attempts to execute them.
* **Context Gathering**: The `Get-PsaiContext` utility snapshots the last 10 lines of history and the first 10 files in your current directory to provide context to the AI.
* **Early Return**: If a comment is detected, the module processes the AI request and returns early, ensuring the original comment isn't treated as a standard PowerShell error.

---

## Development & Testing 🧪

| Task | Command |
|---|---|
| **Reload Module** | `Import-Module ./Psai.psd1 -Force` |
| **Run Tests** | `pwsh -NoProfile -File ./tests/Provider.Tests.ps1` |
| **Verify Trigger** | Type `# hello` and press `Enter` |
