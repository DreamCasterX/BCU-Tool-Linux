#!/usr/bin/env bash

# CREATOR: mike.lu@hp.com
# CHANGE DATE: 11/30/2023


# NOTE: 
# Internet connection may be required in order to install missing dependencies
# BIOS source can be obtained from the Pulsar BIOS package/Capsule/Linux/xxx_xxxxxx.cab
# To flash BIOS, put the .cab file to 'HP-BIOS-Tool-Linux' root directory 


# HOW TO USE:
# Copy the whole 'HP-BIOS-Tool-Linux' folder (containing .sh and .tgz files) to HOME directory and run below command on Terminal:
# (1) cd HP-BIOS-Tool-Linux
# (2) bash HpBiosSetup.sh


# SET FILE PATH
SPQ=$PWD/sp143035.tgz
MOD=$PWD/sp143035/hpflash-3.22/non-rpms/hpuefi-mod-3.04
APP=$PWD/sp143035/hpflash-3.22/non-rpms/hp-flash-3.22_x86_64


# RESTRICT USER ACCOUNT
[[ $EUID == 0 ]] && echo -e "⚠️ Please run as non-root user.\n" && exit 0


# EXTRACT HP LINUX TOOLS
[[ ! -f $SPQ ]] && echo -e "❌ ERROR: spxxxxxx.tgz file is not found!\n" && exit 0 || tar xzfm $SPQ


# CHECK INTERNET CONNETION
CheckNetwork() {
	wget -q --spider www.google.com > /dev/null
	[[ $? != 0 ]] && echo -e "❌ No Internet connection! Check your network and retry.\n" && exit $ERRCODE || :
}


# INTALL DEPENDENCIES
[[ -f /usr/bin/apt ]] && PKG=apt || PKG=dnf
case $PKG in
   "apt")
     	[[ ! -f /usr/bin/mokutil ]] && CheckNetwork && sudo apt update && sudo apt install mokutil -y || : 
     	dpkg -l | grep build-essential > /dev/null 
     	[[ $? != 0 ]] && CheckNetwork && sudo apt update && sudo apt install build-essential -y || : 
     	dpkg -l | grep linux-headers-$(uname -r) > /dev/null 
     	[[ $? != 0 ]] && CheckNetwork && sudo apt update && sudo apt install linux-headers-$(uname -r) -y || :
     	dpkg -l | grep fwupd > /dev/null 
     	[[ $? != 0 ]] && CheckNetwork && sudo apt update && sudo apt install fwupd -y || : 
   	;;
   "dnf")
   	[[ ! -f /usr/bin/mokutil ]] && CheckNetwork && sudo dnf install mokutil -y || :
   	[[ ! -f /usr/bin/make ]] && CheckNetwork && sudo dnf install make -y || :
   	rpm -q kernel-devel-$(uname -r) | grep 'not installed' > /dev/null 
   	[[ $? == 0 ]] && CheckNetwork && sudo dnf install kernel-devel-$(uname -r) -y || :
   	rpm -q kernel-headers-$(uname -r) | grep 'not installed' > /dev/null 
   	[[ $? == 0 ]] && CheckNetwork && sudo dnf install kernel-headers-$(uname -r) -y || :
   	rpm -q fwupd | grep 'not installed' > /dev/null 
   	[[ $? == 0 ]] && CheckNetwork && sudo dnf install fwupd -y || : 
   	;;
esac


# CHECK SECURE BOOT STATUS
! mokutil --sb-state | grep 'disabled' > /dev/null && echo -e "⚠️ Secure boot is not disabled!\n" && exit 0


# INSTALL UEFI MODULE
if [[ ! -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/hpuefi.ko && ! -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/mkdevhpuefi ]]; then
	cd $MOD
	make
	sudo make install
else
	echo "**HP UEFI module is installed**"
fi
[[ $? != 0 ]] && exit $ERRORCODE


# INSTALL REPLICATED SETUP UTILITY
lsmod | grep hpuefi
if [[ ! -d /sys/module/hpuefi && ! -f /opt/hp/hp-flash/bin/hp-repsetup ]]; then
	cd $APP
	sudo bash ./install.sh
