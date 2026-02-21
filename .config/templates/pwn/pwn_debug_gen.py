#!/usr/bin/env python3
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional, Tuple

ROOT = Path.cwd()

DOCKERFILE = ROOT / "Dockerfile"
DOCKERFILE_DEBUG = ROOT / "Dockerfile.debug"
COMPOSE = ROOT / "docker-compose.yml"
COMPOSE_DEBUG = ROOT / "docker-compose.debug.yml"
SOLVE = ROOT / "solve.py"

# ----------------------------
# Utilities
# ----------------------------
def die(msg: str) -> None:
    print(f"[!] {msg}", file=sys.stderr)
    sys.exit(1)

def read_text(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")

def write_text(p: Path, s: str) -> None:
    p.write_text(s, encoding="utf-8")

def run_sh(cmd: str) -> subprocess.CompletedProcess:
    return subprocess.run(["sh", "-lc", cmd], capture_output=True, text=True)

# ----------------------------
# Port picking (auto)
# ----------------------------
def port_in_use(port: int) -> bool:
    p = run_sh(f"ss -ltn sport = :{port} 2>/dev/null | tail -n +2 | wc -l")
    if p.returncode != 0:
        # ss が無い/使えない場合は不明→未使用扱い
        return False
    try:
        return int((p.stdout or "0").strip()) > 0
    except ValueError:
        return False

def find_free_port(start: int, end: int) -> int:
    for port in range(start, end + 1):
        if not port_in_use(port):
            return port
    raise RuntimeError(f"no free port in range {start}-{end}")

def pick_ports() -> Tuple[int, int]:
    local_port = find_free_port(5000, 5999)
    gdb_port = find_free_port(9090, 9999)
    if gdb_port == local_port:
        gdb_port = find_free_port(gdb_port + 1, 9999)
    return local_port, gdb_port

# ----------------------------
# Detection helpers
# ----------------------------
def looks_like_jail(dockerfile_text: str) -> bool:
    t = dockerfile_text.lower()
    return ("from pwn.red/jail" in t) or ("from redpwn/jail" in t) or ("pwn.red/jail" in t)

def looks_like_xinetd(dockerfile_text: str) -> bool:
    t = dockerfile_text.lower()
    return ("xinetd" in t) or ("/etc/xinetd.d" in t)

def extract_first_ubuntu_digest(dockerfile_text: str) -> Optional[str]:
    # FROM ubuntu@sha256:...
    m = re.search(r"^\s*from\s+ubuntu@sha256:([0-9a-f]{64})", dockerfile_text, flags=re.I | re.M)
    if m:
        return m.group(1)
    return None

def last_user_in_dockerfile(dockerfile_text: str) -> Optional[str]:
    # USER user / USER 1000:1000 などを拾う
    users = re.findall(r"^\s*user\s+([^\s#]+)", dockerfile_text, flags=re.I | re.M)
    return users[-1] if users else None

def next_backup_name(base: Path) -> Path:
    if not base.exists():
        return base
    for i in range(1, 1000):
        cand = base.with_name(base.name + f"_{i}")
        if not cand.exists():
            return cand
    raise RuntimeError("too many backups for Dockerfile_bak")

# ----------------------------
# File discovery (host side)
# ----------------------------
def find_first_existing(paths: list[str]) -> Optional[str]:
    for p in paths:
        if Path(p).exists():
            return p
    return None

def discover_chall_path() -> Optional[str]:
    return find_first_existing([
        "chall",
        "./chall",
        "build/chall",
        "./build/chall",
        "bin/chall",
        "./bin/chall",
    ])

def discover_libc_path() -> Optional[str]:
    return find_first_existing([
        "libc.so.6",
        "./libc.so.6",
        "build/libc.so.6",
        "./build/libc.so.6",
        "lib/libc.so.6",
        "./lib/libc.so.6",
    ])

def flag_globs_present() -> bool:
    # flag* が何かしら存在するか（flag.txt / flag-xxxx.txt / build/flag-xxx 等）
    if list(ROOT.glob("flag*")):
        return True
    b = ROOT / "build"
    if b.exists() and list(b.glob("flag*")):
        return True
    return False

# ----------------------------
# Dockerfile generation
# ----------------------------
def make_scratch_dockerfile(base_image: str) -> str:
    # jail/xinetd の時は “作り直し”
    chall = discover_chall_path() or "chall"
    libc = discover_libc_path()
    has_flag = flag_globs_present()

    # COPY 元パスは build context 相対で書きたいので、先頭の "./" は外す
    chall = chall.lstrip("./")
    libc_line = ""
    if libc:
        libc = libc.lstrip("./")
        libc_line = f'COPY --chown=root:user {libc} /home/user/libc.so.6\n'

    # flag は決め打ちせず glob で拾う（存在しなくてもビルドが壊れないように “ある場合だけ”にする）
    # Dockerfile は条件分岐できないので、存在しないのに COPY すると失敗する点が厄介。
    # → ここは「存在チェックした結果」に応じて COPY 行を出す。
    flag_lines = ""
    if has_flag:
        # build/flag* も拾う
        flag_lines = (
            "COPY --chown=root:user flag* /home/user/\n"
            "COPY --chown=root:user build/flag* /home/user/\n"
            # 正規化：最初の flag* を flag.txt に寄せる（失敗してもOK）
            "RUN sh -lc 'set -e; cd /home/user; f=$(ls -1 flag* 2>/dev/null | head -n1 || true); "
            "if [ -n \"$f\" ] && [ \"$f\" != \"flag.txt\" ]; then mv \"$f\" flag.txt; fi; true'\n"
        )

    return f"""\
FROM {base_image}

RUN apt-get update && \\
    apt-get -y upgrade && \\
    apt-get install -y --no-install-recommends \\
        gdb \\
        gdbserver \\
        socat \\
        ca-certificates && \\
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r user && useradd -r -g user user

# Put files under /home/user (simple + predictable)
{flag_lines.rstrip()}

COPY --chown=root:user {chall} /home/user/chall
{libc_line.rstrip()}

WORKDIR /home/user

RUN groupadd -g 1000 user && useradd -m -u 1000 -g 1000 user
USER user

RUN chmod 555 ./chall || true && \\
    chmod 555 ./libc.so.6 2>/dev/null || true && \\
    chmod 444 ./flag.txt 2>/dev/null || true

EXPOSE 5000
EXPOSE 9090

CMD socat TCP-LISTEN:5000,reuseaddr,fork EXEC:"./chall"
"""

def make_debug_append(orig_user: Optional[str]) -> str:
    # USER 問題を自動回避：rootでapt、最後に元に戻す
    # orig_user が無いなら戻さない（rootのままでもデバッグ用途ならOK）
    back = f"\nUSER {orig_user}\n" if orig_user else "\n"
    return f"""\
# --- debug additions ---
USER root
RUN apt-get update && \\
    apt-get -y upgrade && \\
    apt-get install -y --no-install-recommends \\
        gdb \\
        gdbserver \\
        socat \\
        ca-certificates && \\
    rm -rf /var/lib/apt/lists/*
EXPOSE 5000
EXPOSE 9090
{back}"""

def ensure_dockerfiles() -> None:
    """
    - jail/xinetd を検出したら Dockerfile を退避して “新しい Dockerfile” を作る
    - Dockerfile.debug は必ず生成
    """
    if DOCKERFILE.exists():
        src = read_text(DOCKERFILE)
        is_jail = looks_like_jail(src)
        is_xinetd = looks_like_xinetd(src)

        if is_jail or is_xinetd:
            bak = next_backup_name(ROOT / "Dockerfile_bak")
            DOCKERFILE.rename(bak)
            print(f"[+] renamed Dockerfile -> {bak.name} (detected {'jail' if is_jail else 'xinetd'})")

            digest = extract_first_ubuntu_digest(src)
            base = f"ubuntu@sha256:{digest}" if digest else "ubuntu:22.04"

            # 通常用 Dockerfile も “作り直し”で生成（debug生成に依存しない）
            new_df = make_scratch_dockerfile(base)
            write_text(DOCKERFILE, new_df)
            print("[+] wrote Dockerfile (rebuilt for local debug)")

            # debug は通常Dockerfileをベースに append して作る（USER問題もここで吸収）
            orig_user = last_user_in_dockerfile(new_df)
            dbg = new_df.rstrip() + "\n" + make_debug_append(orig_user).lstrip()
            write_text(DOCKERFILE_DEBUG, dbg)
            print("[+] wrote Dockerfile.debug (rebuilt + debug additions)")
            return

        # jail/xinetd でない：Dockerfile.debug を append 生成（USER対策付き）
        orig_user = last_user_in_dockerfile(src)
        if "--- debug additions ---" in src:
            out = src
        else:
            out = src.rstrip() + "\n" + make_debug_append(orig_user).lstrip()
        write_text(DOCKERFILE_DEBUG, out)
        print("[+] wrote Dockerfile.debug (based on Dockerfile + safe append)")
        return

    # Dockerfile が無い：scratch を作る（ubuntu:22.04）
    base = "ubuntu:22.04"
    new_df = make_scratch_dockerfile(base)
    write_text(DOCKERFILE, new_df)
    print("[+] wrote Dockerfile (new, scratch)")
    orig_user = last_user_in_dockerfile(new_df)
    dbg = new_df.rstrip() + "\n" + make_debug_append(orig_user).lstrip()
    write_text(DOCKERFILE_DEBUG, dbg)
    print("[+] wrote Dockerfile.debug (new, scratch + debug additions)")

# ----------------------------
# Compose generation
# ----------------------------
def ensure_compose() -> None:
    if COMPOSE.exists():
        print("[*] docker-compose.yml exists (leave as-is)")
        return

    # Dockerfile が新規/再生成される前提で最小 compose
    DEFAULT_COMPOSE = """\
services:
  challenge:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "5000:5000"
    stdin_open: true
    tty: true
"""
    write_text(COMPOSE, DEFAULT_COMPOSE)
    print("[+] wrote docker-compose.yml (new file)")

def make_compose_debug(local_port: int, gdb_port: int) -> str:
    return f"""services:
  challenge:
    user: "1000:1000"
    userns_mode: "host"
    build:
      context: .
      dockerfile: Dockerfile.debug
    ports:
      - "{local_port}:5000"
      - "{gdb_port}:9090"
    stdin_open: true
    tty: true
    cap_add:
      - SYS_PTRACE
    security_opt:
      - seccomp:unconfined
    labels:
      - "pwn.debug=true"
      - "pwn.service=challenge"
"""

# ----------------------------
# solve.py patch
# ----------------------------
def patch_solve_py(local_port: int, gdb_port: int) -> None:
    if not SOLVE.exists():
        print("[*] solve.py not found (skip patch)")
        return
    s = read_text(SOLVE)
    s2 = re.sub(r"^LOCAL_PORT\s*=\s*\d+\s*$", f"LOCAL_PORT = {local_port}", s, flags=re.M)
    s2 = re.sub(r"^GDB_PORT\s*=\s*\d+\s*$", f"GDB_PORT = {gdb_port}", s2, flags=re.M)
    if s2 != s:
        write_text(SOLVE, s2)
        print("[+] patched solve.py ports")
    else:
        print("[*] solve.py ports not patched (pattern not found)")

# ----------------------------
# Main
# ----------------------------
def main() -> None:
    print("== pwn debug generator (latest: jail/xinetd + USER-safe + flag glob + auto ports) ==")

    local_port, gdb_port = pick_ports()
    print(f"[*] selected host ports: socat={local_port}, gdbserver={gdb_port}")

    ensure_dockerfiles()
    ensure_compose()

    write_text(COMPOSE_DEBUG, make_compose_debug(local_port, gdb_port))
    print("[+] wrote docker-compose.debug.yml")

    patch_solve_py(local_port, gdb_port)

    print("\nNext:")
    print("  docker compose -f docker-compose.debug.yml up -d --build")
    print("  docker compose -f docker-compose.debug.yml down")

if __name__ == "__main__":
    main()

