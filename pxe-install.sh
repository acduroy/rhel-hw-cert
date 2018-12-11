#! /bin/bash

clear
echo -e "\e[3J" 	#Clears scrollbar

printf "This script will create a PXE Boot Server on RHEL7 with DHCP/HTTP/FTP services enabled\n"
printf "****************************************************************************************\n"
printf "Make sure you already downloaded the RHEL7 SERVER DVD ISO image into the PXE server !!!\n"
printf "****************************************************************************************\n" 
printf "Do you want to contune? [Y/n]\n"; read YN
YN=$(echo $YN | awk '{print toupper($0)}')
if [[ $YN == "N" ]]
	printf "User prompted to exit the program ...\n"
	exit 1
fi
#Set a static IP address
clear
ifconfig -a 
echo "Set the static IP address of the PXE server: \n"; 
echo -n "What is the IP address to be set on PXE server? [ex. 10.100.252.5]: "; read IPADDR
echo -n "What's the NIC device name to be used, choose interfaces above? [ex. ens8]: "; read DEV
echo -n "What's the gateway server ip address? [ex. 10.100.252.1]: "; read GW  

#backup and edit the ifcnfg file:
local_ip_value=$(ifconfig $DEV|awk '/inet addr/ {split ($2,A,":"); print A[2]}')
DEV_CFG="ifcfg-$DEV"  
sudo cp /etc/sysconfig/network-scripts/$DEV /etc/sysconfig/network-scripts/$DEV_CFG.orig
echo "/etc/sysconfig/network-scripts/$DEV_CFG"
echo "-------------------------------------------------------"
#sed -ie 's/'$local_ip_value'/'$IPADDR'/' /etc/sysconfig/network-scripts/$DEV_CFG
#sed 's/'$local_ip_value'/'$IPADDR'/' /etc/sysconfig/network-scripts/$DEV_CFG

#Finding UUID of NIC device
UUID=$(uuidgen $DEV)

cat << CFG | sudo tee /etc/sysconfig/network-scripts/$DEV

TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=$DEV
UUID=$UUID
DEVICE=$DEV
ONBOOT=yes
IPADDR=$IPADDR
GATEWAY=$GW
DNS1=10.2.1.205 #IT domain-name-server
PREFIX=24
NM_CONTROLLED=no

CFG


#enable and start the NIC
printf "\n"
sudo ip addr flush $DEV
sudo ifup $DEV
sudo ifdown $DEV
sudo ifup $DEV
sudo chkconfig network on
ifconfig
printf "\n"

echo "Before installation to continue, pls make sure that the RHEL 7 dvd iso image was already downloaded !!!"
read -p "Press enter to continue ..."
printf "Downloading the dvd-iso-image using curl ...\n"

#ref: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-download-red-hat-enterprise-linux
curl -o rhel-server-7.6-x86_64-dvd.iso 'https://access.cdn.redhat.com//content/origin/files/sha256/85/85a...46c/rhel-server-7.6-x86_64-dvd.iso?_auth_=141...7bf -C -
mv rhel*.iso ~/Downloads/
clear

printf "Copy the full Red Hat Enterprise Linux 7 binary DVD ISO image to the PXE server\"
printf "Mount the RHEL7 Server DVD ISO image ...\n"
echo -n "Specify the full directory path that the OS image is located ?[ex. /home/certuser/Downloads]: "; read IMD
echo -n "Where do you want to mount the OS image ?[ex. rhel7-install]: "; read MP 
sudo mkdir /mnt/$MP/
sudo mount -o loop,ro -t iso9660 /<IMD>/<rhel-server-7.5-x86_64-dvd.iso> /$MP/

# Preparing Installation Sources Using HTTP or HTTPs:
# 1. Copy the full Red Hat Enterprise Linux 7 binary DVD ISO image to the HTTP(S) server. 
# 2. Mount the binary DVD ISO image, using the mount command, to a suitable directory. The ff command should execute root CLI: 
	$ sudo mkdir /mnt/rhel7.6-install/
	$ sudo mount -o loop,ro -t iso9660 /<image_directory>/<image.iso> /<mount_point>/
# 3. Install the httpd package by running the following command as root:
        $ su -
        # cd /mnt/rhel7-install/Packages
	# rpm -ivh httpd-2.4.6-80.el7.x86_64.rpm	 
# 4. Copy the files from the mounted image to the HTTP server root. 
	# cp -r /mnt/rhel7-install/ /var/www/html/
# 5. Start the httpd service: 
	# systemctl start httpd.service
        # systemctl status httpd.service 
	# firewall-cmd --permanent --add-service=http

