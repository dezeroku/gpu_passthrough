# GPU passthrough

A collection of notes and scripts for passing through GPU to a VM.
This is done mostly with Windows in mind.

Mostly just following [Arch Wiki on the topic](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF),
with a bash wrapper here and there.

## What can be achieved with this repo

With scripts available here it's possible to:

- create the VM from XML config parametrized with `scripts/values.sh`
- detect changes between the "live" VM and XML config
- apply the above if desired, so the XML config overrides the "live" VM (git is the single source of truth)
- perform automatic pre/post tasks for the vm:
  - start the virtual network
  - isolate the GPU / load the drivers back after VM shutdown
  - isolate the CPUs from host
  - run custom user scripts

## Usual workflow

Go through the steps listed in [Host configuration](#host-configuration)

First after cloning you'll want to modify the values in `scripts/values.sh`.
This is required, as all the hardware setups are different.
What's configurable there:

- GPU IDs required for passthrough
- GPU drivers for loading them back after the VM is shut down
- how much memory the VM gets
- VM name
- audio passthrough [options](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_audio_from_virtual_machine_to_host_via_JACK_and_PipeWire) (input and output devices, latency)
- input mouse and keyboard (correct device IDs must be provided)
- physical disks pass-through (limited, at the moment it's hardcoded to two drives)

Notable things that you CAN NOT set through the values file and require manual intervention (editing XML directly) are at the moment:

- CPU pinning (that's one of the most important things to do, don't overlook it)

Then run `scripts/setup` to create a VM.

Then run `scripts/start` to actually start it.
On the VM shutdown the script will automatically perform the cleanup and finish execution.

## XML configuration

The `xmls` directory contains common configurations.

Common requirements for these are:

- `ISOs/virtio-win.iso` obtainable via `scripts/setup`
- `ISOs/windows.iso` that you have to obtain yourself, the recommended way is to download directly from Microsoft.
  The version used for testing was `Win11_22H2_English_x64v2.iso`, but it should work fine with other releases too

## Scripts

These are present in the `scripts` directory and rely on `scripts/values.sh` content to be properly filled.
Look at the file contents for further instructions.

- `iommu_groups` (copied over from Arch Wiki) for listing IOMMU groups
- `setup` for getting the required ISOs and setting up the VM
- `start` for automation of the binding, isolating, VM startup, etc.
- `isolate_gpu` small scriptlet for binding GPU to `vfio-pci` driver
- `unisolate_gpu` small scriptlet for binding GPU to its defined driver

## Host configuration

The configuration is AMD Ryzen 3600 + RTX 4070, thus the instructions for IOMMU will be AMD specific (you may need more
parameters for Intel, check the Wiki).

### Kernel parameters

- `iommu=pt`, to prevent Linux from touching device that can't be passed through

### Isolate the gpu on early boot level

#### /etc/modprobe.d/vfio.conf

```
options vfio-pci ids=10de:2786,10de:22bcs
```

#### /etc/mkinitcpio.conf

```
MODULES=(vfio_pci vfio vfio_iommu_type1)
```

#### And finally regenerate the initramfs

```
sudo mkinitcpio -P
```

### Installed packages

The list may be inconclusive, as the packages from `virtualization` group from [arch_ansible](https://github.com/dezeroku/arch_ansible) are also installed.

- qemu-desktop
- libvirt
- edk2-ovmf
- virt-manager

### Audio passthrough back to host (Pipewire + JACK)

- modify `user` line in `/etc/libvirt/qemu.conf` so it points to your USER
- restart libvirtd service

### Drivers required during Windows installation

These must be installed from `virtio` ISO (obtainable with `setup.sh` to perform the installation.

Storage drivers `viostor` and `vioscsi` must be loaded at the early stage of the installation.

Network driver `netkvm` must be installed later on, when Windows tries to connect to network.
At this stage you can press `Shift + F10` to get the cmd, which will allow you to press `win + e` and open
the mounted ISO as CD drive. Then run the installer as usual. Alternatively press `Shift + x` to open the device manager
and work from there.
