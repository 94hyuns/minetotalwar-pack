# 영지전 Fabric 서버 설치. 서버를 둘 빈 폴더에서 실행:
#   powershell -ExecutionPolicy Bypass -File server_setup.ps1 [-Dir C:\mtw-server] [-Xmx 10G]
# 하는 일: Fabric 서버 런처 + packwiz-installer-bootstrap 내려받기, start.bat 생성.
# 모드는 start.bat 이 실행될 때마다 packwiz 가 pack.toml 기준으로 맞춘다(서버 업데이트 = release.ps1 뒤 서버 재시작).
# EULA 는 직접 동의해야 한다: 첫 실행 뒤 eula.txt 의 eula=false 를 true 로 바꾸고 다시 시작.
param(
    [string]$Dir = (Get-Location).Path,
    [string]$Xmx = "10G",
    [string]$Minecraft = "1.21.11",
    [string]$Loader = "0.19.5",
    [string]$PackUrl = "https://94hyuns.github.io/minetotalwar-pack/pack.toml"
)
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force $Dir | Out-Null
Set-Location $Dir

$installer = (Invoke-RestMethod "https://meta.fabricmc.net/v2/versions/installer" | Where-Object stable | Select-Object -First 1).version
$launcherUrl = "https://meta.fabricmc.net/v2/versions/loader/$Minecraft/$Loader/$installer/server/jar"
Write-Host "Fabric 서버 런처 받는 중 ($Minecraft / loader $Loader / installer $installer)"
Invoke-WebRequest $launcherUrl -OutFile "fabric-server-launch.jar"

Write-Host "packwiz-installer-bootstrap 받는 중"
Invoke-WebRequest "https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar" -OutFile "packwiz-installer-bootstrap.jar"

@"
@echo off
cd /d %~dp0
echo [영지전] 모드 동기화 중...
java -jar packwiz-installer-bootstrap.jar -g -s server $PackUrl
if errorlevel 1 (
  echo [영지전] 모드 동기화 실패. 인터넷 연결을 확인하세요. 기존 모드로 계속 시작합니다.
)
java -Xms$Xmx -Xmx$Xmx -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -jar fabric-server-launch.jar nogui
pause
"@ | Out-File -Encoding ascii start.bat

if (-not (Test-Path server.properties)) {
@"
motd=\u00a76\uc601\uc9c0\uc804 \u00a77- Fabric 1.21.11
max-players=20
view-distance=10
simulation-distance=8
online-mode=true
white-list=true
enforce-whitelist=true
spawn-protection=0
difficulty=normal
"@ | Out-File -Encoding ascii server.properties
}

Write-Host ""
Write-Host "완료. 다음 순서:"
Write-Host "  1) start.bat 실행 → 모드 4개를 받고 서버가 EULA 때문에 바로 꺼짐"
Write-Host "  2) eula.txt 열어 eula=true 로 바꿈 (Mojang EULA 동의)"
Write-Host "  3) start.bat 다시 실행 → 월드 생성. 콘솔에서 whitelist add <닉네임>, op <닉네임>"
Write-Host "  4) 공유기에서 25565 포트 포워딩"
Write-Host "서버 업데이트: minetotalwar-pack 에서 release.ps1 로 올린 뒤 start.bat 재시작이면 끝"
