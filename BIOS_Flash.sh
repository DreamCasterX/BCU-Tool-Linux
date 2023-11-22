#!/usr/bin/env bash

# CREATOR: Mike Lu
# CHANGE DATE: 11/22/2023


# NOTE: 
# Internet connection is required in order to install required dependencies
# BIOS binary can be obtained from the BIOS package/GLOBAL/BIOS/xxx_xxxxxx.bin (non-32MB) 


# HOW TO USE:
# Copy the whole BCU-Tool-Linux folder (containing .sh and .tgz files) to HOME directory and run below command on Terminal:
# (1) cd BCU-Tool-Linux
# (2) bash Get_BCU_Only.sh


# SET FILE PATH
SPQ=$PWD/sp143035.tgz
MOD=$PWD/sp143035/hpflash-3.22/non-rpms/hpuefi-mod-3.04
APP=$PWD/sp143035/hpflash-3.22/non-rpms/hp-flash-3.22_x86_64
WDIR=/home/$USER/BCU-Tool-Linux



# CHECK INTERNET CONNETION
CheckNetwork() {
	wget -q --spider www.google.com > /dev/null
	[[ $? != 0 ]] && echo -e "❌ No Internet connection! Check your network and retry.\n" && exit $ERRCODE || :
}


# EXTRACT HP LINUX TOOLS
[[ ! -f $SPQ ]] && echo -e "❌ ERROR: spxxxxxx.tgz file is not found!\n" && exit 0 || tar xzf $SPQ


# INTALL DEPENDENCIES
[[ -f /usr/bin/apt ]] && PKG=apt || PKG=dnf
case $PKG in
   "apt")
     	dpkg -l | grep build-essential > /dev/null 
     	[[ $? != 0 ]] && CheckNetwork && sudo apt-get install build-essential gcc-12 -y || :
     	dpkg -l | grep linux-headers-$(uname -r) > /dev/null 
     	[[ $? != 0 ]] && CheckNetwork && sudo apt install linux-headers-$(uname -r) -y || :
   	;;
   "dnf")
   	[[ ! -f /usr/bin/make ]] && CheckNetwork && sudo dnf install make -y || :
   	rpm -q kernel-devel-$(uname -r) | grep 'not installed' > /dev/null 
   	[[ $? == 0 ]] && CheckNetwork && sudo dnf install kernel-devel-$(uname -r) -y || :
   	rpm -q kernel-headers-$(uname -r) | grep 'not installed' > /dev/null 
   	[[ $? == 0 ]] && CheckNetwork && sudo dnf install kernel-headers-$(uname -r) -y || :
   	;;
esac


# INSTALL UEFI MODULE
if [[ ! -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/hpuefi.ko && ! -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/mkdevhpuefi ]]; then
	cd $MOD
	make
	sudo make install
else
	echo "**HP UEFI module is installed**"
fi


# INSTALL REPLICATED SETUP UTILITY
lsmod | grep hpuefi
if [[ ! -d /sys/module/hpuefi && ! -f /opt/hp/hp-flash/bin/hp-repsetup ]]; then
	cd $APP
	sudo bash ./install.sh
else
	echo "**HP setup utility is installed**"
fi


# FLASH BIOS
cd $APP
! ls $WDIR | grep ".bin$" > /dev/null && echo -e "❌ ERROR: BIN file is not found! \n" && exit 0 || sudo bash ./hp-flash $WDIR/$(ls $WDIR | grep ".bin$")
# [[ $? == 0 ]] && echo  -e "\n✅ Please reboot the system to start BIOS flash.\n" || echo -e "\n❌ ERROR: Failed to flash BIOS. Please re-run the script.\n"


