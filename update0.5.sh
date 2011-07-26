#!/bin/bash

cd ~ddtp

#./Packages2packages_tb.sh
#./Packages2db.sh
./db2web.sh
# ./db2Translation.sh
./file2Translation.sh
./file2Translation_udd.sh

# Regenerate the stats files
/home/kleptog/stats/ddts-stats sid >/dev/null
/home/kleptog/stats/ddts-stats wheezy >/dev/null
/home/kleptog/stats/ddts-stats squeeze >/dev/null

#cp -a /home/grisu/public_html/ddtp/* /var/www/ddtp/

#/usr/sbin/logrotate --state /org/ddtp.debian.net/lib/logrotate.state /org/ddtp.debian.net/logrotate.config

date
