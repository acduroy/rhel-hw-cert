## Prerequisite:
## 1. System already installed with RHEL 7.5 OS
## 2. Under folder /root, rename the file 'anaconda-ks.cfg' with 'ks.cfg'
## 3. Install syslinux into the system and download RHEL7.5 DVD.iso image at /tmp directory
## 4. Prepare the USB to be used as installation boot media
## 5. Check the device handle of your USB using the ff. commands
dmesg
lsscsi

echo -n "Input your USB device handle [ex. /dev/sdX]: "; read DEV

## In this example, the USB device name is '/dev/sdb'
## Create two partitions on /dev/sdb
## One of type W95 FAT32 (LBA) of ~250MB, make this partition bootable. 
## and the other type an ext4 partition for the remaining spaces.

sudo parted --script $DEV mklabel msdos mkpart primary fat32  1954 488282 set 1 boot on
sudo parted --script $DEV mkpart primary ext4 488283 62400000

## Format partitons
sudo mkfs -t vfat -n "BOOT" /dev/sdb1
sudo mkfs -L "DATA" /dev/sdb2'

## Write MBR data to the USB device
sudo dd conv=notrunc bs=440 count=1 if=/usr/share/syslinux/mbr.bin of=/dev/sdb

## Install syslinux to first parition
sudo syslinux /dev/sdb1

## Copy files to USB
mkdir BOOT && sudo mount /dev/sdb1 BOOT
mkdir DATA && sudo mount /dev/sdb2 DATA
mkdir DVD && sudo mount /tmp/rhel-server-7.5-x86_64-dvd.iso DVD

## Copy DVD isolinux to BOOT
sudo cp -r ./DVD/isolinux ./BOOT/

## Rename isolinux.cfg to syslinux.cfg
sudo mv BOOT/isolinux/isolinux.cfg BOOT/isolinux/syslinux.cfg

## Copy kickstart file from /root to the BOOT/isolinux directory
sudo cp  /root/ks.cfg ./BOOT/isolinux/

## Copy BOOT/ldlinux.sys file to BOOT/isolinux/ directory
cp BOOT/ldlinux.sys BOOT/isolinux/


## Get the Volume id of the DVD.iso image
isoinfo -d -i /tmp/rhel-server-7.5-x86_64-dvd.iso |grep -i "Volume id" | sed -e 's/Volume id: //' -e 's/ /\\x20/g'

## Sample output below:
## RHEL-7.5\x20Server.x86_64 <- copy this name 

## Edit the syslinux.cfg same look as shown below
#label linux                                                                     
#  menu label ^Install CentOS 7                                                  
#  kernel vmlinuz                                                                
#  append initrd=initrd.img inst.stage2=hd:LABEL=DATA:\RHEL-7.5\x20Server.x86_64 quiet inst.ks=hd:LABEL=BOOT:/isolinux/ks.cfg


## Unmount all devices
umount BOOT/
umount DATA/
umount DVD/