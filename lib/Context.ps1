function Get-PsaiContext {
    $context = @()
    
    # Directory Context
    $context += "Current Directory: $((Get-Location).Path)"
    $files = Get-ChildItem | Select-Object -First 10 | ForEach-Object { $_.Name }
    if ($files) {
        $context += "Files in directory: $($files -join ', ')"
    }

    # Project Detection
    if (Test-Path "package.json") { $context += "Project Type: Node.js" }
    elseif (Test-Path "Cargo.toml") { $context += "Project Type: Rust" }
    elseif (Test-Path "requirements.txt") { $context += "Project Type: Python" }

    # Git Context
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $branch = git branch --show-current 2>$null
        if ($branch) {
            $status = if (git status --porcelain) { "dirty" } else { "clean" }
            $context += "Git: branch=$branch, status=$status"
        }
    }

    # OS Context
    $context += "OS: $($PSVersionTable.OS)"

    return $context -join "`n"
}