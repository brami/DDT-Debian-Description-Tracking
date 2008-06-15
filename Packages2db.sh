#!/bin/bash -e

INPORT2DB="../Packages2db.pl"

cd ~ddtp/Packages

#DISTS="alpha amd64 arm hppa hurd-i386 i386 ia64 m68k mips mipsel powerpc s390 sparc"
DISTS="alpha amd64 arm hppa i386 ia64 mips mipsel powerpc s390 sparc"
PART="main contrib"

distribution="etch"
for part in $PART
do
	for arch in $DISTS
	do
		file="Packages_${distribution}_${part}_${arch}"

		echo `date`: ${distribution}/$arch
		[ -s $file.bz2 ] && mv $file.bz2 Packages.bz2
		wget -q -m -nd http://ftp.de.debian.org/debian/dists/${distribution}/${part}/binary-$arch/Packages.bz2
		mv Packages.bz2 $file.bz2
		echo `date`: Packages file downloaded

		bunzip2 -k -f $file.bz2
		echo `date`: Packages bunzip2

		$INPORT2DB $file $distribution $arch
		echo `date`: data in db

		rm -f $file
	done
done
# Regular vacuum to cut disk usage
psql ddtp -c "VACUUM"

DISTS="alpha amd64 arm hppa i386 ia64 mips mipsel powerpc s390 sparc"

distribution="lenny"
for part in $PART
do
	for arch in $DISTS
	do
		file="Packages_${distribution}_${part}_${arch}"

		echo `date`: ${distribution}/$arch
		[ -s $file.bz2 ] && mv $file.bz2 Packages.bz2
		wget -q -m -nd http://ftp.de.debian.org/debian/dists/${distribution}/${part}/binary-$arch/Packages.bz2
		mv Packages.bz2 $file.bz2
		echo `date`: Packages file downloaded

		bunzip2 -k -f $file.bz2
		echo `date`: Packages bunzip2

		$INPORT2DB $file $distribution $arch
		echo `date`: data in db

		rm -f $file
	done
done
# Regular vacuum to cut disk usage
psql ddtp -c "VACUUM"

# Clear active before loading sid (which is what counts as active)
psql ddtp -c "TRUNCATE active_tb"
psql ddtp -c "TRUNCATE part_description_tb"

DISTS="alpha amd64 arm hppa i386 ia64 m68k mips mipsel powerpc s390 sparc"

distribution="sid"
for part in $PART
do
	for arch in $DISTS
	do
		file="Packages_${distribution}_${part}_${arch}"

		echo `date`: ${distribution}/$arch
		[ -s $file.bz2 ] && mv $file.bz2 Packages.bz2
		wget -q -m -nd http://ftp.de.debian.org/debian/dists/${distribution}/${part}/binary-$arch/Packages.bz2
		mv Packages.bz2 $file.bz2
		echo `date`: Packages file downloaded

		bunzip2 -k -f $file.bz2
		echo `date`: Packages bunzip2

		$INPORT2DB $file $distribution $arch
		echo `date`: data in db

		rm -f $file
	done
done
# Regular vacuum to cut disk usage
psql ddtp -c "VACUUM"

cd ~ddtp
pg_dump ddtp | gzip > pg_dump/pg_ddts.dump.gz
cp -a pg_dump/pg_ddts.dump.gz www/source/pg_ddts_current.dump.gz

chmod 644 pg_dump/pg_ddts.dump.gz www/source/pg_ddts_current.dump.gz

# rotate the pg-dump
/usr/sbin/logrotate --state /org/ddtp.debian.net/lib/logrotate.state /org/ddtp.debian.net/logrotate.config
