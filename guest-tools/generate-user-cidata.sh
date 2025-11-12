#!/bin/bash

# This file is part of Canonical's TDX repository which includes tools
# to setup and configure a confidential computing environment
# based on Intel TDX technology.
# See the LICENSE file in the repository for the license text.

# Copyright 2025 Canonical Ltd.
# SPDX-License-Identifier: GPL-3.0-only

# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3,
# as published by the Free Software Foundation.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranties
# of MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

# Generates a cloud-init ISO for runtime user configuration injection

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

usage() {
    cat <<EOM
Usage: $(basename "$0") [OPTIONS]

Generate a cloud-init ISO for user configuration at TD launch time.

Required options:
  -o, --output PATH         Output ISO file path
  -u, --user USERNAME       Guest username

Authentication options (at least one required):
  -k, --ssh-key PATH        Path to SSH public key file
  -p, --password PASSWORD   Guest password

Optional:
  -n, --hostname HOSTNAME   Guest hostname (default: tdx-guest)
  -h, --help                Show this help

Example:
  $(basename "$0") -o /tmp/userdata.iso -u alice -k ~/.ssh/id_rsa.pub -n alice-td

EOM
}

error() {
    echo "ERROR: $*" >&2
    exit 1
}

# Parse arguments
OUTPUT_ISO=""
GUEST_USER=""
SSH_PUBLIC_KEY=""
GUEST_PASSWORD=""
GUEST_HOSTNAME="tdx-guest"

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_ISO="$2"
            shift 2
            ;;
        -u|--user)
            GUEST_USER="$2"
            shift 2
            ;;
        -k|--ssh-key)
            SSH_KEY_FILE="$2"
            if [[ ! -f "${SSH_KEY_FILE}" ]]; then
                error "SSH public key file not found: ${SSH_KEY_FILE}"
            fi
            SSH_PUBLIC_KEY=$(cat "${SSH_KEY_FILE}")
            if [[ -z "${SSH_PUBLIC_KEY}" ]]; then
                error "SSH public key file is empty: ${SSH_KEY_FILE}"
            fi
            shift 2
            ;;
        -p|--password)
            GUEST_PASSWORD="$2"
            shift 2
            ;;
        -n|--hostname)
            GUEST_HOSTNAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate required arguments
[[ -z "${OUTPUT_ISO}" ]] && error "Output ISO path is required (-o)"
[[ -z "${GUEST_USER}" ]] && error "Guest username is required (-u)"

# Validate authentication method
if [[ -z "${GUEST_PASSWORD}" ]] && [[ -z "${SSH_PUBLIC_KEY}" ]]; then
    error "At least one authentication method must be provided: use -p for password or -k for SSH key (recommended)"
fi

# Create temporary directory for cloud-init files
TMPDIR=$(mktemp -d)
trap "rm -rf ${TMPDIR}" EXIT

# Create user-data
cat > ${TMPDIR}/user-data <<EOF
#cloud-config

# User configuration
users:
  - name: ${GUEST_USER}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
EOF

# Add SSH key if provided
if [[ -n "${SSH_PUBLIC_KEY}" ]]; then
    cat >> ${TMPDIR}/user-data <<EOF
    ssh_authorized_keys:
      - ${SSH_PUBLIC_KEY}
EOF
fi

# Add password if provided
if [[ -n "${GUEST_PASSWORD}" ]]; then
    cat >> ${TMPDIR}/user-data <<EOF
    passwd: ${GUEST_PASSWORD}
    lock_passwd: false
EOF
else
    # Lock password if only SSH key is provided
    cat >> ${TMPDIR}/user-data <<EOF
    lock_passwd: true
EOF
fi

# Create meta-data
cat > ${TMPDIR}/meta-data <<EOF
instance-id: $(uuidgen || echo "tdx-instance-$(date +%s)")
local-hostname: ${GUEST_HOSTNAME}
EOF

# Generate ISO
if command -v genisoimage >/dev/null 2>&1; then
    genisoimage -output "${OUTPUT_ISO}" \
                -volid cidata \
                -joliet \
                -rock \
                ${TMPDIR}/user-data \
                ${TMPDIR}/meta-data >/dev/null 2>&1
elif command -v mkisofs >/dev/null 2>&1; then
    mkisofs -output "${OUTPUT_ISO}" \
            -volid cidata \
            -joliet \
            -rock \
            ${TMPDIR}/user-data \
            ${TMPDIR}/meta-data >/dev/null 2>&1
else
    error "Neither genisoimage nor mkisofs found. Please install genisoimage."
fi

echo "Cloud-init ISO generated: ${OUTPUT_ISO}"
