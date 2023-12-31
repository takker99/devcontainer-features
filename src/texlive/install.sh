#!/bin/bash
# Copyright (c) 2021 Island of TeX / images. All Rights Reserved. MIT License.
# This code is largely based on the [Dockerfile](https://gitlab.com/islandoftex/images/texlive/-/blob/master/Dockerfile)
# and [Dockerfile.base](https://gitlab.com/islandoftex/images/texlive/-/blob/master/Dockerfile.base) from the
# [islandoftex/texlive](https://gitlab.com/islandoftex/images/texlive) Docker image repository.

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

# ConTeXt cache can be created on runtime and does not need to
# increase image size
export TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1
# As we will not install regular documentation why would we want to
# install perl docs…
export NOPERLDOC=1


# install packages for TeX Live installation
apt-get update
# basic utilities for TeX Live installation
INSTALL_LIST=("curl" "git" "unzip")
# miscellaneous dependencies for TeX Live tools
INSTALL_LIST+=("make" "fontconfig" "perl" "default-jre" "libgetopt-long-descriptive-perl" "libdigest-perl-md5-perl" "libncurses6")
# for latexindent (see https://gitlab.com/islandoftex/images/texlive/-/issues/13)
INSTALL_LIST+=("libunicode-linebreak-perl" "libfile-homedir-perl" "libyaml-tiny-perl")
# for eps conversion (see https://gitlab.com/islandoftex/images/texlive/-/issues/14)
INSTALL_LIST+=("ghostscript")
# for metafont (see https://gitlab.com/islandoftex/images/texlive/-/issues/24)
INSTALL_LIST+=("libsm6")
# for gnuplot backend of pgfplots (see https://gitlab.com/islandoftex/images/texlive/-/merge_requests/13)
INSTALL_LIST+=("gnuplot-nox")
# Mark all texlive packages as installed. This enables installing
# latex-related packges in child images.
# Inspired by https://tex.stackexchange.com/a/95373/9075.
INSTALL_LIST+=("equivs")
# at this point also install gpg and gpg-agent to allow tlmgr's
# key subcommand to work correctly (see https://gitlab.com/islandoftex/images/texlive/-/merge_requests/13)
INSTALL_LIST+=("gpg" "gpg-agent")
INSTALL_LIST+=("rsync")
DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends "${INSTALL_LIST[@]}"
# bad fix for python handling
ln -s /usr/bin/python3 /usr/bin/python

# the mirror from which we will download TeX Live
TLMIRRORURL="rsync://mirrors.ctan.org/CTAN/systems/texlive/tlnet/"
# whether to create font and ConTeXt caches
GENERATE_CACHES="yes"

cd /tmp

echo "Download and install equivs file for dummy package"
curl https://tug.org/texlive/files/debian-equivs-2023-ex.txt --output texlive-local
sed -i "s/2023/9999/" texlive-local
# freeglut3 does not ship with debian testing, so we remove it because there
# is no GUI need in the container anyway (see https://gitlab.com/islandoftex/images/texlive/-/merge_requests/28)
sed -i "/Depends: freeglut3/d" texlive-local
# we need to change into tl-equivs to get it working
equivs-build texlive-local
dpkg -i texlive-local_9999.99999999-1_all.deb
apt-get install -qyf --no-install-recommends
# reverse the cd command from above and cleanup
rm -rf ./*texlive*
# Clean up
apt-get remove -y --purge equivs
apt-get autoremove -qy --purge
rm -rf /var/lib/apt/lists/*
apt-get clean

echo "Fetching installation from mirror $TLMIRRORURL"
rsync -a --stats "$TLMIRRORURL" texlive
cd texlive

# create installation profile with the selected options
echo "Building with documentation: ${DOCFILES}"
echo "Building with sources: ${SRCFILES}"
echo "Selecting ${SCHEME} scheme"
echo "Installing collecitons: ${COLLECTIONS}"

echo "selected_scheme scheme-${SCHEME}" > install.profile
# … but disable documentation and source files when asked to stay slim
if [ "${DOCFILES}" = "false" ]; then
  echo "tlpdbopt_install_docfiles 0" >> install.profile
  echo "BUILD: Disabling documentation files"
fi
if [ "${SRCFILES}" = "false" ]; then
  echo "tlpdbopt_install_srcfiles 0" >> install.profile
  echo "BUILD: Disabling source files"
fi
if [ -n "${COLLECTIONS}" ]; then
  for collection in ${COLLECTIONS}; do
    echo "collection-$collection 1"  >> install.profile
  done
fi

echo "tlpdbopt_autobackup 0" >> install.profile
# furthermore we want our symlinks in the system binary folder to avoid
# fiddling around with the PATH
echo "tlpdbopt_sys_bin /usr/bin" >> install.profile

# actually install TeX Live
./install-tl -profile install.profile
cd ..
rm -rf texlive

echo "Set PATH to $PATH"
$(find /usr/local/texlive -name tlmgr) path add

if [ -f "/usr/bin/context" ]; then
  # Temporary fix for ConTeXt (https://gitlab.com/islandoftex/images/texlive/-/merge_requests/30)
  sed -i '/package.loaded\["data-ini"\]/a if os.selfpath then environment.ownbin=lfs.symlinktarget(os.selfpath..io.fileseparator..os.selfname);environment.ownpath=environment.ownbin:match("^.*"..io.fileseparator) else environment.ownpath=kpse.new("luatex"):var_value("SELFAUTOLOC");environment.ownbin=environment.ownpath..io.fileseparator..(arg[-2] or arg[-1] or arg[0] or "luatex"):match("[^"..io.fileseparator.."]*$") end' /usr/bin/mtxrun.lua
fi

# pregenerate caches as per #3; overhead is < 5 MB which does not really
# matter for images in the sizes of GBs; some TL schemes might not have
# all the tools, therefore failure is allowed
if [ "$GENERATE_CACHES" = "yes" ]; then
  echo "Generating caches and ConTeXt files"
  (luaotfload-tool -u || true)
  if [ -f "/usr/bin/xetex" ]; then
    # also generate fontconfig cache as per #18 which is approx. 20 MB but
    # benefits XeLaTeX user to load fonts from the TL tree by font name
    cp "$(find /usr/local/texlive -name texlive-fontconfig.conf)" /etc/fonts/conf.d/09-texlive-fonts.conf
    fc-cache -fsv
  fi
  if [ -f "/usr/bin/context" ]; then
    mtxrun --generate
    texlua /usr/bin/mtxrun.lua --luatex --generate
    context --make
    context --luatex --make
  fi
else
  echo "Not generating caches or ConTeXt files"
fi

if ! (type -P pygmentize > /dev/null 2>&1); then
  # for syntax highlighting
  apt-get update
  apt-get install -qy python3 python3-pygments
fi