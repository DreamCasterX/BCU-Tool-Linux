#!/usr/bin/env bash

# CREATOR: mike.lu@hp.com
# CHANGE DATE: 04/02/2024
__version__="1.1"


# NOTE:
# Internet connection is required in order to install missing dependencies
# BIOS source can be obtained from the Pulsar BIOS package/Capsule/Linux/xxx_xxxxxx.cab
# To flash BIOS, put the .cab file to 'HP-BIOS-Tool-Linux' root directory 


# HOW TO USE:
# Copy the whole 'HP-BIOS-Tool-Linux' folder (containing .sh and .tgz files) to HOME directory and run below command on Terminal:
# (1) cd HP-BIOS-Tool-Linux
# (2) bash HpBiosSetup.sh


# SET FILE PATH
SPQ=$PWD/sp150953.tgz
BIN=$PWD/sp150953/non-rpms
MOD=$PWD/sp150953/non-rpms/hpuefi-mod-3.05
APP=$PWD/sp150953/non-rpms/hp-flash-3.24_x86_64


# RESTRICT USER ACCOUNT
[[ $EUID == 0 ]] && echo -e "⚠️ Please run as non-root user.\n" && exit


# EXTRACT HP LINUX TOOLS
[[ ! -f $SPQ ]] && echo -e "❌ ERROR: spxxxxxx.tgz file is not found!\n" && exit || tar xzfm $SPQ --one-top-level


# CHECK INTERNET CONNETION
CheckNetwork() {
	wget -q --spider www.google.com > /dev/null
	[[ $? != 0 ]] && echo -e "❌ No Internet connection! Check your network and retry.\n" && exit || :
}


# INTALL DEPENDENCIES
[[ -f /usr/bin/apt ]] && PKG=apt || PKG=dnf
case $PKG in
    "apt")
	 [[ ! -f /usr/bin/mokutil ]] && CheckNetwork && sudo apt update && sudo apt install mokutil -y || : 
	 [[ ! -f /usr/bin/curl ]] && CheckNetwork && sudo apt update && sudo apt install curl -y || : 
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
! mokutil --sb-state | grep 'disabled' > /dev/null && echo -e "⚠️ Secure boot is not disabled!\n" && exit


