#!/bin/bash -e

INPORT2DB="./Packages2packages_tb.pl"
DB2FILE="./packages_tb2Packages.pl"

cd ~ddtp

DIST="llx0809-backports llx0809-proposed llx0809-security llx0809-updates llx0809"
PART=" main multiverse restricted universe"
distribution="gaia"

for part in $PART
do
        for dist in $DIST
        do
                file="Packages/Packages-lliurex_${distribution}_${dist}_${part}"

                echo `date`: lliurex ${distribution}/${part}/$dist
                [ -s $file.gz ] && mv $file.gz Packages/Packages.gz
                wget -P Packages -q -m -nd http://lliurex.net/$distribution/dists/$dist/$part/binary-i386/Packages.gz
                [ -s Packages/Packages.gz ] && mv Packages/Packages.gz $file.gz
                echo `date`: Packages file downloaded
        done
done


# Clear active before loading sid (which is what counts as active)
psql ddtp -c "TRUNCATE packages_tb"
for part in $PART
do
	for dist in $DIST
	do
                file="Packages/Packages-lliurex_${distribution}_${dist}_${part}.gz"

		[ -f $file ] && echo -n `date` : $file :
		[ -f $file ] && zcat $file | $INPORT2DB
		[ -f $file ] || echo no $file
	done
done
$DB2FILE Packages/Packages-lliurex_${distribution}
rm -f Packages/Packages-lliurex_${distribution}.bz2
bzip2 Packages/Packages-lliurex_${distribution}
# Regular vacuum to cut disk usage
psql ddtp -c "VACUUM"

