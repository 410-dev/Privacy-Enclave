echo "Downloading from GitHub..."
ADDRESS="$(</usr/local/sniper-installer/address)"
echo "Address: $ADDRESS"
sudo curl -L --progress-bar "$ADDRESS" -o /usr/local/sniper-installer/file.dmg
hdiutil attach /usr/local/sniper-installer/file.dmg
echo "Copying..."
cp -r /Volumes/Sniper\ 0.0.36/Sniper.app /Applications/
echo "Deleting extended attributes..."
xattr -d com.apple.quarantine /Applications/Sniper.app
echo "Done."