# Kickstart Installation of RHEL7 using ftp
# Step 1. Create a kickstart file using the following methods
# a).Perform a manual installation on one system first. After the installation completes, 
# copy a file named anaconda-ks.cfg located in the /root/ directory on the installed system
# and this file will be the kickstart to be used for the entire automated installation.
	$ su -
	# cp anaconda-ks.cfg ks.cfg
	# chmod 755 ks.cfg  #make the file executable
# b).Or if you have Red Hat Customer Portal account, you can use Kickstart Configuration Tool to create your kickstart file. 
# To install the graphical tool at the system:
	$ sudo rpm -ivh /mnt/rhel7-install/Packages/system-config-kickstart<tab>
	$ system-config-kickstart  # to run kickstart tool
# c). Or download the kickstart file using curl
        $ curl https://raw.githubusercontent.com/acduroy/working-scripts/master/hwcert.cfg > hwcert.cfg
        $ chmod 755 hwcert.cfg 

# Step 2. Verify if kickstart file is valid using ksvalidator command line utility before attempting to use in the installation
# To install this package:
	$ su -
	# rpm -ivh /mnt/rhel7-install/Packages/pykickstart<tab>
# After installing the package, you can validate a kickstart file using the ff. command
	$ ksvalidator hwcert.cfg

# Step 3. create tftp server, where kickstart file is stored
	$ sudo rpm -ivh /mnt/rhel7.6-install/Packages/vsftpd<tab>
	$ sudo systemctl start vsftpd.service
	$ sudo systemctl enable vsftpd.service
	$ sudo systemctl status vsftpd 	#check if vsftpd service is enabled
	$ sudo mkdir -p /var/ftp/pub/rhel7
	$ sudo cp -rf /home/certuser/Downloads/kickstart<tab>/hwcert.cfg /var/ftp/pub/rhel7
	$ sudo firewall-cmd --permanent --add-service=ftp
# Step 4. install other packages
        $ sudo rpm -ivh /mnt/rhel7.6-install/Packages/deltarpm<tab>
	$ sudo rpm -ivh /mnt/rhel7.6-install/Packages/python-delta<tab>
	$ sudo rpm -ivh /mnt/rhel7.6-install/Packages/createrepo<tab>
# Step 5. disable iptables if not turn-off yet and set the environment to permissive
	$ sudo service iptables stop
	sample output:
	"Failed to stop iptables.service: Unit iptables.service not loaded"
	$ sudo chkconfig iptables off
	sample output:
	"error reading information on service iptables: No such file or directory"
	$ sudo getenforce #output: "Enforcing"
	$ sudo setenforce 0
        $ sudo getenforce #output: "Permissive"

