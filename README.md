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

## 설치 (처음 한 번만, 이후 업데이트는 자동)

**CurseForge 앱** 기준입니다. 영지전 모드는 게임을 켤 때 스스로 최신 버전으로 바뀌므로, 한 번 깔아 두면 그 뒤는 손댈 게 없습니다.

### 한 번에 가져오기 (준비 중)

최신 [Release](https://github.com/94hyuns/minetotalwar-pack/releases/latest) 의 `minetotalwar-<버전>-curseforge.zip` 을 받아 CurseForge 앱 → **마인크래프트** → **사용자 지정 프로필 만들기** → **가져오기** 에서 고르면 끝. (이 파일이 릴리스에 없으면 아래 수동 설치로)

### 수동 설치

1. CurseForge 앱 → **마인크래프트** → **+ 사용자 지정 프로필 만들기**: 이름 `영지전`, 버전 **1.21.11**, 모드 로더 **Fabric** → 만들기.
2. 프로필에서 **콘텐츠 추가** 로 세 가지를 설치합니다: **Fabric API**, **oωo (owo-lib)**, **GeckoLib**.
3. 최신 [Release](https://github.com/94hyuns/minetotalwar-pack/releases/latest) 에서 `minetotalwar-<버전>.jar` 를 받습니다.
4. 프로필 오른쪽 **⋯** → **폴더 열기** → `mods` 폴더에 3번 jar 를 넣습니다.
5. **플레이**. 처음 켤 때 모드가 최신인지 확인하고, 다르면 받아서 게임을 한 번 다시 띄웁니다("켜지다 꺼지고 10~20초 뒤 다시 켜짐"은 정상).

선택: **JourneyMap** 을 같이 깔면 지도를 쓸 수 있습니다(서버가 지원, 동굴 지도는 꺼져 있음). Sodium·Iris 같은 성능·셰이더 모드는 자유.

### 다른 런처

- **Prism Launcher**: 인스턴스 추가(1.21.11, Fabric) 뒤 `minecraft` 폴더에 [packwiz-installer-bootstrap.jar](https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest) 를 넣고, 편집 → 설정 → 사용자 지정 명령어 → 실행 전 명령어에 `"$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://94hyuns.github.io/minetotalwar-pack/pack.toml`. 켤 때마다 라이브러리까지 자동 갱신.
- **Modrinth 앱**: **+** → **파일에서 가져오기** → 최신 Release 의 `minetotalwar-<버전>.mrpack`. 영지전 모드는 자동 갱신, 라이브러리가 바뀌면 새 mrpack 을 다시 가져오기.

### 문제가 생기면

- 접속할 때 "영지전 모드 버전이 다릅니다"가 뜨면 게임을 껐다 켜세요. 켤 때 자동으로 받습니다.
- 게임이 안 켜지고 "모드가 중복" 같은 말이 나오면 `mods` 폴더에 `minetotalwar-*.jar` 가 둘 이상인지 확인하고 옛 것을 지우세요.
- Fabric API·owo-lib·GeckoLib 가 없다는 말이 나오면 2번의 세 모드를 다시 확인하세요.

---

## 관리자용: 새 버전 배포

영지전 jar 를 빌드한 뒤 저장소 루트에서:

```powershell
.\tools\release.ps1 -Version 1.0.1 -Jar C:\Users\vkghk\MineTotalWar\build\libs\minetotalwar-1.0.1.jar
```

스크립트가 하는 일: jar 해시를 재서 `mods/minetotalwar.pw.toml` 갱신 → `pack.toml` 버전 올림 → `index.toml` 해시 갱신 → `dist/minetotalwar-<버전>.mrpack` 생성 → 커밋·푸시 → GitHub Release `v<버전>` 에 jar 와 mrpack 업로드.
푸시가 끝나면 GitHub Pages 가 1~2분 안에 새 `pack.toml` 을 내보내고, 친구들은 다음 실행 때 자동으로 받습니다.

의존 모드(Fabric API 등)를 올릴 때는 `tools/modrinth_deps.json` 과 `mods/<이름>.pw.toml` 을 함께 바꿉니다. (packwiz 를 설치했다면 `packwiz modrinth update <이름>` 뒤 `python tools/build_pack.py` 로 해시만 다시 맞춰도 됩니다.)

### 서버 세우기

**우분투**(운영 서버, 기존 Paper 와 나란히): `tools/server_setup.sh` 를 서버에 올려 실행합니다. 기본값 `~/minetotalwar`, 포트 **25566**, 8G, tmux 세션 `mtw`.

```bash
bash server_setup.sh ~/minetotalwar 25566 8G
```

**윈도우**: 서버를 둘 빈 폴더에서 `tools/server_setup.ps1` 을 실행합니다(Java 21 필요).

```powershell
powershell -ExecutionPolicy Bypass -File server_setup.ps1 -Dir C:\mtw-server -Xmx 10G
```

Fabric 서버 런처와 packwiz-installer-bootstrap 을 받고 `start.bat` 을 만듭니다. `start.bat` 은 켤 때마다 이 저장소의 `pack.toml` 기준으로 서버 `mods` 를 맞춘 뒤 서버를 시작하므로, **서버 업데이트 = release.ps1 → start.bat 재시작**입니다. 첫 실행 뒤 `eula.txt` 를 직접 `eula=true` 로 바꿔야 합니다. `server.properties` 는 화이트리스트 켜짐으로 생성되니 콘솔에서 `whitelist add <닉네임>` 하세요.

### 처음 한 번: GitHub 설정

1. GitHub 에 **공개** 저장소 `minetotalwar-pack` 을 만들고 이 폴더를 푸시합니다.
2. 저장소 **Settings → Pages → Build and deployment**: Source **Deploy from a branch**, Branch **main** / **(root)** → Save.
3. 첫 Release: `.\tools\release.ps1 -Version 1.0.0 -Jar ...\minetotalwar-1.0.0.jar`
4. 사용자명이 `94hyuns` 가 아니면 `tools/build_pack.py` 의 `GITHUB_USER` 와 이 README 의 주소 두 곳을 바꿉니다.
