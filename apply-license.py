#!/usr/bin/python
# Copyright © 2011 Bart Massey
# [This software is released under the "MIT License"]
# See the file COPYING in the source
# distribution of this software for license terms.

import argparse, datetime, os, re, sys, textwrap
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument("--license-dir", default="/usr/local/lib/apply-license")
ap.add_argument(
    "-m", "--mode",
    choices=["none", "long", "short", "heuristic"],
    default="short",
)
ap.add_argument("-l", "--license-filename", default="LICENSE.txt")
ap.add_argument("-r", "--recursive", action="store_true")
ap.add_argument("-u", "--username")
ap.add_argument("-y", "--year")
ap.add_argument("-q", "--quick", action="store_true")
ap.add_argument("-w", "--width", type=int, default=64)
ap.add_argument("--readme", action="store_true")
ap.add_argument("license_id", nargs="?")
args = ap.parse_args()

if args.quick:
    args.mode = "none"
    args.readme = True

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
    if args.license_filename:
        targets = (args.license_filename,)
    else:
        targets = ("COPYING", "LICENSE", "LICENSE.txt")
    for license_file in targets:
        p = Path(license_file)
        if p.is_file():
            return p
    return None

def find_license():
    if not args.license_id:
        usage("no license specified")
        
    for suffix in ("-license.txt", ".txt", ""):
        lf = Path(args.license_dir) / (args.license_id + suffix)
        if lf.is_file():
            return lf

    usage(f"{args.license_id}: cannot find license file")

license_path = find_existing_license()
if license_path:
    if args.license_id:
        usage("license id specified but license file exists")
    known_license = False
    write_licensefile = False
    license_filename = str(license_path.name)
else:
    license_path = find_license()
    known_license = True
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
    return textwrap.fill(' '.join(text), width = args.width).splitlines()

see_statement = [
    f'See the file {license_filename} in this distribution',
    'for license terms.',
]

see_statement_md = [
    f'See the file `{license_filename}` in this distribution',
    'for license terms.',
]

see_below_statement = [
    'See the end of this file for license terms.',
]

def update_readme(readme_path, md):
    if readme_path.exists():
        r = read_file(readme_path)
    else:
        r = []
    license_doc = [release_statement]
    if md:
        license_doc += see_statement_md
        r += ["", "## License"]
    else:
        license_doc += see_statement
    r += [""]
    r += wrap(license_doc)
    write_file(readme_path, r)

def find_and_update_readme():
    readmes = (
        ("README.tpl", True),
        ("README.md", True),
        ("README.txt", False),
        ("README", False),
    )
    for readme, md in readmes:
        readme_path = Path(readme)
        if readme_path.exists():
            update_readme(readme_path, md)
            return
    update_readme(Path("README.md"), True)

if args.readme:
    find_and_update_readme()

if args.mode == "none":
    exit(0)

def leading_comment(prefix):
    return lambda c: [prefix + (" " if l else "") + l for l in c]

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
        text[first_line:first_line] = comment(comment_text)
    elif mode == "long":
        comment_text += wrap(see_below_statement)
        text[first_line:first_line] = comment(comment_text)
        text += ['']
        text += comment(license)

    write_file(p, text)

root = Path("")
if args.recursive:
    def exc(e):
        raise e
    paths = root.walk(on_error = exc)
else:
    paths = root.iterdir()

try:
    for p in paths:
        if p.is_file():
            add_info(p)
except Exception as e:
    usage(f"directory walk error: {e}")
