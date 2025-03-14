# apply-license
Copyright (c) 2007 Bart Massey

This software is designed to add open source licenses to
software.  Please see the manual page for details.

The author is *not a lawyer*.  Please understand that all
materials provided here are not to be relied upon, and are
used at your own risk.  Consult a qualified attorney for
advice on licensing issues.

## Basic Usage

In a source directory with a `README`, run

    apply-license -q mit

This will "quick-license" the code with the MIT
license: a `LICENSE.txt` will be created with an appropriate
copyirght notice, and license information will be added to
the `README`.

See the manual page or command help for detailed
instructions.

## Installation

Copy `apply-license.py` to `/usr/local/bin/apply-license`
and make it executable. Copy the `licenses` directory to
`/usr/local/share/`

## License

This work is provided under the "MIT License". Please see
the file `LICENSE` in this distribution for license details.
