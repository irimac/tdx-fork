# TDX Guest Image Creation Tools

This directory contains tools for creating TDX-enabled guest images from Ubuntu cloud images.

**Last Updated:** November 12, 2025

---

## Overview

These scripts create **generic TDX-enabled base images** without user-specific configuration. User data (usernames, passwords, SSH keys) is injected at runtime when launching TDs, allowing one base image to serve multiple users.

### Key Concept: Two-Stage Configuration

1. **Build Time (this directory)**: Create generic TDX-enabled base images
2. **Launch Time (../tdvirsh or ../run_td)**: Inject user-specific configuration via cloud-init ISO

---

## Directory Structure

```
image/
├── README.md                    # This file
├── create-td-image.sh           # Main: Create TDX guest base images
├── create-td-uki.sh             # Create UKI from existing TD image
├── create-uki.sh                # Create UKI inside guest (via virt-customize)
├── setup.sh                     # Guest setup script (runs inside image)
└── cloud-init-data/             # Cloud-init templates
    ├── user-data.template       # Base image cloud-init config
    ├── user-data                # Generated cloud-init for image creation
    ├── meta-data.template       # Metadata template
    └── meta-data                # Generated metadata
```

---

## Scripts

### 1. create-td-image.sh - **Main Image Creation Script**

**Purpose:** Creates TDX-enabled Ubuntu guest images from cloud images.

**What it does:**
1. Downloads Ubuntu cloud image from https://cloud-images.ubuntu.com
2. Verifies SHA256 checksum
3. Resizes the image (default: 100GB)
4. Runs cloud-init to configure the base system
5. Runs `setup.sh` inside the image via virt-customize
6. Enables TDX guest features
7. Installs TDX tools
8. Configures SSH for key-based authentication only
9. Creates a generic base image ready for runtime user configuration

**Usage:**
```bash
sudo ./create-td-image.sh -v <version> [OPTIONS]

Required:
  -v VERSION        Ubuntu version (24.04, 25.04)

Optional:
  -o PATH           Output file (default: tdx-guest-ubuntu-<version>-generic.qcow2)
  -s SIZE           Image size in GB (default: 100)
  -n HOSTNAME       Base image hostname (default: tdx-base-image)
  -f                Force recreate (overwrite existing)
  -h                Show help
```

**Examples:**
```bash
# Create Ubuntu 24.04 TDX base image
sudo ./create-td-image.sh -v 24.04

# Create with custom size and output path
sudo ./create-td-image.sh -v 24.04 -s 50 -o /path/to/my-base.qcow2

# Force recreate existing image
sudo ./create-td-image.sh -v 24.04 -f

# Behind a proxy (preserve environment)
sudo -E ./create-td-image.sh -v 24.04
```

**Output:**
- **Generic kernel**: `tdx-guest-ubuntu-24.04-generic.qcow2`
- **Intel kernel** (if `TDX_SETUP_INTEL_KERNEL=1`): `tdx-guest-ubuntu-24.04-intel.qcow2`

**Important Notes:**
- ⚠️ Requires sudo (uses virt-install, virt-customize)
- ⚠️ Downloads ~700MB cloud image on first run
- ⚠️ Creates temporary files in `/tmp/`
- ⚠️ Takes 5-10 minutes to complete
- ✅ Creates generic base images without user-specific data
- ✅ User configuration provided at VM launch time

---

### 2. setup.sh - **Guest Configuration Script**

**Purpose:** Runs inside the guest image during creation to configure TDX and security settings.

**What it does:**
1. Updates package lists
2. Installs required packages:
   - `cpuid`, `linux-tools-common`, `msr-tools` - Hardware introspection
   - `python3`, `python3-pip` - For TDX tools
3. Configures SSH security:
   - Disables password authentication
   - Disables keyboard-interactive authentication
   - Enables public key authentication only
   - Restricts root login to key-based only
   - Removes cloud-init SSH overrides
4. Enables TDX guest features (via `setup-tdx-guest.sh`)
5. Installs TDX tools from `tdx-tools/`
6. Cleans up temporary files

**Invoked by:** `create-td-image.sh` via virt-customize

**SSH Security Configuration:**
```bash
PasswordAuthentication no
PermitRootLogin prohibit-password
KbdInteractiveAuthentication no
PubkeyAuthentication yes
```

**Note:** This script runs automatically during image creation. You don't need to run it manually.

---

### 3. create-td-uki.sh - **UKI Creation from Existing Image**

**Purpose:** Creates a Unified Kernel Image (UKI) from an existing TD image.

**What is UKI?**
A Unified Kernel Image combines:
- Linux kernel
- Initramfs
- Kernel command line
- Optional: Secure Boot signature

UKIs enable direct boot and measured boot for TDX.

**Usage:**
```bash
sudo ./create-td-uki.sh <td-guest-image.qcow2>
```

