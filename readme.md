# USAP Assignment 1

s3668468 Cameron Tavelli

## Set up environment

xUbuntu (A linux distribution) is already installed on my system and the following steps are for linux users

### Install TigerVNC and NMAP

1. Update the system repos
   1. `sudo apt update -y`
2. Install TigerVNC
   1. `sudo apt install tigervnc-*`
   2. *Enter Yes*
   3. **SCREENSHOT**
3. Install NMAP
   1. `sudo apt install nmap`
   2. *Enter Yes*
   3. **SCREENSHOT**

## Install Raspberry Pi OS

<https://www.raspberrypi.org/downloads/raspberry-pi-os/>

1. Insert micro SD card reader with SD card into the system
   1. **SCREENSHOT**
2. Download Raspberry Pi OS (32-bit) with desktop and recommended software image from the Raspberry Pi website  

3. Extract the .zip
    1. `unzip 2020-08-20-raspios-buster-armhf-full.zip`
4. Unmount partitions
    1. `lsblk -p`
    2. `sudo unmount -f /dev/sdb1`
    3. **SCREENSHOT**
5. Write the Raspberry Pi image onto the SD Card
    1. `sudo dd if=2020-08-20-raspios-buster-armhf-full.img of=/dev/sdb bs=4M status=progress`
    2. **SCREENSHOT**
6. Insert the SD Card into the Raspberry Pi
7. Run the configurator on the device and enable SSH
8. Use nmap to verify the IP of the Raspberry Pi
    1. `nmap -sn 192.168.0.0/24`
    2. **SCREENSHOT**
9. SSH into the Raspberry Pi
    1. `ssh pi@192.168.x.x`
    2. **SCREENSHOT**
    3. Update the system: `sudo apt update -y && sudo apt upgrade -y`
10. Uninstall RealVNC and install TigerVNC
    1. `sudo apt remove realvnc-*`
    2. `sudo apt install -y tigervnc-standalone-server`
11. Create a service to run the VNC Server
    1. `sudo nano /etc/systemd/system/vncserver@.service`  

      ```bash
      [Unit]
      Description=Remote Desktop Service (VNC)
      After=syslog.target network.target

      [Service]
      Type=forking
      User=pi
      WorkingDirectory=/home/pi
      ExecStart=/usr/bin/tigervncserver %i -geometry 1440x900 -alwaysshared -localhost no
      ExecStop=/usr/bin/tigervncserver -kill %i

      [Install]
      WantedBy=multi-user.target
      ```

12. Start the VNC Server on the Pi and enable it to start on boot
    1. `tigervncserver`
        1. *Enter a password*
        2. *Verify password*
        3. *No*
    2. `sudo systemctl enable vncserver@:1`
    3. `sudo systemctl restart vncserver@:1`
13. Connect to the Raspberry Pi from a client machine
    1. `vncviewer raspberrypi.local:1`
    2. **SCREENSHOT**

### Setting up a RAID configuration

1. Prepare two identical USB drives
2. Insert a USB drive into the Raspberry Pi and format it for RAID
   1. `lsblk -p`
   2. `gdisk /dev/sda`
      3. `n`
      4. *Enter* x3
      5. `fd00`
      6. `p`
      7. `w`
      8. `Y`
   3. Repeat this step for other USB drive (`/dev/sdb`)
      1. **SCREENSHOT**
3. Once both USB drives are partitioned for Linux RAID, install mdadm and create a RAID1 configuration
   1. `sudo apt install mdadm`
   2. Verify the changes on the USB drives with `sudo mdadm -E /dev/sd[ab]1`
   3. Create a RAID1 configuration on `/dev/md0`
      1. `sudo mdadm --create /dev/md0 --level=mirror --raid-devices=2 /dev/sd[ab]1`
      2. `y`
   4. Watch the RAID configuration being created
      1. `watch cat /proc/mdstat`
      2. **SCREENSHOT**
4. Once RAID is complete, create a file system on RAID `/dev/md0`
   1. `sudo mkfs -t ext4 /dev/md0`
5. Create a mount point to attach new file system
   1. `sudo mkdir /mnt/md0`
6. Mount file system
   1. `sudo mount /dev/md0 /mnt/md0`
7. Check if the mount was successful
   1. `df -h /mnt/md0`
   2. **SCREENSHOT**
8. Save the mdadm array layout (Can only be done in root)
   1. `sudo su`
   2. `mdadm --detail --scan /dev/md0 >> /etc/mdadm/mdadm.conf`
   3. `cat /etc/mdadm/mdadm.conf`
   4. `exit`
9. Update initramfs
   1. `sudo update-initramfs -u`