# Step 6. make a directory /var/ftp/pub/rhel7/dvd to store the dvd iso image
	$ sudo mkdir -p /var/ftp/pub/rhel7/dvd
	$ sudo cp -rvf /mnt/rhel7.6-install/* /var/ftp/pub/rhel7/dvd/

# Step 7.  create yum.repo file under directory /etc/yum.repos.d/ and insert the ff lines into the file.
	$ sudo touch /etc/yum.repos.d/yum.repo
	$ sudo cat << YUM_CFG | sudo tee /etc/yum.repos.d/yum.repo
          
          [PXE]
	  name=PXE_server
	  baseurl=file:///var/ftp/pub/rhel7/dvd
          enabled=1
          gpgcheck=0
         
	  [RHCERT]
          name=rhcert
	  baseurl=file:///var/ftp/pub/rhel7/rhcert-6.2-packages
	  enabled=1
	  gpgcheck=0

	  [DEBUG_KERNEL]
	  name=rhel7-x86_64-debug           
	  baseurl=file:///var/ftp/pub/rhel7/debug-kernel-packages
	  enabled=1
	  gpgcheck=0

	  YUM_CFG

	$ cd /var/ftp/pub/rhel7/dvd/repodata/
        $ ls
	$ sudo cp *comps-Server.x86_64.xml  /var/ftp/pub/rhel7/dvd/groups-comps-Server.xml
	$ sudo createrepo -vg /var/ftp/pub/rhel7/dvd/groups-comps-Server.xml /var/ftp/pub/rhel7/dvd/
 	$ yum list all
	$ yum grouplist
	$ sudo rm -rf /var/cache/yum/*
	$ yum clean all
	$ subscription-manager clean
	$ cd

# Step 8. create a soft link of /var/ftp/pub/ into /var/www/html/
	$ sudo ln -s /var/ftp/pub/ /var/www/html/
 	$ sudo service vsftpd restart
	$ sudo chkconfig vsftpd on
	$ sudo service httpd restart
	$ sudo chkconfig httpd on
# Step 9. fix SELinux security context by using restorecon command
	$ sudo restorecon -R /var/www/html/
	$ sudo restorecon -R /var/ftp/pub/
# Step 10. Install syslinux and xinetd service
	$ ll /mnt/rhel7.6-install/Packages/syslinux*
Sample output:
-r--r--r--. 1 root root 1014340 Sep 25 06:29 /mnt/rhel7.6-install/Packages/syslinux-4.05-15.el7.x86_64.rpm

-r--r--r--. 1 root root  372556 Sep 25 06:29 /mnt/rhel7.6-install/Packages/syslinux-extlinux-4.05-15.el7.x86_64.rpm

-r--r--r--. 1 root root  440076 Sep 25 06:29 /mnt/rhel7.6-install/Packages/syslinux-tftpboot-4.05-15.el7.noarch.rpm


#select the syslinux that proceeds with number:
	$ sudo rpm -ivh /mnt/rhel7.6-install/Packages/syslinux-4.05-15.el7.x86_64.rpm

	$ sudo rpm -ivh /mnt/rhel7.6-install/Packages/xinetd<tab>
        $ sudo rpm -ivh /mnt/rhel7.6-install/Packages/tftp-server<tab>
# Step 11. Create "pxelinux.cfg" directory into the /var/lib/tftpboot/ and copy "pxelinux.0" from /usr/share/syslinux/pxelinux.0 to /var/lib/tftpboot/
	$ sudo mkdir /var/lib/tftpboot/pxelinux.cfg
	$ sudo cp /usr/share/syslinux/pxelinux.0  /var/lib/tftpboot/
# Step 12. edit /etc/xinetd.d/tftp
	$ cd /etc/xinetd.d/
	$ sudo cp tftp tftp.org
	$ sed '/disable\>/s/\<yes\>/no/' /etc/xinetd.d/tftp

# Use the reference about using sed command 
# https://unix.stackexchange.com/questions/405840/why-cant-i-grep-this-way
# ------------------------------
#The spaces are more commonly known as "whitespace", and can include not just spaces but tabs (and other "blank" characters). 
#In a regular expression you can often refer to these either with [[:space:]] or \s (depending on the RE engine) which includes 
#both horizontal (space, tab and some unicode spacing characters of various width if available) for which you can also use [[:blank:]] 
#and sometimes \h and vertical spacing characters (like line feed, form feed, vertical tab or carriage return). [[:space:]] is sometimes 
#used in place of [[:blank:]] for its covering of the spurious carriage return character in Microsoft text files.
#
#You cannot replace with grep - it's just a searching tool. Instead, to replace the yes with no you can use a command like this:
#
# sed '/disable\>/s/\<yes\>/no/' /etc/xinetd.d/tftp
#This tells sed to substitute (change) the word yes into no on any line that contains the word disable. (The \> (initially a ex/vi regexp 
#operator), in some sed implementations, forces an end-of-word (though beware it's not whitespace-delimited-words, it would also match on 
#disable-option)). Conveniently this sidesteps the issue of whitespace altogether.
#
#Be careful: with a line such as eyes yes, an unbounded yes substitution would apply to the first instance of yes and leave you with eno yes. 
#That's why I have used \<yes\> instead of just yes.
# ------------------------------

# Step 13. Extended steps to install packages and debug kernel:
# Create a directory for kernel and hwcert packages under folder /var/ftp/pub/rhel7 
	$ sudo mkdir -p /var/ftp/pub/rhel7/rhcert-6.2-packages/

	$ sudo mkdir -p /var/ftp/pub/rhel7/debug-kernel-packages/

# Step 14. Copy packages and kernel 
	$ sudo cp -rvf ~/Downloads/packages-6.2/* /var/ftp/pub/rhel7/rhcert-6.2-packages/
	$ sudo cp -rvf ~/Downloads/kernel-3.10.957/* /var/ftp/pub/rhel7/debug-kernel-packages/ 
# Step 15. create a repositories for hwcert and kernel packages
	$ sudo createrepo /var/ftp/pub/rhel7/rhcert-6.2-packages/
	$ sudo createrepo /var/ftp/pub/rhel7/debug-kernel-packages/ 
# Step 16. After install of syslinux xinetd and tftp, create a "pxelinux.cfg" directory under folder /var/lib/tftpboot/
	$ sudo mkdir -p /var/lib/tftpboot/pxelinux.cfg/
# Step 17. Copy the vmlinuz and initrd.img files from /var/ftp/pub/dvd/images/pxeboot/ to /var/lib/tftpboot/ 
	$ sudo cp -rf /var/ftp/pub/rhel7/dvd/images/pxeboot/vmlinuz /var/lib/tftpboot/
	$ sudo cp -rf /var/ftp/pub/rhel7/dvd/images/pxeboot/initrd.img /var/lib/tftpboot/
# Step 18. Copy all files from /var/ftp/pub/rhel7/dvd/isolinux/ to /var/lib/tftpboot/ excluding "vmlinuz" and "initrd.img" files
	$ sudo shopt -s extglob
	$ sudo cp !(/var/ftp/pub/rhel7/dvd/isolinux/vmlinuz|/var/ftp/pub/rhel7/dvd/isolinux/initrd.img) /var/lib/tftpboot/
# 	or
	$ sudo cp !(vmlinuz|initrd.img) /var/lib/tftpboot/
# --------------------
# Reference to copy selected files using bash
# Note: item #4 works and it was used in this script

# 1. https://stackoverflow.com/questions/24206349/copy-multiple-files-from-one-directory-to-another-from-linux-shell
#  	$ cp /home/ankur/folder/{file1,file2} /home/ankur/dest 
# 2. https://stackoverflow.com/questions/670460/move-all-files-except-one
# If you use bash and have the extglob shell option set (which is usually the case):
# 	$ cp ~/Linux/Old/!(Tux.png) ~/Linux/New/
# 3. https://www.tecmint.com/delete-all-files-in-directory-except-one-few-file-extensions/
#	$  sudo shopt -s extglob
# 	$  rm -v !("filename1"|"filename2")
# 	You can later disable extglob with
#	$ shopt -u extglob
# 4. https://www.unix.com/shell-programming-and-scripting/84310-copy-everything-except-2-files.html 
# 	$ cp !(foo|bar) /my/destination/dir
# --------------------

# Step 19. Create a boot menu at /var/lib/tftpboot/pxelinux.cfg/default
	sudo touch /var/lib/tftpboot/pxelinux.cfg/default
	sudo cat << BOOT_CFG | sudo tee /var/lib/tftpboot/pxelinux.cfg/default
	
	default vesamenu.c32
	# prompt 1
	timeout 600
	display boot.msg
	
	menu background splash.png
	menu title Welcome to the RHEL 7.6 PXE Installation
	label local
	menu label boot from "Local Drive"
	menu default
	localboot 0xffff

	label ws
	menu label Unattended Installation of RHEL 7.6 ^Workstation
	kernel vmlinuz
	append biosdevname=0 ksdevice=link load_ramdisk=1 initrd=initrd.img network ks=http://10.100.204.5/pub/rhel7/hwcert.cfg moipv6

	label si
	menu label Standard Installation of RHEL 7.6 
	kernel vmlinuz
	append biosdevname=0 ksdevice=link load_ramdisk=1 initrd=initrd.img 

	BOOT_CFG

# Step 20. Install dhcp server. 
	$ ll /var/ftp/pub/rhel7/dvd/Packages/dhcp-*
	Sample output:
	-r--r--r--. 1 root root 525620 Dec  8 15:56 dhcp-4.2.5-68.el7_5.1.x86_64.rpm

	-r--r--r--. 1 root root 178972 Dec  8 15:56 dhcp-common-4.2.5-68.el7_5.1.x86_64.rpm

	-r--r--r--. 1 root root 134160 Dec  8 15:56 dhcp-libs-4.2.5-68.el7_5.1.i686.rpm

	-r--r--r--. 1 root root 134576 Dec  8 15:56 dhcp-libs-4.2.5-68.el7_5.1.x86_64.rpm

	
	# Select the dhcp- that proceeds with a number immediately
	$ sudo rpm -ivh /var/ftp/pub/rhel7/dvd/Packages/dhcp-4.2.5-68.el7_5.1.x86_64.rpm

# Step 21. Copy /usr/share/doc/dhcp-*/dhcpd.conf.example /etc/dhcp/dhcpd.conf
	$ sudo cp -rvf /usr/share/doc/dhcp-4.2.5/dhcpd.conf.example /etc/dhcp/dhcpd.conf 
# Step 22. Edit the file /etc/dhcp/dhcpd.conf
	sudo cat << CFG | sudo tee /etc/dhcp/dhcpd.conf

# Optional Steps to take:
# 1. If need to add username to the sudoer's file, use below command
	$ su -
	$ visudo
	## add the ff lines to the file
        ## <username>  ALL=(ALL)  ALLS

# Step optional #2. If need to modify the hostname, perform the ff command
	$ sudo hostnamectl set-hostname  <desired_name>  
	   

# Insert the media where the DVD iso image of the RHEL7 installation located
# Once, the installation boot menu appeared, press the tab key. Enter at command line:
	ks=ftp://<ip_address_ftp_server>/pub/ks.cfg


 


