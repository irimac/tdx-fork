# TDX Guest Tools - tdvirsh Documentation Package

Complete documentation for the `tdvirsh` Trust Domain management tool.

---

## Quick Links

| Document | Purpose | Audience |
|----------|---------|----------|
| **[USAGE_GUIDE.md](./USAGE_GUIDE.md)** | Complete user manual | End users, operators |
| **[TDVIRSH_SUMMARY.md](./TDVIRSH_SUMMARY.md)** | Quick reference guide | All users |
| **[TDVIRSH_ANALYSIS.md](./TDVIRSH_ANALYSIS.md)** | Complete technical analysis | Developers, decision makers |
| **[DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md)** | Implementation details & rationale | Developers, maintainers |
| **tdvirsh** (script) | The enhanced tool (heavily commented) | Developers, code reviewers |

---

## What is tdvirsh?

A **production-ready** wrapper around `virsh` for managing Intel TDX Trust Domains with integrated libvirt storage pool support and runtime user configuration.

### Key Features

✅ **Storage Pool Integration** - Native libvirt pool management at `/var/lib/libvirt/images`
✅ **Automatic Setup** - Pool and base image auto-imported on first use
✅ **GPU Passthrough** - Full VFIO setup with DMA configuration
✅ **Graceful Shutdown** - Safe VM termination with 5-second wait
✅ **Rich Information** - Display IP, SSH port, and vSOCK CID
✅ **Orphan Detection** - Clean up unused overlay volumes
✅ **Production Ready** - Comprehensive error handling and validation

---

## Quick Start

```bash
# Make executable
chmod +x tdvirsh

# Create your first TD (auto-creates pool and imports image)
./tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub

# Create TD with custom storage pool
./tdvirsh new --user bob --ssh-key ~/.ssh/id_rsa.pub --pool my-custom-pool

# List all TDs with connection info
./tdvirsh list

# Check pool status
./tdvirsh pool-info

# Delete a TD
./tdvirsh delete <domain-name>

# Clean orphaned volumes
./tdvirsh pool-cleanup
```

---

## Documentation Structure

### 1. USAGE_GUIDE.md - **Start Here for Daily Use**

**Best for:** Users who want to use the tool

**Contents:**
- Quick start guide
- Command reference with examples
- Common workflows
- GPU passthrough guide
- Storage pool management
- Troubleshooting
- FAQ

**When to read:** When you need to:
- Create, list, or delete TDs
- Configure GPU passthrough
- Understand storage pools
- Solve common problems

---

### 2. TDVIRSH_SUMMARY.md - **Quick Reference**

**Best for:** All users needing quick answers

**Contents:**
- TL;DR recommendations
- Quick stats and comparisons
- Command reference with examples
- Troubleshooting guide
- Common workflows
- Decision matrices

**When to read:** When you need to:
- Get started quickly
- Find command syntax
- Make quick decisions
- Solve common problems
- See practical examples

---

### 3. TDVIRSH_ANALYSIS.md - **Complete Technical Analysis**

**Best for:** Developers, architects, decision makers

**Contents:**
- Comprehensive feature analysis
- Security assessment
- Code quality evaluation
- Performance benchmarks
- Migration strategies
- Architecture deep-dive

**When to read:** When you need to:
- Understand implementation details
- Evaluate for production use
- Plan migrations
- Make architectural decisions
- Review code quality

---

### 4. DEVELOPMENT_LOG.md - **Deep Technical Details**

**Best for:** Developers, maintainers, contributors

**Contents:**
- Complete analysis of original code
- Design decisions and rationale
- Implementation details
- Function-by-function changes
- Testing considerations
- Lessons learned
- Future enhancements

**When to read:** When you need to:
- Understand implementation details
- Contribute code changes
- Debug complex issues
- Learn about design patterns
- Plan future features

---

### 5. tdvirsh (Script) - **The Source Code**

**Best for:** Code review, learning, debugging

**Features:**
- Comprehensive inline comments (1,190 lines total)
- Function-level documentation (all 13 functions)
- Parameter descriptions
- Usage examples
- Step-by-step explanations

**When to read:** When you need to:
- Review code changes
- Understand specific functions
- Debug runtime issues
- Learn bash scripting patterns
- Make code modifications

