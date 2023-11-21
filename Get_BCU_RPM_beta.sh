#!/usr/bin/env bash

# CREATOR: Mike Lu
# CHANGE DATE: 11/21/2023

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

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root (sudo su)."
else



# SET FILE PATH
SPQ=$PWD/sp143035.tgz
MOD=$PWD/hpflash-3.22/non-rpms/hpuefi-mod-3.04
MOD_RPM_SRC=hpuefi-mod-3.04-1.src.rpm
MOD_RPM=hpuefi-mod-3.04-1.$(uname -m).rpm
RPM8_PATH=$PWD/hpflash-3.22/rpms/rh80
RPM9_PATH=$PWD/hpflash-3.22/rpms/rh90
APP=$PWD/hpflash-3.22/non-rpms/hp-flash-3.22_x86_64
APP_RPM8=$PWD/hpflash-3.22/rpms/rh80/hp-flash-3.22-1.rh80.x86_64.rpm
APP_RPM9=$PWD/hpflash-3.22/rpms/rh90/hp-flash-3.22-1.rh90.x86_64.rpm
BCU=/opt/hp/hp-flash



# CHECK INTERNET CONNETION
  nslookup "hp.com" > /dev/null
  if [ $? != 0 ]
  then 
    echo "❌ No Internet connection! Please check your network" && sleep 5 && exit 0
  fi
  
  
# EXTRACT HP LINUX TOOLS
  if [ ! -f $SPQ ]; then
	echo "❌ ERROR: spxxxxxx.tgz file is not found!"
	read -p 'Please fix the above error first and re-try.' && exit 0	
  else
	tar xzf $SPQ
  fi


# INSTALL UEFI MODULE AND REPLICATED SETUP UTILITY
  [[ -f /usr/bin/rpm ]] && PKG=rpms || PKG=non-rpms
  case $PKG in
   "rpms")
 	RH_VER=`cat /etc/*-release | grep ^PRETTY_NAME= | cut -d '"' -f2 | cut -d ' ' -f5`
 	[[ ! -f /usr/bin/rpmbuild ]] && dnf install rpm-build -y
 	if [[ $RH_VER == 8.* && $(rpm -qa | grep hpuefi | echo $?) == 1 ]]; then
		cd $RPM8_PATH
		rpm -i $MOD_RPM_SRC
		rpmbuild -bb $HOME/rpmbuild/SPECS/hpuefi-mod.spec
		rpm -i $HOME/rpmbuild/RPMS/$(uname -m)/$MOD_RPM
	fi
	if [[ $RH_VER == 9.* && $(rpm -qa | grep hpuefi | echo $?) == 1 ]]; then
		cd $RPM9_PATH
		rpm -i $MOD_RPM_SRC
		rpmbuild -bb $HOME/rpmbuild/SPECS/hpuefi-mod.spec
		rpm -i $HOME/rpmbuild/RPMS/$(uname -m)/$MOD_RPM
	else	
		echo "**HP UEFI module is installed**"
	fi
	if [[ $RH_VER == 8.* && ! -f /opt/hp/hp-flash/bin/hp-repsetup ]]; then
		cd $RPM8_PATH
		rpm -i $APP_RPM8
	fi
	if [[ $RH_VER == 9.* && ! -f /opt/hp/hp-flash/bin/hp-repsetup ]]; then
		cd $RPM9_PATH
		rpm -i $APP_RPM9
	else
		echo "**HP setup utility is installed**"
	fi
	;;
   "non-rpms")
	if [ ! -d "/sys/module/hpuefi" ]; then
		cd $MOD
		make
		# sudo rmmod hpuefi   # Uncomment if you want to remove the old UEFI module
		# insmod hpuefi.ko
		# sudo bash ./mkdevhpuefi
		sudo make install
	else
		echo "**HP UEFI module is installed**"
	fi
	if [ ! -f /opt/hp/hp-flash/bin/hp-repsetup ]; then
		cd $APP
		sudo ./install.sh
	else
		echo "**HP setup utility is installed**"
	fi
	;;
  esac


# GET BCU
  # lsmod | grep "hpuefi" 
  # if [ $? == 0 ]; then
	cd $BCU
	sudo bash ./hp-repsetup -g -a -q
	sudo chown $USER "HPSETUP.TXT"
	sudo chmod o+w HPSETUP.TXT && ln -sf $BCU/HPSETUP.TXT /home/$USERNAME/BCU-Tool-Linux/HPSETUP.TXT
	echo "✅ BCU got. Please check HPSETUP.TXT"
	echo ""
  # else
	# echo "❌ ERROR: HP UEFI module is NOT installed successfully! Please re-try."
  # fi
fi

