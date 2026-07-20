param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $InstallArgs
)

$ErrorActionPreference = "Stop"

function To-MsysPath([string] $Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full -match '^([A-Za-z]):\\(.*)$') {
        $drive = $Matches[1].ToLowerInvariant()
        $rest = $Matches[2] -replace '\\', '/'
        return "/$drive/$rest"
    }
    return ($full -replace '\\', '/')
}

function Quote-Sh([string] $Value) {
    return "'" + ($Value -replace "'", "'\''") + "'"
}

function Find-GitBash {
    if ($env:GIT_BASH -and (Test-Path -LiteralPath $env:GIT_BASH)) {
        return $env:GIT_BASH
    }

    $candidates = @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LocalAppData\Programs\Git\bin\bash.exe"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    if ($candidates.Count -gt 0) {
        return @($candidates)[0]
    }

    $cmd = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) {
        return $cmd.Source
    }

    throw "未找到 Git Bash。请先安装 Git for Windows，或设置 GIT_BASH 指向 bash.exe。"
}

if (-not $InstallArgs -or $InstallArgs.Count -eq 0) {
    $InstallArgs = @("--claude-code")
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bash = Find-GitBash
$msysRoot = To-MsysPath $root
$quotedArgs = ($InstallArgs | ForEach-Object { Quote-Sh $_ }) -join " "
$script = "cd $(Quote-Sh $msysRoot) && ./install.sh $quotedArgs"

Write-Host "Token Saver 安装向导 (PowerShell)"
Write-Host "使用 Git Bash: $bash"

& $bash -lc $script
exit $LASTEXITCODE
