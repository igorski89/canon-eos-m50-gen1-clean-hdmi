#!/usr/bin/env python3
"""Minimal PTP-over-USB client for probing a Canon EOS M50.

Deliberately bare: OpenSession does NOT send SetRemoteMode/SetEventMode,
so we can observe whether a plain session disturbs HDMI live view.

Subcommands:
  info                      GetDeviceInfo (no session), list vendor opcodes
  session SECONDS           open a bare session and hold it
  enable                    send 0x9050 EnableEventProc x3, print responses
  evproc NAME [ARGS..] [-r] run named event procedure via 0x9052 (-r: fetch return)
  keepalive INTERVAL [N]    send 0x911D KeepDeviceOn every INTERVAL seconds
  run [KEEPALIVE]           production: wait, remote mode, FA_OSDMuteOn, hold; auto-reconnect
"""
import struct
import sys
import time

import usb.core
import usb.util
import usb.backend.libusb1

CANON_VID = 0x04A9
BACKEND = usb.backend.libusb1.get_backend(
    find_library=lambda _: "/opt/homebrew/lib/libusb-1.0.dylib")

CMD, DATA, RESP = 1, 2, 3
OK = 0x2001


class PTP:
    def __init__(self):
        self.dev = usb.core.find(idVendor=CANON_VID, backend=BACKEND)
        if self.dev is None:
            sys.exit("No Canon device on USB")
        self.dev.set_configuration()
        intf = self.dev.get_active_configuration()[(0, 0)]
        eps = {(usb.util.endpoint_direction(e.bEndpointAddress),
                usb.util.endpoint_type(e.bmAttributes)): e for e in intf}
        self.ep_out = eps[(usb.util.ENDPOINT_OUT, usb.util.ENDPOINT_TYPE_BULK)]
        self.ep_in = eps[(usb.util.ENDPOINT_IN, usb.util.ENDPOINT_TYPE_BULK)]
        self.tid = 0
        self.session = False

    def _send(self, kind, code, payload):
        self.ep_out.write(struct.pack("<IHHI", 12 + len(payload), kind, code,
                                      self.tid) + payload, timeout=5000)

    def _recv(self, timeout=10000):
        buf = bytes(self.ep_in.read(512 * 1024, timeout=timeout))
        length, kind, code, _ = struct.unpack_from("<IHHI", buf)
        while len(buf) < length:
            buf += bytes(self.ep_in.read(512 * 1024, timeout=timeout))
        return kind, code, buf[12:length]

    def transact(self, code, params=(), data_out=None, timeout=10000):
        self.tid += 1
        self._send(CMD, code, b"".join(struct.pack("<I", p) for p in params))
        if data_out is not None:
            self._send(DATA, code, data_out)
        data_in = b""
        while True:
            kind, rcode, payload = self._recv(timeout)
            if kind == DATA:
                data_in += payload
            elif kind == RESP:
                n = len(payload) // 4
                return rcode, struct.unpack(f"<{n}I", payload), data_in

    def open(self):
        rc, _, _ = self.transact(0x1002, (1,))
        if rc not in (OK, 0x201E):  # 0x201E: session already open
            sys.exit(f"OpenSession failed: 0x{rc:04X}")
        self.session = True

    def close(self):
        if self.session:
            self.transact(0x1003)


def parse_device_info(d):
    off = 8  # StandardVersion u16, VendorExtensionID u32, VendorExtensionVersion u16
    n = d[off]; off += 1 + 2 * n  # VendorExtensionDesc string
    off += 2  # FunctionalMode
    count = struct.unpack_from("<I", d, off)[0]; off += 4
    ops = struct.unpack_from(f"<{count}H", d, off)
    off += 2 * count
    return ops


