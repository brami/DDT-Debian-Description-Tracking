#!/bin/bash -e

cd ~ddtp

# Fetch active langs from database
LANGS=`psql ddtp -q -A -t -c "select distinct language from translation_tb"`

#DISTS="lenny sid"
#DISTS="squeeze sid"
DISTS="wheezy sid"

mkdir -p packagelist
cd packagelist
for distribution in $DISTS squeeze md5sum timestamp timestamp.gpg
do
	rm -f $distribution
	wget -q -m -nd http://ftp-master.debian.org/i18n/$distribution || \
		echo "failed to wget http://ftp-master.debian.org/i18n/$distribution"
done
md5sum --check md5sum
cd ..

rm -rf Translation-files_new

for distribution in $DISTS
do
	sed -e "s/ [^ ][^ ]*$//" < packagelist/$distribution | sort | uniq > Packages/packagelist-$distribution
	for lang in $LANGS
	do
		mkdir -p Translation-files_new/dists/$distribution/main/i18n/ 
		./file2Translation.pl $distribution $lang | uniq > Translation-files_new/dists/$distribution/main/i18n/Translation-$lang
		echo `date`: create the $distribution/Translation-$lang
	done
	cp packagelist/timestamp packagelist/timestamp.gpg Translation-files_new/
	cd Translation-files_new
	sha256sum dists/$distribution/main/i18n/Translation-* >> SHA256SUMS
	cd $OLDPWD
done

rm -rf ./Translation-files_to-check
cp -a ./Translation-files_new/ ./Translation-files_to-check

./ddtp-dinstall/ddtp_i18n_check.sh ./Translation-files_to-check/ ./packagelist/

rm -rf Translation-files
mv Translation-files_new Translation-files

/srv/scripts/ddtp_dinstall.sh
