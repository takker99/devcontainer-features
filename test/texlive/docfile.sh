#!/bin/bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

# minimal
check "tex" tex --version
check "pdftex" pdftex --version
check "luatex" luatex --version
check "bibtex" bibtex --version
check "tlmgr" tlmgr --version
check "python" python --version
check "pygmentize" pygmentize -V

# basic
check "latex" latex --version

# document
check "texdoc" cat /usr/local/texlive/2023/texmf-dist/doc/latex/amsmath/README.md

reportResults
