# How to install teamviewer on Red Hat 7 using yum
#1. Switch to the root user
su - 

#2. Enable EPEL repository on the server. Install EPEL repository:
#Ref: https://www.itzgeek.com/how-tos/linux/centos-how-tos/enable-epel-repository-for-centos-7-rhel-7.html
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#Output:
#etrieving http://mirror.pnl.gov/epel/7/x86_64/e/epel-release-latest-7.noarch.rpm
#warning: /var/tmp/rpm-tmp.iPpiIE: Header V3 RSA/SHA256 Signature, key ID 352c64e5: NOKEY
#Preparing...                          ################################# [100%]
#Updating / installing...
#1:epel-release-latest-7.noarch.rpm               ################################# [100%]

#List the installed repo’s:
yum repolist

#Output:
#Loaded plugins: fastestmirror
#Loading mirror speeds from cached hostfile
#* base: centos.excellmedia.net
#* epel: epel.mirror.net.in
#* extras: centos.excellmedia.net
#* updates: centos.excellmedia.net
#repo id               repo name                                           status
#base/7/x86_64         CentOS-7 - Base                                     8,465
#epel/x86_64           Extra Packages for Enterprise Linux 7 - x86_64      4,731
#extras/7/x86_64       CentOS-7 - Extras                                      30
#updates/7/x86_64      CentOS-7 - Updates                                    326
#repolist: 13,552

#List the EPEL packages:
yum --disablerepo=* --enablerepo=epel list

#Output:
#zathura-devel.x86_64                     0.2.7-2.el7                        epel
#zathura-djvu.x86_64                      0.2.3-5.el7                        epel
#zathura-pdf-poppler.x86_64               0.2.5-2.el7                        epel
#zathura-plugins-all.x86_64               0.2.7-2.el7                        epel
#zathura-ps.x86_64                        0.2.2-4.el7                        epel
#zeromq3.x86_64                           3.2.4-1.el7                        epel
#zeromq3-devel.x86_64                     3.2.4-1.el7                        epel
#zipios++.x86_64                          0.1.5.9-9.el7                      epel
#zipios++-devel.x86_64                    0.1.5.9-9.el7                      epel
#zlib-ada.x86_64                          1.4-0.5.20120830CVS.el7            epel
#zlib-ada-devel.x86_64                    1.4-0.5.20120830CVS.el7            epel
#zmap.x86_64                              1.2.0-1.el7                        epel
#zsh-lovers.noarch                        0.9.0-1.el7                        epel


#Install the package:
yum install zmap


#Install the wget package.
yum -y install wget

# Download the latest version of TeamViewer (v13 at the time of writing).
wget https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm

# Install the TeamViewer using the yum command.
yum -y install teamviewer.x86_64.rpm

#Start TeamViewer
teamviewer