---

## Feature Overview

| Feature | Status |
|---------|--------|
| **Production Ready** | ✅ Yes |
| **Storage Pools** | ✅ Full Support |
| **Runtime User Config** | ✅ SSH key / Password injection |
| **GPU Setup** | ✅ Yes |
| **Graceful Shutdown** | ✅ Yes |
| **Connection Info** | ✅ Full (IP, SSH port, vSOCK CID) |
| **Portable** | ✅ Yes |
| **Pool Management** | ✅ pool-info/cleanup commands |
| **Security** | ✅ Enhanced (640 perms, SSH keys) |
| **Lines of Code** | 1,290 (heavily commented) |
| **Documentation** | ✅ Comprehensive |

---

## File Inventory

```
guest-tools/
├── README.md                      # This file - documentation index
├── TDVIRSH_SUMMARY.md             # Quick reference guide ⭐
├── TDVIRSH_ANALYSIS.md            # Complete technical analysis
├── USAGE_GUIDE.md                 # Complete user manual
├── TDVIRSH_COMPARISON.md          # Legacy comparison document
├── DEVELOPMENT_LOG.md             # Implementation log (technical)
├── DOCUMENTATION_INDEX.md         # Master documentation index
├── tdvirsh                        # Production-ready TD manager ⭐
├── run_td                         # Python TD launcher (alternative to tdvirsh)
├── generate-user-cidata.sh        # Cloud-init ISO generator (runtime user config) ⭐
├── trust_domain.xml.template      # Libvirt XML template
├── trust_domain-sb.xml.template   # Secure Boot template
└── image/                         # Image creation tools
    ├── README.md                  # Image creation documentation
    ├── create-td-image.sh         # Main: Create TDX base images
    ├── setup.sh                   # Guest configuration script
    └── cloud-init-data/           # Cloud-init templates
```

---

## Usage Examples

### Basic Operations

```bash
# Create TD with user and SSH key (required)
./tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub

# Create TD with custom image
./tdvirsh new -i /path/to/custom-image.qcow2 --user bob --ssh-key ~/.ssh/id_rsa.pub

# Create TD with GPU passthrough
./tdvirsh new -g 0000:17:00.0 --user charlie --ssh-key ~/.ssh/id_rsa.pub

# Create TD with custom storage pool
./tdvirsh new --user dave --ssh-key ~/.ssh/id_rsa.pub --pool my-custom-pool

# List all TDs with connection details
./tdvirsh list
# Output: Id Name  State  (ip:192.168.122.45, hostfwd:2222, cid:3)

# Delete specific TD
./tdvirsh delete tdvirsh-trust_domain-abc123...

# Delete all TDs
./tdvirsh delete all
```

### Pool Management

```bash
# Show pool information
./tdvirsh pool-info
# Shows: pool status, capacity, all volumes

# Clean up orphaned overlays
./tdvirsh pool-cleanup
# Scans and removes unused overlay volumes
```

### SSH Connection

```bash
# After creating TD
./tdvirsh list

# Note the hostfwd port (e.g., 2222) and use your username
ssh -p 2222 alice@localhost

# Or use IP directly
ssh alice@192.168.122.45

# Authentication is via SSH key (configured with --ssh-key during TD creation)
```

---

## Helper Scripts

### generate-user-cidata.sh - Runtime User Configuration Generator

**Purpose:** Generates cloud-init ISO files with user-specific configuration (username, SSH keys, passwords, hostname) for runtime injection into TDs.

**Automatically called by:**
- `tdvirsh new` - Generates ISO during VM creation
- `run_td` - Generates ISO during VM launch

**Can also be used standalone** for custom workflows.

**Usage:**
```bash
./generate-user-cidata.sh -o <output.iso> -u <username> [OPTIONS]

Required:
  -o, --output PATH         Output ISO file path
  -u, --user USERNAME       Guest username

Authentication (at least one required):
  -k, --ssh-key PATH        SSH public key file (recommended)
  -p, --password PASSWORD   Guest password

Optional:
  -n, --hostname HOSTNAME   Guest hostname (default: tdx-guest)
  -h, --help                Show help
```

