#!/bin/bash

# Copyright (C) 2024 Canonical Ltd.
#
# This file is part of tdx repo. See LICENSE file for license information.

_on_error() {
  trap '' ERR
  line_path=$(caller)
  line=${line_path% *}
  path=${line_path#* }

  echo ""
  echo "ERR $path:$line $BASH_COMMAND exited with $1"
  exit 1
}
trap '_on_error $?' ERR

set -eE

apt update

# Utilities packages for automated testing
# linux-tools-common for perf, please make sure that linux-tools is also installed
apt install -y cpuid linux-tools-common msr-tools python3 python3-pip

# setup ssh
# disable password auth + prohibit root login for security
sed -i 's|[#]*PasswordAuthentication .*|PasswordAuthentication no|g' /etc/ssh/sshd_config
sed -i 's|[#]*PermitRootLogin .*|PermitRootLogin prohibit-password|g' /etc/ssh/sshd_config
sed -i 's|[#]*KbdInteractiveAuthentication .*|KbdInteractiveAuthentication no|g' /etc/ssh/sshd_config
sed -i 's|[#]*PubkeyAuthentication .*|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
# Ensure cloudimg settings don't override our security settings
rm -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# Enable TDX
/tmp/tdx/setup-tdx-guest.sh

# Install tools
cd /tmp/tdx/tdx-tools/
python3 -m pip install --break-system-packages ./

rm -rf /tmp/tdx || true
