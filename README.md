# Psai 🤖🐚

**Psai** is an intelligent, interactive CLI assistant for PowerShell. It allows you to transform natural language descriptions into executable PowerShell commands directly within your terminal session. By intercepting comments, Psai streamlines your workflow, allowing you to stay in the flow without searching for syntax.

---

## Features ✨

| Feature | Description |
|---|---|
| **Comment Trigger** | Type a query starting with `#` and press Enter to get an AI suggestion. |
| **Context-Aware** | Uses your current directory, terminal history, and system info to ground suggestions. |
| **Buffer Injection** | Suggestions are injected directly into your terminal line via `PSReadLine`. |
| **Extensible** | Compatible with any OpenAI-compatible API provider. |

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

Psai relies on environment variables for API communication. Ensure the following are set in your profile or session:

| Environment Variable | Description |
|---|---|
| `PSAI_OPENAI_KEY` | Your API authentication key. |
| `PSAI_OPENAI_URL` | The API completion endpoint URL. |
| `PSAI_OPENAI_MODEL` | The specific model name to be used (e.g., `gpt-4o`). |

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
| **Verify Trigger** | Type `# hello` and press `Enter` |
