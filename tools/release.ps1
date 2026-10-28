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

# jar 를 먼저 릴리스에 올리고, 성공했을 때만 모드팩(pack.toml·mods)을 푸시한다.
# 반대 순서면 업로드가 실패했을 때 모드팩이 없는 jar 를 가리켜 서버가 켜지지 못한다 (2026-10-20 v1.0.44 토큰 403)
gh release create "v$Version" "dist\$jarName" $mrpack.FullName --title "영지전 $Version" --notes "영지전 모드 $Version. Prism(packwiz) 사용자는 자동 갱신, Modrinth 앱은 mrpack 다시 가져오기."
if ($LASTEXITCODE -ne 0) {
    cmd /c "git checkout -- pack.toml index.toml mods 2>&1"
    throw "릴리스 만들기 실패 — 모드팩은 바꾸지 않았습니다(이전 버전 그대로)"
}
Write-Host "릴리스: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/v$Version"

cmd /c "git add pack.toml index.toml mods patchnotes 2>&1"
cmd /c "git commit -m v$Version 2>&1"
cmd /c "git push 2>&1"
if ($LASTEXITCODE -ne 0) { throw "git push 실패 — 릴리스는 있으니 푸시만 다시 하면 됩니다" }

# 패치노트를 디스코드 #서버공지로 (설계 §33, 2026-10-20 사용자: 커밋 메시지는 보기 힘듦 → 플레이어용 글)
# 저장소의 patchnotes/<버전>.md 를 카드 하나로 올린다. 파일이 없으면 건너뛴다.
# 웹훅 주소는 저장소 밖 파일 %USERPROFILE%\.minetotalwar-discord-webhook (없으면 건너뜀)
# 다중 길드 (설계 §33): 그 파일은 한 줄에 주소 하나 — 여러 줄이면 디스코드 서버마다 올린다. 실패는 주소 번호로만 알림(주소는 출력 안 함)
function Post-PatchNotes {
    param([string]$Version)
    $hookFile = Join-Path $env:USERPROFILE ".minetotalwar-discord-webhook"
    $notesFile = Join-Path $root "patchnotes\$Version.md"
    if (-not (Test-Path $hookFile)) { Write-Host "디스코드 웹훅 파일이 없어 패치노트를 건너뜀: $hookFile"; return }
    if (-not (Test-Path $notesFile)) { Write-Host "패치노트 파일이 없어 건너뜀: $notesFile"; return }
    $hooks = @(Get-Content $hookFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
    if ($hooks.Count -eq 0) { Write-Host "디스코드 웹훅 파일에 주소가 없어 패치노트를 건너뜀: $hookFile"; return }
    $notes = (Get-Content $notesFile -Raw -Encoding UTF8).Trim()
    if ($notes.Length -gt 4000) { $notes = $notes.Substring(0, 4000) + "…" }
    $embed = @{ title = "📦 영지전 v$Version 업데이트"; description = $notes; color = 0x3498DB; timestamp = (Get-Date).ToUniversalTime().ToString("o") }
    $json = @{ embeds = @($embed); allowed_mentions = @{ parse = @() } } | ConvertTo-Json -Depth 5 -Compress
    for ($i = 0; $i -lt $hooks.Count; $i++) {
        $label = if ($hooks.Count -gt 1) { " ($($i + 1)번 주소)" } else { "" }
        try {
            Invoke-RestMethod -Uri $hooks[$i] -Method Post -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null
            Write-Host "패치노트 게시${label}: $notesFile"
        } catch {
            Write-Host "패치노트 게시 실패${label}: $($_.Exception.Message)"
        }
    }
}

Post-PatchNotes -Version $Version
Write-Host "완료: v$Version"
