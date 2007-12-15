#!/bin/bash

cd ~ddtp

./Packages2db.sh
./db2web.sh
./db2Translation.sh

# Regenerate the stats files
#/home/kleptog/stats/ddts-stats sid
#/home/kleptog/stats/ddts-stats etch

#cp -a /home/grisu/public_html/ddtp/* /var/www/ddtp/
