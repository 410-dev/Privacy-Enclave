#!/bin/bash
echo "Removing..."
sudo mpkg --select com.skyclad0x7b7.sniper-installer com.saittam82.tuntap org.hysong.privacyenclavecommandline org.hysong.verstect org.hysong.libprivacyenclave org.hysong.nemesis org.hysong.nemesisapi org.hysong.commoncrypto
sudo mpkg --remove :selected --ignore-dependency