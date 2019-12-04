#!/bin/bash
echo "Preparation Script"
echo "V. Beta 1"
echo ""
echo "Required dependencies: mpkg8, mpkg, mpkg-profiler, net1.2, org.hysong.hephaestus2, org.hysong.libhephaestus3, org.hysong.hephaestus3-runtime, org.hysong.nemesisapi, org.hysong.nemesis"
echo "Checking dependencies..."
INSTALLED=$(mpkg -l)
if [[ ! -z $(echo "$INSTALLED" | grep "no such") ]]; then
	echo "Oh.. MPKG is not installed."
	echo "Installing mpkg with mpkg4..."
	# MPKG 8 Installation Script
	curl -Ls https://raw.githubusercontent.com/410-dev/Macintosh-Packager/master/net-live -o ~/netlive
	chmod +x ~/netlive
	sudo ~/netlive
	sudo /usr/local/bin/net mpkg-beta
	sudo /usr/local/bin/mpkg --upgrade
	sudo /usr/local/bin/net mpkg8_profile
	echo "Please restart the script."
	exit 3
fi
if [[ -z $(echo "$INSTALLED" | grep "mpkg8") ]]; then
	echo "Upgrading mpkg..."
	# MPKG 8 Installation Script
	sudo /usr/local/bin/net mpkg-beta
	sudo /usr/local/bin/mpkg --upgrade
	sudo /usr/local/bin/net mpkg8_profile
	echo "Please restart the script."
	exit 2
fi
echo "Starting dependencies installation..."
echo "Installing..."
cd "$(dirname "$0")/mpacks"
sudo net libusersupport_1.0_darwin64-signed
if [[ "$1" == "--sniper" ]]; then
	sudo mpkg -i "com.saittam82.tuntap_20150118.mpack"
	sudo mpkg -i "com.skyclad0x7b7.sniper-installer_0.0.36.mpack"
fi
sudo mpkg -i "org.hysong.commoncrypto_1.0.mpack" --override
sudo mpkg -i "org.hysong.nemesisapi_1.1.mpack" --override
sudo mpkg -i "org.hysong.nemesis_1.1.mpack" --override
sudo mpkg -i "org.hysong.verstect_SH1.5.mpack" --override
sudo mpkg -i "org.hysong.libprivacyenclave_1.0.mpack" --override
sudo mpkg -i "org.hysong.privacyenclavecommandline_1.0.mpack" --override
#sudo mpkg -i "org.hysong.privacyenclave-application_1.0.mpack" --override
echo "Completo!"