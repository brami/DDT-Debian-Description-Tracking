#!/bin/bash -e

cd ~ddtp

# Fetch active langs from database
LANGS=`psql ddtp -q -A -t -c "select distinct language from translation_tb"`

for lang in $LANGS
do
        DATE=`date`
	echo -n "$DATE $lang: "
	./completeTranslations.pl $lang 
done
