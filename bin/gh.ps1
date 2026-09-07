# gh を Docker コンテナ経由で実行するラッパー（Windows PowerShell 用）。
# 使い方: プロファイルに関数を定義するのが楽:
#   function gh { & "D:\llm\claude\base_agentic_coding\bin\gh.ps1" @args }
$ErrorActionPreference = 'Stop'

$image = if ($env:GH_IMAGE) { $env:GH_IMAGE } else { 'base-agentic-coding-gh:latest' }

# GITHUB_TOKEN も受け付ける。
$token = if ($env:GH_TOKEN) { $env:GH_TOKEN } elseif ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { '' }
if (-not $token) {
    Write-Warning 'GH_TOKEN(または GITHUB_TOKEN) が未設定です。認証が必要な操作は失敗します。'
}

# 実行ユーザー: .env と同じ既定値（Windows に id コマンドは無い）。
$uid = if ($env:UID) { $env:UID } else { '1000' }
$gid = if ($env:GID) { $env:GID } else { '1000' }

# git リポジトリのトップを /work にマウントし、カレントの相対位置で実行する。
$repoRoot = (git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    $repoRoot = (Get-Location).Path
    $workdir  = '/work'
} else {
    $rootNative = ($repoRoot -replace '/', '\')
    $cwd = (Get-Location).Path
    if ($cwd.ToLower().StartsWith($rootNative.ToLower())) {
        $rel = $cwd.Substring($rootNative.Length).Trim('\', '/') -replace '\\', '/'
        $workdir = if ($rel) { "/work/$rel" } else { '/work' }
    } else {
        $workdir = '/work'
    }
}
$repoRoot = $repoRoot -replace '\\', '/'

# 対話端末のときだけ -t を付ける。
$ttyArgs = @()
if (-not [Console]::IsInputRedirected) { $ttyArgs = @('-t') }

docker run --rm -i @ttyArgs `
    -v "${repoRoot}:/work" `
    -w $workdir `
    -e "GH_TOKEN=$token" `
    -e "GH_HOST=$($env:GH_HOST)" `
    -e "GH_REPO=$($env:GH_REPO)" `
    -u "${uid}:${gid}" `
    $image @args
