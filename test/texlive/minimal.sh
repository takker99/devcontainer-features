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

reportResults
