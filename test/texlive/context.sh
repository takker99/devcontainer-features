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

# context
check "context" context --version
check "context-luatex" context --luatex --version

reportResults