def pack_evproc(name, args):
    """Mirror mlinstall's canon_evproc_pack: name\\0, argc, 20-byte records, footer."""
    body = name.encode() + b"\0"
    records, footer, nstr = b"", b"", 0
    for a in args:
        if isinstance(a, int):
            records += struct.pack("<IIIII", 2, a & 0xFFFFFFFF, 0, 0, 0)
        else:
            s = a.encode() + b"\0"
            records += struct.pack("<IIIII", 4, 0, 0, 0, len(s))
            # mlinstall footer entry: u32 0 + NUL-terminated UTF-8
            footer += struct.pack("<I", 0) + s
            nstr += 1
    return body + struct.pack("<I", len(args)) + records + struct.pack("<I", nstr) + footer


def parse_arg(s):
    try:
        return int(s, 0)
    except ValueError:
        return s


def log(msg):
    print(f"{time.strftime('%H:%M:%S')} {msg}", flush=True)


def release_from_macos():
    """macOS's ptpcamerad grabs the camera on plug-in and shows the PC-connect screen."""
    import subprocess
    subprocess.run(["killall", "-9", "ptpcamerad", "mscamerad-xpc"],
                   stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)


def run_forever(keepalive):
    """Wait for the camera, enter remote mode, hide the HDMI overlay, keep the
    session alive; on any disconnect, start over."""
    while True:
        if usb.core.find(idVendor=CANON_VID, backend=BACKEND) is None:
            time.sleep(2)
            continue
        try:
            release_from_macos()
            time.sleep(0.5)
            p = PTP()
            p.open()
            for code in (0x9114, 0x9115):  # SetRemoteMode 1, SetEventMode 1
                p.transact(code, (1,))
            for _ in range(3):
                p.transact(0x9050)
            rc, _, _ = p.transact(0x9052, (0, 0), data_out=pack_evproc("FA_OSDMuteOn", []))
            log(f"connected; remote mode on; FA_OSDMuteOn rc=0x{rc:04X}")
            last_ka = time.time()
            while True:
                p.transact(0x9116)  # GetEvent
                if keepalive and time.time() - last_ka >= keepalive:
                    p.transact(0x911D)  # KeepDeviceOn
                    last_ka = time.time()
                time.sleep(0.5)
        except (usb.core.USBError, SystemExit) as e:
            log(f"camera lost ({e}); waiting to reconnect")
            usb.util.dispose_resources(p.dev) if "p" in locals() else None
            time.sleep(2)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "run":
        run_forever(float(sys.argv[2]) if len(sys.argv) > 2 else 60)
        return
    if cmd == "send":
        # send FIFO WORDS...: hand one command to a running "serve"; fail if none
        import os
        try:
            fd = os.open(sys.argv[2], os.O_WRONLY | os.O_NONBLOCK)
        except OSError as e:
            sys.exit(f"No server listening on {sys.argv[2]}: {e}")
        os.write(fd, (" ".join(sys.argv[3:]) + "\n").encode())
        os.close(fd)
        return
    p = PTP()

    if cmd == "info":
        rc, _, d = p.transact(0x1001)
        ops = parse_device_info(d)
        print(f"GetDeviceInfo rc=0x{rc:04X}, {len(ops)} ops")
        print(" ".join(f"{o:04X}" for o in sorted(ops)))
        for o, n in [(0x9050, "EnableEventProc"), (0x9052, "ExecuteEventProc"),
                     (0x9053, "GetEventProcReturnData"), (0x9060, "IsNeoKabotanProcMode"),
                     (0x911D, "KeepDeviceOn"), (0x9114, "SetRemoteMode")]:
            print(f"  0x{o:04X} {n:24s} {'YES' if o in ops else 'no'}")
        return

    p.open()
    try:
        if cmd == "session":
            secs = float(sys.argv[2])
            print(f"Bare session open; holding {secs}s")
            time.sleep(secs)
        elif cmd == "remote":
            # remote SECONDS [KEEPALIVE_INTERVAL]: EOS-Utility-style tethered session
            secs = float(sys.argv[2])
            ka = float(sys.argv[3]) if len(sys.argv) > 3 else 0
            for code, prm, name in [(0x9114, (1,), "SetRemoteMode"), (0x9115, (1,), "SetEventMode")]:
                rc, _, _ = p.transact(code, prm)
                print(f"{name}: rc=0x{rc:04X}", flush=True)
            start = last_ka = time.time()
            while time.time() - start < secs:
                p.transact(0x9116)  # GetEvent: drain the event queue
                if ka and time.time() - last_ka >= ka:
                    rc, _, _ = p.transact(0x911D)
                    print(f"{time.strftime('%H:%M:%S')} KeepDeviceOn rc=0x{rc:04X}", flush=True)
                    last_ka = time.time()
                time.sleep(0.5)
        elif cmd == "serve":
            # serve FIFO: remote-mode session; each line written to FIFO is
            # "evproc NAME ARGS..." or "keepalive", run inside this session.
            import os, select
            fifo = sys.argv[2]
            if not os.path.exists(fifo):
                os.mkfifo(fifo)
            fd = os.open(fifo, os.O_RDONLY | os.O_NONBLOCK)
            for code, prm in [(0x9114, (1,)), (0x9115, (1,))]:
                p.transact(code, prm)
            ka = float(sys.argv[3]) if len(sys.argv) > 3 else 0
            print(f"serving (keepalive every {ka or 'never'}s)", flush=True)
            pending = b""
            last_ka = time.time()
            while True:
                p.transact(0x9116)
                if ka and time.time() - last_ka >= ka:
                    rc, _, _ = p.transact(0x911D)
                    print(f"{time.strftime('%H:%M:%S')} KeepDeviceOn rc=0x{rc:04X}", flush=True)
                    last_ka = time.time()
                r, _, _ = select.select([fd], [], [], 0.5)
                if not r:
                    continue
                chunk = os.read(fd, 4096)
                if not chunk:  # writer closed; reopen to wait for the next one
                    os.close(fd)
                    fd = os.open(fifo, os.O_RDONLY | os.O_NONBLOCK)
                    continue
                pending += chunk
                while b"\n" in pending:
                    line, pending = pending.split(b"\n", 1)
                    words = line.decode().split()
                    if not words:
                        continue
                    stamp = time.strftime('%H:%M:%S')
                    if words[0] == "keepalive":
                        rc, _, _ = p.transact(0x911D)
                        print(f"{stamp} KeepDeviceOn rc=0x{rc:04X}", flush=True)
                    elif words[0] == "evproc" and len(words) > 1:
                        for _ in range(3):
                            p.transact(0x9050)
                        args = [parse_arg(a) for a in words[2:]]
                        rc, prm, _ = p.transact(0x9052, (0, 0), data_out=pack_evproc(words[1], args))
                        print(f"{stamp} {words[1]} {args}: rc=0x{rc:04X} {prm}", flush=True)
                    elif words[0] == "quit":
                        return
        elif cmd == "enable":
            for i in range(3):
                rc, prm, _ = p.transact(0x9050)
                print(f"0x9050 #{i}: rc=0x{rc:04X} params={prm}")
        elif cmd == "evproc":
            want_ret = "-r" in sys.argv
            args = [parse_arg(a) for a in sys.argv[3:] if a != "-r"]
            for i in range(3):
                rc, _, _ = p.transact(0x9050)
            print(f"EnableEventProc: rc=0x{rc:04X}")
            data = pack_evproc(sys.argv[2], args)
            rc, prm, _ = p.transact(0x9052, (0, int(want_ret)), data_out=data)
            print(f"ExecuteEventProc {sys.argv[2]} {args}: rc=0x{rc:04X} params={[hex(x) for x in prm]}")
            if want_ret and rc == OK:
                rc, prm, d = p.transact(0x9053, (0, 0, 1))
                print(f"ReturnData rc=0x{rc:04X} params={prm} data={d!r}")
        elif cmd == "keepalive":
            interval = float(sys.argv[2])
            n = int(sys.argv[3]) if len(sys.argv) > 3 else 0
            i = 0
            while n == 0 or i < n:
                rc, _, _ = p.transact(0x911D)
                print(f"{time.strftime('%H:%M:%S')} KeepDeviceOn rc=0x{rc:04X}", flush=True)
                i += 1
                time.sleep(interval)
        else:
            sys.exit(__doc__)
    finally:
        p.close()


if __name__ == "__main__":
    main()