else
	echo "**HP setup utility is installed**"
fi


# DEFINE FUNCTIONS
GET_BCU() {
	cd $APP
	sudo bash ./hp-repsetup -g -a -q
	sudo chown $USER HPSETUP.TXT 2> /dev/null
	sudo chmod o+w HPSETUP.TXT 2> /dev/null && ln -sf $APP/HPSETUP.TXT $PWD/../../../../HPSETUP.TXT 2> /dev/null
	[[ $? == 0 ]] && echo -e "\n✅ BCU got. To view, run 'cat HPSETUP.TXT'\n            To edit, run 'open HPSETUP.TXT'\n" || echo -e "\n❌ ERROR: Failed to get BCU. Please re-run the script.\n"
}

SET_BCU() {
	cd $APP
	if [[ -L $PWD/../../../../HPSETUP.TXT ]]; then 
		sudo bash ./hp-repsetup -s -q 
		echo -e "\n✅ BCU is set. Please reboot the system to take effect.\n" && exit 0
	fi
	if [[ ! -L $PWD/../../../../HPSETUP.TXT && -f $PWD/../../../../HPSETUP.TXT ]]; then
		mv $PWD/../../../../HPSETUP.TXT $APP/HPSETUP.TXT 2> /dev/null && ln -sf $APP/HPSETUP.TXT $PWD/../../../../HPSETUP.TXT 2> /dev/null
		sudo bash ./hp-repsetup -s -q
		echo -e "\n✅ BCU is set. Please reboot the system to take effect.\n" && exit 0
	fi
	if [[ ! -L $PWD/../../../../HPSETUP.TXT && ! -f $PWD/../../../../HPSETUP.TXT && ! -f $APP/HPSETUP.TXT ]]; then
		echo -e "❌ ERROR: BCU file is not found!\n" && exit 0
	else
		echo -e "\n❌ ERROR: Failed to set BCU. Please re-run the script.\n"
	fi
}

LOCK_MPM() {
	cd $APP
	sudo bash ./hp-repsetup -g -a -q
	sudo chown $USER HPSETUP.TXT 2> /dev/null
	sudo chmod o+w HPSETUP.TXT 2> /dev/null
	sed -i 's/*Unlock/Unlock/' HPSETUP.TXT 2> /dev/null
	sed -i 's/	Lock/	*Lock/' HPSETUP.TXT 2> /dev/null
	sudo bash ./hp-repsetup -s -q
	cat HPSETUP.TXT | grep -A 2 "Manufacturing Programming Mode" 2> /dev/null
	[[ $? == 0 ]] && echo -e "\n✅ Please reboot the system to lock MPM.\n" || echo -e "\n❌ ERROR: Failed to lock MPM. Please re-run the script.\n"
}

FLASH_BIOS() {
	echo -e "\nCurrent system BIOS info: 
$(sudo dmidecode -t 0 | grep -A1 Version:)\n"
	! ls $PWD | grep .cab > /dev/null && echo -e "\n❌ ERROR: BIOS capsule is not found! \n" && exit 0
	[[ -f /etc/fwupd/daemon.conf ]] && sudo sed -i 's/OnlyTrusted=true/OnlyTrusted=false/' /etc/fwupd/daemon.conf
	sudo fwupdmgr install $PWD/*.cab --allow-reinstall --allow-older --force || sudo sed -i 's/OnlyTrusted=true/OnlyTrusted=false/' /etc/fwupd/daemon.conf 2> /dev/null
}


# USER INTERACTION
echo -e "  \nGet BCU [G]   Set BCU [S]   Lock MPM [L]   Flash BIOS [F]\n"
read -p "Select an action: " ACTION
while [[ $ACTION != [GgSsLlFf] ]]
do
	echo -e "Invalid input!"
	read -p "Select an action: " ACTION
done
[[ $ACTION == [Gg] ]] && GET_BCU ; [[ $ACTION == [Ss] ]] && SET_BCU ; [[ $ACTION == [Ll] ]] && LOCK_MPM ; [[ $ACTION == [Ff] ]] && FLASH_BIOS



