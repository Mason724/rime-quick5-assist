# rime-quick5-assist 安裝腳本
# 用法（在解壓後的資料夾內）：powershell -ExecutionPolicy Bypass -File .\install.ps1
# 做的事：備份現有檔案 → 複製補丁與 lua → 下載 predict.db → 提示重新部署

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$dst = Join-Path $env:APPDATA 'Rime'

if (-not (Test-Path $dst)) {
    Write-Host "找不到 Rime 用戶目錄：$dst" -ForegroundColor Red
    Write-Host '請先安裝並執行一次小狼毫（Weasel），讓它建立用戶目錄。'
    exit 1
}

Write-Host "目標目錄：$dst"
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path $dst "_backup_quick5assist_$stamp"
New-Item -ItemType Directory -Path $backup -Force | Out-Null

function Copy-WithBackup($rel) {
    $from = Join-Path $src $rel
    $to = Join-Path $dst $rel
    if (-not (Test-Path $from)) { return }
    if (Test-Path $to) {
        $bdir = Join-Path $backup (Split-Path $rel -Parent)
        if ($bdir -and -not (Test-Path $bdir)) { New-Item -ItemType Directory -Path $bdir -Force | Out-Null }
        Copy-Item $to $bdir -Force
    }
    $tdir = Split-Path $to -Parent
    if (-not (Test-Path $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
    Copy-Item $from $to -Force
    Write-Host "  已複製 $rel"
}

Copy-WithBackup 'quick5.custom.yaml'
Copy-WithBackup 'quick5_phrase.schema.yaml'
Copy-WithBackup 'lua\assist.lua'

$db = Join-Path $dst 'predict.db'
if (Test-Path $db) {
    Write-Host '  predict.db 已存在，跳過下載'
} else {
    Write-Host '  下載 predict.db（約 7 MB）...'
    $url = 'https://github.com/rime/librime-predict/releases/download/data-1.0/predict.db'
    try {
        Invoke-WebRequest -Uri $url -OutFile $db -UseBasicParsing
        Write-Host '  已下載 predict.db'
    } catch {
        Write-Host "  下載失敗：$($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  請手動下載：$url" -ForegroundColor Yellow
        Write-Host "  放到：$db"
    }
}

Write-Host ''
Write-Host '完成。備份在：' -ForegroundColor Green
Write-Host "  $backup"
Write-Host ''
Write-Host '最後一步：在工作列的小狼毫圖示上按右鍵 →「重新部署」，然後打一個詞試試。' -ForegroundColor Green
