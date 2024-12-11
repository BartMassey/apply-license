#!/usr/bin/python
# Copyright © 2011 Bart Massey
# [This software is released under the "MIT License"]
# Please see the file COPYING in the source
# distribution of this software for license terms.

import argparse, datetime, os, re, sys, textwrap
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument("--license-dir", default="/usr/local/lib/apply-license")
ap.add_argument(
    "-m", "--mode",
    choices=["long", "short", "heuristic"],
    default="short",
)
ap.add_argument("-l", "--license-filename", default="LICENSE.txt")
ap.add_argument("-r", "--recursive", action="store_true")
ap.add_argument("-u", "--username")
ap.add_argument("-y", "--year")
ap.add_argument("license_file", nargs="?")
args = ap.parse_args()

def usage(mesg):
    print(f"apply-license: {mesg}")
    ap.print_usage()
    exit(1)

if args.username:
    username = args.username
elif "USERNAME" in os.environ:
    username = os.environ["USERNAME"]
else:
    usage("no username")

if args.year:
    year = args.year
else:
    year = datetime.date.today().year

def read_file(p, can_fail=False):
    try:
        with p.open("r") as f:
             return f.read().splitlines()
    except Exception as e:
        message = f"cannot read file: {e}"
        if can_fail:
            print(message)
            return None
        else:
            usage(message)

def write_file(p, text, can_fail=False):
    try:
        with p.open("w") as f:
             f.write('\n'.join(text) + '\n')
    except Exception as e:
        message = f"cannot write file: {e}"
        if can_fail:
            print(message)
            return
        else:
            usage(message)

def find_existing_license():
    for license_file in ("COPYING", "LICENSE", "LICENSE.txt"):
        p = Path(license_file)
        if p.is_file():
            return p
    return None

def find_license():
    if args.license_file:
        lf = Path(args.license_file)
        if lf.is_file():
            return (lf, False)
        for suffix in ("-license.txt", ".txt", ""):
            lf = Path(args.license_dir) / (args.license_file + suffix)
            if lf.is_file():
                return (lf, True)
    usage(f"cannot find license file")

license_path = find_existing_license()
if license_path:
    known_license = False
    write_licensefile = False
    license_filename = str(license_path.name)
else:
    license_path, known_license = find_license()
    license_filename = args.license_filename
    write_licensefile = True
license = read_file(license_path)

copyright = f"Copyright © {year} {username}"
if known_license:
    license_name = license[0].strip()
    release_statement = \
       f'This work is made available under the "{license_name}".'
else:
    stripped_license = [l for l in license if l.strip()]
    if re.search("[Cc]opyright", stripped_license[0]):
        copyright = stripped_license[0].strip()
        s = stripped_license[1].strip()
        info = re.fullmatch(r'\[([^"]*"([^"]+)"[^"]*)\]', s)
        if info:
            release_statement = info[1]
            if release_statement[-1] != ".":
                release_statement += "."
            license_name = info[2]
        else:
            license_name = "an open source license"
            release_statement = \
                "This work is made available under an open source license."

header_text = [
    copyright,
    "",
    f"[{release_statement}]",
    "",
]

if write_licensefile:
    new_license = header_text + license
    write_file(Path(license_filename), new_license)

def wrap(text):
    return textwrap.fill(' '.join(text), width = 64).splitlines()

see_statement = [
    f'Please see the file {license_filename} in this distribution',
    'for license terms.',
]

def leading_comment(prefix):
    return lambda c: [prefix + " " + l for l in c]

def c_comment(c):
    star_comment = leading_comment(" *")
    return f"/*\n{star_comment(c)} */\n"

def html_comment(c):
    nop_comment = leading_comment("")
    return f"<!-- \n{nop_comment(c)}-->\n*/"

makefile_comment = leading_comment("#")

comment_styles = (
    (("c", "cc", "cpp", "h", "y", "l", "css", "java"), c_comment),
    (("html",), html_comment),
    (("hs", "cabal"), leading_comment("--")),
    (("js", "rust", "ron"), leading_comment("//")),
    (("lisp", "el", "scm"), leading_comment(";")),
    (("m4",), leading_comment("dnl")),
    (("tex", "cls", "sty"), leading_comment("%")),
    (
        ("sh", "bash", "awk", "5c", "rb", "pl", "py", "toml", "php"),
        leading_comment("#"),
    ),
    (("man",), leading_comment(r'.\"')),
)

commenters = {s : f for ss, f in comment_styles for s in ss}

def add_info(p):
    if not p.suffix or p.suffix[1:] not in commenters:
        return
    comment = commenters[p.suffix[1:]]

    text = read_file(p, can_fail=True)
    if not text:
        return

    first_line = 0
    if text[0].startswith("#!"):
        first_line = 1
    elif p.suffix == ".man" and text[0].startswith(".TH"):
        first_line = 1

    head = '\n'.join(text[first_line:first_line + 3])
    if re.search("[Cc]opyright", head):
        return

    comment_text = list(header_text)
    mode = args.mode
    if mode == "heuristic":
        if len(text) < 2 * len(license):
            mode = "short"
        else:
            mode = "long"

    if mode == "short":
        comment_text += wrap(see_statement)
    elif mode == "long":
        comment_text += license

    text[first_line:first_line] = comment(comment_text)
    write_file(p, text)

root = Path("")
if args.recursive:
    def exc(e):
        raise e
    paths = root.walk(on_error = exc)
else:
    paths = root.iterdir()

#try:
    for p in paths:
        if p.is_file():
            add_info(p)
#except Exception as e:
#    usage(f"directory walk error: {e}")
