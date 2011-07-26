#!/bin/bash -e

cd ~ddtp

# Fetch active langs from database
LANGS=`psql ddtp -q -A -t -c "select distinct language from translation_tb"`

#DISTS="lenny squeeze wheezy sid"
DISTS="squeeze wheezy sid"

rm -rf Translation_udd

for distribution in $DISTS
do
	sed -e "s/ [^ ][^ ]*$//" < packagelist/$distribution | sort | uniq > Packages/packagelist-$distribution
	for lang in $LANGS
	do
		mkdir -p Translation_udd/dists/$distribution/main/i18n/ 
		./file2Translation.pl --with-version $distribution $lang | uniq | gzip > Translation_udd/dists/$distribution/main/i18n/Translation-$lang.gz
		echo `date`: create the $distribution/Translation-$lang
	done
	cp packagelist/timestamp packagelist/timestamp.gpg Translation_udd/
	cd Translation_udd
	sha256sum dists/$distribution/main/i18n/Translation-* >> SHA256SUMS
	cd ~ddtp
done

rm -rf ./www/Translation_udd
cp -a ./Translation_udd/ ./www/
