#!/usr/bin/env python3
"""Fail the build if a Papyrus string literal holds a backslash escape.

The open-source compiler used by build-papyrus.sh does not expand escape
sequences, and Skyrim does not either. A literal such as "line one\\nline two"
reaches the game as the characters backslash and n, and the player sees them
in the message box. Line breaks must come from a real line-feed character
(see CHT_HunterScript.Br and its LineBreak property), and quotes inside text
should be written as apostrophes.

Usage: check_string_escapes.py <src dir with .psc> [<dir with .pex> ...]
Checks the .psc sources (string literals only, comments and doc strings are
skipped) and the compiled .pex files (string constants in the string table only).
"""
import re
import struct
import sys
from pathlib import Path


def scan_psc(path: Path):
    problems = []
    in_block = False   # ;/ ... /;
    in_doc = False     # { ... }
    for no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        i, n, in_str = 0, len(line), False
        while i < n:
            c = line[i]
            two = line[i:i + 2]
            if in_block:
                if two == "/;":
                    in_block = False
                    i += 2
                    continue
            elif in_doc:
                if c == "}":
                    in_doc = False
            elif in_str:
                if c == "\\":
                    problems.append((no, i + 1, line.strip()))
                    i += 2
                    continue
                if c == '"':
                    in_str = False
            else:
                if two == ";/":
                    in_block = True
                    i += 2
                    continue
                if c == ";":
                    break
                if c == "{":
                    in_doc = True
                elif c == '"':
                    in_str = True
            i += 1
    return problems


PEX_ESCAPE = re.compile(r'\\[nrt0"\\]')
PEX_MAGIC = 0xFA57C0DE


def pex_strings(data: bytes):
    """The string table of a Skyrim PEX (big-endian): header, 3 header strings, then the table."""
    if len(data) < 16 or struct.unpack_from(">I", data, 0)[0] != PEX_MAGIC:
        raise ValueError("not a Skyrim PEX file")
    off = 16
    for _ in range(3):  # source file name, user name, machine name: metadata, not script text
        (n,) = struct.unpack_from(">H", data, off)
        off += 2 + n
    (count,) = struct.unpack_from(">H", data, off)
    off += 2
    for _ in range(count):
        (n,) = struct.unpack_from(">H", data, off)
        yield data[off + 2 : off + 2 + n].decode("latin-1")
        off += 2 + n


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    bad = 0
    for p in sorted(Path(argv[1]).glob("*.psc")):
        for no, col, text in scan_psc(p):
            bad += 1
            print(f"[papyrus] {p.name}:{no}:{col}: backslash escape in a string literal: {text}", file=sys.stderr)
    for d in argv[2:]:
        for p in sorted(Path(d).glob("*.pex")):
            try:
                found = [t for t in pex_strings(p.read_bytes()) if PEX_ESCAPE.search(t)]
            except (ValueError, struct.error) as e:
                bad += 1
                print(f"[papyrus] {p.name}: cannot read string table ({e})", file=sys.stderr)
                continue
            for t in found:
                bad += 1
                print(f"[papyrus] {p.name}: compiled string constant holds a literal backslash escape: {t!r}", file=sys.stderr)
    if bad:
        print(f"[papyrus] {bad} literal escape problem(s). Papyrus does not expand them; see tools/modkit/papyrus/check_string_escapes.py", file=sys.stderr)
        return 1
    print("[papyrus] no literal backslash escapes in string literals")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