**Examples:**
```bash
# Generate ISO with SSH key authentication
./generate-user-cidata.sh \
    -o /tmp/alice-config.iso \
    -u alice \
    -k ~/.ssh/id_rsa.pub \
    -n alice-workstation

# Generate ISO with password authentication
./generate-user-cidata.sh \
    -o /tmp/bob-config.iso \
    -u bob \
    -p SecurePassword123 \
    -n bob-td

# Generate ISO with both auth methods
./generate-user-cidata.sh \
    -o /tmp/charlie-config.iso \
    -u charlie \
    -k ~/.ssh/id_rsa.pub \
    -p BackupPassword
```

**What it creates:**
- Cloud-init ISO with `user-data` and `meta-data`
- User account with specified username
- SSH authorized_keys (if -k provided)
- Password (if -p provided, otherwise locked)
- Hostname configuration
- Sudo permissions (NOPASSWD:ALL)

**How it's used:**
1. User runs: `./tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub`
2. tdvirsh calls: `generate-user-cidata.sh -o /path/to/cidata.iso -u alice -k ~/.ssh/id_rsa.pub`
3. ISO is attached to VM as secondary disk (vdb)
4. Cloud-init reads ISO on first boot
5. User account is created with SSH key
6. User can login: `ssh -p 2222 alice@localhost`

**Requirements:**
- `genisoimage` or `mkisofs` command must be installed
- SSH public key file must exist and be readable (if using -k)

**Output location (when called by tdvirsh):**
- `/var/lib/libvirt/images/cidata.<random>.iso`
- Automatically cleaned up when VM is deleted

**Note:** This script is part of the runtime user injection architecture. It separates user configuration from base image creation, allowing one generic base image to serve multiple users.

---

## Key Improvements Over Original

### 1. Storage Pool Integration

**Before (original):**
```bash
# Manual file operations in /var/tmp
qemu-img create -b base.qcow2 overlay.qcow2
# Manual cleanup with rm
```

**After (tdvirsh):**
```bash
# Native libvirt API
virsh vol-create-as pool overlay 0 --backing-vol base
# Pool-aware cleanup
virsh vol-delete --pool pool overlay
```

**Benefits:**
- Better integration with libvirt
- Automatic permission handling
- Easier monitoring
- Standard best practices

---

### 2. New Commands

**pool-info** - Show storage pool status
```bash
$ ./tdvirsh pool-info
=== Storage Pool Information ===
Name:           tdvirsh-pool
State:          running
Capacity:       931.51 GiB
Allocation:     45.23 GiB
Available:      886.28 GiB

=== Available Volumes ===
 Name                                    Path
--------------------------------------------------------------------------------
 tdx-guest-ubuntu-24.04-generic.qcow2   /var/lib/libvirt/images/...
 overlay.AbC123XyZ456789.qcow2          /var/lib/libvirt/images/...
```

**pool-cleanup** - Remove orphaned overlays
```bash
$ ./tdvirsh pool-cleanup
Scanning for orphaned overlay volumes...
Found orphaned overlay: overlay.OldOne123.qcow2, removing...
Removed 1 orphaned overlay volume(s).
```

---

### 3. Automatic Base Image Import

**Before:** Manual copy to expected location
**After:** Automatic detection and import

```bash
# Detects image not in pool
Base image found at ./image/tdx-guest.qcow2, will import to storage pool.
Importing base image to storage pool...
Base image imported successfully.
```

---

## Installation Options

### Option 1: Direct Use (Recommended)
```bash
cd /path/to/tdx-fork/guest-tools/
./tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub
```

### Option 2: Install to PATH
```bash
sudo cp tdvirsh /usr/local/bin/tdvirsh
tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub  # Available system-wide
```

### Option 3: Symlink
```bash
sudo ln -s $(pwd)/tdvirsh /usr/local/bin/tdvirsh
```

---

## Prerequisites

```bash
# Required packages
sudo apt install \
    libvirt-daemon-system \
    qemu-kvm \
    qemu-utils \
    virtinst

# User permissions
sudo usermod -aG libvirt $USER
# Logout/login required

# Verify
virsh version
```

---

## Troubleshooting Quick Reference

### Pool Creation Fails
```bash
# Check permissions
sudo mkdir -p /var/lib/libvirt/images
sudo chmod 755 /var/lib/libvirt/images

# Check libvirtd
sudo systemctl status libvirtd
```

