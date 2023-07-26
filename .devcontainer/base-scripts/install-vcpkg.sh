#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adapted from the microsoft vcpkg installer for use in fedora
# MIT licence link included above
#-------------------------------------------------------------------------------

set -e

USERNAME=${1:-"code"}

. /etc/os-release

# Add to bashrc/zshrc files for all users.
updaterc()  {
    echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/bash.bashrc
    fi
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/zsh/zshrc
    fi
}

# Setup group and add user
umask 0002
if ! cat /etc/group | grep -e "^vcpkg:" > /dev/null 2>&1; then
    groupadd -r "vcpkg"
fi
usermod -a -G "vcpkg" "${USERNAME}"

# Start Installation
# Clone repository with ports and installer
mkdir -p "${VCPKG_ROOT}"
mkdir -p "${VCPKG_DOWNLOADS}"
git clone --depth=1 \
    -c core.eol=lf \
    -c core.autocrlf=false \
    -c fsck.zeroPaddedFilemode=ignore \
    -c fetch.fsck.zeroPaddedFilemode=ignore \
    -c receive.fsck.zeroPaddedFilemode=ignore \
    https://github.com/microsoft/vcpkg "${VCPKG_ROOT}"

## Run installer to get latest stable vcpkg binary
## https://github.com/microsoft/vcpkg/blob/7e7dad5fe20cdc085731343e0e197a7ae655555b/scripts/bootstrap.sh#L126-L144
"${VCPKG_ROOT}"/bootstrap-vcpkg.sh

# Add vcpkg to PATH
updaterc "$(cat << EOF
export VCPKG_ROOT="${VCPKG_ROOT}"
if [[ "\${PATH}" != *"\${VCPKG_ROOT}"* ]]; then export PATH="\${PATH}:\${VCPKG_ROOT}"; fi
EOF
)"

# Give read/write permissions to the user group.
chown -R ":vcpkg" "${VCPKG_ROOT}" "${VCPKG_DOWNLOADS}"
chmod g+r+w+s "${VCPKG_ROOT}" "${VCPKG_DOWNLOADS}"
chmod -R g+r+w "${VCPKG_ROOT}" "${VCPKG_DOWNLOADS}"

# Enable tab completion for bash and zsh
VCPKG_FORCE_SYSTEM_BINARIES=1 su "${USERNAME}" -c "${VCPKG_ROOT}/vcpkg integrate bash"
VCPKG_FORCE_SYSTEM_BINARIES=1 su "${USERNAME}" -c "${VCPKG_ROOT}/vcpkg integrate zsh"
