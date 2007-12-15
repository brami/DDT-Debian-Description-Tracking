#!/bin/bash -e

cd ~ddtp

ARCHIV=~www-data/ddtp/debian

mkdir -p $ARCHIV

echo `date`: start build Translations files
for distribution in etch sid
do
	for lang in cs da de eo es fi fr hu it ja nl pl pt_BR pt_PT ru sk sv_SE uk
	do
		echo `date`: $distribution $lang
		./Translation2db.pl Translations_$distribution/Translation-$lang $lang
		echo `date`: write Translations_$distribution/Translation-$lang from db
		mkdir -p $ARCHIV/dists/$distribution/main/i18n/
		cp Translations_$distribution/Translation-$lang $ARCHIV/dists/$distribution/main/i18n/
		gzip < $ARCHIV/dists/$distribution/main/i18n/Translation-$lang > $ARCHIV/dists/$distribution/main/i18n/Translation-$lang.gz
		bzip2 < $ARCHIV/dists/$distribution/main/i18n/Translation-$lang > $ARCHIV/dists/$distribution/main/i18n/Translation-$lang.bz2
		echo `date`: create Translation-$lang gz/bz2 files
	done
done

echo `date`: finish build Translations files
echo `date`: start build Translations.tar.gz
(cd $ARCHIV/dists/ && tar -zkvcf ../Translations_new.tar.gz etch/main/i18n/ sid/main/i18n/ && mv ../Translations_new.tar.gz ../Translations.tar.gz)
echo `date`: finish build Translations.tar.gz
