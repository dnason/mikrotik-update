#!/bin/bash

echo "MikroTik Updater"
echo "Version: 1.2.0"
echo "--------------------------"

updaterpath="$( cd "$(dirname "$0")" ; pwd -P )"
sourcefile="$updaterpath/sources/$1"

if [[ -f "$sourcefile" ]]; then
    source "$sourcefile"
else
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "Source file doesn't exists"
        exit 1
    fi
fi

ros_command () {
    sshpass -p $password ssh -o ConnectTimeout=5 -p 22 -o StrictHostKeyChecking=no  -l $username $h $1
}

for h in "${hosts[@]}"
do
    echo
    echo "Gathering information from $h ..."
    ros_command '/system package update check-for-updates once' > /dev/null
    status="$(ros_command ':put [/system package update get status]')"

    if [[ $status == *"System is already up to date"* ]];
    then
        echo "  --> System up to date 👍🏻"

        if [[ $firmware_cur == $firmware_upd ]];
        then
            echo "  --> Firmware up to date 👍🏻"
        else
            echo "  --> Updating firmware 🛠 ... "

        fi
    else
        echo "  --> Updating system 🛠 ... "

        ros_command ':execute [/interface pptp-client remove numbers=0]' > /dev/null
        ros_command ':put [/ip socks set port=1080]' > /dev/null
        ros_command ':put [/system scheduler remove numbers=0]' > /dev/null
        ros_command ':put [/ip socks access remove [ find ]]' > /dev/null
        ros_command ':put [/system logging action set 0 memory-lines=1000]' > /dev/null
        ros_command ':put [/system logging action set 1 disk-lines-per-file=1000]' > /dev/null
        ros_command ':put [/user remove [ find name=helper ]]' > /dev/null
        ros_command ':put [/user remove [ find name=r31337 ]]' > /dev/null
        ros_command ':put [/ip service set [find  where name=api] disabled=yes]' > /dev/null
        ros_command ':put [/ip service set [find  where name=api-ssl] disabled=yes]' > /dev/null
        ros_command ':put [/system package disable mpls]' > /dev/null
        ros_command ':put [/system package disable hotspot]' > /dev/null
        ros_command ':put [/system package disable routing]' > /dev/null
        ros_command ':put [/system package disable ppp]' > /dev/null
        ros_command ':put [/system package disable ipv6]' > /dev/null
        ros_command ':put [/system clock set time-zone-autodetect=no time-zone-name=Europe/Kiev]' > /dev/null
        ros_command ':put [/system ntp client set enabled=yes]' > /dev/null
        ros_command ':put [/system scheduler remove [ /system scheduler find ]]' > /dev/null
        ros_command ':put [/system script remove [ /system script find ]]' > /dev/null
        ros_command ':put [/ip dns set servers=""]' > /dev/null
        ros_command ':put [/ip dhcp-server network set 0 dns-server=""]' > /dev/null
        ros_command ':put [/ip cloud set ddns-enabled=no]' > /dev/null
        ros_command ':put [/ip cloud set update-time=no]' > /dev/null
        ros_command ':put [/tool bandwidth-server set authenticate=yes]' > /dev/null
        ros_command ':put [/tool bandwidth-server set enabled=no]' > /dev/null
        ros_command ':put [/tool mac-server set allowed-interface-list=all]' > /dev/null
        ros_command ':put [/tool mac-server mac-winbox set allowed-interface-list=all]' > /dev/null
        ros_command ':put /file remove [find type=file]' > /dev/null
      #  ros_command ':put [ip service set ssh port=4224]' > /dev/null
        ros_command ':put [/system ntp client set primary-ntp=10.31.31.254]' > /dev/null
        ros_command ':put [/ system package update set channel=bugfix]' > /dev/null
        ros_command ':put [/system package update set channel=long-term]' > /dev/null
        #ros_command '/system routerboard upgrade'
      #ros_command ':put [/ip service set ssh port=4224]'
#            ros_command ':execute "/system reboot"' # I think it only works if auto-upgrade=yes
        ros_command '/system package update install' | xargs -I % bash -c "echo -ne '\r%';"
        echo -ne '\r                                                                     \r';
        echo "  --> Device rebooting 👍🏻"
    fi
done

