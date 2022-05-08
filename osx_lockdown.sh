#!/bin/zsh
CURRENT_USER=$(scutil <<< 'show State:/Users/ConsoleUser' | awk '/Name :/ && ! /loginwindow/ { print $3 }')
CONFIGURATION_PROFILES=$(sudo profiles -P -o stdout) &> /dev/null
GREEN="\033[1;32m"; NOCOLOR="\033[0m"

if ! command ls ~/Library/Containers/com.apple.Safari 1>/dev/null 2>&1; then
    echo "Setting Safari preferences requires Full Disk Access.\n"
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    read -r
    exit 1
fi

printf "      CIS 1.2     Ensure Auto Update Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutomaticCheckEnabled = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 1.3     Ensure Download New Updates When Available is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutomaticDownload = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 1.4     Ensure Installation of App Update Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutomaticallyInstallAppUpdates = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 1.5     Ensure System Data Files Are Downloaded Automatically Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'ConfigDataInstall = 1') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c 'CriticalUpdateInstall = 1') &> /dev/null
if [[ "$result_policy" == 1 ]] && [[ "$result_policy2" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 1.6     Ensure Install of macOS Updates Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutomaticallyInstallMacOSUpdates = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 2.1.2   Ensure Show Bluetooth Status in Menu Bar Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'Bluetooth = 18') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    defaults write com.apple.controlcenter Bluetooth -int 18
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 2.3.3   Audit Lock Screen and Start Screen Saver Tools\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'wvous-tr-corner') &> /dev/null
if [[ "$result_policy" == 5 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    defaults write com.apple.dock wvous-br-corner -int 5
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 2.4.3   Ensure Screen Sharing Is Disabled\r"
sudo launchctl disable system/com.apple.screensharing
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 2.4.6   Ensure DVD or CD Sharing Is Disabled\r"
sudo launchctl disable system/com.apple.ODSAgent
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 2.4.8   Ensure File Sharing Is Disabled\r"
sudo launchctl disable system/com.apple.smbd
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 2.4.13  Ensure AirPlay Receiver Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AirplayRecieverEnabled = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    defaults write com.apple.controlcenter AirplayRecieverEnabled -bool false
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 2.5.1.1 Ensure FileVault Is Enabled\r"
result=$(sudo fdesetup status | awk '{print $3}') &> /dev/null
if [[ "$result" == "Off." ]]; then
    sudo fdesetup enable -defer /dev/null -showrecoverykey -forceatlogin 0 -dontaskatlogout
fi
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 2.5.2.2 Ensure Firewall Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'EnableFirewall = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on &> /dev/null
    sudo pkill -HUP socketfilterfw
fi

printf "      CIS 2.5.2.3 Ensure Firewall Stealth Mode Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'EnableStealthMode = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on &> /dev/null
fi

printf "      CIS 2.5.3   Ensure Location Services Is Enabled\r"
result=$(sudo launchctl list | grep -c com.apple.locationd) &> /dev/null
if [[ "$result" != 1 ]]; then
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locationd.plist
fi
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 2.5.6   Ensure Limit Ad Tracking Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c '"forceLimitAdTracking" = 1') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c '"allowApplePersonalizedAdvertising" = 0') &> /dev/null
if [[ "$result_policy" == 1 ]] && [[ "$result_policy2" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    defaults write ~/Library/Preferences/com.apple.Adlib.plist allowApplePersonalizedAdvertising -bool false
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 2.8     Ensure Wake for Network Access Is Disabled\r"
sudo pmset -a womp 0
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 2.10    Ensure Secure Keyboard Entry Terminal.app is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'SecureKeyboardEntry = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    defaults write -app Terminal SecureKeyboardEntry -bool true
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 4.2     Ensure Show Wi-Fi status in Menu Bar Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'WiFi = 18') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    defaults write com.apple.controlcenter WiFi -int 18
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 4.4     Ensure HTTP Server Is Disabled\r"
sudo launchctl disable system/org.apache.httpd
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 4.5     Ensure NFS Server Is Disabled\r"
sudo launchctl disable system/com.apple.nfsd
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 5.1.4   Ensure Library Validation Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep 'DisableLibraryValidation = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation DisableLibraryValidation -bool false
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 5.5     Ensure login keychain is locked when the computer sleeps\r"
security set-keychain-settings -l /Users/"$CURRENT_USER"/Library/Keychains/login.keychain
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 5.15    Ensure Fast User Switching Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'MultipleSessionEnabled = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    sudo defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool false
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 5.2.6   Ensure Complex Password Must Contain Uppercase and Lowercase Characters Is Configured\r"
sudo pwpolicy -n /Local/Default -setglobalpolicy "requiresMixedCase=1"
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 6.1.1   Ensure Login Window Displays as Name and Password Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'SHOWFULLNAME = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      CIS 6.2     Ensure Show All Filename Extensions Setting is Enabled\r"
defaults write /Users/"$CURRENT_USER"/Library/Preferences/.GlobalPreferences.plist AppleShowAllExtensions -bool true
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      CIS 6.3     Ensure Automatic Opening of Safe Files in Safari Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep 'AutoOpenSafeDownloads = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoOpenSafeDownloads -bool false
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      Prevent Time Machine from Prompting to Use New Hard Drives as Backup Volume\r"
sudo defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      Enforce System Hibernation\r"
sudo pmset -a hibernatemode 25
sudo pmset -a powernap 0
sudo pmset -a standby 0
sudo pmset -a standbydelay 0
sudo pmset -a autopoweroff 0
printf "[${GREEN}OK${NOCOLOR}]\n"

printf "      Use more restrictive umask\r"
sudo launchctl config user umask 077 &> /dev/null
printf "[${GREEN}OK${NOCOLOR}]\n"

if command ls ~/Library/Containers/com.apple.Safari 1>/dev/null 2>&1; then
    echo "Remember to remove the Full Disk Access.\n"
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    read -r
fi

exit 0