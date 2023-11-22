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
     	[[ $? != 0 ]] && CheckNetwork && sudo apt-get install build-essential -y || : # gcc-12 may be required for some distro
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


GET_BCU() {
	cd $APP
	sudo bash ./hp-repsetup -g -a -q
	sudo chown $USER "HPSETUP.TXT" 2> /dev/null
	sudo chmod o+w HPSETUP.TXT 2> /dev/null && ln -sf $APP/HPSETUP.TXT /home/$USER/BCU-Tool-Linux/HPSETUP.TXT 2> /dev/null
	[[ $? == 0 ]] && echo -e "\n✅ BCU got. Please check HPSETUP.TXT\n" || echo -e "\n❌ ERROR: Failed to get BCU. Please re-run the script.\n"
}

SET_BCU() {
	cd $APP
	if [[ -L /home/$USER/BCU-Tool-Linux/HPSETUP.TXT ]]; then 
		sudo bash ./hp-repsetup -s -q 
		echo  -e "\n✅ BCU is set. Please reboot the system to take effect.\n" && exit 0
	fi
	if [[ ! -L /home/$USER/BCU-Tool-Linux/HPSETUP.TXT && -f /home/$USER/BCU-Tool-Linux/HPSETUP.TXT ]]; then
		mv /home/$USER/BCU-Tool-Linux/HPSETUP.TXT $APP/HPSETUP.TXT 2> /dev/null && ln -sf $APP/HPSETUP.TXT /home/$USER/BCU-Tool-Linux/HPSETUP.TXT 2> /dev/null
		sudo bash ./hp-repsetup -s -q
		echo  -e "\n✅ BCU is set. Please reboot the system to take effect.\n"
	else
		echo -e "\n❌ ERROR: Failed to set BCU. Please re-run the script.\n"
	fi
}

LOCK_MPM() {
	cd $APP
	sudo bash ./hp-repsetup -g -a -q
	sudo chown $USER "HPSETUP.TXT" 2> /dev/null
	sudo chmod o+w HPSETUP.TXT 2> /dev/null
	sed -i 's/*Unlock/Unlock/' HPSETUP.TXT 2> /dev/null
	sed -i 's/	Lock/	*Lock/' HPSETUP.TXT 2> /dev/null
	cat HPSETUP.TXT | grep -A 2 "Manufacturing Programming Mode" 2> /dev/null
	sudo bash ./hp-repsetup -s -q
	[[ $? == 0 ]] && echo  -e "\n✅ Please reboot the system to lock MPM\n" || echo -e "\n❌ ERROR: Failed to lock MPM. Please re-run the script.\n"
}

FLASH_BIOS() {
	cd $APP
	! ls $WDIR | grep ".bin$" > /dev/null && echo -e "❌ ERROR: BIN file is not found! \n" && exit 0 || sudo bash ./hp-flash $WDIR/$(ls $WDIR | grep ".bin$")
	# [[ $? == 0 ]] && echo  -e "\n✅ Please reboot the system to start BIOS flash.\n" || echo -e "\n❌ ERROR: Failed to flash BIOS. Please re-run the script.\n"
}


echo -e "  \nGet BCU [g]   Set BCU [s]   Lock MPM [l]   Flash BIOS [f] \n"
read -p "Select an action: " ACTION
while [[ $ACTION != [GgSsLlFf] ]]
do
	echo -e "Invalid input!"
	read -p "Select an action: " ACTION
done
[[ $ACTION == [Gg] ]] && GET_BCU ; [[ $ACTION == [Ss] ]] && SET_BCU ; [[ $ACTION == [Ll] ]] && LOCK_MPM ; [[ $ACTION == [Ff] ]] && FLASH_BIOS