### Permission Denied
```bash
# Add user to libvirt group
sudo usermod -aG libvirt $USER
# Logout and login again
```

### GPU Not Visible in Guest
```bash
# Check BDF format (must be 0000:17:00.0)
lspci | grep NVIDIA

# Verify IOMMU enabled
dmesg | grep -i iommu

# Check vfio-pci binding
lspci -k -s 0000:17:00.0
```

### Orphaned Overlays After Crash
```bash
# Clean up automatically
./tdvirsh pool-cleanup
```

**For more troubleshooting, see [USAGE_GUIDE.md](./USAGE_GUIDE.md#troubleshooting)**

---

## Getting Started

### First Time Setup

```bash
# 1. Create a base TD image
cd guest-tools/image/
sudo ./create-td-image.sh -v 25.04

# 2. Launch a TD with your user configuration
cd ..
./tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub

# 3. Verify it's running
./tdvirsh list

# 4. Check pool status
./tdvirsh pool-info
```

### Storage Location

- **Pool**: `/var/lib/libvirt/images`
- **Base images**: Auto-imported to pool on first use
- **Overlays**: Created per-VM in pool
- **User data**: Runtime cloud-init ISOs in pool

---

## FAQ

### Q: Where are VM images stored?
**A:** All images are stored in the libvirt storage pool at `/var/lib/libvirt/images`:
- Base images are auto-imported on first use
- Per-VM overlay images (copy-on-write)
- Cloud-init ISOs for user configuration

### Q: Is it safe for production?
**A:** Yes. It includes:
- Comprehensive error handling
- Graceful VM shutdown
- Input validation
- Proper cleanup
- Tested workflows

However, it's newer than the original, so consider:
- Testing in your environment first
- Gradual rollout
- Keeping original as backup

### Q: Can I change the storage pool name or location?
**A:** Yes, you can specify a custom pool name using the `--pool` option:
```bash
./tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub --pool my-custom-pool
```

Or edit the default values in the script:
```bash
STORAGE_POOL_NAME="my-custom-pool"
STORAGE_POOL_PATH="/your/custom/path"
```

### Q: How do I contribute or report bugs?
**A:**
- Read [DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md) for architecture
- Submit issues to repository
- Include: command used, error message, pool-info output

---

## Support & Resources

### Documentation
- **[USAGE_GUIDE.md](./USAGE_GUIDE.md)** - Complete user manual
- **[TDVIRSH_COMPARISON.md](./TDVIRSH_COMPARISON.md)** - Version comparison
- **[DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md)** - Technical details

### External Resources
- [Libvirt Storage Pools](https://libvirt.org/storage.html)
- [Libvirt Domain XML](https://libvirt.org/formatdomain.html)
- [Intel TDX Documentation](https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/overview.html)
- [Canonical TDX Repository](https://github.com/canonical/tdx)

### Getting Help
```bash
# Check script help
./tdvirsh --help

# Check logs
sudo journalctl -u libvirtd -f

# Check VM console
./tdvirsh console <domain>

# Debug pool
virsh pool-info tdvirsh-pool
virsh vol-list tdvirsh-pool
```

---

## Project Context

This documentation package was created as part of an analysis and enhancement effort for TDX guest management tools. The goal was to:

1. **Analyze** the existing `tdvirsh` script
2. **Design** improvements incorporating modern libvirt practices
3. **Enhance** security with proper permissions and ownership
4. **Implement** a production-ready version with all features
5. **Document** everything comprehensively for future users

The result is `tdvirsh` - an enhanced solution that combines:
- Production readiness of the original
- Modern storage pool approach
- Enhanced features for better management
- Comprehensive documentation

---

## License

Copyright 2024 Canonical Ltd.
SPDX-License-Identifier: GPL-3.0-only

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3, as published by the Free Software Foundation.

---

## Revision History

| Date | Version | Description |
|------|---------|-------------|
| 2025-11-04 | 2.0 | Updated for tdvirsh with comprehensive analysis |
| 2025-11-03 | 1.0 | Initial release with complete documentation package |

---

**For detailed usage instructions, start with [USAGE_GUIDE.md](./USAGE_GUIDE.md)**
