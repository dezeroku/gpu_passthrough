# GPU passthrough

A collection of notes and scripts for passing through GPU to a VM.
This is done mostly with Windows in mind.

Mostly just following [Arch Wiki on the topic](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF),
with a wrapper here and there.

The configuration is Ryzen 3600 + RTX 4070, thus the instructions for IOMMU will be AMD specific (you may need more
parameters for Intel, check the Wiki).

## Kernel parameters

- `iommu=pt`, to prevent Linux from touching device that can't be passed through

## Isolate the gpu on early boot level

### /etc/modprobe.d/vfio.conf

```
options vfio-pci ids=10de:2786,10de:22bcs
```

### /etc/mkinitcpio.conf

```
MODULES=(vfio_pci vfio vfio_iommu_type1)
```

### And finally regenerate the initramfs

```
sudo mkinitcpio -P
```

## Installed packages

The list may be inconclusive, as the packages from `virtualization` group from [arch_ansible](https://github.com/dezeroku/arch_ansible) are also installed.

- qemu-desktop
- libvirt
- edk2-ovmf
- virt-manager

## Audio passthrough back to host (Pipewire + JACK)

- modify `user` line in `/etc/libvirt/qemu.conf` so it points to your USER
- restart libvirtd service

## Drivers required during Windows installation

These must be installed from `virtio` ISO (obtainable with `setup.sh` to perform the installation.

Storage drivers `viostor` and `vioscsi` must be loaded at the early stage of the installation.

Network driver `netkvm` must be installed later on, when Windows tries to connect to network.
At this stage you can press `Shift + F10` to get the cmd, which will allow you to press `win + e` and open
the mounted ISO as CD drive. Then run the installer as usual. Alternatively press `Shift + x` to open the device manager
and work from there.

## Scripts

These are present in `scripts` directory

- `iommu_groups` (copied over from Arch Wiki) for listing IOMMU groups
- `setup` for getting the required ISOs
- `start` (requires manual configuration) for automation of the binding, isolating, etc.

## XML configuration

The `xmls` directory contains common configurations.

Common requirements for these are:

- `ISOs/virtio-win.iso` obtainable via `scripts/setup`
- `ISOs/windows.iso` that you have to obtain yourself, the recommended way is to download directly from Microsoft.
  The version used for testing was `Win11_22H2_English_x64v2.iso`, but it should work fine with other releases too
