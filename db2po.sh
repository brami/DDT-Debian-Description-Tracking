#!/bin/bash -e

cd ~

rm -rf pos
mkdir -p pos

#for distribution in etch sid
for distribution in sid
do
	for lang in cs da de eo es fi fr go hu it ja km_KH ko nl pl pl_PL pt_BR pt_PT ru sk sv uk zh_CN zh_TW
	do
		./db2po.pl $distribution $lang 
		echo `date`: create the $lang po for $distribution
	done
done

cd pos
tar -zkcf ../pos.tar.gz .
