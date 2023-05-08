#!/usr/bin/env bash

# CREATOR: Mike Lu
# CHANGE DATE: 05/08/2023

# HOW TO USE:
# Copy the two files (.sh and .tgz) to Desktop and type below command on Terminal to run this script:
# (1) cd ~/Desktop
# (2) ./Set_BCU_Only.sh

# NOTE: 
# If make/gcc/g++ tools are not pre-installed (e.g., clean OS), install them before running this script.
# On Ubuntu:
# (1) sudo apt update
# (2) sudo apt install build-essential 
#
# On RHEL:
# (1) sudo dnf makecache
# (2) sudo dnf groupinstall "Development Tools"



# SET FILE PATH
SPQ=$PWD/sp143035.tgz
MOD=$PWD/sp143035/hpflash-3.22/non-rpms/hpuefi-mod-3.04
BCU=$PWD/sp143035/hpflash-3.22/non-rpms/hp-flash-3.22_x86_64


# EXTRACT HP LINUX TOOLS
if [ ! -f $SPQ ]; then
	echo "**ERROR: spxxxxxx.tgz file is not found on the Desktop !!**"
	read -p 'Press "Ctrl + C" and fix the above error first'	
else
	tar xf $SPQ
fi

# INSTALL UEFI MODULE
if [ ! -d "/sys/module/hpuefi" ]; then
	cd $MOD
	make
	# sudo rmmod hpuefi   # Uncomment this if you want to remove the old UEFI module
	sudo insmod hpuefi.ko
	sudo bash ./mkdevhpuefi
	sudo make install
else
	echo "**HP UEFI module is installed**"
fi

# INSTALL REPLICATED SETUP UTILITY
if [ ! -f /opt/hp/hp-flash/bin/hp-repsetup ]; then
	cd $BCU
	sudo bash ./install.sh
else
	echo "**HP setup utility is installed**"
fi

# GET BCU & SET BCU
lsmod | grep "hpuefi" 
if [ $? == 0 ]; then
	cd $BCU
	sudo bash ./hp-repsetup -s -q
	sudo chown $USER "HPSETUP.TXT"
	sudo chmod o+w HPSETUP.TXT
	echo "**BCU is set. Please reboot the system to take effect**"
	echo ""
else
	echo "**ERROR: HP UEFI module is NOT installed successfully !!**"
fi

