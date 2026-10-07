#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""영지전 모드팩 빌드 스크립트 (packwiz 형식 + Modrinth .mrpack).

사용:
  python tools/build_pack.py                      # pack.toml/index.toml 해시 갱신 + dist/*.mrpack 생성
  python tools/build_pack.py --jar <경로> --version 1.0.1
      → 영지전 jar 의 해시를 재서 mods/minetotalwar.pw.toml 을 갱신하고(다운로드 주소는 GitHub Release),
        pack.toml 의 version 을 바꾼 뒤 위 작업을 수행. jar 는 dist/ 에도 복사(릴리스에 올릴 것).

GitHub 사용자명·저장소 이름은 아래 상수. Pages 주소 = https://<USER>.github.io/<REPO>/pack.toml
"""
import argparse, hashlib, json, os, re, shutil, sys, zipfile

GITHUB_USER = "94hyuns"
REPO = "minetotalwar-pack"
PACK_NAME = "영지전"
MINECRAFT = "1.21.11"
FABRIC_LOADER = "0.19.5"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODS = os.path.join(ROOT, "mods")
DIST = os.path.join(ROOT, "dist")


def sha(path, algo):
    h = hashlib.new(algo)
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def read(path):
    return open(path, encoding="utf-8").read()


def write(path, text):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def toml_get(text, key, table=None):
    """아주 단순한 TOML 읽기: [table] 안의 key = "value" 한 줄."""
    section = text
    if table:
        m = re.search(r"^\[" + re.escape(table) + r"\]\n(.*?)(?=^\[|\Z)", text, re.S | re.M)
        section = m.group(1) if m else ""
    m = re.search(r'^' + re.escape(key) + r'\s*=\s*"([^"]*)"', section, re.M)
    return m.group(1) if m else None


def toml_set(text, key, value, table=None):
    if table:
        m = re.search(r"^\[" + re.escape(table) + r"\]\n", text, re.M)
        start = m.end()
        end_m = re.search(r"^\[", text[start:], re.M)
        end = start + end_m.start() if end_m else len(text)
        body = text[start:end]
        body2, n = re.subn(r'^' + re.escape(key) + r'\s*=\s*"[^"]*"', f'{key} = "{value}"', body, flags=re.M)
        if n == 0:
            body2 = body.rstrip("\n") + f'\n{key} = "{value}"\n'
        return text[:start] + body2 + text[end:]
    text2, n = re.subn(r'^' + re.escape(key) + r'\s*=\s*"[^"]*"', f'{key} = "{value}"', text, flags=re.M)
    return text2 if n else text.rstrip("\n") + f'\n{key} = "{value}"\n'


def update_mod_jar(jar, version):
    if not os.path.isfile(jar):
        sys.exit(f"jar 없음: {jar}")
    filename = os.path.basename(jar)
    url = f"https://github.com/{GITHUB_USER}/{REPO}/releases/download/v{version}/{filename}"
    path = os.path.join(MODS, "minetotalwar.pw.toml")
    text = read(path)
    text = toml_set(text, "filename", filename)
    text = toml_set(text, "url", url, "download")
    text = toml_set(text, "hash", sha(jar, "sha512"), "download")
    write(path, text)
    pack = os.path.join(ROOT, "pack.toml")
    write(pack, toml_set(read(pack), "version", version))
    os.makedirs(DIST, exist_ok=True)
    shutil.copy2(jar, os.path.join(DIST, filename))
    print(f"minetotalwar.pw.toml → {filename} ({url})")


def refresh_index():
    files = []
    for dirpath, _, names in os.walk(ROOT):
        rel_dir = os.path.relpath(dirpath, ROOT)
        if rel_dir.split(os.sep)[0] in (".git", "tools", "dist", ".github") or rel_dir.startswith("."):
            if rel_dir != ".":
                continue
        for n in sorted(names):
            rel = os.path.normpath(os.path.join(rel_dir, n)).replace(os.sep, "/")
            if rel in ("pack.toml", "index.toml", "README.md", ".gitignore", "LICENSE") or rel.startswith(("tools/", "dist/", ".git")):
                continue
            files.append(rel)
    lines = ['hash-format = "sha256"', ""]
    for rel in sorted(files):
        lines += ["[[files]]", f'file = "{rel}"', f'hash = "{sha(os.path.join(ROOT, rel), "sha256")}"']
        if rel.endswith(".pw.toml"):
            lines.append("metafile = true")
        lines.append("")
    index_path = os.path.join(ROOT, "index.toml")
    write(index_path, "\n".join(lines))
    pack = os.path.join(ROOT, "pack.toml")
    write(pack, toml_set(read(pack), "hash", sha(index_path, "sha256"), "index"))
    print(f"index.toml: {len(files)}개 파일, pack.toml 해시 갱신")


def build_mrpack():
    """mods/*.pw.toml 을 읽어 Modrinth 모드팩(.mrpack)을 만든다. 영지전 jar 는 GitHub Release 주소를 그대로 쓴다."""
    pack = read(os.path.join(ROOT, "pack.toml"))
    version = toml_get(pack, "version")
    deps = json.load(open(os.path.join(ROOT, "tools", "modrinth_deps.json"), encoding="utf-8"))
    files = []
    for n in sorted(os.listdir(MODS)):
        if not n.endswith(".pw.toml"):
            continue
        t = read(os.path.join(MODS, n))
        filename = toml_get(t, "filename")
        url = toml_get(t, "url", "download")
        entry = {"path": f"mods/{filename}", "hashes": {}, "env": {"client": "required", "server": "required"}, "downloads": [url]}
        slug = n[:-len(".pw.toml")]
        if slug in deps:
            d = deps[slug]
            entry["hashes"] = {"sha1": d["sha1"], "sha512": d["sha512"]}
            entry["fileSize"] = d["size"]
        else:
            local = os.path.join(DIST, filename)
            if not os.path.isfile(local):
                sys.exit(f"mrpack 에 넣을 영지전 jar 가 dist/ 에 없음: 먼저 --jar 로 갱신하세요 ({local})")
            entry["hashes"] = {"sha1": sha(local, "sha1"), "sha512": sha(local, "sha512")}
            entry["fileSize"] = os.path.getsize(local)
        files.append(entry)
    index = {
        "formatVersion": 1, "game": "minecraft", "versionId": version, "name": PACK_NAME,
        "summary": "영지전 서버 접속용 모드팩 (Fabric)",
        "files": files,
        "dependencies": {"minecraft": MINECRAFT, "fabric-loader": FABRIC_LOADER},
    }
    os.makedirs(DIST, exist_ok=True)
    out = os.path.join(DIST, f"{PACK_NAME}-{version}.mrpack")
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("modrinth.index.json", json.dumps(index, ensure_ascii=False, indent=2))
        overrides = os.path.join(ROOT, "overrides")
        if os.path.isdir(overrides):
            for dirpath, _, names in os.walk(overrides):
                for nm in names:
                    full = os.path.join(dirpath, nm)
                    z.write(full, "overrides/" + os.path.relpath(full, overrides).replace(os.sep, "/"))
    print(f"mrpack: {out} ({len(files)}개 모드)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jar", help="새 영지전 jar 경로")
    ap.add_argument("--version", help="팩 버전(= GitHub Release 태그 v<version>)")
    a = ap.parse_args()
    if a.jar or a.version:
        if not (a.jar and a.version):
            sys.exit("--jar 와 --version 은 함께 지정")
        update_mod_jar(a.jar, a.version)
    refresh_index()
    build_mrpack()


if __name__ == "__main__":
    main()
