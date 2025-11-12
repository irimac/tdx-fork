# TDvirsh Usage Guide

Complete guide for using `tdvirsh` to manage TDX Trust Domains with libvirt storage pool integration.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Commands Reference](#commands-reference)
4. [Common Workflows](#common-workflows)
5. [GPU Passthrough](#gpu-passthrough)
6. [Storage Pool Management](#storage-pool-management)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Usage](#advanced-usage)
9. [Best Practices](#best-practices)
10. [FAQ](#faq)

---

## Quick Start

### Prerequisites

```bash
# Required packages
sudo apt install libvirt-daemon-system qemu-kvm qemu-utils

# Verify libvirt is running
sudo systemctl status libvirtd

# Add your user to libvirt group (logout/login required)
sudo usermod -aG libvirt $USER
```

### Create Your First TD

```bash
cd /home/rimac/VBoxShare/tdx/guest-tools/

# Create TD with default settings
./tdvirsh new

# The script will:
# 1. Create storage pool at /var/lib/libvirt/images
# 2. Import base image to pool
# 3. Create overlay volume
# 4. Boot the VM
# 5. Display connection info
```

### Connect to Your TD

```bash
# List all TDs with connection info
./tdvirsh list

# Example output:
# Id   Name                                State    (ip:192.168.122.45, hostfwd:2222, cid:3)
# 1    tdvirsh-trust_domain-abc123...     running  (ip:192.168.122.45, hostfwd:2222, cid:3)

# SSH into the TD
ssh -p 2222 tdx@localhost
# Default password: 123456 (change this!)
```

---

## Installation

### Method 1: Direct Use

```bash
# Make executable
chmod +x /path/to/tdvirsh

# Run directly
./tdvirsh new
```

### Method 2: Install to PATH

```bash
# Copy to system binary directory
sudo cp tdvirsh /usr/local/bin/tdvirsh

# Now available system-wide
tdvirsh new
```

### Method 3: Symlink

```bash
# Create symlink
sudo ln -s /path/to/tdvirsh /usr/local/bin/tdvirsh

# Use system-wide
tdvirsh new
```

### Verify Installation

```bash
# Check help
./tdvirsh --help

# Should display usage information
```

---

## Commands Reference

### new - Create and Run Trust Domain

**Syntax:**
```bash
./tdvirsh new [OPTIONS]
```

**Options:**
- `-i, --td-image PATH` - Path to base image (auto-imported to pool)
- `-t, --xml-template PATH` - Path to libvirt XML template
- `-g, --gpus BDF_LIST` - Comma-separated list of GPU BDFs for passthrough

**Examples:**

```bash
# Create TD with default image
./tdvirsh new

# Create TD with custom image
./tdvirsh new -i /path/to/custom-image.qcow2

# Create TD with GPU passthrough (single GPU)
./tdvirsh new -g 0000:17:00.0

# Create TD with multiple GPUs
./tdvirsh new -g 0000:17:00.0,0000:65:00.0

# Create TD with custom template
./tdvirsh new -t /path/to/custom-template.xml

# Combine all options
./tdvirsh new \
  -i /path/to/image.qcow2 \
  -t /path/to/template.xml \
  -g 0000:17:00.0,0000:65:00.0
```

**What Happens:**
1. Storage pool checked/created at `/var/lib/libvirt/images`
2. Base image imported to pool (if not already present)
3. GPU setup script executed (if `-g` specified)
4. Overlay volume created in pool
5. Domain XML generated
6. VM defined and started
7. Connection info displayed

**Output:**
```
Create and run new virsh domain from /path/to/image.qcow2 and ./trust_domain.xml.template
---
Creating storage pool 'tdvirsh-pool' at /var/lib/libvirt/images...
Storage pool 'tdvirsh-pool' created successfully.
Importing base image to storage pool...
Base image imported successfully.
Using base image 'tdx-guest-ubuntu-24.04-generic.qcow2' from storage pool.
Created overlay volume: overlay.AbC123XyZ456789.qcow2
---
Domain created successfully!
Id:             1
Name:           tdvirsh-trust_domain-abc123-def456-...
UUID:           abc123-def456-...
OS Type:        hvm
State:          running
CPU(s):         32
Max memory:     16777216 KiB
Used memory:    16777216 KiB
```

---

### list - List All Trust Domains

**Syntax:**
```bash
./tdvirsh list
```

**Output:**
```
 Id   Name                                     State      (connection info)
-----------------------------------------------------------------------------------
 1    tdvirsh-trust_domain-abc123...          running    (ip:192.168.122.45, hostfwd:2222, cid:3)
 2    tdvirsh-trust_domain-def456...          running    (ip:192.168.122.46, hostfwd:2223, cid:4)
 -    tdvirsh-trust_domain-ghi789...          shut off   (ip:unknown, hostfwd:, cid:)
```

**Connection Info:**
- **ip** - Guest IP address (for direct network access)
- **hostfwd** - Host port for SSH forwarding (use `ssh -p <port> localhost`)
- **cid** - vSOCK Context ID (for vSOCK communication)

**Use Cases:**
- Check which TDs are running
- Get SSH connection information
- Find TD domain names for deletion
- Monitor TD status

---

### delete - Stop and Delete Trust Domain

**Syntax:**
```bash
./tdvirsh delete <domain-name>
./tdvirsh delete all
```

**Examples:**

```bash
# Delete specific TD
./tdvirsh delete tdvirsh-trust_domain-abc123-def456-...

# Delete all TDs
./tdvirsh delete all
```

**What Happens:**
1. Graceful shutdown requested (via `virsh shutdown`)
2. 5 second wait for clean shutdown
3. Force destroy if still running
4. Domain undefined from libvirt
5. Overlay volume deleted from storage pool
6. XML configuration file removed

**Output:**
```
Destroying domain tdvirsh-trust_domain-abc123...
Waiting for VM to shutdown ...
Removing overlay volume: overlay.AbC123XyZ456789.qcow2
Domain tdvirsh-trust_domain-abc123... destroyed successfully.
```

**Delete All Output:**
```
Cleaning all tdvirsh domains...
Destroying domain tdvirsh-trust_domain-abc123...
Waiting for VM to shutdown ...
Removing overlay volume: overlay.AbC123XyZ456789.qcow2
Domain tdvirsh-trust_domain-abc123... destroyed successfully.
Destroying domain tdvirsh-trust_domain-def456...
[...]
Checking for orphaned overlay volumes...
Cleanup complete.
```

---

### pool-info - Show Storage Pool Information

**Syntax:**
```bash
./tdvirsh pool-info
```

**Output:**
```
=== Storage Pool Information ===
Name:           tdvirsh-pool
UUID:           abc123-def456-...
State:          running
Persistent:     yes
Autostart:      yes
Capacity:       931.51 GiB
Allocation:     45.23 GiB
Available:      886.28 GiB

=== Available Volumes ===
 Name                                    Path
--------------------------------------------------------------------------------
 tdx-guest-ubuntu-24.04-generic.qcow2   /var/lib/libvirt/images/tdx-guest-ubuntu-24.04-generic.qcow2
 overlay.AbC123XyZ456789.qcow2          /var/lib/libvirt/images/overlay.AbC123XyZ456789.qcow2
 overlay.DeF456GhI012345.qcow2          /var/lib/libvirt/images/overlay.DeF456GhI012345.qcow2
```

**Use Cases:**
- Check pool status and capacity
- List all volumes (base images + overlays)
- Verify base image imported
- Monitor storage usage
- Troubleshoot pool issues

---

### pool-cleanup - Remove Orphaned Overlay Volumes

**Syntax:**
```bash
./tdvirsh pool-cleanup
```

**What It Does:**
- Scans storage pool for overlay volumes
- Checks if each overlay is used by any domain
- Removes overlays not used by any domain
- Reports count of removed volumes

**Output:**
```
Scanning for orphaned overlay volumes...
Found orphaned overlay: overlay.OldOne123.qcow2, removing...
Found orphaned overlay: overlay.OldTwo456.qcow2, removing...
Removed 2 orphaned overlay volume(s).
```

**When to Use:**
- After crashes or errors left orphaned overlays
- Periodic cleanup to reclaim space
- Before major maintenance
- When storage space is low

**Safety:**
- Only removes overlay.*.qcow2 files
- Never removes base images
- Checks all domains (running and stopped)

---

### Virsh Passthrough

**Any unrecognized command is passed to virsh:**

```bash
# Start a stopped TD
./tdvirsh start tdvirsh-trust_domain-abc123...

# Open console
./tdvirsh console tdvirsh-trust_domain-abc123...

# Show domain info
./tdvirsh dominfo tdvirsh-trust_domain-abc123...

# Take snapshot
./tdvirsh snapshot-create-as tdvirsh-trust_domain-abc123... snap1

# Any other virsh command
./tdvirsh <virsh-command> [args]
```

---

## Common Workflows

### Workflow 1: Create Multiple TDs

```bash
# Create first TD
./tdvirsh new
# Note the domain name from output

# Create second TD (shares same base image)
./tdvirsh new
# Gets its own overlay

# Create third TD
./tdvirsh new

# List all
./tdvirsh list
```

**Result:** 3 running TDs, each with its own overlay, all sharing the same base image.

---

### Workflow 2: Test and Cleanup

```bash
# Create test TD
./tdvirsh new

# Do testing...

# Check pool status
./tdvirsh pool-info

# Delete test TD
./tdvirsh delete tdvirsh-trust_domain-<uuid>

# Verify cleanup
./tdvirsh list
./tdvirsh pool-info
```

---

### Workflow 3: Batch Operations

```bash
# Create 5 TDs for testing
for i in {1..5}; do
    ./tdvirsh new
    echo "Created TD $i"
done

# List all
./tdvirsh list

# Delete all when done
./tdvirsh delete all
```

---

### Workflow 4: Custom Image Workflow

```bash
# Create custom image
cd image/
sudo ./create-td-image.sh -v 24.04 -u myuser -p mypass -o my-custom-image.qcow2

# Use custom image
cd ..
./tdvirsh new -i image/my-custom-image.qcow2

# Verify it was imported
./tdvirsh pool-info | grep my-custom-image
```

---

## GPU Passthrough

### Prerequisites

```bash
# Check for GPUs
lspci | grep NVIDIA

# Verify IOMMU enabled
dmesg | grep -i iommu

# Check VFIO modules
lsmod | grep vfio
```

### Finding GPU BDF Addresses

```bash
# List all GPUs with BDF addresses
lspci -nn | grep NVIDIA

# Example output:
# 0000:17:00.0 3D controller [0302]: NVIDIA Corporation Device [10de:20b5] (rev a1)
# 0000:65:00.0 3D controller [0302]: NVIDIA Corporation Device [10de:20b5] (rev a1)
#      ^^^^^^^^^
#      This is the BDF address
```

### Single GPU Passthrough

```bash
# Pass single GPU
./tdvirsh new -g 0000:17:00.0

# The script will:
# 1. Call setup-gpus.sh to prepare GPU
# 2. Unbind from host driver
# 3. Bind to vfio-pci
# 4. Set DMA entry limit
# 5. Generate hostdev XML
# 6. Attach to VM
```

### Multiple GPU Passthrough

```bash
# Pass multiple GPUs (comma-separated)
./tdvirsh new -g 0000:17:00.0,0000:65:00.0,0000:ca:00.0
```

### Verifying GPU in Guest

```bash
# SSH into TD
ssh -p <port> tdx@localhost

# Check for GPUs
lspci | grep NVIDIA

# Should see your GPU(s)
```

### GPU Passthrough Troubleshooting

**Issue:** GPU not visible in guest
```bash
# Check if setup script ran
sudo journalctl -xe | grep setup-gpus

# Verify GPU bound to vfio-pci
lspci -k -s 0000:17:00.0
# Should show: Kernel driver in use: vfio-pci

# Check domain XML includes hostdev
./tdvirsh dumpxml <domain> | grep hostdev
```

**Issue:** Invalid BDF format error
```bash
# BDF must be in format: 0000:00:00.0
# Valid:   0000:17:00.0
# Invalid: 17:00.0 (missing domain)
# Invalid: 0000:17:00.0. (trailing dot)
```

---

## Storage Pool Management

### Understanding Storage Pools

**What is a storage pool?**
- Libvirt managed storage location
- Contains base images and overlays
- Provides consistent API for volume operations
- Handles permissions automatically

**Pool Details:**
- **Name:** `tdvirsh-pool`
- **Type:** Directory pool
- **Path:** `/var/lib/libvirt/images`
- **Auto-created:** Yes (on first use)
- **Autostart:** Yes (survives reboots)

### Pool Lifecycle

**First Run:**
```bash
./tdvirsh new
# Pool doesn't exist
# → Pool created
# → Pool started
# → Pool set to autostart
# → Base image imported
# → Overlay created
# → VM started
```

**Subsequent Runs:**
```bash
./tdvirsh new
# Pool exists and is running
# → Pool refreshed
# → Base image already present
# → New overlay created
# → VM started
```

### Manual Pool Operations

```bash
# Check pool status
virsh pool-info tdvirsh-pool

# List volumes in pool
virsh vol-list tdvirsh-pool

# Get volume info
virsh vol-info --pool tdvirsh-pool <volume-name>

# Get volume path
virsh vol-path --pool tdvirsh-pool <volume-name>

# Delete volume manually (careful!)
virsh vol-delete --pool tdvirsh-pool <volume-name>

# Refresh pool (detect manual changes)
virsh pool-refresh tdvirsh-pool
```

### Backing Up Base Images

```bash
# List base images
./tdvirsh pool-info | grep -v overlay

# Copy base image out of pool
cp /var/lib/libvirt/images/tdx-guest-ubuntu-24.04-generic.qcow2 \
   /backup/location/

# Restore base image to pool
cp /backup/location/tdx-guest-ubuntu-24.04-generic.qcow2 \
   /var/lib/libvirt/images/
virsh pool-refresh tdvirsh-pool
```

### Space Management

```bash
# Check pool capacity
./tdvirsh pool-info | grep -E "Capacity|Allocation|Available"

# Check overlay sizes
cd /var/lib/libvirt/images
ls -lh overlay.*.qcow2

# Remove orphaned overlays
./tdvirsh pool-cleanup

# Delete old base images (manual)
# Be very careful!
virsh vol-list tdvirsh-pool
virsh vol-delete --pool tdvirsh-pool old-base-image.qcow2
```

---

## Troubleshooting

### Issue: "Permission denied" errors

**Cause:** User not in libvirt group

**Solution:**
```bash
# Add user to libvirt group
sudo usermod -aG libvirt $USER

# Logout and login again (or reboot)

# Verify
groups | grep libvirt
```

---

### Issue: Pool creation fails

**Symptom:**
```
ERROR: Failed to create storage pool
```

**Solutions:**

```bash
# Check if directory exists and is writable
ls -ld /var/lib/libvirt/images
sudo mkdir -p /var/lib/libvirt/images
sudo chown root:root /var/lib/libvirt/images
sudo chmod 755 /var/lib/libvirt/images

# Check libvirtd is running
sudo systemctl status libvirtd
sudo systemctl start libvirtd

# Try manual pool creation
virsh pool-define-as tdvirsh-pool dir --target /var/lib/libvirt/images
virsh pool-start tdvirsh-pool
```

---

### Issue: Base image import fails

**Symptom:**
```
ERROR: Base image not found at /path/to/image.qcow2
```

**Solutions:**

```bash
# Verify image exists
ls -l /path/to/image.qcow2

# Use absolute path
./tdvirsh new -i $(realpath /path/to/image.qcow2)

# Create image first
cd image/
sudo ./create-td-image.sh -v 24.04
cd ..
./tdvirsh new
```

---

### Issue: Overlay creation fails

**Symptom:**
```
ERROR: Failed to create overlay image in storage pool.
```

**Solutions:**

```bash
# Check pool is running
virsh pool-info tdvirsh-pool

# Refresh pool
virsh pool-refresh tdvirsh-pool

# Check base image in pool
virsh vol-list tdvirsh-pool | grep base-image-name

# Manual import
sudo cp /path/to/base.qcow2 /var/lib/libvirt/images/
virsh pool-refresh tdvirsh-pool

# Try again
./tdvirsh new
```

---

### Issue: GPU passthrough not working

**Symptom:**
GPU not visible in guest

**Solutions:**

```bash
# Check GPU BDF format
lspci | grep NVIDIA
# Use full format: 0000:17:00.0

# Verify IOMMU enabled
dmesg | grep -i iommu
# Should show IOMMU enabled messages

# Check setup script exists
ls -l ../gpu-cc/h100/setup-gpus.sh

# Manual GPU preparation
sudo ../gpu-cc/h100/setup-gpus.sh 0000:17:00.0

# Check vfio-pci binding
lspci -k -s 0000:17:00.0 | grep vfio

# Try again with sudo
sudo ./tdvirsh new -g 0000:17:00.0
```

---

### Issue: "No route to host" when SSHing

**Symptom:**
Cannot SSH to guest

**Solutions:**

```bash
# Check VM is running
./tdvirsh list

# Get connection info
./tdvirsh list | grep running

# Try direct IP instead of hostfwd
ssh tdx@<ip-address>

# Check network interface in guest
./tdvirsh console <domain>
# Login and run: ip addr

# Restart networking in guest
sudo systemctl restart networking

# Check libvirt network
virsh net-list
virsh net-info default
```

---

### Issue: Orphaned overlays after crash

**Symptom:**
Pool has overlays with no associated domains

**Solution:**
```bash
# List all volumes
./tdvirsh pool-info

# Clean up orphans
./tdvirsh pool-cleanup

# Should report removed volumes
```

---

### Issue: XML template not found

**Symptom:**
```
libvirt guest XML template not found at path '/path/to/template.xml'
```

**Solutions:**

```bash
# Use default template (don't specify -t)
./tdvirsh new

# Verify template exists
ls -l trust_domain.xml.template

# Use absolute path
./tdvirsh new -t $(realpath trust_domain.xml.template)
```

---

## Advanced Usage

### Custom XML Templates

**Create custom template:**

```bash
# Copy default template
cp trust_domain.xml.template my-custom-template.xml

# Edit as needed
nano my-custom-template.xml

# Use custom template
./tdvirsh new -t my-custom-template.xml
```

**Template Variables:**
- `BASE_IMG_PATH` - Replaced with base image path
- `DOMAIN` - Replaced with domain prefix
- `OVERLAY_IMG_PATH` - Replaced with overlay path
- `HOSTDEV_DEVICES` - Replaced with GPU XML (if GPUs specified)

---

### Configuration File

**Create/edit config file:**

```bash
# Create config at repository root
cd /path/to/tdx
nano setup-tdx-config

# Example content:
export GUEST_USER="admin"
export GUEST_PASSWORD="secure-password"
export GUEST_HOSTNAME="my-tdx-host"
export TDX_SETUP_INTEL_KERNEL="1"
```

**Config is automatically sourced by tdvirsh**

---

### Scripting with tdvirsh

**Example: Create and configure TD**

```bash
#!/bin/bash

# Create TD
DOMAIN=$(./tdvirsh new 2>&1 | grep "Name:" | awk '{print $2}')

# Wait for boot
sleep 30

# Get IP
IP=$(./tdvirsh list | grep "$DOMAIN" | grep -oP 'ip:\K[0-9.]+')

# Configure via SSH
ssh-keygen -f ~/.ssh/known_hosts -R "$IP"
sshpass -p "123456" ssh -o StrictHostKeyChecking=no tdx@$IP "
    sudo apt update
    sudo apt install -y nvidia-driver-535
    sudo reboot
"

echo "TD $DOMAIN created at $IP"
```

---

### Integration with Ansible

**Inventory generation:**

```bash
#!/bin/bash
# generate-inventory.sh

echo "[tdx_guests]"
./tdvirsh list | grep running | while read line; do
    IP=$(echo $line | grep -oP 'ip:\K[0-9.]+')
    NAME=$(echo $line | awk '{print $2}')
    echo "$NAME ansible_host=$IP ansible_user=tdx ansible_password=123456"
done
```

**Usage:**
```bash
./generate-inventory.sh > inventory.ini
ansible -i inventory.ini tdx_guests -m ping
```

---

## Best Practices

### Security

1. **Change default password immediately**
   ```bash
   ssh tdx@<ip>
   passwd
   ```

2. **Use SSH keys instead of passwords**
   ```bash
   ssh-copy-id tdx@<ip>
   ```

3. **Keep base images updated**
   ```bash
   cd image/
   sudo ./create-td-image.sh -v 24.04 -f  # Force recreate
   ```

4. **Limit GPU access**
   - Only attach GPUs that guest needs
   - Use IOMMU grouping properly

### Resource Management

1. **Monitor storage usage**
   ```bash
   ./tdvirsh pool-info
   ```

2. **Regular cleanup**
   ```bash
   # Weekly cleanup
   ./tdvirsh pool-cleanup
   ```

3. **Delete unused TDs promptly**
   ```bash
   ./tdvirsh delete <unused-domain>
   ```

### Operational

1. **Use descriptive naming**
   - Edit XML template to include project names
   - Keep track of domain UUIDs

2. **Document configurations**
   - Save custom templates with comments
   - Keep log of GPU assignments

3. **Test before production**
   - Create test TD first
   - Verify all functionality
   - Then create production TDs

4. **Backup regularly**
   - Backup base images
   - Backup custom templates
   - Document pool configuration

---

## FAQ

### Q: Can I use tdvirsh alongside original tdvirsh?

**A:** Yes! They use different pool names and can coexist. However:
- Original uses `/var/tmp/tdvirsh/`
- tdvirsh uses `/var/lib/libvirt/images`
- Domain names may conflict (both use `tdvirsh-` prefix)

---

### Q: Can I migrate VMs from original tdvirsh to tdvirsh?

**A:** Not directly. You need to:
1. Note the base image used
2. Delete VM with original tdvirsh
3. Recreate with tdvirsh using same image
4. VMs are ephemeral (overlay-based), data not preserved

---

### Q: What happens if I delete base image from pool?

**A:** All overlays using that base will break! Only delete base images if no overlays depend on them.

```bash
# Check what's using a base image
virsh vol-info --pool tdvirsh-pool base-image.qcow2

# Safer: keep all base images
```

---

### Q: Can I resize overlays?

**A:** Overlays inherit size from base image. To get larger disk:
1. Resize base image before import
2. Or resize base image in pool and recreate overlays

```bash
# Resize base image (in pool)
virsh vol-resize --pool tdvirsh-pool base-image.qcow2 200G

# Then create new VMs (old VMs unchanged)
```

---

### Q: How do I add more memory/CPUs to TD?

**A:** Edit XML template:

```xml
<!-- In trust_domain.xml.template -->
<memory unit='KiB'>32777216</memory>  <!-- 32GB instead of 16GB -->
<vcpu placement='static'>64</vcpu>   <!-- 64 vCPUs instead of 32 -->
```

Then create new TD with custom template.

---

### Q: Can I use different storage pool location?

**A:** Yes, edit the script:

```bash
# Change this line in tdvirsh
STORAGE_POOL_PATH="/var/lib/libvirt/images"

# To your preferred location
STORAGE_POOL_PATH="/my/custom/path"
```

Or manually create pool before running script.

---

### Q: Why use storage pools vs direct files?

**A:** Storage pools provide:
- Consistent API for all operations
- Automatic permission handling
- Better integration with libvirt tools
- Easier monitoring and management
- Standard libvirt best practice

---

### Q: Can I snapshot TDs?

**A:** Yes, using virsh commands:

```bash
# Create snapshot
./tdvirsh snapshot-create-as <domain> snap1

# List snapshots
./tdvirsh snapshot-list <domain>

# Revert to snapshot
./tdvirsh snapshot-revert <domain> snap1

# Delete snapshot
./tdvirsh snapshot-delete <domain> snap1
```

---

## Additional Resources

### Documentation
- [DEVELOPMENT_LOG.md](./DEVELOPMENT_LOG.md) - Complete development history
- [TDVIRSH_COMPARISON.md](./TDVIRSH_COMPARISON.md) - Version comparison
- [README.md](./README.md) - Documentation overview

### Libvirt Resources
- [Libvirt Storage Pools](https://libvirt.org/storage.html)
- [Libvirt Domain XML](https://libvirt.org/formatdomain.html)
- [VFIO GPU Passthrough](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)

### TDX Resources
- Intel TDX Documentation
- Ubuntu TDX Guide
- [Canonical TDX Repository](https://github.com/canonical/tdx)

---

## Getting Help

### Check Logs

```bash
# Libvirt logs
sudo journalctl -u libvirtd -f

# System logs
sudo journalctl -xe

# VM console
./tdvirsh console <domain>
```

### Debugging

```bash
# Verbose virsh
virsh -d 0 list --all

# Check pool status
virsh pool-info tdvirsh-pool

# Check domain XML
./tdvirsh dumpxml <domain>

# Check volume details
virsh vol-info --pool tdvirsh-pool <volume>
```

### Reporting Issues

When reporting issues, include:
1. Command that failed
2. Complete error message
3. Output of `pool-info`
4. Output of `virsh version`
5. Ubuntu version (`lsb_release -a`)
6. Relevant logs

---

**End of Usage Guide**
