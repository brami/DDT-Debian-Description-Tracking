#!/bin/bash

cd ~ddtp

LOGDIR=/srv/ddtp.debian.net/cronlog
LOGPREFIX=$LOGDIR/update.cron.$(date "+%Y%m%d-%H%M")

[ ! -d "$LOGDIR" ] && mkdir "$LOGDIR"

# This should be removed later -- Nekral
date

date                                      >> $LOGPREFIX.log
#./Packages2packages_tb.sh                 >> $LOGPREFIX.log 2>> $LOGPREFIX.err
#./Packages2db.sh                          >> $LOGPREFIX.log 2>> $LOGPREFIX.err
#./completeTranslations.sh                 >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./db2web.sh                               >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./file2Translation.sh                     >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./file2Translation_udd.sh                 >> $LOGPREFIX.log 2>> $LOGPREFIX.err

# Regenerate the stats files
/home/kleptog/stats/ddts-stats sid >/dev/null
/home/kleptog/stats/ddts-stats wheezy >/dev/null
/home/kleptog/stats/ddts-stats squeeze >/dev/null

#cp -a /home/grisu/public_html/ddtp/* /var/www/ddtp/

#/usr/sbin/logrotate --state /org/ddtp.debian.net/lib/logrotate.state /org/ddtp.debian.net/logrotate.config

cat $LOGPREFIX.err

# This should be removed later -- Nekral
date