**Example:**
```bash
sudo ./create-td-uki.sh tdx-guest-ubuntu-24.04-generic.qcow2
```

**Output:**
- UKI file extracted from the image
- Can be used for direct kernel boot

---

### 4. create-uki.sh - **UKI Creation Inside Guest**

**Purpose:** Creates UKI inside a running guest or via virt-customize.

**How it works:**
- Uses `systemd-ukify` to create unified kernel image
- Detects kernel version from `/boot/`
- Generates UKI for the installed kernel

**Invoked by:** virt-customize or run inside guest

**Note:** Typically used by `create-td-uki.sh`, not directly.

---

## Cloud-Init Configuration

### cloud-init-data/user-data.template

**Purpose:** Base system configuration without user-specific data.

**What it configures:**
- **Networking**: DHCP on all ethernet interfaces
- **MOTD**: Welcome message
- **udev rules**: TDX guest device permissions
- **Packages**: python3-pip, golang, ntp
- **Behavior**: Shutdown after base configuration

**Important:**
- ❌ No users created
- ❌ No passwords set
- ❌ No SSH keys configured
- ✅ System is configured for runtime user injection

**Runtime User Configuration:**
User-specific configuration is provided via a separate cloud-init ISO generated at VM launch time by:
- `../generate-user-cidata.sh`
- `../tdvirsh` (generates ISO automatically)
- `../run_td` (generates ISO automatically)

---

## Workflow

### Complete Image Creation Workflow

```
1. Download Ubuntu Cloud Image
   ↓
2. Verify SHA256 Checksum
   ↓
3. Resize Image (100GB default)
   ↓
4. Boot with cloud-init (user-data.template)
   ├─ Configure networking
   ├─ Install base packages
   └─ Shutdown after config
   ↓
5. Run setup.sh via virt-customize
   ├─ Configure SSH security
   ├─ Enable TDX features
   ├─ Install TDX tools
   └─ Clean up
   ↓
6. Output: Generic TDX Base Image
   └─ Ready for runtime user injection
```

### Launch Workflow (Runtime User Injection)

```
1. User runs: tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub
   ↓
2. generate-user-cidata.sh creates cloud-init ISO with:
   ├─ Username: alice
   ├─ SSH public key
   ├─ Hostname
   └─ Optional: password
   ↓
3. VM boots with:
   ├─ Base image (qcow2) - generic system
   └─ Cloud-init ISO - user-specific config
   ↓
4. Cloud-init configures user at first boot
   ↓
5. User can SSH with their key: ssh -p 2222 alice@localhost
```

---

## Requirements

### System Requirements
- **OS**: Ubuntu 22.04 or newer
- **Disk Space**: ~10GB free (for downloads and temporary files)
- **Memory**: 4GB+ recommended for virt-install
- **CPU**: Multi-core recommended (image creation is CPU-intensive)

### Package Requirements
```bash
sudo apt install -y \
    libvirt-daemon-system \
    qemu-kvm \
    qemu-utils \
    virtinst \
    libguestfs-tools \
    genisoimage \
    wget
```

### Permissions
- Scripts require `sudo` (they use virt-install, virt-customize, qemu-img)
- User should be in `libvirt` group: `sudo usermod -aG libvirt $USER`

---

## Configuration

### Environment Variables

Set in `../../setup-tdx-config` file:

```bash
# Kernel type selection
TDX_SETUP_INTEL_KERNEL=0    # 0=generic kernel, 1=Intel kernel

# Application installation
TDX_SETUP_APPS_OLLAMA=0     # 1=Install Ollama AI

# Guest configuration (for base image)
GUEST_HOSTNAME="tdx-base-image"
UBUNTU_VERSION="24.04"
```

**Note:** User-specific variables (GUEST_USER, GUEST_PASSWORD) are **no longer used** in image creation. User data is provided at launch time.

---

## Examples

### Example 1: Create Standard TDX Image

```bash
cd /path/to/tdx-fork/guest-tools/image/

# Create Ubuntu 24.04 TDX image with defaults
sudo ./create-td-image.sh -v 24.04

# Output: tdx-guest-ubuntu-24.04-generic.qcow2 (~100GB)
```

### Example 2: Create Smaller Custom Image

```bash
# Create 50GB image with custom name
sudo ./create-td-image.sh \
    -v 24.04 \
    -s 50 \
    -o /var/lib/libvirt/images/my-tdx-base.qcow2
```

### Example 3: Create Image Behind Proxy

```bash
# Preserve environment variables for proxy
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080

sudo -E ./create-td-image.sh -v 24.04
```

### Example 4: Recreate Existing Image

```bash
# Force recreate (will re-download cloud image)
sudo ./create-td-image.sh -v 24.04 -f
```

### Example 5: Use Created Image

