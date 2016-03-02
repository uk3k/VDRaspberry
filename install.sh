#!/bin/bash

##run this script as root or die! don't use sudo!!!
#quick n'dirty....this only works for armv7 (Raspberry Pi 2)


#important: before compiling edit FFDecsa-Section in the Makefiles for SC an DVBAPI:
#from "PARALLEL   ?= ????" to "PARALLEL   ?= PARALLEL_128_4INT"
#and remove all -mmmx -msse -msse2 -msse3 flags ;-) in the same section

echo "deb-src http://archive.raspbian.org/raspbian/ jessie main contrib non-free rpi" >> /etc/apt/sources.list
apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
apt-get install -y python-software-properties software-properties-common git git-core fontconfig libjpeg-dev lirc udisks upower xorg alsa-utils mesa-utils librtmp1 libmad0 lm-sensors libmpeg2-4 avahi-daemon libnfs4 consolekit pm-utils samba build-essential libcap-dev gettext libncurses-dev pkg-config w-scan cmake subversion openssl libssl-dev libusb-dev libusb-1.0 libpcsc-perl libpcsclite-dev
apt-get build-dep -y vdr
apt-get build-dep -y kodi

#vdr
### testing ###
install="/home/pi"
tv_vdr="true"
tv_oscam="true"
### testing end ###

#vdr
if [ "$tv_vdr" = "true" ]
  then
  useradd vdr
  usermod -a -G video vdr
  mkdir -p $install/src /var/vdr /var/vdr/record
  mkdir -p /var/lib/vdr/plugins/vnsiserver /var/lib/vdr/plugins/streamdev-server /var/lib/vdr/plugins/sc /var/lib/vdr/plugins/svdrpservice
  chown -R :video /var/vdr /var/lib/vdr/
  chmod -R g+w /var/vdr /var/lib/vdr/
  cd /$install/src
  #git clone git://projects.vdr-developer.org/vdr.git

  #use stable release for testing
  wget https://projects.vdr-developer.org/git/vdr.git/snapshot/vdr-vdr-2.2.0.tar.gz
  tar xfvz vdr-vdr-2.2.0.tar.gz
  rm vdr-vdr-2.2.0.tar.gz
  mv vdr-vdr-2.2.0 vdr
  #end code use stable release for testing

cd /$install/src/vdr/PLUGINS/src
  #get plugin sources (streamdev, vnsi, dvbapi, svdrpservice, sc)
  git clone git://projects.vdr-developer.org/vdr-plugin-streamdev.git
  git clone https://github.com/FernetMenta/vdr-plugin-vnsiserver
  git clone https://github.com/manio/vdr-plugin-dvbapi.git
  git clone https://github.com/3PO/vdr-plugin-sc.git
  wget http://vdr.schmirler.de/svdrpservice/vdr-svdrpservice-1.0.0.tgz
  tar -xzf vdr-svdrpservice-1.0.0.tgz
  rm *.tgz
  ln -s vdr-plugin-streamdev streamdev
  ln -s vdr-plugin-vnsiserver vnsiserver
  ln -s vdr-plugin-dvbapi dvbapi
  ln -s vdr-plugin-sc sc
  ln -s svdrpservice-1.0.0 svdrpservice
  nano vdr-plugin-sc/Makefile
  nano vdr-plugin-dvbapi/Makefile
  cd ../../
  make -j4 && make install
fi

#oscam
if [ "$tv_oscam" = "true" ]
        then
                cd $install/src
                rm -R oscam*
                svn co http://streamboard.de.vu/svn/oscam/trunk oscam-svn
                cd oscam-svn*
                mkdir build
                cd build
                cmake .. -DHAVE_LIBUSB=1 -DWEBIF=1 -DHAVE_DVBAPI=1 -DCARDREADER_SMARGO=1 -DUSE_LIBUSB=1 -DWEBIF=1 -DIRDETO_GUESSING=1 -DCS_ANTICASC=1 -DWITH_DEBUG=1 -DCS_WITH_DOUBLECHECK=1 -DCS_LED=0 -DQBOXHD_LED=0 -DCS_LOGHISTORY=1 -DWITH_SSL=0 -DMODULE_CAMD33=0 -DMODULE_CAMD35=1 -DMODULE_CAMD35_TCP=1 -DMODULE_NEWCAMD=1 -DMODULE_CCCAM=1 -DMODULE_GBOX=1 -DMODULE_RADEGAST=1 -DMODULE_SERIAL=1 -DMODULE_MONITOR=1 -DMODULE_CONSTCW=1 -DREADER_NAGRA=1 -DREADER_IRDETO=1 -DREADER_CONAX=1 -DREADER_CRYPTOWORKS=1 -DREADER_SECA=1 -DREADER_VIACCESS=1 -DREADER_VIDEOGUARD=1 -DREADER_DRE=1 -DREADER_TONGFANG=1 -DCMAKE_BUILD_TYPE=Debug
                make -j4 && make install
fi

#write configs and scripts

#vdr

cat > /var/lib/vdr/vdr.groups <<vdrgroups
vdr
video
vdrgroups

#create access rules for vdr
echo "192.168.1.0/24	#any host on the local net" > /var/lib/vdr/allowed_hosts.conf
echo "newcamd:127.0.0.1:33330:1/1838/FFFF:softcam:dummy:0102030405060708091011121314" > /var/lib/vdr/cardclient.conf
ln -s /var/lib/vdr/allowed_hosts.conf /var/lib/vdr/svdrphosts.conf
ln -s /var/lib/vdr/allowed_hosts.conf > /var/lib/vdr/plugins/vnsiserver/allowed_hosts.conf
ln -s /var/lib/vdr/allowed_hosts.conf > /var/lib/vdr/plugins/streamdev-server/streamdevhosts.conf
ln -s /var/lib/vdr /etc/vdr

#init-scripts
wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/vdr/vdr
wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/oscam/oscam

chmod +x /etc/init.d/oscam
chmod +x /etc/init.d/vdr
chmod +x /usr/local/bin/runvdr
update-rc.d oscam defaults
udate-rc.d vdr defaults

###create oscam logging dir
mkdir -p /var/log/oscam
chmod -R 775 /var/log/oscam/
chown -R nobody /var/log/oscam
