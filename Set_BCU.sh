#!/usr/bin/env bash

# CREATOR: Mike Lu
# CHANGE DATE: 11/21/2023


# NOTE: 
# Internet connection is required in order to install required dependencies


# HOW TO USE:
# Copy the whole BCU-Tool-Linux folder (containing .sh and .tgz files) to HOME directory and run below command on Terminal:
# (1) cd BCU-Tool-Linux
# (2) bash Set_BCU_Only.sh


# SET FILE PATH
SPQ=$PWD/sp143035.tgz
MOD=$PWD/sp143035/hpflash-3.22/non-rpms/hpuefi-mod-3.04
APP=$PWD/sp143035/hpflash-3.22/non-rpms/hp-flash-3.22_x86_64


# CHECK INTERNET CONNETION
nslookup "hp.com" > /dev/null
if [ $? != 0 ]; then 
	echo "❌ No Internet connection! Please check your network" && exit 0
fi


# EXTRACT HP LINUX TOOLS
if [ ! -f $SPQ ]; then
	echo "❌ ERROR: spxxxxxx.tgz file is not found!"
	read -p 'Please fix the above error first and re-try.' && exit 0	
else
	tar xzf $SPQ
fi


# INTALL DEPENDENCIES
[[ -f /usr/bin/apt ]] && PKG=apt || PKG=dnf
case $PKG in
   "apt")
   	[[ ! -f /usr/bin/make ]] && sudo apt install make -y
   	sudo apt install linux-headers-4.15.0-32-generic -y
   	;;
   "dnf")
   	[[ ! -f /usr/bin/make ]] && sudo dnf install make -y
   	rpm -q kernel-devel-$(uname -r) | grep 'not installed' > /dev/null ; [[ $? == 0 ]] && sudo dnf install kernel-devel-$(uname -r) -y
   	rpm -q kernel-headers-$(uname -r) | grep 'not installed' > /dev/null ; [[ $? == 0 ]] && sudo dnf install kernel-headers-$(uname -r) -y
   	;;
esac


# INSTALL UEFI MODULE
# /sys/module/hpuefi
if [[ ! -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/hpuefi.ko && ! -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/mkdevhpuefi ]]; then
	cd $MOD
	make
	sudo make install
else
	echo "**HP UEFI module is installed**"
fi


# INSTALL REPLICATED SETUP UTILITY
lsmod | grep hpuefi
if [[ $? != 0  && ! -f /opt/hp/hp-flash/bin/hp-repsetup ]]; then
	cd $APP
	sudo bash ./install.sh
else
	echo "**HP setup utility is installed**"
fi


# SET BCU
cd $APP
if [[ -L /home/$USERNAME/BCU-Tool-Linux/HPSETUP.txt ]]; then 
	sudo bash ./hp-repsetup -s -q 
	echo  -e "✅ BCU is set. Please reboot the system to take effect.\n" && exit 0
fi
if [[ ! -L /home/$USERNAME/BCU-Tool-Linux/HPSETUP.txt && -f /home/$USERNAME/BCU-Tool-Linux/HPSETUP.txt ]]; then
	cp /home/$USERNAME/BCU-Tool-Linux/HPSETUP.txt $APP/HPSETUP.txt
	sudo bash ./hp-repsetup -s -q
	echo  -e "✅ BCU is set. Please reboot the system to take effect.\n"
else
	echo -e "❌ ERROR: Failed to set BCU. Please re-run the script.\n"
fi