```bash
# After creating the image, use it with tdvirsh
cd ../

# Launch TD with user configuration
./tdvirsh new \
    --td-image ./image/tdx-guest-ubuntu-24.04-generic.qcow2 \
    --user alice \
    --ssh-key ~/.ssh/id_rsa.pub

# Or with run_td
./run_td \
    --image ./image/tdx-guest-ubuntu-24.04-generic.qcow2 \
    --user bob \
    --ssh-key ~/.ssh/id_rsa.pub \
    --hostname bob-workstation
```

---

## Troubleshooting

### Issue: "Permission denied" errors

**Cause:** Script needs sudo privileges

**Solution:**
```bash
sudo ./create-td-image.sh -v 24.04
```

---

### Issue: "passt package is installed"

**Cause:** The `passt` package conflicts with virt-install networking

**Solution:**
```bash
sudo apt autoremove passt
```

---

### Issue: Download fails or checksum mismatch

**Cause:** Network issues or corrupted download

**Solution:**
```bash
# Clean up and retry
rm -f ubuntu-*.img SHA256SUMS
sudo ./create-td-image.sh -v 24.04
```

---

### Issue: "Failed to connect to libvirt"

**Cause:** libvirtd not running or permission issues

**Solution:**
```bash
# Start libvirtd
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Add user to libvirt group
sudo usermod -aG libvirt $USER
# Logout and login required
```

---

### Issue: Image creation hangs or times out

**Cause:** Insufficient resources or network issues during cloud-init

**Solution:**
1. Check available disk space: `df -h /tmp/`
2. Check memory: `free -h`
3. Check libvirt logs: `sudo journalctl -u libvirtd -f`
4. Kill any stuck VMs: `virsh list --all` then `virsh destroy <name>`

---

### Issue: Image created but SSH key auth doesn't work

**Cause:** Likely using old workflow with baked-in credentials

**Solution:**
- Ensure using latest scripts (runtime user injection)
- Don't specify user/password/key during image creation
- Provide user config at launch time:
  ```bash
  ./tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub
  ```

---

## Best Practices

1. **Create Generic Base Images**
   - Don't bake user-specific data into images
   - One base image serves many users
   - Faster deployment, less storage

2. **Use Standard Naming**
   - Keep default naming: `tdx-guest-ubuntu-<version>-<kernel>.qcow2`
   - Helps tools auto-detect images

3. **Verify Images**
   ```bash
   # Check image info
   qemu-img info tdx-guest-ubuntu-24.04-generic.qcow2

   # Check SSH config inside image
   virt-cat -a tdx-guest-ubuntu-24.04-generic.qcow2 /etc/ssh/sshd_config | grep -E "Password|PubkeyAuth|PermitRoot"
   ```

4. **Keep Images Updated**
   ```bash
   # Recreate monthly to get security updates
   sudo ./create-td-image.sh -v 24.04 -f
   ```

5. **Behind Proxy**
   - Always use `sudo -E` to preserve proxy environment variables

6. **Backup Custom Images**
   ```bash
   # Backup your custom base images
   cp tdx-guest-ubuntu-24.04-generic.qcow2 /backup/location/
   ```

---

## Technical Details

### Image Creation Process Details

**1. Cloud Image Download:**
- Source: https://cloud-images.ubuntu.com/releases/
- Format: qcow2 (with .img suffix)
- Size: ~700MB compressed
- Partitions: EFI boot, ext4 root (~2GB)

**2. Resize Operation:**
- Uses `qemu-img resize`
- Expands root partition to specified size
- Does not fill space (qcow2 is sparse)

**3. First Boot (cloud-init):**
- Runs `user-data.template` configuration
- Installs packages
- Configures networking
- Powers off automatically

**4. Customization (virt-customize):**
- Mounts image without booting
- Copies files into image
- Runs scripts inside guest context
- Used for `setup.sh` execution

**5. TDX Enablement:**
- Runs `setup-tdx-guest.sh` from main repo
- Configures kernel parameters
- Enables TDX-specific features
- Installs TDX attestation tools

---

## Security Features

### SSH Hardening

**Implemented in setup.sh:**
- ✅ Password authentication disabled
- ✅ Root login restricted to keys only
- ✅ Keyboard-interactive auth disabled
- ✅ Public key authentication required
- ✅ Cloud-init SSH overrides removed

**Config: `/etc/ssh/sshd_config`**
```
PasswordAuthentication no
PermitRootLogin prohibit-password
KbdInteractiveAuthentication no
PubkeyAuthentication yes
```

### File Permissions

**Base images:**
- Owner: `root:root`
- Permissions: `644` (readable by all)

**After import to libvirt pool:**
- Owner: `root:qemu`
- Permissions: `640` (not world-readable)

### No Hardcoded Credentials

