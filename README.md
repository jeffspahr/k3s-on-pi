# k3s-on-pi
## Goal
Get a 3 node HA k3s cluster up and running on a set of Raspberry Pis

## Equipment
* 3 [Raspberry Pi 4 Model B/8GB](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/)
* 3 [Samsung 256GB EVO Plus SD Card](https://www.amazon.com/gp/product/B06XFS5657)

## Image
* Download the [Ubuntu 20.04.1 LTS 64 bit](https://ubuntu.com/download/raspberry-pi)
* Follow https://ubuntu.com/tutorials/create-an-ubuntu-image-for-a-raspberry-pi-on-macos#2-on-your-macos-machine

**WARNING - Be sure to pick the correct device.  This activity is destructive.**

```
$ diskutil list
/dev/disk0 (internal, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *500.3 GB   disk0
   1:                        EFI EFI                     314.6 MB   disk0s1
   2:                 Apple_APFS Container disk1         500.0 GB   disk0s2

/dev/disk1 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +500.0 GB   disk1
                                 Physical Store disk0s2
   1:                APFS Volume Macintosh HD - Data     50.4 GB    disk1s1
   2:                APFS Volume Preboot                 82.1 MB    disk1s2
   3:                APFS Volume Recovery                528.8 MB   disk1s3
   4:                APFS Volume VM                      5.4 GB     disk1s4
   5:                APFS Volume Macintosh HD            11.2 GB    disk1s5

/dev/disk2 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *256.1 GB   disk2
   1:               Windows_NTFS                         256.1 GB   disk2s1

/dev/disk3 (disk image):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        +52.5 MB    disk3
   1:                  Apple_HFS ESET Management Agent   52.4 MB    disk3s1
```
```
$ diskutil unmountDisk /dev/disk2
Unmount of all volumes on disk2 was successful
```

```
sudo sh -c 'gunzip -c ~/Downloads/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz | sudo dd of=/dev/disk2 bs=32m'
```

## Networking
I went out of my way to have the servers join the network automatically so I could avoid ever needing a keyboard and monitor.  I used [Netplan](https://netplan.io/) and a run once startup script to apply it on the first boot.

Mount the newly imaged Ubuntu root filesystem to add the netplan file and startup script.

Note: This is a pain on macOS since it doesn't support ext3/4 natively.  I ended up running an Ubuntu VM and passing through the USB device that had the SD card to be able to mount the filesystem.

[01-wifis-config.yaml](01-wifis-config.yaml)

`cp 01-wifis-config.yaml /sd-root-filesystem/etc/netplan/`
`chmod 644 /sd-root-filesystem/etc/netplan/01-wifis-config.yaml`

[netplan-apply.sh](netplan-apply.sh)

`cp netplan-apply.sh /sd-root-filesystem/etc/init.d/`
`chmod 755 /sd-root-filesystem/etc/init.d/netplan-apply.sh`

## Run Prereqs
First Run:

`ansible-playbook -bk -i inventory/k3s -u ubuntu playbooks/setup.yaml`

You can run as your user after the first run:

`ansible-playbook -b -i inventory/k3s playbooks/setup.yaml`

## Install k3s using k3sup

https://github.com/alexellis/k3sup

Run [k3s-bootstrap.sh](k3s-bootstrap.sh)

`echo "export KUBECONFIG=`pwd`/kubeconfig"`

`kubectl get nodes -o wide`

## Uninstall k3s
`ansible-playbook -b -i inventory/k3s playbooks/uninstall.yaml`
