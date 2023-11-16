#!/usr/bin/env bash

# CREATOR: Mike Lu
# CHANGE DATE: 11/16/2023

# NOTE: 
# If make/gcc/g++ tools are not pre-installed (e.g., clean OS), install them before running this script.
# On Ubuntu:
# (1) sudo apt update
# (2) sudo apt install build-essential 
#
# On RHEL:
# (1) sudo dnf update
# (2) sudo dnf groupinstall "Development Tools"


# HOW TO USE:
# Copy the whole BCU-Tool-Linux folder (containing .sh and .tgz files) to HOME directory and run below command on Terminal:
# (1) cd ~/BCU-Tool-Linux
# (2) bash Get_BCU_Only.sh


# SET FILE PATH
SPQ=$PWD/sp143035.tgz
MOD=$PWD/sp143035/hpflash-3.22/non-rpms/hpuefi-mod-3.04
BCU=$PWD/sp143035/hpflash-3.22/non-rpms/hp-flash-3.22_x86_64


# EXTRACT HP LINUX TOOLS
if [ ! -f $SPQ ]; then
	echo "❌ ERROR: spxxxxxx.tgz file is not found!"
	read -p 'Please fix the above error first and re-try.' && exit 0	
else
	tar xf $SPQ
fi

# INSTALL UEFI MODULE
if [ ! -d "/sys/module/hpuefi" ]; then
	cd $MOD
	make
	# sudo rmmod hpuefi   # Uncomment if you want to remove the old UEFI module
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


# GET BCU
lsmod | grep "hpuefi" 
if [ $? == 0 ]; then
	cd $BCU
	sudo bash ./hp-repsetup -g -a -q
	sudo chown $USER "HPSETUP.TXT"
	sudo chmod o+w HPSETUP.TXT && ln -s $BCU/HPSETUP.TXT ~/BCU-Tool-Linux/HPSETUP.TXT
	echo "✅ BCU got. Please check HPSETUP.TXT"
	echo ""
else
	echo "❌ ERROR: HP UEFI module is NOT installed successfully! Please re-try."
fi

