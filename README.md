# 영지전 모드팩

영지전 서버에 접속하기 위한 모드 모음입니다. Minecraft **1.21.11**, **Fabric** 로더 0.19.5.

| 모드 | 용도 |
|---|---|
| 영지전 (minetotalwar) | 서버 본체 모드. 자주 업데이트됩니다 |
| Fabric API | 필수 라이브러리 |
| owo-lib | 내정 화면 GUI 라이브러리 |
| GeckoLib | 보스 몬스터 모델 |

리소스팩은 따로 없습니다. 테마·글꼴·사운드는 모드 안에 들어 있습니다.

---

## 설치 (한 번만 하면 이후 업데이트는 자동)

**Prism Launcher** 를 씁니다. 게임을 켤 때마다 바뀐 모드를 자동으로 받습니다.

1. [Prism Launcher](https://prismlauncher.org/download/) 를 설치하고 Microsoft 계정으로 로그인합니다.
2. 왼쪽 위 **인스턴스 추가** → 이름 `영지전`, 버전 **1.21.11**, 모드 로더 **Fabric** 선택 → 확인.
3. [packwiz-installer-bootstrap.jar](https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest) 를 내려받습니다.
4. 인스턴스를 오른쪽 클릭 → **폴더 열기** → `minecraft` 폴더(없으면 `.minecraft`) 안에 3번 파일을 넣습니다.
5. 인스턴스를 오른쪽 클릭 → **편집** → **설정** → **사용자 지정 명령어** 체크 → **실행 전 명령어**에 아래 한 줄을 붙여 넣습니다.

```
"$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://94hyuns.github.io/minetotalwar-pack/pack.toml
```

6. **실행**. 첫 실행 때 모드를 받고 게임이 켜집니다. 이후에는 켤 때마다 바뀐 것만 받습니다.

### 다른 방법: Modrinth 앱 (업데이트는 수동)

[Modrinth App](https://modrinth.com/app) → **+** → **파일에서 가져오기** → 최신 [Release](https://github.com/94hyuns/minetotalwar-pack/releases/latest) 의 `영지전-<버전>.mrpack`.
모드가 바뀌면 새 mrpack 을 받아 다시 가져와야 합니다. 그래서 Prism 방식을 권장합니다.

### 문제가 생기면

- 서버에 들어갈 때 "영지전 모드 업데이트가 필요합니다"가 뜨면: Prism 은 게임을 껐다 켜면 됩니다. Modrinth 앱은 새 mrpack 을 받습니다.
- 실행 전 명령어가 실패하면 Java 가 없거나 인터넷 문제입니다. Prism 설정 → Java 에서 Java 21 이 잡혀 있는지 확인하세요.

---

## 관리자용: 새 버전 배포

영지전 jar 를 빌드한 뒤 저장소 루트에서:

```powershell
.\tools\release.ps1 -Version 1.0.1 -Jar C:\Users\vkghk\MineTotalWar\build\libs\minetotalwar-1.0.1.jar
```

스크립트가 하는 일: jar 해시를 재서 `mods/minetotalwar.pw.toml` 갱신 → `pack.toml` 버전 올림 → `index.toml` 해시 갱신 → `dist/영지전-<버전>.mrpack` 생성 → 커밋·푸시 → GitHub Release `v<버전>` 에 jar 와 mrpack 업로드.
푸시가 끝나면 GitHub Pages 가 1~2분 안에 새 `pack.toml` 을 내보내고, 친구들은 다음 실행 때 자동으로 받습니다.

의존 모드(Fabric API 등)를 올릴 때는 `tools/modrinth_deps.json` 과 `mods/<이름>.pw.toml` 을 함께 바꿉니다. (packwiz 를 설치했다면 `packwiz modrinth update <이름>` 뒤 `python tools/build_pack.py` 로 해시만 다시 맞춰도 됩니다.)

### 서버 세우기

서버를 둘 빈 폴더에서 `tools/server_setup.ps1` 을 실행합니다(Java 21 필요).

```powershell
powershell -ExecutionPolicy Bypass -File server_setup.ps1 -Dir C:\mtw-server -Xmx 10G
```

Fabric 서버 런처와 packwiz-installer-bootstrap 을 받고 `start.bat` 을 만듭니다. `start.bat` 은 켤 때마다 이 저장소의 `pack.toml` 기준으로 서버 `mods` 를 맞춘 뒤 서버를 시작하므로, **서버 업데이트 = release.ps1 → start.bat 재시작**입니다. 첫 실행 뒤 `eula.txt` 를 직접 `eula=true` 로 바꿔야 합니다. `server.properties` 는 화이트리스트 켜짐으로 생성되니 콘솔에서 `whitelist add <닉네임>` 하세요.

### 처음 한 번: GitHub 설정

1. GitHub 에 **공개** 저장소 `minetotalwar-pack` 을 만들고 이 폴더를 푸시합니다.
2. 저장소 **Settings → Pages → Build and deployment**: Source **Deploy from a branch**, Branch **main** / **(root)** → Save.
3. 첫 Release: `.\tools\release.ps1 -Version 1.0.0 -Jar ...\minetotalwar-1.0.0.jar`
4. 사용자명이 `94hyuns` 가 아니면 `tools/build_pack.py` 의 `GITHUB_USER` 와 이 README 의 주소 두 곳을 바꿉니다.
