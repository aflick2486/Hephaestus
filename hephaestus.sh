#!/bin/bash

#######################
#Author: Adam Flickema#
#############################
#Contact: aflickem@emich.edu#
#############################

###############################################
#MUST RUN AS ROOT
#Must have apt-get or yum installed
###############################################

#A linux security script that uses linux best practices and asks the user which things that they would like to use
#It will be able to be used on different forms on linux ostypes

#Version 2
#Added support for Ubuntu/Debian systems

apt=`command -v apt-get`
yum=`command -v yum`


if [ ! -z "$apt" ]; then
	apt-get install lsb-release &> /dev/null
elif [ ! -z "$yum" ]; then
	yum install redhat-lsb-core &> /dev/null
else
	echo "No supported pkg manager."
	exit 1;
fi

os=`lsb_release -si`

echo '################'
echo "Linux Security"
echo '################'
echo ""
echo '###########################'
echo "Operating System: $os"
echo '###########################'
echo ""
#Tests operating system ID and if CentOS runs all commands for CentOS
if [ "$os" == "CentOS" ] || [ "$os" == "Red Hat" ]; then

	echo '######################'
	echo "Checking for Updates"
	echo '######################'
	echo ""
	echo '####################'
	echo "Available Updates:"
	echo '####################'

	yum check-update | awk '(NR >=4) {print $1;}' | sed ':a;N;$!ba;s/\n/,/g'
	while true; do
		read -p "Would you like to install these updates?" yn
		case $yn in
			[Yy]* ) yum update
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	echo ""

#Asks the user if they would like to update the programs or not

	echo '##############'
	echo "Disable IPV6"
	echo '##############'

	if grep -Fxq "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf &> /dev/null; then
		echo "IPv6 is already disabled."
	else
		while true; do
			read -p "Would you like to disable IPv6?" yn
			case $yn in
				[Yy]* ) echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
					echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
					echo "IPV6INIT=\"no\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
					chkconfig -level 345 ip6tables off &> /dev/null
					break;;
				[Nn]* ) break;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	fi

	echo '########################################################'
	echo "Disbale Root Shell"
	echo "Warning: Make sure main user is in sudoers file first!"
	echo '########################################################'

        if grep -Fxq "root:x:0:0:root:/root:/sbin/nologin" /etc/passwd &> /dev/null; then
                 echo "Root shell is already disabled.I"
	else
		while true; do
			read -p "Would you like to disable root shell?" yn
			case $yn in
				[Yy]* ) sed -i -e 's#^root:x:0:0:root:/root:/bin/bash#root:x:0:0:root:/root:/sbin/nologin#' /etc/passwd
					break;;
				[Nn]* ) break;;
				* )  echo "Please answer yes or no.";;
			esac
		done
	fi

	echo '######################'
	echo "Limit Password Reuse"
	echo '######################'

	while true; do
		read -p "Would you like to limit password reuse?" yn
		case $yn in
			[Yy]* ) read -p "How many passwords would you like to remember?" num
				sed -i "17a password    sufficient    pam_unix.so use_authtok md5 shadow remember=$num" /etc/pam.d/system-auth
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done


	echo '####################'
	echo "Max Logon Attempts"
	echo '####################'

	while true; do
		read -p "Would you like have a max logon attempt amount?" yn
		case $yn in
			[Yy]* ) read -p "What is the maximum amount of login attempts?" num
				sed -i "8a auth        required      pam_tally.so no_magic_root" /etc/pam.d/system-auth
				sed -i "13a account     required      pam_tally.so deny=$num no_magic_root lock_time=180" /etc/pam.d/system-auth
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	echo '########################'
	echo "Linux Kernel Hardening"
	echo '########################'

	while true; do
		read -p "Would you like to turn on execshield?" yn
		case $yn in
			[Yy]* ) echo -e "\n#Turn on execshield" >> /etc/sysctl.conf
				echo "kernel.exec-shield=1" >> /etc/sysctl.conf
				echo "kernel.randomaize_va_space=1" >> /etc/sysctl.conf
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	while true; do
		read -p "Would you like to enable IP spoofing protection and logging?" yn
		case $yn in
			[Yy]* ) echo -e "\n#Enable IP spoofing protection and logging\nnet.ipv4.conf.all.rp_filter=1\nnet.ipv4.conf.all.log_martians=1" >> /etc/sysctl.conf
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	while true; do
		read -p "Would you like to disable IP source routing?" yn
		case $yn in
			[Yy]* ) echo -e "\n#Disable IP source routing\nnet.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	while true; do
		read -p "Would you like to block ping and broadcast requests?" yn
		case $yn in
        	        [Yy]* ) echo -e "\n#Ignore broadcast request\nnet.ipv4.icmp_echo_ignore_broadcast=1\nnet.ipv4.icmp_ignore_bogus_error_messages=1" >> /etc/sysctl.conf
				break;;
          	        [Nn]* ) break;;
                	* ) echo "Please answer yes or no.";;
		esac
	done

	echo '##################################################'
	echo "Remove X Windows"
	echo "!!!Caution!!!"
	echo "Only do this if you are on a web or mail server."
	echo '##################################################'

	while true; do
        read -p "Would you like to remove X Windows?" yn
        case $yn in
		[Yy]* ) yum --assumeno groupremove "X Windows System"
		read -p "This is what will be removed. Are your aure you want to continue?" yn
		case $yn in
			[Yy]* ) yum groupremove "X Windows System"
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
		break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
	done

