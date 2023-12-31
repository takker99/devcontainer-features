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

# latex
check "latex" latex --version

# bibtexextra
check "biber" biber --version

# context
check "context" context --version
check "context-luatex" context --luatex --version

# xetex
check "xetex" xetex --version

# biextra
check "latexmk" latexmk --version
check "xindy" xindy --version
check "arara" arara --version

reportResults
