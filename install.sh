#!/bin/bash

##run this script as root or die! don't use sudo!!!
#quick n'dirty....this only works for armv7 (Raspberry Pi 2)
#start from scratch using fresh raspbian jessie image and resize root partition first!!!
#important: before compiling edit FFDecsa-Section in the Makefiles for SC an DVBAPI:
#from "PARALLEL   ?= ????" to "PARALLEL   ?= PARALLEL_128_4INT"
#and remove all -mmmx -msse -msse2 -msse3 flags ;-) in the same section

#note: oscam and vdr are preconfigured for unitymedia (NRW) but due 
#actual law restrictions you have to get rsa-key and box-key for oscam.server on your own

#replace systemd with upstart
sudo apt-get install -y upstart systemd-shim systemd-sysv-
apt-get update && apt-get upgrade -y

#install packages
echo "deb-src http://archive.raspbian.org/raspbian/ jessie main contrib non-free rpi" >> /etc/apt/sources.list
apt-get update
apt-get install -y python-software-properties software-properties-common git git-core fontconfig htop
apt-get install -y libjpeg-dev lirc udisks upower xorg alsa-utils mesa-utils librtmp1 libmad0 lm-sensors 
apt-get install -y libmpeg2-4 avahi-daemon libnfs4 consolekit pm-utils samba build-essential 
apt-get install -y libcap-dev gettext libncurses-dev pkg-config w-scan cmake subversion openssl libssl-dev 
apt-get install -y libusb-dev libusb-1.0 libpcsc-perl libpcsclite-dev
apt-get build-dep -y vdr
apt-get build-dep -y oscam

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
  mkdir -p $install/src $install/download /var/vdr /var/vdr/record
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
  sed -i 's/PARALLEL_128_SSE2/PARALLEL_128_4INT/' vdr-plugin-sc/Makefile
  sed -i 's/-mmmx//' vdr-plugin-sc/Makefile
  sed -i 's/-msse//' vdr-plugin-sc/Makefile
  sed -i 's/-msse2//' vdr-plugin-sc/Makefile
  sed -i 's/-msse3//' vdr-plugin-sc/Makefile
  sed -i 's/PARALLEL_128_SSE2/PARALLEL_128_4INT/' vdr-plugin-dvbapi/Makefile
  sed -i 's/-mmmx//' vdr-plugin-dvbapi/Makefile
  sed -i 's/-msse//' vdr-plugin-dvbapi/Makefile
  sed -i 's/-msse2//' vdr-plugin-dvbapi/Makefile
  sed -i 's/-msse3//' vdr-plugin-dvbapi/Makefile
  #nano vdr-plugin-dvbapi/Makefile
  #nano vdr-plugin-sc/Makefile
  cd ../../
  make -j4 && make install

#add users to vdr-groups
cat > /var/lib/vdr/vdr.groups <<vdrgroups
vdr
video
vdrgroups

  cd $install/download
  #download main vdr configs
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/vdr/vdr.conf
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/vdr/setup.conf
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/vdr/channels.conf
  #wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/vdr/runvdr
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/vdr/startvdr.sh
  mv vdr.conf /etc/init/vdr.conf
  mv setup.conf /var/lib/vdr/setup.conf
  mv channels.conf /var/lib/vdr/channels.conf
  #mv runvdr /usr/local/bin/runvdr
  mv startvdr.sh /var/lib/vdr/startvdr.sh

  #install init-script
  #chmod +x /usr/local/bin/runvdr
  chmod +x /var/lib/vdr/startvdr.sh
  
  #create and link plugin configs
  echo "newcamd:127.0.0.1:33330:1/1838/FFFF:softcam:dummy:0102030405060708091011121314" > /var/lib/vdr/plugins/sc/cardclient.conf
  touch /var/lib/vdr/plugins/sc/cardslot.conf
  touch /var/lib/vdr/plugins/sc/override.conf
  touch /var/lib/vdr/plugins/sc/smartcard.conf
  touch /var/lib/vdr/plugins/sc/SoftCam.Key
  echo "192.168.1.0/24	#any host on the local net" > /var/lib/vdr/allowed_hosts.conf
  rm /var/lib/vdr/allowed_hosts.conf /var/lib/vdr/allowed_hosts.conf /var/lib/vdr/allowed_hosts.conf
  rm -r /etc/vdr
  ln -s /var/lib/vdr/allowed_hosts.conf /var/lib/vdr/svdrphosts.conf
  ln -s /var/lib/vdr/allowed_hosts.conf > /var/lib/vdr/plugins/vnsiserver/allowed_hosts.conf  
  ln -s /var/lib/vdr/allowed_hosts.conf > /var/lib/vdr/plugins/streamdev-server/streamdevhosts.conf
  ln -s /var/lib/vdr /etc/vdr
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
  
  #download main oscam configs
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/oscam/oscam
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/oscam/oscam.conf
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/oscam/oscam.server
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/oscam/oscam.user
  wget https://raw.githubusercontent.com/uk3k/VDRaspberry/master/configs/oscam/oscam.dvbapi
  mv oscam /etc/init.d/oscam
  mv oscam.conf /usr/local/etc/oscam.conf
  mv oscam.server /usr/local/etc/oscam.server
  mv oscam.user /usr/local/etc/oscam.user
  mv oscam.dvbapi /usr/local/etc/oscam.dvbapi

  #install init-script
  chmod +x /etc/init.d/oscam
  update-rc.d oscam defaults

  ###create oscam logging dir
  mkdir -p /var/log/oscam
  chmod -R 775 /var/log/oscam/
  chown -R nobody /var/log/oscam
fi

#install sundtek dvb-c driver
wget http://sundtek.de/media/sundtek-netinst-driver.deb
dpkg -i sundtek-netinst-driver.deb