elif [ "$os" == "Ubuntu" ] || [ "$os" == "Debian" ]; then

	echo '######################'
	echo "Checking for Updates"
	echo '######################'
	echo ""
	echo '####################'
	echo "Available Updates:"
	echo '####################'

	apt-get update &> /dev/null
	apt list --upgradeable
	while true; do
		read -p "Would you like to install these updates?" yn
		case $yn in
			[Yy]* ) apt-get upgrade
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	echo ""

	echo '##############'
	echo "Disable IPV6"
	echo '##############'

	if grep -Fxq "alias net-pf-10 off" /etc/modprobe.d/aliases &> /dev/null; then
		echo "IPv6 is already disabled."
	else
		while true; do
			read -p "Would you like to disable IPv6?" yn
			case $yn in
				[Yy]* ) echo "alias net-pf-10 off" >> /etc/modprobe.d/aliases
					echo "alias ipv6 off"
					sed -i '/alias net-pf-10 ipv6/d' /etc/modprobe.d/aliases
					break;;
				[Nn]* ) break;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	fi

	echo '########################################################'
	echo "Disbale Root Shell"
	echo "Warning: Make sure main user is in sudoers file first!"
	echo '########################################################'

        if grep -Fxq "root:x:0:0:root:/root:/usr/sbin/nologin" /etc/passwd &> /dev/null; then
                 echo "Root shell is already disabled."
	else
		while true; do
			read -p "Would you like to disable root shell?" yn
			case $yn in
				[Yy]* ) sed -i -e 's#^root:x:0:0:root:/root:/bin/bash#root:x:0:0:root:/root:/usr/sbin/nologin#' /etc/passwd
					break;;
				[Nn]* ) break;;
				* )  echo "Please answer yes or no.";;
			esac
		done
	fi

	echo '######################'
	echo "Limit Password Reuse"
	echo '######################'

	while true; do
		read -p "Would you like to limit password reuse?" yn
		case $yn in
			[Yy]* ) read -p "How many passwords would you like to remember?" num
				sed -i "17a password    sufficient    pam_unix.so use_authtok md5 shadow remember=$num" /etc/pam.d/common-password
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	echo '####################'
	echo "Max Logon Attempts"
	echo '####################'

	while true; do
		read -p "Would you like have a max logon attempt amount?" yn
		case $yn in
			[Yy]* ) read -p "What is the maximum amount of login attempts?" num
				sed -i "8a auth        required      pam_tally.so no_magic_root" /etc/pam.d/common-password
				sed -i "13a account     required      pam_tally.so deny=$num no_magic_root lock_time=180" /etc/pam.d/common-password
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
	echo '########################'
	echo "Linux Kernel Hardening"
	echo '########################'

	while true; do
		read -p "Would you like to turn on execshield?" yn
		case $yn in
			[Yy]* ) echo -e "\n#Turn on execshield" >> /etc/sysctl.conf
				echo "kernel.exec-shield=1" >> /etc/sysctl.conf
				echo "kernel.randomaize_va_space=1" >> /etc/sysctl.conf
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	while true; do
		read -p "Would you like to enable IP spoofing protection and logging?" yn
		case $yn in
			[Yy]* ) echo -e "\n#Enable IP spoofing protection and logging\nnet.ipv4.conf.all.rp_filter=1\nnet.ipv4.conf.all.log_martians=1" >> /etc/sysctl.conf
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	while true; do
		read -p "Would you like to disable IP source routing?" yn
		case $yn in
			[Yy]* ) echo -e "\n#Disable IP source routing\nnet.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf
				break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	while true; do
			read -p "Would you like to block ping and broadcast requests?" yn
			case $yn in
                [Yy]* ) echo -e "\n#Ignore broadcast request\nnet.ipv4.icmp_echo_ignore_broadcast=1\nnet.ipv4.icmp_ignore_bogus_error_messages=1" >> /etc/sysctl.conf
					break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
			esac
	done

	echo '##################################################'
	echo "Remove X Windows"
	echo "!!!Caution!!!"
	echo '##################################################'
	while true; do
        read -p "Would you like to remove X Windows?" yn
        case $yn in
					[Yy]* ) apt-get --assume-no remove libx11.* libqt.*
			read -p "This is what will be removed and installed. Are you sure you want to continue?" yn
			case $yn in
				[Yy]* ) apt-get purge libx11.* libqt.*
					apt -y autoremove
					break;;
				[Nn]* )
					break;;
				*) echo "Please answer yes or no.";;
			esac
			break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
	done

else
	echo "$os is not supported."
	exit 1;
fi

exit 0
