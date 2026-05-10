# Agent Instructions for Psai

## Core Architecture 🏗️
- **Key Interception**: Psai uses `Set-PSReadLineKeyHandler` to intercept the `Enter` key. This is a critical integration point; modifications to key handling should ensure compatibility with `PSReadLine`.
- **Comment Trigger**: The module specifically looks for terminal buffers starting with `#`. It extracts the query after the `#` and passes it to the AI provider.
- **Early Return**: If a comment query is processed, the script block returns early to prevent PowerShell from attempting to execute the comment text.

## Environment & Configuration ⚙️
The following environment variables are mandatory for the module to function:
- `PSAI_OPENAI_KEY`: Your API authentication key.
- `PSAI_OPENAI_URL`: The completion endpoint (e.g., your OpenAI or proxy URL).
- `PSAI_OPENAI_MODEL`: The specific model name to be used for suggestions.

## Implementation Details 🛠️
- **Context Gathering**: `Get-PsaiContext` (located in `lib/Context.ps1`) gathers current state to ground the AI:
  - The last 10 lines of terminal history.
  - The current working directory (CWD).
  - OS and Shell versioning.
  - A snapshot of the first 10 files in the current directory.
- **AI Constraints**: The system prompt requires the AI to return **raw PowerShell commands only**. It must exclude markdown formatting (backticks) and explanations to allow for direct injection into the terminal buffer.
- **Terminal Injection**: Suggestions are injected into the buffer using `[Microsoft.PowerShell.PSConsoleReadLine]::Insert($suggestion)`.
- **Output Handling**: Status messages use `[console]::WriteLine` to bypass `PSReadLine` swallowing, ensuring the user sees "Thinking..." or "Success!" messages.

## Verification & Testing 🧪
| Step | Action | Expected Result |
|---|---|---|
| **Reload** | `Import-Module ./Psai.psd1 -Force` | The module reloads with all latest logic and library changes. |
| **Trigger** | Type `# list all files` and press `Enter`. | The comment is replaced by `Get-ChildItem` (or similar). |
| **Check Logs** | Observe `[psai]` prefixed lines. | Indicates the context was gathered and the API was contacted successfully. |