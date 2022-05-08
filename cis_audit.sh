#!/bin/zsh
HARDWARE_UUID=$(system_profiler SPHardwareDataType | grep 'Hardware UUID' | awk -F ': ' '{print $2}' | xargs)
CONFIGURATION_PROFILES=$(sudo profiles -P -o stdout) &> /dev/null
RED="\033[1;31m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"; NOCOLOR="\033[0m"

printf "${GREEN}CIS Apple macOS 12.0 Monterey Benchmark v1.0.0\n\n${NOCOLOR}"
printf "Some checks might show incorrectly NOK when the settings have not been changed from default\n\n"

printf "      1.1     Ensure All Apple-provided Software Is Current\r"
result=$(softwareupdate -l | grep "*" | wc -l | tr -d ' ') &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
   printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      1.2     Ensure Auto Update Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutomaticCheckEnabled = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep -c 'AutomaticCheckEnabled = 1') &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      1.3     Ensure Download New Updates When Available is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutomaticDownload = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep -c 'AutomaticDownload = 1') &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      1.4     Ensure Installation of App Update Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutomaticallyInstallAppUpdates = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.commerce | grep -c 'AutoUpdate = 1') &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      1.5     Ensure System Data Files Are Downloaded Automatically Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'ConfigDataInstall = 1') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c 'CriticalUpdateInstall = 1') &> /dev/null
