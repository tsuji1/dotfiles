#!/usr/bin/env python3
import os
import re
import subprocess
from pwn import *

# ============================================================
# Configuration
# ============================================================
BINARY = "./chall"
LIBC = "./libc.so.6"
CONTAINER_NAME = "debug_container"

REMOTE_HOST = "34.170.146.252"
REMOTE_PORT = 40839

# Local Docker settings
LOCAL_PORT = 5000
GDB_PORT = 9090

context.binary = BINARY
context.terminal = ["tmux", "splitw", "-h"]
# context.log_level = "debug"

elf = ELF(BINARY)
if os.path.exists(LIBC):
    libc = ELF(LIBC)

localscript = f"""
b safe
"""

gdbscript = r"""
b safe
continue
"""

def conn(argv=[]):
    """
    Usage:
        python solve.py               # ローカルprocess
        python solve.py LOCAL         # docker composeのサービスに接続 (localhost:LOCAL_PORT)
        python solve.py REMOTE        # リモート接続
        python solve.py GDB           # ローカルprocess + gdb.debug
        python solve.py LOCALGDB      # docker内 gdbserver --attach
        python solve.py HOSTGDB       # ホストから直接 gdb attach (docker top でhost pid取得)
    """
    if args.REMOTE:
        return remote(REMOTE_HOST, REMOTE_PORT)
    elif args.LOCAL:
        return remote("localhost", LOCAL_PORT)
    elif args.GDB:
        return gdb.debug([BINARY] + argv, gdbscript=gdbscript)
    else:
        return process([BINARY] + argv)

# ============================================================
# Helpers
# ============================================================
def sh(cmd: list[str], check=True) -> str:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(
            f"Command failed ({p.returncode}): {' '.join(cmd)}\n"
            f"stdout:\n{p.stdout}\n"
            f"stderr:\n{p.stderr}\n"
        )
    return p.stdout


def get_host_pid_by_container_pid(container: str, pid_in_container: str) -> int:
    init_host_pid = get_container_pid(container)
    # /proc/<init>/root/proc/<pid>/status の 1行目 "Pid:" がホストPID
    status = sh(["cat", f"/proc/{init_host_pid}/root/proc/{pid_in_container}/status"], check=True)
    for line in status.splitlines():
        if line.startswith("Pid:"):
            return int(line.split()[1])
    raise RuntimeError("failed to read host pid from status")

def get_host_pid_of_chall(container: str) -> int:
    pid_in = sh(["docker", "exec", container, "pidof", "chall"], check=True).strip().split()
    if not pid_in:
        raise RuntimeError("chall not found in container (no active connection yet?)")
    return get_host_pid_by_container_pid(container, pid_in[0])


# ============================================================
# GDB Attach
# ============================================================
def attach_gdbserver_in_container(io):
    """
    docker内 gdbserver :GDB_PORT --attach <container-pid> で attach
    （あなたの元の実装を、少し簡潔化したもの）
    """
    if args.REMOTE:
        log.warning("Cannot attach GDB in REMOTE mode")
        return

    # gdbserver kill
    log.info("Killing existing gdbserver in container (if any)...")
    subprocess.run(["docker", "exec", "-u", "root", CONTAINER_NAME, "pkill", "-9", "gdbserver"],
                   capture_output=True, text=True)
    sleep(0.3)

    # container内PID（これは“コンテナPID”）
    pid_out = sh(["docker", "exec", CONTAINER_NAME, "pidof", "chall"], check=True).strip()
    if not pid_out:
        raise RuntimeError("chall not found in container (pidof empty)")
    chall_pid = pid_out.split()[0]
    log.info(f"chall PID in container namespace: {chall_pid}")

    # gdbserver 起動
    log.info(f"Starting gdbserver in container: :{GDB_PORT} --attach {chall_pid}")
    p = subprocess.Popen(
        ["docker", "exec", "-u", "root", CONTAINER_NAME, "gdbserver",
         f":{GDB_PORT}", "--attach", chall_pid],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    # 起動待ち（雑に "Listening on port" を待つ）
    ready = False
    buf = []
    for _ in range(80):
        line = p.stdout.readline() if p.stdout else ""
        if line:
            line = line.strip()
            buf.append(line)
            if "Listening on port" in line:
                ready = True
                break
        sleep(0.05)

    if not ready:
        raise RuntimeError("gdbserver did not become ready.\n" + "\n".join(buf[-30:]))

    full = localscript + "\n" + gdbscript
    log.success("gdbserver ready, attaching gdb...")
    gdb.attach(("localhost", GDB_PORT), exe=BINARY, gdbscript=full)
    pause()

def attach_host_gdb(io):
    """
    ホストから“直接”gdb attachする版（今回追加したい部分）
    - docker top でホストPIDを取る（重要！）
    - そのPIDへ gdb.attach(pid, ...)
    """
    if args.REMOTE:
        log.warning("Cannot attach GDB in REMOTE mode")
        return

    # ここが肝：ホストPIDを docker top で取る
    host_pid = get_host_pid_in_container(CONTAINER_NAME, comm_regex=r"chall")
    log.info(f"Host PID for target in container: {host_pid}")

    full = localscript + "\n" + gdbscript
    log.success("Attaching host gdb directly to container process...")
    # pwntools は pid(int) でも attach できる
    gdb.attach(host_pid, exe=BINARY, gdbscript=full)
    pause()

def GDB(io):
    """
    優先順：
      HOSTGDB  -> ホストから直接 attach（あなたが言ってた超有用テク）
      LOCALGDB -> gdbserver attach（従来）
      (else)   -> ローカルプロセス attach
    """
    if args.HOSTGDB:
        attach_host_gdb(io)
        return

    if args.LOCALGDB or (args.LOCAL and args.GDBSERVER):
        attach_gdbserver_in_container(io)
        return

    if not args.GDB and not args.REMOTE:
        # ローカルプロセスなら普通に attach
        gdb.attach(io, gdbscript=gdbscript)
        pause()

def exploit():
    io = conn()
    GDB(io)
    io.interactive()

if __name__ == "__main__":
    exploit()

