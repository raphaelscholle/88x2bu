#!/bin/bash

# Purpose: Install Realtek USB WiFi adapter drivers.
#
# This version of the installation script uses dkms.

SCRIPT_NAME="install-driver.sh"
SCRIPT_VERSION="20220821"
OPTIONS_FILE="88x2bu.conf"
BLACKLIST_FILE="rtw88_8822bu.conf"

DRV_NAME="rtl88x2bu"
DRV_VERSION="5.13.1"

DRV_DIR="$(pwd)"
KRNL_VERSION="$(uname -r)"

# support for NoPrompt allows non-interactive use of this script
NO_PROMPT=0

# get the options
while [ $# -gt 0 ]
do
	case $1 in
		NoPrompt)
			NO_PROMPT=1 ;;
		*h|*help|*)
			echo "Syntax $0 <NoPrompt>"
			echo "       NoPrompt - noninteractive mode"
			echo "       -h|--help - Show help"
			exit 1
			;;
	esac
	shift
done

# check to ensure sudo was used
if [[ $EUID -ne 0 ]]
then
	echo "You must run this script with superuser (root) privileges."
	echo "Try: \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# check for previous installation
if [[ -d "/usr/src/${DRV_NAME}-${DRV_VERSION}" ]]
then
	echo "It appears that this driver may already be installed."
	echo "You will need to run the following before reattempting installation."
	echo "$ sudo ./remove-driver.sh"
	exit 1
fi

# information that helps with bug reports

# displays script name and version
echo "Running ${SCRIPT_NAME} version ${SCRIPT_VERSION}"

# kernel
uname -r

# architecture - for ARM: aarch64 = 64 bit, armv7l = 32 bit
uname -m

echo "Starting installation..."

# the add command requires source in /usr/src/${DRV_NAME}-${DRV_VERSION}
echo "Copying source files to: /usr/src/${DRV_NAME}-${DRV_VERSION}"
cp -rf "${DRV_DIR}" /usr/src/${DRV_NAME}-${DRV_VERSION}

# sets module parameters (driver options)
echo "Copying ${OPTIONS_FILE} to: /etc/modprobe.d"
cp -f ${OPTIONS_FILE} /etc/modprobe.d

# blacklist the in-kernel module (driver) so that there is no conflict
echo "Copying ${BLACKLIST_FILE} to: /etc/modprobe.d"
cp -f ${BLACKLIST_FILE} /etc/modprobe.d

dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [[ "$RESULT" != "0" ]]
then
	echo "An error occurred. dkms add error = ${RESULT}"
	echo "Please report this error."
	echo "Please copy all screen output and paste it into the report."
	echo "You will need to run the following before reattempting installation."
	echo "$ sudo ./remove-driver.sh"
	exit $RESULT
fi

dkms build -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [[ "$RESULT" != "0" ]]
then
	echo "An error occurred. dkms build error = ${RESULT}"
	echo "Please report this error."
	echo "Please copy all screen output and paste it into the report."
	echo "You will need to run the following before reattempting installation."
	echo "$ sudo ./remove-driver.sh"
	exit $RESULT
fi

dkms install -m ${DRV_NAME} -v ${DRV_VERSION}
RESULT=$?

if [[ "$RESULT" != "0" ]]
then
	echo "An error occurred. dkms install error = ${RESULT}"
	echo "Please report this error."
	echo "Please copy all screen output and paste it into the report."
	echo "You will need to run the following before reattempting installation."
	echo "$ sudo ./remove-driver.sh"
	exit $RESULT
fi

echo "The driver was installed successfully."

# unblock wifi
rfkill unblock wlan
exit 0
