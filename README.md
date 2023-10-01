Just following https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

iommu=pt added to kernel parameters

iommu_groups.sh copied

gpu 10de:2786
gpu audio 10de:22bc

packages:
Install qemu-desktop, libvirt, edk2-ovmf, and virt-manager

sudo virsh net-start default


w11 installation

tpm passthrough

isolate_cpu.sh

pipewire-jack
#qemu-audio-pa
modify user in /etc/libvirt/qemu.conf so it points to your USER
restart libvirtd service

sudo virsh domxml-to-native qemu-argv --xml win.xml

We care about vscsi, viostor (for normal drivers, not passthrough)

During OOBE later on, press win + x, open deivce manager and install netkvm drivers for the ethernet controller
