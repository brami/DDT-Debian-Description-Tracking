#!/bin/bash

cd ~ddtp

./Packages2db.sh
./db2web.sh
./db2Translation.sh

# Regenerate the stats files
/home/kleptog/stats/ddts-stats sid >/dev/null
/home/kleptog/stats/ddts-stats lenny >/dev/null
/home/kleptog/stats/ddts-stats etch >/dev/null

#cp -a /home/grisu/public_html/ddtp/* /var/www/ddtp/
