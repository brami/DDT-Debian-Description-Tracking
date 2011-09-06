#!/bin/bash -e

cd ~

rm -rf pos
mkdir -p pos

if [ "x$1" = "x" ]
then
	LANGS=`psql ddtp -q -A -t -c "select distinct language from translation_tb where description_id>1"`
else
	LANGS=$1
fi

if [ "x$2" = "x" ]
then
	DISTRIBUTIONS=lenny etch sid
else
	DISTRIBUTIONS=$2
fi

for distribution in $DISTRIBUTIONS
do
	for lang in $LANGS
	do
		./db2po.pl $distribution $lang 
		echo `date`: create the $lang po for $distribution
	done
done

cd pos
tar -zkcf ../pos.tar.gz .
