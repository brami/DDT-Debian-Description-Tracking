#!/bin/bash -e

INPORT2DB="../Packages2db.pl"

cd ~ddtp/Packages



#distribution="gaia"
#	file="Packages-lliurex_${distribution}"
#
#	echo `date`: lliurex_${distribution}
#
#	bunzip2 -k -f $file.bz2
#	echo `date`: Packages bunzip2
#
#	$INPORT2DB $file lliurex_$distribution
#	echo `date`: data in db
#
#	rm -f $file


PART="main contrib"

#distribution="etch"
#for part in $PART
#do
#		file="Packages_${distribution}_${part}"
#
#		echo `date`: ${distribution}/${part}
#
#		bunzip2 -k -f $file.bz2
#		echo `date`: Packages bunzip2
#
#		$INPORT2DB $file $distribution
#		echo `date`: data in db
#
#		rm -f $file
#done
# Regular vacuum to cut disk usage
#psql ddtp -c "VACUUM"


#distribution="lenny"
#for part in $PART
#do
#		file="Packages_${distribution}_${part}"
#
#		echo `date`: ${distribution}/${part}
#
#		bunzip2 -k -f $file.bz2
#		echo `date`: Packages bunzip2
#
#		$INPORT2DB $file $distribution
#		echo `date`: data in db
#
#		rm -f $file
#done
# Regular vacuum to cut disk usage
#psql ddtp -c "VACUUM"



distribution="squeeze"
for part in $PART
do
		file="Packages_${distribution}_${part}"

		echo `date`: ${distribution}/${part}

		bunzip2 -k -f $file.bz2
		echo `date`: Packages bunzip2

		$INPORT2DB $file $distribution
		echo `date`: data in db

		rm -f $file
done
distribution="wheezy"
for part in $PART
do
		file="Packages_${distribution}_${part}"

		echo `date`: ${distribution}/${part}

		bunzip2 -k -f $file.bz2
		echo `date`: Packages bunzip2

		$INPORT2DB $file $distribution
		echo `date`: data in db

		rm -f $file
done
# Regular vacuum to cut disk usage
psql ddtp -c "VACUUM"

# Clear active before loading sid (which is what counts as active)
psql ddtp -c "TRUNCATE active_tb"
psql ddtp -c "TRUNCATE part_description_tb"


distribution="sid"
for part in $PART
do
		file="Packages_${distribution}_${part}"

		echo `date`: ${distribution}/${part}

		bunzip2 -k -f $file.bz2
		echo `date`: Packages bunzip2

		$INPORT2DB $file $distribution 
		echo `date`: data in db

		rm -f $file
done
# Regular vacuum to cut disk usage
psql ddtp -c "VACUUM"

cd ~ddtp
pg_dump ddtp | gzip > pg_dump/pg_ddts.dump.gz
cp -a pg_dump/pg_ddts.dump.gz www/source/pg_ddts_current.dump.gz

chmod 644 pg_dump/pg_ddts.dump.gz www/source/pg_ddts_current.dump.gz