10. Add new file system mount options to the fstab file for automatic mounting at boot
    1. `sudo nano /etc/fstab`  

    ```bash
    /dev/md0    /mnt/md0    ext4    defaults    0    0
    ```

11. The RAID1 configuration is now complete and should be automatically mounted when the Raspberry Pi boots up. The next steps are to set up pushbullet notifications for when one of the USB drives fail
12. First, create a Push Bullet account and optain the API Key
    1. <https://www.pushbullet.com/>
13. Enter your API key into a file called `pushbullet` in the .config directory
    1. `nano ~/.config/pushbullet`
    2. `PB_API_KEY=<api_key>`
14. Download and install Pushbullet
    1. `sudo apt install -y git`
    2. `sudo git clone https://github.com/Red5d/pushbullet-bash /opt/pb/`
    3. `cd /opt/pb/`
    4. `sudo git submodule init && sudo git submodule update`
    5. `cd`
    6. `sudo ln -s /opt/pb/pushbullet /usr/local/bin/pushbullet`
    7. `pushbullet list`  
    Pushbullet can now be used in the command line
15. Next we download a script (<https://github.com/hunleyd/mdadm_notify>) that triggers when mdadm reports an event. This event is then pushed to all pushbullet devices on the account.
    1. `sudo git clone https://github.com/hunleyd/mdadm_notify /opt/mn/`
    2. `sudo nano /opt/mn/mdadm_notify`
    3. Edit the final line so it looks like this  
    `echo "$msg" | pushbullet push all note $msg`
    4. Edit the mdadm configuration file so that is uses the newly created program
    `sudo nano /etc/mdadm/mdadm.conf`
    5. Replace the MAILADDR line with the following:
    `PROGRAM /opt/mn/mdadm_notify`
    6. To simulate a fault we will be using the following commands
    `mdadm --manage --set-faulty /dev/md0 /dev/sda`
    **SCREENSHOT**
    Congragulations you have now implemented Pushbullet notifications! Mdadm will automatically use this script whenever it detects an event.

## Installing Docker

1. Ensure you are logged into the Raspberry Pi
   1. `ssh pi@192.168.x.x`
2. Download the Docker convenience script from <https://get.docker.com>
   1. `wget -O get-docker.sh https://get.docker.com`
3. Make the Docker script an executable and run it
   1. `chmod +x get-docker.sh`
4. Run Docker script
   1. `sudo sh get-docker.sh`
   2. **SCREENSHOT**
5. After the script is installed, add the user to the Docker group
   1. `sudo usermod -aG docker pi`
   2. `sudo reboot now`
6. Upgrade the Docker install by running a standard apt update and upgrade
   1. `sudo apt update -y && sudo apt upgrade -y`

## Creating Docker Image

### Install Packages

1. Create a centos:centos7 Docker image and run it
   1. `docker image pull centos:centos7`
   2. `docker run -i -t centos:centos7`
2. Download the centos install script from the github repository.
   1. `yum makecache && yum install -y wget`
   2. `wget -N https://github.com/s3668468/usap-a1/blob/master/centos7_install.sh`
3. Make the script an executable and run it
   1. `chmod +x centos7_install.sh`
   2. `./centos7_install.sh`
4. This script should install all nessecary applications for the Docker image.  
   Please refer to the installation script for correct methods.
5. Commit and save the Docker image
   1. Press *CTRL+P* and *CTRL+Q* to exit the Docker image without closing it
   2. Obtain the Docker ID with `docker ps`
   3. `docker commit <containerid> <name:tag>`

### Make configuration changes

#### Expose nginx

1. Open the saved Docker container with the following commands and run nginx
   1. `docker run -i -t -p 80:80 <name:tag>`
   2. `nginx`
2. Connect to it from the client machine
   1. **SCREENSHOT**

#### Create new users

1. Create a new user called 'fred' who has access to root
   1. `yum install -y sudo`
   2. `useradd fred`
   3. `usermod -aG wheel fred`  
      Wheel is used as installing sudo does not create the privileged group
   4. `passwd fred`
   5. Password is `usap`
2. Create a new user called 'user' who has access to root, Berryconda and has zsh set by default.
   1. `useradd user -s /bin/zsh`
   2. `usermod -aG wheel user`
   3. `passwd user`
   4. Password is `usap`
   5. `su user`
   6. ZSH set up is required
      1. Enter `1`
      2. Enter `0`
   7. Berryconda was symbolically link during the installation script from earlier. To test user `conda --version`

#### Install OhMyZSH and Auto Suggestions

<https://github.com/ohmyzsh/ohmyzsh>
<https://github.com/zsh-users/zsh-autosuggestions>

1. Log into 'fred' and install OhMyZsh
   1. `su fred`
   2. `sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
   3. Enter `y`
   4. `git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions`
   5. Add the following line to the plugins in `.zshrc`
      `nano ~/.zshrc`
      `plugins=(zsh-autosuggestions)`
   6. Add a custom theme by editing the `ZSH_THEME` variable
      `ZSH_THEME="afowler"`

2. Repeat these steps for 'user'
   1. **SCREENSHOT**

#### Enable SSH with redirected port

1. Exit the Docker image with CTRL+P and CTRL+Q
2. Commit and save the Docker image
   1. `docker commit <containerid> <name:tag>`
   2. `docker stop <containerid>`
3. Start the Docker image with more port argument
   1. `docker run -i -t -p 80:80 -p 1234:22 <name:tag>`
4. Create an ssh key and run the process to test connection
   1. `ssh-keygen -A`
   2. sshd requires an absolute path
      `/usr/sbin/sshd -D`
   3. **SCREENSHOT**

#### Enable x11 over SSH and Disable Root Access

1. Edit the SSH configuration file and enable X11 and disable root access
   1. `nano /etc/ssh/sshd_config`
   2. Uncomment `PermitRootLogin` and set it to `no`
   3. Uncomment `X11Forwarding yes`, `X11DisplayOffset 10` and `X11UseLocalhost yes`
   4. Start sshd with `/sbin/sshd`
2. Install xeyes on the client machine
   1. `sudo apt install x11-apps`
   2. `ssh -X user@raspberrypi.local -p 1234`

#### Add zsh to the list of available shells on the system

1. Adding zsh to the list of shells can be done with one command
   1. `echo "/bin/zsh" >> /etc/shells`

#### Write a script to start nginx and sshd

1. Create a script file and add in commands to start nginx and sshd
   1. `cd && nano nginx_sshd.sh`
   2. Enter the folling text:  

      ```bash
      !/bin/bash
      /sbin/nginx
      /sbin/sshd
      ```

   3. Make the script and executable and run it
      `chmod +x nginx_sshd.sh`
      `sh nginx_sshd.sh`

#### Configure Git

1. Configure git user name
   1. `git config --global user.name "Cameron Tavelli"`
2. Configure git user email
   1. `git config --global user.email "s3668468@student.rmit.edu.au"`

#### Check versions for every program

1. Run the provided script to automatically check
   1. `wget -N https://github.com/s3668468/usap-a1/blob/master/version.sh`
   2. `chmod +x version.sh`
   3. `sh version.sh`

### Commit Docker image

<https://docs.docker.com/engine/reference/commandline/push/>

1. Create an account on <https://hub.docker.com>
2. Log into the account in terminal
   1. `docker login`
   2. Username: `<username>`
   3. Password: `<password>`
3. Check and tag the Docker image
   1. `docker images`
   2. `docker tag centos7:latest s3668468/centos7:latest`
   3. `docker push s3668468/centos7:latest`
4. Check the Docker image on the repository and set it to private
   1. Link to Docker image <https://hub.docker.com/repository/docker/s3668468/centos7/general>

### <https://github.com/s3668468/usap-a1>

## References

- [1]"Download Raspberry Pi OS for Raspberry Pi", Raspberry Pi, 2020. [Online]. Available: <https://www.raspberrypi.org/downloads/raspberry-pi-os/>
- [2]"Pushbullet - Your devices working better together", Pushbullet.com, 2020. [Online]. Available: <https://www.pushbullet.com/>
- [3]Get.docker.com, 2020. [Online]. Available: <https://get.docker.com>
- [4]"ohmyzsh/ohmyzsh", GitHub, 2020. [Online]. Available: <https://github.com/ohmyzsh/ohmyzsh>
- [5]"zsh-users/zsh-autosuggestions", GitHub, 2020. [Online]. Available: <https://github.com/zsh-users/zsh-autosuggestions>
- [6]"docker push", Docker Documentation, 2020. [Online]. Available: <https://docs.docker.com/engine/reference/commandline/push/>
- [7]"CentOS Repositories", 2020. [Online]. Available: <https://centos.pkgs.org/>
- [8]"SpecialInterestGroup/AltArch/armhfp - CentOS Wiki", Wiki.centos.org, 2020. [Online]. Available: <https://wiki.centos.org/action/show/SpecialInterestGroup/AltArch/armhfp>
- [9]"jjhelmus/berryconda", GitHub, 2020. [Online]. Available: <https://github.com/jjhelmus/berryconda>
- [10]"mozilla/rr", GitHub, 2020. [Online]. Available: <https://github.com/mozilla/rr>