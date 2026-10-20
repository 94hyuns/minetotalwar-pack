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

# 패치노트를 디스코드 #서버공지로 (설계 §33): 모드 저장소에서 지난 "vX.Y.Z" 커밋 뒤의 커밋 첫 줄들.
# 웹훅 주소는 저장소 밖 파일 %USERPROFILE%\.minetotalwar-discord-webhook (없으면 건너뜀)
function Post-PatchNotes {
    param([string]$Version, [string]$Jar)
    $hookFile = Join-Path $env:USERPROFILE ".minetotalwar-discord-webhook"
    if (-not (Test-Path $hookFile)) { Write-Host "디스코드 웹훅 파일이 없어 패치노트를 건너뜀: $hookFile"; return }
    $hook = (Get-Content $hookFile -Raw).Trim()
    $modRoot = (Resolve-Path (Join-Path (Split-Path -Parent $Jar) "..\..")).Path
    $previous = [Console]::OutputEncoding
    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    try {
        $subjects = @(git -C $modRoot log --no-merges --format=%s -n 300)
    } finally {
        [Console]::OutputEncoding = $previous
    }
    $lines = @()
    foreach ($subject in $subjects) {
        if ($subject -match '^v\d+\.\d+\.\d+') { break }
        $lines += $(if ($subject.Length -gt 60) { $subject.Substring(0, 60) + "…" } else { $subject })
    }
    [array]::Reverse($lines)
    $shown = @($lines | Select-Object -First 25)
    $text = "📦 영지전 v$Version 배포 ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))`n" + (($shown | ForEach-Object { "- $_" }) -join "`n")
    if ($lines.Count -gt 25) { $text += "`n외 $($lines.Count - 25)건" }
    if ($lines.Count -eq 0) { $text += "`n(변경 기록 없음)" }
    $json = @{ content = $text; allowed_mentions = @{ parse = @() } } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Uri $hook -Method Post -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null
        Write-Host "패치노트 게시: $($lines.Count)건"
    } catch {
        Write-Host "패치노트 게시 실패: $_"
    }
}

gh release create "v$Version" "dist\$jarName" $mrpack.FullName --title "영지전 $Version" --notes "영지전 모드 $Version. Prism(packwiz) 사용자는 자동 갱신, Modrinth 앱은 mrpack 다시 가져오기."
Write-Host "완료: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/v$Version"
Post-PatchNotes -Version $Version -Jar $Jar
