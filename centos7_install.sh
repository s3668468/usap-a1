!/bin/bash

cd;

echo "Cache";
yum makecache;
yum install -y yum-utils dnf make nano;

echo "Installing wget";
yum install -y wget;

echo "Installing man support pages";
yum install -y man man-pages;

echo "Installing clang and clang extras";
yum install -y gcc gcc-c++ clang;

echo "Installing vim"
yum install -y vim;

echo "Installing nginx"
#Add a repository. Source: <https://wiki.centos.org/action/show/SpecialInterestGroup/AltArch/armhfp>
cat > /etc/yum.repos.d/epel.repo << EOF
[epel]
name=Epel rebuild for armhfp
baseurl=https://armv7.dev.centos.org/repodir/epel-pass-1/
enabled=1
gpgcheck=0

EOF
yum install -y nginx;

echo "Installing git"
yum install -y git;

echo "Installing nmap"
yum install -y nmap;

echo "Installing Berryconda";
yum install -y bzip2;
wget -N https://github.com/jjhelmus/berryconda/releases/download/v2.0.0/Berryconda3-2.0.0-Linux-armv7l.sh;
chmod +x Berryconda3-2.0.0-Linux-armv7l.sh;
./Berryconda3-2.0.0-Linux-armv7l.sh -b -p /opt/berryconda3;
#MAKE SURE TO DECLARE PATH OR SYMBOLIC LINK
ln -s /opt/berryconda3/bin/conda /usr/local/bin/conda;

echo "Install RR - Reverse and Replay";
#This software cannot be installed due to it not being supproted on ARM architecture. Source: <https://github.com/mozilla/rr>

echo "Install sshd";
yum install -y openssh-server openssh-clients;

echo "Installing zsh";
yum install -y ncurses-devel make;
wget -N https://sourceforge.net/projects/zsh/files/zsh/5.8/zsh-5.8.tar.xz;
tar xf zsh-5.8.tar.xz -v;
cd zsh*;
./configure;
make install;
ln -s /usr/local/bin/zsh /bin/zsh;
cd;

echo "INSTALLATION SCRIPT COMPLETE";
echo "NOTE: If something breaks, please refer to the script and enter the commands manually";