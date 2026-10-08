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

gh release create "v$Version" "dist\$jarName" $mrpack.FullName --title "영지전 $Version" --notes "영지전 모드 $Version. Prism(packwiz) 사용자는 자동 갱신, Modrinth 앱은 mrpack 다시 가져오기."
Write-Host "완료: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/v$Version"
