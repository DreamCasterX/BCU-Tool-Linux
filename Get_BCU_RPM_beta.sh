#!/usr/bin/env bash

# CREATOR: Mike Lu
# CHANGE DATE: 11/23/2023

# NOTE: 
# Internet connection may be required in order to install missing dependencies
# BIOS source can be obtained from the Pulsar BIOS package/GLOBAL/BIOS/xxx_xxxxxx.bin (*non-32MB)
# To flash BIOS, put the .bin file to 'HP-BIOS-Tool-Linux' root directory 


# HOW TO USE:
# Copy the whole 'HP-BIOS-Tool-Linux' folder (containing .sh and .tgz files) to HOME directory and run below command on Terminal:
# (1) cd HP-BIOS-Tool-Linux
# (2) bash Get_BCU_RPM_beta.sh


# RESTRICT USER ACCOUNT
[[ $EUID != 0 ]] && echo -e "⚠️ Please run as root (sudo su).\n" && exit 0


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
CheckNetwork() {
	wget -q --spider www.google.com > /dev/null
	[[ $? != 0 ]] && echo -e "❌ No Internet connection! Check your network and retry.\n" && exit $ERRCODE || :
}
  

# EXTRACT HP LINUX TOOLS
[[ ! -f $SPQ ]] && echo -e "❌ ERROR: spxxxxxx.tgz file is not found!\n" && exit 0 || tar xzf $SPQ


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
cd $APP
sudo bash ./hp-repsetup -g -a -q
sudo chown $USER HPSETUP.TXT 2> /dev/null
sudo chmod o+w HPSETUP.TXT 2> /dev/null && ln -sf $APP/HPSETUP.TXT $WDIR/HPSETUP.TXT 2> /dev/null
[[ $? == 0 ]] && echo -e "\n✅ BCU got. Please check HPSETUP.TXT\n" || echo -e "\n❌ ERROR: Failed to get BCU. Please re-run the script.\n"