- ❌ No default passwords
- ❌ No baked-in SSH keys
- ❌ No default users
- ✅ Clean, generic base images
- ✅ Runtime user injection only

---

## Advanced Usage

### Creating Images with Intel Kernel

```bash
# Edit config file
echo "TDX_SETUP_INTEL_KERNEL=1" >> ../../setup-tdx-config

# Create image
sudo ./create-td-image.sh -v 24.04

# Output: tdx-guest-ubuntu-24.04-intel.qcow2
```

### Creating Images with Ollama Pre-installed

```bash
# Edit config file
echo "TDX_SETUP_APPS_OLLAMA=1" >> ../../setup-tdx-config

# Create image (will install Ollama)
sudo ./create-td-image.sh -v 24.04
```

### Custom Cloud-Init Configuration

```bash
# Edit cloud-init template
vi cloud-init-data/user-data.template

# Add your custom packages, files, or commands
# Then create image
sudo ./create-td-image.sh -v 24.04
```

### Creating UKI for Direct Boot

```bash
# First create standard image
sudo ./create-td-image.sh -v 24.04

# Then create UKI from it
sudo ./create-td-uki.sh tdx-guest-ubuntu-24.04-generic.qcow2

# Use UKI for direct kernel boot with measured boot
```

---

## FAQ

### Q: Why doesn't the script accept -u, -p, -k flags anymore?

**A:** The architecture changed to runtime user injection. User configuration (username, password, SSH keys) is now provided when launching the VM, not when creating the base image. This allows one base image to serve multiple users.

---

### Q: How do I specify the user when creating an image?

**A:** You don't. Create a generic base image with this script, then specify the user when launching:
```bash
./tdvirsh new --user alice --ssh-key ~/.ssh/id_rsa.pub
```

---

### Q: Can I still use the old workflow?

**A:** No. The old workflow with baked-in credentials has been removed for security and efficiency. The new runtime injection method is more flexible and secure.

---

### Q: How long does image creation take?

**A:**
- First run: 10-15 minutes (includes ~700MB download)
- Subsequent runs: 5-10 minutes (cloud image cached)
- With `-f` flag: 10-15 minutes (re-downloads)

---

### Q: Where are temporary files stored?

**A:**
- Cloud images: `./ubuntu-<version>-server-cloudimg-amd64.img`
- Temporary image: `/tmp/tdx-guest-tmp.qcow2`
- Checksums: `./SHA256SUMS`

Temporary files are cleaned up automatically on success.

---

### Q: Can I create images for multiple Ubuntu versions?

**A:** Yes! Just specify different versions:
```bash
sudo ./create-td-image.sh -v 24.04
sudo ./create-td-image.sh -v 25.04
```

---

### Q: What's the difference between generic and intel kernels?

**A:**
- **Generic kernel**: Standard Ubuntu kernel, fully upstreamed TDX support
- **Intel kernel**: May have non-upstreamed features, under development

Recommendation: Use generic kernel unless you need specific Intel features.

---

### Q: How do I verify the created image is secure?

**A:**
```bash
# Check SSH config
virt-cat -a tdx-guest-ubuntu-24.04-generic.qcow2 /etc/ssh/sshd_config | grep "PasswordAuthentication"
# Should show: PasswordAuthentication no

# Check for users
virt-cat -a tdx-guest-ubuntu-24.04-generic.qcow2 /etc/passwd
# Should show only system users, no regular users

# Check for authorized_keys
virt-ls -a tdx-guest-ubuntu-24.04-generic.qcow2 /root/.ssh/ 2>&1
# Should show empty or not exist
```

---

## Related Documentation

- **Main README**: `../../README.md` - Complete project documentation
- **tdvirsh Documentation**: `../README.md` - VM management tool
- **USAGE_GUIDE**: `../USAGE_GUIDE.md` - Comprehensive usage guide
- **generate-user-cidata.sh**: `../generate-user-cidata.sh` - Runtime user config generator

---

## Support

### Common Issues

| Issue | Solution |
|-------|----------|
| Permission denied | Use `sudo` |
| passt installed | Remove: `sudo apt remove passt` |
| Download fails | Check network, retry with `-f` |
| Hangs during creation | Check resources (disk, memory, CPU) |
| Can't connect with SSH key | Ensure using runtime injection at launch |

### Getting Help

1. Check script output for error messages
2. Review `/tmp/tdx-guest-setup.txt` log file
3. Check libvirt logs: `sudo journalctl -u libvirtd -f`
4. Verify requirements are installed
5. Ensure sufficient disk space and memory

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-12 | 2.0 | Runtime user injection architecture, removed -u/-p/-k flags |
| 2024-11-04 | 1.0 | Initial version with baked-in credentials |

---

**Document Version:** 2.0
**Last Updated:** November 12, 2025
**Status:** Production Ready ✅
