#!/usr/bin/env bash
# ZeroCar Install Script
# by jrossmanjr -- https://github.com/jrossmnajr/zerocar
# Use a RaspberryPi as a WiFi hotspot to serve up files
#---------------------------------------------------Thanks Developers------------------------------------------------#
# Shoutout to the folks making PiHole, Adafruit, & PIRATEBOX for showing me the way and essentially teaching me BASH
# A lot of help came from ADAFRUIT: https://learn.adafruit.com/setting-up-a-raspberry-pi-as-a-wifi-access-point/install-software
# Thanks to RaspberryConnect.com for some refinement of the setup code
# RaspiAP by billz is awesome and make management easier -- https://github.com/billz/raspap-webgui
# thanks to Moe Long for a Jellyfin tutorial -- https://www.electromaker.io/tutorial/blog/how-to-install-jellyfin-on-the-raspberry-pi
#--------------------------------------------------------------------------------------------------------------------#
# MIT License
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
#documentation files (the "Software"), to deal in the Software without restriction, including without limitation
#the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
#and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
#THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
#OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
#OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#--------------------------------------------------------------------------------------------------------------------#
echo ":::
███████╗███████╗██████╗  ██████╗  ██████╗ █████╗ ██████╗
╚══███╔╝██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔══██╗██╔══██╗
  ███╔╝ █████╗  ██████╔╝██║   ██║██║     ███████║██████╔╝
 ███╔╝  ██╔══╝  ██╔══██╗██║   ██║██║     ██╔══██║██╔══██╗
███████╗███████╗██║  ██║╚██████╔╝╚██████╗██║  ██║██║  ██║
╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝
    By - jrossmanjr   //   https://github.com/jrossmnajr/zerocar             "

# Find the rows and columns will default to 80x24 if it can not be detected
screen_size=$(stty size 2>/dev/null || echo 24 80)
rows=$(echo $screen_size | awk '{print $1}')
columns=$(echo $screen_size | awk '{print $2}')

# Divide by two so the dialogues take up half of the screen, which looks nice.
r=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
c=$(( c < 70 ? 70 : c ))


# Run this script as root or under sudo
if [[ $EUID -eq 0 ]];then
  echo "::: You are root."
else
  echo "::: sudo will be used."
  # Check if it is actually installed
  # If it isn't, exit because the install cannot complete
  if [[ $(dpkg-query -s sudo) ]];then
    export SUDO="sudo"
  else
    echo "::: Please install sudo or run this script as root."
    exit 1
  fi
fi

# Into popups, variable setup, and directory creation
whiptail --msgbox --title "ZeroCar automated installer" "\nThis installer turns your Raspberry Pi into \nan awesome WiFi router and media streamer!" ${r} ${c}
whiptail --msgbox --title "ZeroCar automated installer" "\n\nFirst things first... Lets set up some variables!" ${r} ${c}
var2=$(whiptail --inputbox "Name the WiFi Hotspot" ${r} ${c} ZeroCar --title "Wifi Name" 3>&1 1>&2 2>&3)
var3=$(whiptail --passwordbox "Please enter a password for the WiFi hotspot" ${r} ${c} --title "HotSpot Password" 3>&1 1>&2 2>&3)
whiptail --msgbox --title "ZeroCar automated installer" "\n\nOk all the data has been entered...The install will now complete!" ${r} ${c}
#mkdir media
#cd media
#mkdir config
#mkdir tv
#mkdir movies
#--------------------------------------------------------------------------------------------------------------------#
# Functions to setup the rest of the server
#--------------------------------------------------------------------------------------------------------------------#


function delete_junk() {
# delete all the junk that has nothing to do with being a lightweight server if your using the full install not lite
  echo ":::"
  echo "::: Removing JUNK...from the trunk"
  $SUDO apt-get -y purge dns-root-data minecraft-pi python-minecraftpi wolfram-engine sonic-pi libreoffice scratch
  $SUDO apt-get autoremove
  echo "::: DONE!"
}

function install_the_things() {
  echo ":::"
  echo "::: Updating and installing necessary files"
  $SUDO apt update
  $SUDO apt upgrade -y
  $SUDO apt install -y wget git apt-transport-https
  echo "::: DONE installing all the things!"
}

function install_jellyfin() {
  # install Jellyfin
  echo ":::"
  echo "::: Installing Jellyfin"
  $SUDO add-apt-repository universe
  echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/ubuntu $( lsb_release -c -s ) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
  wget -O - https://repo.jellyfin.org/debian/jellyfin_team.gpg.key | sudo apt-key add -
  $SUDO apt update
  $SUDO apt install jellyfin -y
  $SUDO usermod -aG video jellyfin
  $SUDO systemctl restart jellyfin
  echo ":::"
  echo "::: DONE!"
}

function instal_raspiap() {
  echo ":::"
  echo "::: Installing Access Pont Software..."
  whiptail --msgbox --title "Installing Access Pont Software" "\n ********************************* \n *** DO NOT RESTART WHEN RaspiAP FINISHES!  *** \n  ********************************* " ${r} ${c}
  wget -q https://git.io/voEUQ -O /tmp/raspap && bash /tmp/raspap
}

function edit_hostapd() {
  # editing hostapd and associated properties
  echo ":::"
  echo "::: Editing hostapd"
  $SUDO echo 'driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
auth_algs=1
wpa_key_mgmt=WPA-PSK
beacon_int=100
channel=36
hw_mode=a

# N
ieee80211n=1
require_ht=1
ht_capab=[MAX-AMSDU-3839][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]

# AC
ieee80211ac=1
require_vht=1
ieee80211d=0
ieee80211h=0
vht_capab=[MAX-AMSDU-3839][SHORT-GI-80]
vht_oper_chwidth=1
vht_oper_centr_freq_seg0_idx=42

interface=wlan0
wpa=2
wpa_pairwise=CCMP
country_code=US
ignore_broadcast_ssid=0' > /etc/hostapd/hostapd.conf
  echo "ssid=$var2" | sudo tee --append /etc/hostapd/hostapd.conf > /dev/null
  echo "wpa_passphrase=$var3" | sudo tee --append /etc/hostapd/hostapd.conf > /dev/null
  echo "::: DONE!"
}

function edit_dhcpdconf() {
  # editing dhcpcd
  echo ":::"
  echo "::: Editing dhcpd.conf"
  $SUDO echo '# RaspAP wlan0 configuration
hostname
clientid
persistent
option rapid_commit
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
option ntp_servers
require dhcp_server_identifier
slaac private
nohook lookup-hostname
interface wlan0
static ip_address=10.0.0.1/24
static domain_name_server=1.1.1.1 8.8.8.8' > /etc/dhcpcd.conf
  echo "::: DONE!"
}

function edit_dnsmasq() {
  # editing dnsmasq
  echo ":::"
  echo "::: Editing dnsmasq.conf"
  echo "domain-needed
interface=wlan0
dhcp-range=10.0.0.2,10.0.0.245,255.255.255.0,24h" > /etc/dnsmasq.conf
  echo "::: DONE"
}

function finishing_touches() {
  # restarting
  echo "::: Finishing touches..."
  $SUDO chmod -R 777 /home/pi
  $SUDO sysctl -p
  var4=$(hostname -I)
  echo "::: To setup Jellyfin --- Access at $var4:8096"
  echo "::: "
  echo "::: PLEASE RESTART THE PI! :::"
}


delete_junk
install_the_things
install_jellyfin
instal_raspiap
edit_hostapd
edit_dhcpdconf
edit_dnsmasq
finishing_touches