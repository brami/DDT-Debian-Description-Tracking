#!/bin/bash -e

INPORT2DB="../Packages2db.pl"

cd ~ddtp/Packages

load_distribution ()
{
	distribution=$1
	parts=$2
	for part in $parts
	do
		file="Packages_${distribution}_${part}"

		echo `date`: ${distribution}/${part}

		bunzip2 -k -f $file.bz2
		echo `date`: Packages bunzip2

#		[ "$distribution" = "lliurex" ] && distribution="gaia"
		$INPORT2DB $file $distribution
		echo `date`: data in db

		rm -f $file
	done
}

#load_distribution lliurex gaia

PARTS="main contrib"
load_distribution squeeze $PARTS
load_distribution wheezy $PARTS

# Clear active before loading sid (which is what counts as active)
psql ddtp -c "TRUNCATE active_tb"
psql ddtp -c "TRUNCATE part_description_tb"

load_distribution sid $PARTS

# Regular vacuum to cut disk usage
psql ddtp -c "VACUUM"

cd ~ddtp
pg_dump ddtp | gzip > pg_dump/pg_ddts.dump.gz
cp -a pg_dump/pg_ddts.dump.gz www/source/pg_ddts_current.dump.gz

chmod 644 pg_dump/pg_ddts.dump.gz www/source/pg_ddts_current.dump.gz

