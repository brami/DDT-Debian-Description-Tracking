#!/bin/bash

#echo "update.sh disabled by Nekral (2011 07 27 19:48) to trigger it manually for the next round"
#exit 1


cd ~ddtp

LOGDIR=/srv/ddtp.debian.net/cronlog
LOGPREFIX=$LOGDIR/update.cron.$(date "+%Y%m%d-%H%M")

[ ! -d "$LOGDIR" ] && mkdir "$LOGDIR"

date                                      >> $LOGPREFIX.log
./Packages2packages_tb.sh                 >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./Packages2db.sh                          >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./completeTranslations.sh                 >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./db2web.sh                               >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./file2Translation.sh                     >> $LOGPREFIX.log 2>> $LOGPREFIX.err

# Regenerate the stats files
./ddts-stats sid                          >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./ddts-stats wheezy                       >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./ddts-stats squeeze                      >> $LOGPREFIX.log 2>> $LOGPREFIX.err

./popcon2db.pl                            >> $LOGPREFIX.log 2>> $LOGPREFIX.err
./fill_statistic.pl                       >> $LOGPREFIX.log 2>> $LOGPREFIX.err

#cp -a /home/grisu/public_html/ddtp/* /var/www/ddtp/

echo -n "Rotating (/srv/ddtp.debian.net/logrotate.config)" ... >> $LOGPREFIX.log
/usr/sbin/logrotate --state /srv/ddtp.debian.net/lib/logrotate.state /srv/ddtp.debian.net/logrotate.config
echo "OK"                                 >> $LOGPREFIX.log

date                                      >> $LOGPREFIX.log

cat $LOGPREFIX.err
