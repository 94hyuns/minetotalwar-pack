# 영지전 모드팩 새 버전 배포. 저장소 루트에서 실행.
#   .\tools\release.ps1 -Version 1.0.1 -Jar C:\Users\vkghk\MineTotalWar\build\libs\minetotalwar-1.0.1.jar
# 필요: python, git, GitHub CLI(gh, 로그인 상태)
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Jar
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $Jar)) { throw "jar 없음: $Jar" }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "GitHub CLI(gh) 가 없습니다. winget install GitHub.cli 뒤 gh auth login" }

python tools\build_pack.py --jar $Jar --version $Version
if ($LASTEXITCODE -ne 0) { throw "build_pack.py 실패" }

$jarName = Split-Path -Leaf $Jar
$mrpack = Get-ChildItem dist\*-$Version.mrpack | Select-Object -First 1
if ($null -eq $mrpack) { throw "mrpack 이 생성되지 않음" }

cmd /c "git add pack.toml index.toml mods 2>&1"
cmd /c "git commit -m v$Version 2>&1"
cmd /c "git push 2>&1"
if ($LASTEXITCODE -ne 0) { throw "git push 실패" }

# 패치노트를 디스코드 #서버공지로 (설계 §33, 2026-10-20 사용자: 커밋 메시지는 보기 힘듦 → 플레이어용 글)
# 저장소의 patchnotes/<버전>.md 를 카드 하나로 올린다. 파일이 없으면 건너뛴다.
# 웹훅 주소는 저장소 밖 파일 %USERPROFILE%\.minetotalwar-discord-webhook (없으면 건너뜀)
function Post-PatchNotes {
    param([string]$Version)
    $hookFile = Join-Path $env:USERPROFILE ".minetotalwar-discord-webhook"
    $notesFile = Join-Path $root "patchnotes\$Version.md"
    if (-not (Test-Path $hookFile)) { Write-Host "디스코드 웹훅 파일이 없어 패치노트를 건너뜀: $hookFile"; return }
    if (-not (Test-Path $notesFile)) { Write-Host "패치노트 파일이 없어 건너뜀: $notesFile"; return }
    $hook = (Get-Content $hookFile -Raw).Trim()
    $notes = (Get-Content $notesFile -Raw -Encoding UTF8).Trim()
    if ($notes.Length -gt 4000) { $notes = $notes.Substring(0, 4000) + "…" }
    $embed = @{ title = "📦 영지전 v$Version 업데이트"; description = $notes; color = 0x3498DB; timestamp = (Get-Date).ToUniversalTime().ToString("o") }
    $json = @{ embeds = @($embed); allowed_mentions = @{ parse = @() } } | ConvertTo-Json -Depth 5 -Compress
    try {
        Invoke-RestMethod -Uri $hook -Method Post -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null
        Write-Host "패치노트 게시: $notesFile"
    } catch {
        Write-Host "패치노트 게시 실패: $_"
    }
}

gh release create "v$Version" "dist\$jarName" $mrpack.FullName --title "영지전 $Version" --notes "영지전 모드 $Version. Prism(packwiz) 사용자는 자동 갱신, Modrinth 앱은 mrpack 다시 가져오기."
Write-Host "완료: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/v$Version"
Post-PatchNotes -Version $Version
