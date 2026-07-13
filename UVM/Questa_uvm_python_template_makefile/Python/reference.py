"""
8-bit adder reference model for UVM verification with DPI-C.
Communicates with C/DPI-C via Windows named pipes.

Protocol:
  - Python connects to two named pipes (cmd_pipe, rsp_pipe)
  - Sends "READY" on rsp_pipe once connected
  - Receives commands on cmd_pipe:
      "COMPUTE <a> <b>"  → compute 8-bit adder result
      "EXIT"             → shutdown
  - For COMPUTE: responds with "<sum> <cout>" then "COMPLETE"
"""

import sys
import struct
import os

# Try to import pywin32 for named pipe support
try:
    import win32file
    import win32pipe
    import pywintypes
    HAS_PYWIN32 = True
except ImportError:
    HAS_PYWIN32 = False


def send_line(pipe_handle, line: str) -> None:
    """Send a line of text through the pipe."""
    data = (line + "\n").encode("utf-8")
    if HAS_PYWIN32:
        win32file.WriteFile(pipe_handle, data)
    else:
        os.write(pipe_handle, data)


def recv_line(pipe_handle) -> str:
    """Receive a line of text from the pipe."""
    line = bytearray()
    while True:
        if HAS_PYWIN32:
            hr, ch = win32file.ReadFile(pipe_handle, 1)
            if hr != 0 or len(ch) == 0:
                break
            ch = ch[0]
        else:
            ch = os.read(pipe_handle, 1)
            if not ch:
                break
            ch = ch[0]

        if ch == ord('\n'):
            break
        if ch != ord('\r'):
            line.append(ch)
    return bytes(line).decode("utf-8")


def do_compute(a: int, b: int):
    """
    8-bit adder reference model.
    Returns (sum, cout) where sum = (a + b) & 0xFF, cout = (a + b) >> 8
    """
    result = a + b
    s = result & 0xFF
    cout = (result >> 8) & 0x1
    return s, cout


def main():
    if len(sys.argv) < 3:
        print(f"Usage: python reference.py <cmd_pipe_name> <rsp_pipe_name>",
              file=sys.stderr)
        print(f"  Received {len(sys.argv)} args: {sys.argv}", file=sys.stderr)
        sys.exit(1)

    cmd_pipe_name = sys.argv[1]
    rsp_pipe_name = sys.argv[2]

    print(f"[Python] Connecting to CMD pipe: {cmd_pipe_name}", file=sys.stderr)
    print(f"[Python] Connecting to RSP pipe: {rsp_pipe_name}", file=sys.stderr)

    # Connect to the named pipes that C created
    if HAS_PYWIN32:
        cmd_pipe = win32file.CreateFile(
            cmd_pipe_name,
            win32file.GENERIC_READ | win32file.GENERIC_WRITE,
            0,  # no sharing
            None,  # default security
            win32file.OPEN_EXISTING,
            0,  # default attributes
            None  # no template
        )

        rsp_pipe = win32file.CreateFile(
            rsp_pipe_name,
            win32file.GENERIC_READ | win32file.GENERIC_WRITE,
            0,
            None,
            win32file.OPEN_EXISTING,
            0,
            None
        )
    else:
        # Fallback: use os.open with the pipe name
        import msvcrt
        # Use CreateFileW via ctypes as fallback
        import ctypes
        from ctypes import wintypes

        GENERIC_READ = 0x80000000
        GENERIC_WRITE = 0x40000000
        OPEN_EXISTING = 3
        FILE_ATTRIBUTE_NORMAL = 0x80

        CreateFileW = ctypes.windll.kernel32.CreateFileW
        CreateFileW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                                wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD,
                                wintypes.HANDLE]
        CreateFileW.restype = wintypes.HANDLE

        INVALID_HANDLE_VALUE = wintypes.HANDLE(-1).value

        h = CreateFileW(cmd_pipe_name, GENERIC_READ | GENERIC_WRITE,
                        0, None, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, None)
        if h == INVALID_HANDLE_VALUE:
            print(f"[Python] Failed to open cmd pipe: {cmd_pipe_name}", file=sys.stderr)
            sys.exit(1)
        cmd_pipe = msvcrt.open_osfhandle(h, os.O_RDWR)

        h = CreateFileW(rsp_pipe_name, GENERIC_READ | GENERIC_WRITE,
                        0, None, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, None)
        if h == INVALID_HANDLE_VALUE:
            print(f"[Python] Failed to open rsp pipe: {rsp_pipe_name}", file=sys.stderr)
            sys.exit(1)
        rsp_pipe = msvcrt.open_osfhandle(h, os.O_RDWR)

    print("[Python] Pipe connections established", file=sys.stderr)

    # Send READY signal to C
    send_line(rsp_pipe, "READY")
    print("[Python] READY signal sent", file=sys.stderr)

    # Main command loop
    while True:
        cmd = recv_line(cmd_pipe)
        print(f"[Python] Received command: {cmd}", file=sys.stderr)

        if cmd == "EXIT":
            print("[Python] Received EXIT, shutting down", file=sys.stderr)
            break
        elif cmd.startswith("COMPUTE"):
            parts = cmd.split()
            if len(parts) != 3:
                send_line(rsp_pipe, "ERROR invalid COMPUTE format")
                send_line(rsp_pipe, "COMPLETE")
                continue

            try:
                a = int(parts[1])
                b = int(parts[2])
            except ValueError:
                send_line(rsp_pipe, "ERROR invalid operands")
                send_line(rsp_pipe, "COMPLETE")
                continue

            s, cout = do_compute(a, b)
            print(f"[Python] COMPUTE: {a} + {b} = sum={s}, cout={cout}", file=sys.stderr)

            # Send result: "<sum> <cout>"
            send_line(rsp_pipe, f"{s} {cout}")
            # Send completion flag
            send_line(rsp_pipe, "COMPLETE")
        else:
            print(f"[Python] Unknown command: {cmd}", file=sys.stderr)
            send_line(rsp_pipe, f"ERROR unknown command: {cmd}")
            send_line(rsp_pipe, "COMPLETE")

    # Cleanup
    if HAS_PYWIN32:
        cmd_pipe.Close()
        rsp_pipe.Close()
    else:
        os.close(cmd_pipe)
        os.close(rsp_pipe)

    print("[Python] Exiting", file=sys.stderr)


if __name__ == "__main__":
    main()
