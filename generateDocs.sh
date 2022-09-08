#!/bin/sh
rm -fr ./SfApexDocs
rm -fr ./docs/documentation/
mkdir ./docs/documentation/
java -jar ./SfApexDoc.jar -s ./force-app/main/default/classes -t . -h ./docs/txt/home.txt -a ./docs/txt/author.txt
cp ./SfApexDocs/*.* ./docs/documentation/
cp ./docs/images/logo.png ./docs/documentation/logo.png
rm -fr ./SfApexDocs
rm ./SfApexDocLog.txt
open ./docs/documentation/index.html