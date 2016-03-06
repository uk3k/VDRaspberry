#!/bin/bash

#temporary fix for not working runvdr on VDRaspbian
#2016-03-06 Paul Krause

#start sundtek mediaclient driver
/opt/bin/mediaclient --start
#run vdr
/usr/local/bin/vdr -w 60 --video=/var/vdr/record --epgfile=/var/vdr/epg.data export VDR_CHARSET_OVERRIDE="ISO-8859-15" -P vnsiserver -P dvbapi -P streamdev-server -P svdrpservice
