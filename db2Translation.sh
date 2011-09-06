#!/bin/bash -e

cd ~ddtp

# Fetch active langs from database
LANGS=`psql ddtp -q -A -t -c "select distinct language from translation_tb where description_id>1"`

for distribution in etch lenny sid
do
	for lang in $LANGS
	do
		mkdir -p new_trans/dists/$distribution/main/i18n/ 
		./db2Translation.pl $distribution $lang > new_trans/dists/$distribution/main/i18n/Translation-$lang
		echo `date`: create the $distribution/Translation-$lang
		bzip2 < new_trans/dists/$distribution/main/i18n/Translation-$lang > new_trans/dists/$distribution/main/i18n/Translation-$lang.bz2
		echo `date`: create the $distribution/Translation-$lang.bz2
		gzip < new_trans/dists/$distribution/main/i18n/Translation-$lang > new_trans/dists/$distribution/main/i18n/Translation-$lang.gz
		echo `date`: create the $distribution/Translation-$lang.gz
	done
	mkdir -p new_trans/dists/$distribution/main/binary-i386/
	touch new_trans/dists/$distribution/main/binary-i386/Packages
	gzip < new_trans/dists/$distribution/main/binary-i386/Packages >  new_trans/dists/$distribution/main/binary-i386/Packages.gz
	bzip2 < new_trans/dists/$distribution/main/binary-i386/Packages > new_trans/dists/$distribution/main/binary-i386/Packages.bz2
	mkdir -p new_trans/dists/$distribution/main/binary-amd64/
	touch new_trans/dists/$distribution/main/binary-amd64/Packages
	gzip < new_trans/dists/$distribution/main/binary-amd64/Packages >  new_trans/dists/$distribution/main/binary-amd64/Packages.gz
	bzip2 < new_trans/dists/$distribution/main/binary-amd64/Packages > new_trans/dists/$distribution/main/binary-amd64/Packages.bz2
done

cd new_trans/dists/
tar -zkcf ../Translations.tar.gz .

cd ~ddtp
rm -rf /var/www/ddtp/debian/
mv new_trans /var/www/ddtp/debian
