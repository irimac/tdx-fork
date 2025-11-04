# TDX Guest Tools - tdvirsh Documentation Package

Complete documentation for the `tdvirsh_claude_01` Trust Domain management tool.

---

## Quick Links

| Document | Purpose | Audience |
|----------|---------|----------|
| **[USAGE_GUIDE.md](./USAGE_GUIDE.md)** | Complete user manual | End users, operators |
| **[TDVIRSH_01_SUMMARY.md](./TDVIRSH_01_SUMMARY.md)** | Quick reference guide | All users |
| **[TDVIRSH_01_ANALYSIS.md](./TDVIRSH_01_ANALYSIS.md)** | Complete technical analysis | Developers, decision makers |
| **[DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md)** | Implementation details & rationale | Developers, maintainers |
| **tdvirsh_01** (script) | The enhanced tool (heavily commented) | Developers, code reviewers |

---

## What is tdvirsh_01?

A **production-ready** wrapper around `virsh` for managing Intel TDX Trust Domains with integrated libvirt storage pool support.

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
chmod +x tdvirsh_01

# Create your first TD (auto-creates pool and imports image)
./tdvirsh_01 new

# List all TDs with connection info
./tdvirsh_01 list

# Check pool status
./tdvirsh_01 pool-info

# Delete a TD
./tdvirsh_01 delete <domain-name>

# Clean orphaned volumes
./tdvirsh_01 pool-cleanup
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

### 2. TDVIRSH_01_SUMMARY.md - **Quick Reference**

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

### 3. TDVIRSH_01_ANALYSIS.md - **Complete Technical Analysis**

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

### 5. tdvirsh_01 (Script) - **The Source Code**

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

## Version Comparison at a Glance

| Feature | Original tdvirsh | **tdvirsh_01** |
|---------|------------------|----------------|
| **Production Ready** | ✅ Yes | ✅ **Yes** |
| **Storage Pools** | ❌ No | ✅ **Full Support** |
| **GPU Setup** | ✅ Yes | ✅ **Yes** |
| **Graceful Shutdown** | ✅ Yes | ✅ **Yes** |
| **Connection Info** | ✅ Full | ✅ **Full** |
| **Portable** | ✅ Yes | ✅ **Yes** |
| **Pool Management** | ❌ No | ✅ **pool-info/cleanup** |
| **Security** | Basic | ✅ **Enhanced (640 perms)** |
| **Lines of Code** | 304 | **1,190** |
| **Documentation** | Minimal (~20 lines) | **Comprehensive (~580 lines)** |

**Verdict:** Use `tdvirsh_01` for all new work.

---

## File Inventory

```
guest-tools/
├── README.md                      # This file - documentation index
├── TDVIRSH_01_SUMMARY.md          # Quick reference guide ⭐
├── TDVIRSH_01_ANALYSIS.md         # Complete technical analysis
├── USAGE_GUIDE.md                 # Complete user manual
├── TDVIRSH_COMPARISON.md          # Legacy comparison document
├── DEVELOPMENT_LOG.md             # Implementation log (technical)
├── tdvirsh                        # Original version (keep for reference)
├── tdvirsh_01                     # Enhanced version (recommended) ⭐
├── trust_domain.xml.template      # Libvirt XML template
└── trust_domain-sb.xml.template   # Secure Boot template
```

---

## Usage Examples

### Basic Operations

```bash
# Create TD with defaults
./tdvirsh_01 new

# Create TD with custom image
./tdvirsh_01 new -i /path/to/custom-image.qcow2

# Create TD with GPU passthrough
./tdvirsh_01 new -g 0000:17:00.0

# List all TDs with connection details
./tdvirsh_01 list
# Output: Id Name  State  (ip:192.168.122.45, hostfwd:2222, cid:3)

# Delete specific TD
./tdvirsh_01 delete tdvirsh-trust_domain-abc123...

# Delete all TDs
./tdvirsh_01 delete all
```

### Pool Management

```bash
# Show pool information
./tdvirsh_01 pool-info
# Shows: pool status, capacity, all volumes

# Clean up orphaned overlays
./tdvirsh_01 pool-cleanup
# Scans and removes unused overlay volumes
```

### SSH Connection

```bash
# After creating TD
./tdvirsh_01 list

# Note the hostfwd port (e.g., 2222)
ssh -p 2222 tdx@localhost

# Or use IP directly
ssh tdx@192.168.122.45

# Default password: 123456 (change immediately!)
```

---

## Key Improvements Over Original

### 1. Storage Pool Integration

**Before (original):**
```bash
# Manual file operations in /var/tmp
qemu-img create -b base.qcow2 overlay.qcow2
# Manual cleanup with rm
```

**After (tdvirsh_01):**
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
$ ./tdvirsh_01 pool-info
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
$ ./tdvirsh_01 pool-cleanup
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
./tdvirsh_01 new
```

### Option 2: Install to PATH
```bash
sudo cp tdvirsh_01 /usr/local/bin/tdvirsh
tdvirsh new  # Available system-wide
```

### Option 3: Symlink
```bash
sudo ln -s $(pwd)/tdvirsh_01 /usr/local/bin/tdvirsh
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
./tdvirsh_01 pool-cleanup
```

**For more troubleshooting, see [USAGE_GUIDE.md](./USAGE_GUIDE.md#troubleshooting)**

---

## Migration from Original tdvirsh

### Quick Migration (5 minutes)

```bash
# 1. Backup original
cp tdvirsh tdvirsh.backup

# 2. Test new version
./tdvirsh_01 new

# 3. Verify it works
./tdvirsh_01 list
./tdvirsh_01 pool-info

# 4. Replace if satisfied
mv tdvirsh tdvirsh.original
cp tdvirsh_01 tdvirsh
```

### What Changes

✅ **Compatible:**
- All command-line arguments
- Config file (setup-tdx-config)
- XML templates
- GPU BDF format
- Existing base images (auto-imported)

⚠️ **Changed:**
- Storage location (/var/tmp → /var/lib/libvirt/images)
- Overlay creation method
- Overlay cleanup method

❌ **Not Compatible:**
- Cannot reuse existing overlays from /var/tmp
- Must recreate VMs (not migrate running VMs)

**For detailed migration guide, see [TDVIRSH_01_ANALYSIS.md](./TDVIRSH_01_ANALYSIS.md#compatibility-assessment)**

---

## FAQ

### Q: Can I use both versions simultaneously?
**A:** Yes, but be aware:
- Different storage locations (/var/tmp vs /var/lib/libvirt/images)
- Different pool names
- Domain name prefix is the same (possible conflict)

### Q: What happens to my existing VMs?
**A:** tdvirsh_01 won't see VMs created by original tdvirsh. They use different storage locations. You can keep both or migrate.

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

### Q: Can I change the storage pool location?
**A:** Yes, edit `STORAGE_POOL_PATH` in the script:
```bash
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
./tdvirsh_01 --help

# Check logs
sudo journalctl -u libvirtd -f

# Check VM console
./tdvirsh_01 console <domain>

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

The result is `tdvirsh_01` - an enhanced solution that combines:
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
| 2025-11-04 | 2.0 | Updated for tdvirsh_01 with comprehensive analysis |
| 2025-11-03 | 1.0 | Initial release with complete documentation package |

---

**For detailed usage instructions, start with [USAGE_GUIDE.md](./USAGE_GUIDE.md)**
