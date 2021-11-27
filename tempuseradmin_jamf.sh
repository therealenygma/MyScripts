#!/bin/bash
set -x

USERNAME=`who |grep console| awk '{print $1}'`

TIMEINTERVAL = ""

# note the user
echo $USERNAME >> /var/somelogfolder/userToRemove

if [ "$4" != "" ] && [ "$TIMEINTERVAL == "" ];then
    TIMEINTERVAL=$4
fi
# give current logged user admin rights
/usr/sbin/dseditgroup -o edit -a $USERNAME -t user admin

# create LaunchDaemon to remove admin rights
#####
echo '<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict>
	<key>Disabled</key>
	<false/>
	<key>Label</key> 
	<string>com.tempadmin.adminremove</string> 
	<key>ProgramArguments</key> 
	<array> 
		<string>/Library/Scripts/removeTempAdmin.sh</string>
	</array>
	<key>StartInterval</key>
	<integer>$TIMEINTERVAL</integer> 
</dict> 
</plist>' > /Library/LaunchDaemons/com.tempadmin.adminremove.plist
#####



# create admin rights removal script
#####
echo '#!/bin/bash
if [[ -f /var/somelogfolder/userToRemove ]]; then 
USERNAME=`cat /var/somelogfolder/userToRemove`
echo "removing" $USERNAME "from admin group"
/usr/sbin/dseditgroup -o edit -d $USERNAME -t user admin
rm -f /var/somelogfolder/userToRemove
else

defaults write /Library/LaunchDaemons/com.tempadmin.adminremove.plist disabled -bool false
	echo "going to unload"
	launchctl unload -w /Library/LaunchDaemons/com.tempadmin.adminremove.plist
	echo "Completed"
	rm -f /Library/LaunchDaemons/com.tempadmin.adminremove.plist
fi

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Utilities/Keychain\ Access.app/Contents/Resources/Keychain_Unlocked.png -heading 'Temporary Admin Ended' -description "
Your time as n admin has come to an end." -button1 'OK' > /dev/null 2>&1 &
exit 0' > /Library/Scripts/removeTempAdmin.sh
#####

# set the permission on the files just made
chown root /Library/LaunchDaemons/com.tempadmin.adminremove.plist
chmod 644 /Library/LaunchDaemons/com.tempadmin.adminremove.plist
defaults write /Library/LaunchDaemons/com.tempadmin.adminremove.plist disabled -bool false
chmod 755 /Library/Scripts/removeTempAdmin.sh


# enable and load the LaunchDaemon
launchctl load -w /Library/LaunchDaemons/com.tempadmin.adminremove.plist


# build log files in /var/somelogfolder
[ ! -d /var/somelogfolder ] && mkdir /var/somelogfolder
TIME=`date "+Date:%m-%d-%Y TIME:%H:%M:%S"`
echo $TIME " by " $USERNAME >> /var/somelogfolder/10minAdmin.txt

# notify
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Utilities/Keychain\ Access.app/Contents/Resources/Keychain_Unlocked.png -heading 'Temporary Admin Granted' -description "
Please use responsibly. 
All administrative activity is logged. 
Access expires in 10 minutes." -button1 'OK' > /dev/null 2>&1 &

exit 0