# CHECK THE LATEST VERSION
release_url=https://api.github.com/repos/DreamCasterX/HP-BIOS-Tool-Linux/releases/latest
new_version=$(curl -s "${release_url}" | grep '"tag_name":' | awk -F\" '{print $4}')
release_note=$(curl -s "${release_url}" | grep '"body":' | awk -F\" '{print $4}')
tarball_url="https://github.com/DreamCasterX/HP-BIOS-Tool-Linux/archive/refs/tags/${new_version}.tar.gz"
CheckNetwork
if [[ $new_version != $__version__ ]]; then
	echo -e "⭐️ New version found!\n\nVersion: $new_version\nRelease note:\n$release_note"
	find -type f ! -name '*.sh' ! -name '*.cab' ! -name '*.TXT' -delete
	find -type d -exec rm -r {} \; 2> /dev/null
  	sleep 2
  	echo -e "\nDownloading update..."
  	pushd "$PWD" > /dev/null 2>&1
  	curl --silent --insecure --fail --retry-connrefused --retry 3 --retry-delay 2 --location --output ".HpBiosCtl.tar.gz" "${tarball_url}"
  	if [[ -e ".HpBiosCtl.tar.gz" ]]; then
		tar -xf .HpBiosCtl.tar.gz -C "$PWD" --strip-components 1 > /dev/null 2>&1
		rm -f .HpBiosCtl.tar.gz
		rm -f README.md
		popd > /dev/null 2>&1
		sleep 3
		chmod 777 *.tgz
		chmod 777 HpBiosCtl.sh
		# DELETE EXISTING MODULE FILES
		sudo rm -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/hpuefi.ko && sudo rm -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/mkdevhpuefi
		sudo rm -f /opt/hp/hp-flash/bin/hp-repsetup
		sudo /sbin/rmmod hpuefi 2> /dev/null
		echo -e "Successfully updated! Please run HpBiosCtl.sh again.\n\n" ; exit 1
    	else
		echo -e "\n❌ Error occured while downloading" ; exit 1
    	fi 
fi


# INSTALL UEFI MODULE
if [[ ! -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/hpuefi.ko && ! -f /lib/modules/$(uname -r)/kernel/drivers/hpuefi/mkdevhpuefi ]]; then
	[[ -f $MOD.tgz	]] && cd $BIN && tar xzfm $MOD.tgz && rm -f $MOD.tgz
	cd $MOD
	make
	sudo make install
else
	echo "**HP UEFI module is installed**"
fi
[[ $? != 0 ]] && exit $ERRCODE


# INSTALL REPLICATED SETUP UTILITY
if [[ ! -d /sys/module/hpuefi && ! -f /opt/hp/hp-flash/bin/hp-repsetup ]]; then
	[[ -f $APP.tgz	]] && cd $BIN && tar xzfm $APP.tgz && rm -f $APP.tgz 
	cd $APP
	sudo bash ./install.sh
	# lsmod | grep hpuefi   # kernel module is loaded after installation 
else
	echo "**HP setup utility is installed**"
fi


# DEFINE FUNCTIONS
GET_BCU() {	
	cd $APP
	sudo bash ./hp-repsetup -g -a -q   
	# kernel module is loaded to execute the tool, and then removed as soon as the execution is complete
	sudo chown $USER HPSETUP.TXT 2> /dev/null
	sudo chmod o+w HPSETUP.TXT 2> /dev/null && ln -sf $APP/HPSETUP.TXT $PWD/../../../HPSETUP.TXT 2> /dev/null
	[[ $? == 0 ]] && echo -e "\n✅ BCU got. To view, run 'cat HPSETUP.TXT'\n            To edit, run 'xdg-open HPSETUP.TXT'\n" || echo -e "\n❌ ERROR: Failed to get BCU. Please re-run the script.\n"
}

SET_BCU() {
	cd $APP
	if [[ -L $PWD/../../../HPSETUP.TXT ]]; then 
		sudo bash ./hp-repsetup -s -q 
		echo -e "\n✅ BCU is set. Please reboot the system to take effect.\n" && exit 0
	fi
	if [[ ! -L $PWD/../../../HPSETUP.TXT && -f $PWD/../../../HPSETUP.TXT ]]; then
		mv $PWD/../../../HPSETUP.TXT $APP/HPSETUP.TXT 2> /dev/null && ln -sf $APP/HPSETUP.TXT $PWD/../../../HPSETUP.TXT 2> /dev/null
		sudo bash ./hp-repsetup -s -q
		echo -e "\n✅ BCU is set. Please reboot the system to take effect.\n" && exit 0
	fi
	if [[ ! -L $PWD/../../../HPSETUP.TXT && ! -f $PWD/../../../HPSETUP.TXT && ! -f $APP/HPSETUP.TXT ]]; then
		echo -e "❌ ERROR: BCU file is not found!\n" && exit
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
	cd $BIN/../..
	echo -e "\nCurrent system BIOS info: 
$(sudo dmidecode -t 0 | grep -A1 Version:)\n"
	! ls | grep .cab > /dev/null && echo -e "\n❌ ERROR: BIOS capsule is not found! \n" && exit
	[[ -f /etc/fwupd/daemon.conf ]] && sudo sed -i 's/OnlyTrusted=true/OnlyTrusted=false/' /etc/fwupd/daemon.conf
	sudo fwupdmgr install $PWD/*.cab --allow-reinstall --allow-older --force || (sudo sed -i 's/OnlyTrusted=true/OnlyTrusted=false/' /etc/fwupd/daemon.conf 2> /dev/null && sudo fwupdmgr install $PWD/*.cab --allow-reinstall --allow-older --force)
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



