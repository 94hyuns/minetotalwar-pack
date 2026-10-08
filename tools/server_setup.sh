#!/usr/bin/env bash
# 영지전 Fabric 서버 설치 (우분투). 기존 Paper 서버(~/minecraft, 25565, tmux mc)와 나란히 둔다.
#   bash server_setup.sh [DIR=~/minetotalwar] [PORT=25566] [XMX=8G]
# 하는 일: Fabric 서버 런처 + packwiz-installer-bootstrap 내려받기, start.sh 생성, server.properties 기본값.
# start.sh 는 실행마다 packwiz 로 mods 를 pack.toml 기준으로 맞춘 뒤 서버를 시작한다(서버 업데이트 = release.ps1 → 재시작).
# EULA 는 직접 동의: eula.txt 의 eula=false 를 true 로.
set -euo pipefail
DIR="${1:-$HOME/minetotalwar}"
PORT="${2:-25566}"
XMX="${3:-8G}"
MC="1.21.11"; LOADER="0.19.5"
PACK_URL="https://94hyuns.github.io/minetotalwar-pack/pack.toml"

mkdir -p "$DIR"; cd "$DIR"
INSTALLER=$(curl -fsSL https://meta.fabricmc.net/v2/versions/installer | python3 -c 'import sys,json; print([v for v in json.load(sys.stdin) if v["stable"]][0]["version"])')
echo "Fabric 서버 런처 받는 중 ($MC / loader $LOADER / installer $INSTALLER)"
curl -fsSL -o fabric-server-launch.jar "https://meta.fabricmc.net/v2/versions/loader/$MC/$LOADER/$INSTALLER/server/jar"
echo "packwiz-installer-bootstrap 받는 중"
curl -fsSL -o packwiz-installer-bootstrap.jar "https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"

cat > start.sh <<EOF
#!/usr/bin/env bash
cd "\$(dirname "\$0")"
export TZ=Asia/Seoul
echo "[영지전] 모드 동기화 중..."
if ! java -jar packwiz-installer-bootstrap.jar -g -s server $PACK_URL; then
  echo "[영지전] 모드 동기화 실패. 기존 모드로 계속 시작합니다."
fi
exec java -Xms$XMX -Xmx$XMX -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -jar fabric-server-launch.jar nogui
EOF
chmod +x start.sh

if [ ! -f server.properties ]; then
cat > server.properties <<EOF
server-port=$PORT
query.port=$PORT
motd=§6영지전 §7- Fabric $MC
max-players=20
view-distance=10
simulation-distance=8
online-mode=true
white-list=true
enforce-whitelist=true
spawn-protection=0
difficulty=normal
EOF
fi

echo
echo "완료: $DIR (포트 $PORT, 메모리 $XMX)"
echo "  1) tmux new-session -d -s mtw -c $DIR ./start.sh   → 모드 받고 EULA 때문에 바로 꺼짐"
echo "  2) sed -i 's/eula=false/eula=true/' $DIR/eula.txt   (Mojang EULA 동의)"
echo "  3) 다시 1) → 콘솔: tmux attach -t mtw → whitelist add <닉>, op <닉>"
