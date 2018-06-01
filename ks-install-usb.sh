# First mount the original .iso image on your pc, and copy its contents under tmp/
# Keep the original file

cp -ai tmp/isolinux/initrd.img initrd.img.orig
mkdir irmod
cd irmod

#Extract initrd in irmod/
xz -d < ../tmp/isolinux/initrd.img | cpio --extract --make-directories --no-absolute-filenames

#Add the ks.cfg in there
cp ../tmp/ks.cfg .

# Recreate the initrd.img inside isolinux/
find . | cpio -H newc --create | xz --format=lzma --compress --stdout > ../tmp/isolinux/initrd.img

#cleanup
cd ..
rm -r irmod

# Add  ks=file:/ks.cfg to the boot parameters in isolinux.cfg. you can do it by hand, this is an example for our own isolinux.cfg
sed -s -i 's|ks=.*ks\.cfg ksdevice=link|ks=file:/k1.cfg|' ../tmp/isolinux/isolinux.cfg ../isolinux.cfg


# Then proceed with creating the image as usual:
cd tmp/

imgname="inaccess-centos7-ks1-v1.iso"
xorriso -as mkisofs -R -J -V "CentOS 7 x86_64" -o "../${imgname}" \
        -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4  \
        -boot-info-table -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin .
cd ..