if [[ "$result_policy" == 1 ]] && [[ "$result_policy2" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep -c 'ConfigDataInstall = 1') &> /dev/null
    result_cmd2=$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep -c 'CriticalUpdateInstall = 1') &> /dev/null
    if [[ "$result_cmd" == 1 ]] && [[ "$result_cmd2" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      1.6     Ensure Install of macOS Updates Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutomaticallyInstallMacOSUpdates = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep -c 'AutomaticallyInstallMacOSUpdates = 1') &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      1.7     Audit Computer Name (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.1.1   Ensure Bluetooth Is Disabled If No Devices Are Paired\r"
result=$(sudo defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState) &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${YELLOW}NOK${NOCOLOR}]\n"
fi

printf "      2.1.2   Ensure Show Bluetooth Status in Menu Bar Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'Bluetooth = 18') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(defaults read com.apple.controlcenter Bluetooth) &> /dev/null
    if [[ "$result_cmd" == 18 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.2.1   Ensure \"Set time and date automatically\" Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'forceAutomaticDateAndTime = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo systemsetup -getusingnetworktime | awk '{print $3}') &> /dev/null
    if [[ "$result_cmd" == "On" ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.2.2   Ensure time set is within appropriate limits (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.3.1   Ensure an Inactivity Interval of 20 Minutes Or Less for the Screen Saver Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'idleTime') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(defaults read ~/Library/Preferences/ByHost/com.apple.screensaver."$HARDWARE_UUID".plist idleTime) &> /dev/null
    if [[ "$result_cmd" -le 1200 ]] && [[ "$result" != "" ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.3.2   Ensure Screen Saver Corners Are Secure\r"
bl_corner=$(defaults read ~/Library/Preferences/com.apple.dock wvous-bl-corner) &> /dev/null
tl_corner=$(defaults read ~/Library/Preferences/com.apple.dock wvous-tl-corner) &> /dev/null
tr_corner=$(defaults read ~/Library/Preferences/com.apple.dock wvous-tr-corner) &> /dev/null
br_corner=$(defaults read ~/Library/Preferences/com.apple.dock wvous-br-corner) &> /dev/null
if [[ "$bl_corner" != 6 ]] && [[ "$tl_corner" != 6 ]] && [[ "$tr_corner" != 6 ]] && [[ "$br_corner" != 6 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.3.3   Audit Lock Screen and Start Screen Saver Tools\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'wvous-bl-corner') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c 'wvous-br-corner') &> /dev/null
result_policy3=$(echo "$CONFIGURATION_PROFILES" | grep -c 'wvous-tl-corner') &> /dev/null
result_policy4=$(echo "$CONFIGURATION_PROFILES" | grep -c 'wvous-tr-corner') &> /dev/null
if [[ "$result_policy" == 5 ]] || [[ "$result_policy2" == 5 ]] || [[ "$result_policy3" == 5 ]] || [[ "$result_policy4" == 5 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    bl_corner=$(defaults read ~/Library/Preferences/com.apple.dock wvous-bl-corner) &> /dev/null
    tl_corner=$(defaults read ~/Library/Preferences/com.apple.dock wvous-tl-corner) &> /dev/null
    tr_corner=$(defaults read ~/Library/Preferences/com.apple.dock wvous-tr-corner) &> /dev/null
    br_corner=$(defaults read ~/Library/Preferences/com.apple.dock wvous-br-corner) &> /dev/null
    if [[ "$bl_corner" == 5 ]] || [[ "$tl_corner" == 5 ]] || [[ "$tr_corner" == 5 ]] || [[ "$br_corner" == 5 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.4.1   Ensure Remote Apple Events Is Disabled\r"
result=$(sudo systemsetup -getremoteappleevents | awk '{print $4}') &> /dev/null
if [[ "$result" == "Off" ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.4.2   Ensure Internet Sharing Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'forceInternetSharingOff = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.plist ]; then
        natAirport=$(/usr/libexec/PlistBuddy -c "print :NAT:AirPort:Enabled" /Library/Preferences/SystemConfiguration/com.apple.nat.plist) &> /dev/null
        natEnabled=$(/usr/libexec/PlistBuddy -c "print :NAT:Enabled" /Library/Preferences/SystemConfiguration/com.apple.nat.plist) &> /dev/null
        natPrimary=$(/usr/libexec/PlistBuddy -c "print :NAT:PrimaryInterface:Enabled" /Library/Preferences/SystemConfiguration/com.apple.nat.plist) &> /dev/null
        if [[ "$natAirport" == "true" ]] || [[ "$natEnabled" == "true" ]] || [[ "$natPrimary" == "true" ]]; then
            printf "[${RED}NOK${NOCOLOR}]\n"
        else
            printf "[${GREEN}OK${NOCOLOR}]\n"
        fi
    else
        printf "[${GREEN}OK${NOCOLOR}]\n"
    fi
fi

printf "      2.4.3   Ensure Screen Sharing Is Disabled\r"
result=$(sudo launchctl print-disabled system | grep -c '"com.apple.screensharing" => true') &> /dev/null
if [[ "$result" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.4.4   Ensure Printer Sharing Is Disabled\r"
result=$(sudo cupsctl | grep -c 'share_printers=0') &> /dev/null
if [[ "$result" != 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.4.5   Ensure Remote Login Is Disabled\r"
result=$(sudo systemsetup -getremotelogin | awk '{print $3}') &> /dev/null
if [[ "$result" == "Off" ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.4.6   Ensure DVD or CD Sharing Is Disabled\r"
result=$(sudo launchctl print-disabled system | grep -c '"com.apple.ODSAgent" => true') &> /dev/null
if [[ "$result" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.4.7   Ensure Bluetooth Sharing Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'PrefKeyServicesEnabled = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(/usr/libexec/PlistBuddy -c "print :PrefKeyServicesEnabled" ~/Library/Preferences/ByHost/com.apple.Bluetooth."$HARDWARE_UUID".plist) &> /dev/null
    if [[ "$result_cmd" == "true" ]]; then
        printf "[${RED}NOK${NOCOLOR}]\n"
    else
        printf "[${GREEN}OK${NOCOLOR}]\n"
    fi
fi

printf "      2.4.8   Ensure File Sharing Is Disabled\r"
result=$(sudo launchctl print-disabled system | grep -c '"com.apple.smbd" => true') &> /dev/null
if [[ "$result" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.4.9   Ensure Remote Management Is Disabled\r"
result=$(sudo ps -ef | grep -e ARDAgent | grep -c "/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/MacOS/ARDAgent") &> /dev/null
if [[ "$result" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.4.10  Ensure Content Caching Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'allowContentCaching = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.AssetCache Activated) &> /dev/null
    if [[ "$result_cmd" == 0 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.4.11  Ensure AirDrop Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'DisableAirDrop = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(defaults read com.apple.NetworkBrowser DisableAirDrop) &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.4.12  Ensure Media Sharing Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'homeSharingUIStatus = 0') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c 'legacySharingUIStatus = 0') &> /dev/null
result_policy3=$(echo "$CONFIGURATION_PROFILES" | grep -c 'mediaSharingUIStatus = 0') &> /dev/null
if [[ "$result_policy" == 1 ]] && [[ "$result_policy2" == 1 ]] && [[ "$result_policy3" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    mediaSharingStatusHome=$(defaults read com.apple.amp.mediasharingd home-sharing-enabled) &> /dev/null
    mediaSharingStatusPublic=$(defaults read com.apple.amp.mediasharingd public-sharing-enabled) &> /dev/null
    if [[ "$mediaSharingStatusHome" == 0 ]] && [[ "$mediaSharingStatusPublic" == 0 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    elif [[ "$mediaSharingStatusHome" == "" ]] && [[ "$mediaSharingStatusPublic" == "" ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.4.13  Ensure AirPlay Receiver Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AirplayRecieverEnabled = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(defaults read com.apple.controlcenter AirplayRecieverEnabled) &> /dev/null
    if [[ "$result_cmd" == 0 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.5.1.1 Ensure FileVault Is Enabled\r"
result=$(sudo fdesetup status | awk '{print $3}') &> /dev/null
if [[ "$result" == "Off." ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      2.5.1.2 Ensure all user storage APFS volumes are encrypted (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.5.1.3 Ensure all user storage CoreStorage volumes are encrypted\r"
apfsyes=$(sudo diskutil ap list) &> /dev/null
if [[ "$apfsyes" == "No APFS Containers found" ]]; then
    # get Logical Volume Family
    LFV=$(sudo diskutil cs list | grep 'Logical Volume Family' | awk '/Logical Volume Family/ {print $5}') &> /dev/null
    # Check encryption status is complete
    EncryptStatus=$(sudo diskutil cs "$LFV" | awk '/Conversion Status/ {print $3}') &> /dev/null
    if [[ "$EncryptStatus" != "Complete" ]]; then
        printf "[${RED}NOK${NOCOLOR}]\n"
    else
        printf "[${GREEN}OK${NOCOLOR}]\n"
    fi
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      2.5.2.1 Ensure Gatekeeper is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AllowIdentifiedDevelopers = 1') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c 'EnableAssessment = 1') &> /dev/null
if [[ "$result_policy" == 1 ]] && [[ "$result_policy2" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo spctl --status | grep -c 'assessments enabled') &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.5.2.2 Ensure Firewall Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'EnableFirewall = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.alf globalstate) &> /dev/null
    if [[ "$result_cmd" == 0 ]]; then
        printf "[${RED}NOK${NOCOLOR}]\n"
    else
        printf "[${GREEN}OK${NOCOLOR}]\n"
    fi
fi

printf "      2.5.2.3 Ensure Firewall Stealth Mode Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'EnableStealthMode = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | awk '{print $3}') &> /dev/null
    if [[ "$result_cmd" == "enabled" ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.5.3   Ensure Location Services Is Enabled\r"
result=$(sudo launchctl list | grep -c com.apple.locationd) &> /dev/null
if [[ "$result" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.5.4   Audit Location Services Access (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.5.5   Ensure Sending Diagnostic and Usage Data to Apple Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'allowDiagnosticSubmission = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit) &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${RED}NOK${NOCOLOR}]\n"
    else
        printf "[${GREEN}OK${NOCOLOR}]\n"
    fi
fi

printf "      2.5.6   Ensure Limit Ad Tracking Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c '"forceLimitAdTracking" = 1') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c '"allowApplePersonalizedAdvertising" = 0') &> /dev/null
if [[ "$result_policy" == 1 ]] && [[ "$result_policy2" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(defaults read com.apple.AdLib allowApplePersonalizedAdvertising) &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${RED}NOK${NOCOLOR}]\n"
    else
        printf "[${GREEN}OK${NOCOLOR}]\n"
    fi
fi

printf "      2.5.7   Audit Camera Privacy and Confidentiality (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.6.1.1 Audit iCloud Configuration\r"
result_cmd=$(defaults read ~/Library/Preferences/ Accounts | grep -c 'AccountDescription = iCloud') &> /dev/null
if [[ "$result_cmd" -gt 0 ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      2.6.1.2 Audit iCloud Keychain (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.6.1.3 Audit iCloud Drive (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.6.1.4 Ensure iCloud Drive Document and Desktop Sync is Disabled (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.6.2   Audit App Store Password Settings (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.7.1   Ensure Backup Up Automatically is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'AutoBackup = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.TimeMachine.plist AutoBackup) &> /dev/null
    if [[ "$result_cmd" != 1 ]]; then
        printf "[${RED}NOK${NOCOLOR}]\n"
    else
        printf "[${GREEN}OK${NOCOLOR}]\n"
    fi
fi

printf "      2.7.2   Ensure Time Machine Volumes Are Encrypted\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.8     Ensure Wake for Network Access Is Disabled (Plug in power source)\r"
result=$(sudo pmset -g | grep womp | awk '{print $2}') &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.9     Ensure Power Nap Is Disabled\r"
result=$(sudo pmset -g everything | grep -c 'powernap 1') &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      2.10    Ensure Secure Keyboard Entry terminal.app is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'SecureKeyboardEntry = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(defaults read -app Terminal SecureKeyboardEntry) &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.11    Ensure EFI Version Is Valid and Checked Regularly\r"
if [[ $(ioreg -w 0 -c AppleSEPManager | grep -q AppleSEPManager) ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    result=$(sudo /usr/libexec/firmwarecheckers/eficheck/eficheck --integrity-check | grep -c 'No changes detected') &> /dev/null
    if [[ "$result" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      2.12    Audit Automatic Actions for Optical Media (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.13    Audit Siri Settings (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.14    Audit Sidecar Settings (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.15    Audit Touch ID and Wallet & Apple Pay Settings (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.16    Audit Notification System Preference Settings (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      2.17    Audit Passwords System Preference Setting (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      3.1     Ensure Security Auditing Is Enabled\r"
result=$(sudo launchctl list | grep -c auditd) &> /dev/null
if [[ "$result" -gt 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      3.2     Ensure Security Auditing Flags Are Configured Per Local Organizational Requirements\r"
result=$(sudo egrep "^flags:" /etc/security/audit_control) &> /dev/null
if [[ "$result" != *"aa"* ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      3.3     Ensure install.log Is Retained for 365 or More Days and No Maximum Size\r"
result=$(sudo grep -i ttl /etc/asl/com.apple.install | awk -F'ttl=' '{print $2}') &> /dev/null
if [[ "$result" == "" ]] || [[ "$result" -lt 365 ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      3.4     Ensure Security Auditing Retention Is Enabled\r"
result=$(sudo cat /etc/security/audit_control | egrep expire-after) &> /dev/null
if [[ "$result" == "expire-after:60d OR 1G" ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      3.5     Ensure Access to Audit Records Is Controlled\r"
etccheck=$(sudo ls -le /etc/security/audit_control | awk '{print $3 $4}' | awk 'NF' | grep -v 'root wheel') &> /dev/null
varcheck=$(sudo ls -le /var/audit | awk '{print $3 $4}' | awk 'NF' | grep -v 'root wheel') &> /dev/null
if [[ "$etccheck" != "" ]] && [[ "$varcheck" != "" ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      3.6     Ensure Firewall Logging Is Enabled and Configured\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'EnableLogging = 1') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c 'LoggingOption = detail') &> /dev/null
if [[ "$result_policy" == 1 ]] && [[ "$result_policy2" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getloggingmode | sed -e 's/[[:space:]]*$//') &> /dev/null
    if [[ "$result_cmd" == "Log mode is on" ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      3.7     Audit Software Inventory\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      4.1     Ensure Bonjour Advertising Services Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'NoMulticastAdvertisements = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.mDNSResponder NoMulticastAdvertisements) &> /dev/null
    if [[ "$result_cmd" != 1 ]]; then
        printf "[${RED}NOK${NOCOLOR}]\n"
    else
        printf "[${GREEN}OK${NOCOLOR}]\n"
    fi
fi

printf "      4.2     Ensure Show Wi-Fi status in Menu Bar Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'WiFi = 18') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(defaults read com.apple.controlcenter Bluetooth) &> /dev/null
    if [[ "$result_cmd" == 18 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      4.3     Audit Network Specific Locations (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      4.4     Ensure HTTP Server Is Disabled\r"
result=$(sudo launchctl print-disabled system | grep -c '"org.apache.httpd" => true') &> /dev/null
if [[ "$result" == 1 ]] ; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      4.5     Ensure NFS Server Is Disabled\r"
result=$(sudo launchctl print-disabled system | grep -c '"com.apple.nfsd" => true') &> /dev/null
if [[ "$result" == 1 ]] ; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      4.6     Audit Wi-Fi Settings (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      5.1.1   Ensure Home Folders Are Secure\r"
result=$(sudo find /Users -mindepth 1 -maxdepth 1 -type d -perm -1 | grep -v "Shared" | grep -v "Guest" | wc -l | xargs) &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.1.2   Ensure System Integrity Protection Status (SIPS) Is Enabled\r"
result=$(sudo csrutil status | awk '{print $5}') &> /dev/null
if [[ "$result" == "enabled." ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.1.3   Ensure Apple Mobile File Integrity Is Enabled\r"
result=$(sudo nvram -p | grep -c 'amfi_get_out_of_my_way=1') &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.1.4   Ensure Library Validation Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep 'DisableLibraryValidation = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.security.libraryvalidation DisableLibraryValidation) &> /dev/null
    if [[ "$result_cmd" == 0 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      5.1.5   Ensure Sealed System Volume (SSV) Is Enabled\r"
result=$(sudo csrutil authenticated-root status | awk '{print $4}') &> /dev/null
if [[ "$result" == "enabled" ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.1.6   Ensure Appropriate Permissions Are Enabled for System Wide Applications\r"
result=$(sudo find /Applications -iname '*\.app' -type d -perm -2 -ls | wc -l | xargs) &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.1.7   Ensure No World Writable Files Exist in the System Folder\r"
result=$(sudo find  /System/Volumes/Data/System -type d -perm -2 -ls | grep -v 'Public/Drop Box' | wc -l | xargs) &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.1.8   Ensure No World Writable Files Exist in the Library Folder\r"
result=$(sudo find /Library -type d -perm -2 -ls | grep -v Caches | grep -v Adobe | grep -v VMware | grep -v '/Audio/Data' | wc -l | xargs) &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.2.1   Ensure Password Account Lockout Threshold Is Configured\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'maxFailedAttempts') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo pwpolicy -getaccountpolicies | grep -A 1 'policyAttributeMaximumFailedAuthentications' | tail -1 | cut -d'>' -f2 | cut -d'<' -f1) &> /dev/null
    if [[ "$result_cmd" -le 5 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      5.2.2   Ensure Password Minimum Length Is Configured\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'minLength') &> /dev/null
if [[ "$result_policy" -ge 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo pwpolicy -getaccountpolicies | grep -A1 minimumLength | tail -1 | cut -d'>' -f2 | cut -d'<' -f1) &> /dev/null
    if [[ "$result_cmd" -ge 15 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      5.2.3   Ensure Complex Password Must Contain Alphabetic Characters Is Configured\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'requireAlphanumeric') &> /dev/null
if [[ "$result_policy" -ge 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo pwpolicy -getaccountpolicies | grep -A1 minimumLetters | tail -1 | cut -d'>' -f2 | cut -d'<' -f1) &> /dev/null
    if [[ "$result_cmd" -ge 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      5.2.4   Ensure Complex Password Must Contain Numeric Character Is Configured\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'requireAlphanumeric') &> /dev/null
if [[ "$result_policy" -ge 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo pwpolicy -getaccountpolicies | grep -A1 minimumNumericCharacters | tail -1 | cut -d'>' -f2 | cut -d'<' -f1) &> /dev/null
    if [[ "$result_cmd" -ge 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      5.2.5   Ensure Complex Password Must Contain Special Character Is Configured\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'minComplexChars') &> /dev/null
if [[ "$result_policy" -ge 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo pwpolicy -getaccountpolicies | grep -A1 minimumSymbols | tail -1 | cut -d'>' -f2 | cut -d'<' -f1) &> /dev/null
    if [[ "$result_cmd" -ge 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      5.2.6   Ensure Complex Password Must Contain Uppercase and Lowercase Characters Is Configured\r"
result=$(sudo pwpolicy -getaccountpolicies | grep -A1 minimumMixedCaseCharacters | tail -1 | cut -d'>' -f2 | cut -d'<' -f1) &> /dev/null
if [[ "$result" -ge 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.2.7   Ensure Password Age Is Configured\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'maxPINAgeInDays') &> /dev/null
if [[ "$result_policy" -ge 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo pwpolicy -getaccountpolicies | grep -A1 policyAttributeDaysUntilExpiration | tail -1 | cut -d'>' - f2 | cut -d'<' -f1) &> /dev/null
    if [[ "$result_cmd" -le 365 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      5.2.8   Ensure Password History Is Configured\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'pinHistory') &> /dev/null
if [[ "$result_policy" -ge 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo pwpolicy -getaccountpolicies | grep -A1 policyAttributePasswordHistoryDepth | tail -1 | cut -d'>' - f2 | cut -d'<' -f1) &> /dev/null
    if [[ "$result_cmd" -ge 15 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      5.3     Ensure the Sudo Timeout Period Is Set to Zero\r"
result=$(sudo cat /etc/sudoers | grep timestamp) &> /dev/null
if [[ "$result" == "" ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      5.4     Ensure a Separate Timestamp Is Enabled for Each User/tty Combo\r"
result=$(sudo cat /etc/sudoers | egrep tty_tickets) &> /dev/null
if [[ "$result" != "" ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      5.5     Ensure login keychain is locked when the computer sleeps\r"
result=$(security show-keychain-info ~/Library/Keychains/login.keychain 2>&1 | grep -c 'lock-on-sleep') &> /dev/null
if [[ "$result" == 0 ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      5.6     Ensure the \"root\" Account Is Disabled\r"
rootEnabled=$(sudo dscl . -read /Users/root AuthenticationAuthority 2>&1 | grep -c 'No such key') &> /dev/null
rootEnabledRemediate=$(sudo dscl . -read /Users/root UserShell 2>&1 | grep -c '/usr/bin/false') &> /dev/null
if [[ "$rootEnabled" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
elif [[ "$rootEnabledRemediate" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.7     Ensure Automatic Login Is Disabled\r"
result=$(sudo defaults read /Library/Preferences/com.apple.loginwindow | grep -ow 'autoLoginUser') &> /dev/null
if [[ "$result" == "" ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.8     Ensure a Password is Required to Wake the Computer From Sleep or Screen Saver Is Enabled (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      5.9     Ensure system is set to hibernate\r"
result=$(sudo system_profiler SPHardwareDataType | egrep -c 'Model Identifier: MacBook') &> /dev/null
if [[ "$result" -ge 0 ]]; then
    hibernateValue=$(sudo pmset -g | egrep standbydelaylow | awk '{print $2}') &> /dev/null
    if [[ "$hibernateValue" == "" ]] || [[ "$hibernateValue" -le 900 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      5.10    Require an administrator password to access system-wide preferences\r"
result=$(sudo security authorizationdb read system.preferences 2> /dev/null | grep -A1 shared | grep -E '(true|false)' | grep -c 'true') &> /dev/null
if [[ "$result" == 1 ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      5.11    Ensure an administrator account cannot login to another user's active and locked session\r"
result=$(sudo security authorizationdb read system.login.screensaver | grep -c 'se-login-window-ui') &> /dev/null
if [[ "$result" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      5.12    Ensure a Custom Message for the Login Screen Is Enabled\r"
result=$(sudo defaults read /Library/Preferences/com.apple.loginwindow.plist LoginwindowText) &> /dev/null
if [[ $result == "" ]] || [[ $result = *"does not exist"* ]]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      5.13    Ensure a Login Window Banner Exists (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      5.14    Ensure Users' Accounts Do Not Have a Password Hint (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      5.15    Ensure Fast User Switching Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'MultipleSessionEnabled = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/.GlobalPreferences.plist MultipleSessionEnabled) &> /dev/null
    if [[ "$result_cmd" == 0 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      6.1.1   Ensure Login Window Displays as Name and Password Is Enabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'SHOWFULLNAME = 1') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.loginwindow SHOWFULLNAME) &> /dev/null
    if [[ "$result_cmd" == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      6.1.2   Ensure Show Password Hints Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'RetriesUntilHint = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.loginwindow RetriesUntilHint 2>&1)
    if [[ "$result_cmd" == 0 ]] || [[ $(echo "$result_cmd" | grep -c 'does not exist') == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      6.1.3   Ensure Guest Account Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep -c 'DisableGuestAccount = 1') &> /dev/null
result_policy2=$(echo "$CONFIGURATION_PROFILES" | grep -c 'EnableGuestAccount = 0') &> /dev/null
if [[ "$result_policy" == 1 ]] && [[ "$result_policy2" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/com.apple.loginwindow.plist GuestEnabled) &> /dev/null
    if [[ "$result_cmd" == 0 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      6.1.4   Ensure Guest Access to Shared Folders Is Disabled\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep 'AllowGuestAccess = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(sudo defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess 2>&1) &> /dev/null
    if [[ "$result_cmd" == 0 ]] || [[ $(echo "$result_cmd" | grep -c 'does not exist') == 1 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      6.1.5   Ensure the Guest Home Folder Does Not Exist\r"
if [ -e /Users/Guest ]; then
    printf "[${RED}NOK${NOCOLOR}]\n"
else
    printf "[${GREEN}OK${NOCOLOR}]\n"
fi

printf "      6.2     Ensure Show All Filename Extensions Setting is Enabled\r"
result=$(defaults read ~/Library/Preferences/.GlobalPreferences AppleShowAllExtensions) &> /dev/null
if [[ "$result" == 1 ]]; then
    printf "[${GREEN}OK${NOCOLOR}]\n"
else
    printf "[${RED}NOK${NOCOLOR}]\n"
fi

printf "      6.3     Ensure Automatic Opening of Safe Files in Safari Is Disabled (check needs Full Disk Access)\r"
result_policy=$(echo "$CONFIGURATION_PROFILES" | grep 'AutoOpenSafeDownloads = 0') &> /dev/null
if [[ "$result_policy" == 1 ]]; then
    printf "[${GREEN}MDM${NOCOLOR}]\n"
else
    result_cmd=$(defaults read ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoOpenSafeDownloads) &> /dev/null
    if [[ "$result_cmd" == 0 ]]; then
        printf "[${GREEN}OK${NOCOLOR}]\n"
    else
        printf "[${RED}NOK${NOCOLOR}]\n"
    fi
fi

printf "      7.1     Extensible Firmware Interface (EFI) password (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

printf "      7.2     FileVault and Local Account Password Reset using AppleID (Manual)\r"
printf "[${YELLOW}-${NOCOLOR}]\n"

echo "$(date -u)" "Audit complete"
exit 0