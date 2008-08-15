#!/bin/bash -e

INPORT2DB="./Packages2packages_tb.pl"
DB2FILE="./packages_tb2Packages.pl"

cd ~ddtp

DISTS="alpha amd64 arm armel hppa hurd-i386 i386 ia64 m68k mips mipsel powerpc s390 sparc"
#DISTS="i386"
PART="main contrib"
DISTRIBUTION="sarge etch lenny sid"
DISTRIBUTION="etch lenny sid"

for distribution  in $DISTRIBUTION
do
	for part in $PART
	do
		for arch in $DISTS
		do
			file="Packages/Packages_${distribution}_${part}_${arch}"

			echo `date`: ${distribution}/${part}/$arch
			[ -s $file.bz2 ] && mv $file.bz2 Packages/Packages.bz2
			wget -P Packages -q -m -nd http://ftp.de.debian.org/debian/dists/${distribution}/${part}/binary-$arch/Packages.bz2
			[ -s Packages/Packages.bz2 ] && mv Packages/Packages.bz2 $file.bz2
			echo `date`: Packages file downloaded
		done
	done
done

for distribution  in $DISTRIBUTION
do
	for part in $PART
	do
		# Clear active before loading sid (which is what counts as active)
		psql ddtp -c "TRUNCATE packages_tb"

		for arch in $DISTS
		do
			file="Packages/Packages_${distribution}_${part}_${arch}.bz2"

			[ -f $file ] && echo -n `date` : $file
			[ -f $file ] && bzcat $file | $INPORT2DB
			[ -f $file ] || echo no $file
		done

		$DB2FILE > $file
	done
done
# Regular vacuum to cut disk usage
psql ddtp -c "VACUUM"

