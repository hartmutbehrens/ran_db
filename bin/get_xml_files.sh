#!/bin/bash
if [ ! $# = 3 ]
then
	echo Usage: $0 URL COUNTRY CUSTOMER
	exit 1
fi

DATE=`date +%Y%m%d`
URL=$1
COUNTRY=$2
CUSTOMER=$3
BASEDIR="$( cd "$( dirname "$0" )" && cd .. && pwd )"
XML_DIR=$BASEDIR/xml
PM_DIR=$BASEDIR/pm
OFFICE_FILE=$DATE.$COUNTRY$CUSTOMER.xml
DATE_FILE=DATES.$DATE.xml

if [ ! -e $XML_DIR ]
then
	`mkdir $XML_DIR`
fi
#first get the list of available elements
echo Retrieving list of offices available on $DATE
if [ -e $XML_DIR/$OFFICE_FILE ]
then
	echo Already retrieved $XML_DIR/$OFFICE_FILE
else
	`curl -sSo $XML_DIR/$OFFICE_FILE "$URL?COUNTRY=$COUNTRY&CUSTOMER=$CUSTOMER&BUTTON=XML_PRESENT"`
fi

#retrieve list of Offices and dates on which pm is available
echo Parsing office file $XML_DIR/$OFFICE_FILE
for OFFICE in `./xparthse.pl file -x /officelog/office $XML_DIR/$OFFICE_FILE`
do
	echo Found office $OFFICE
	if [ ! -e $PM_DIR/$OFFICE ]
	then
		`mkdir -p $PM_DIR/$OFFICE`	
	fi

	if [ -e $PM_DIR/$OFFICE/$DATE_FILE ]
	then
		echo Already have date file $DATE_FILE for $OFFICE
	else
		echo Retrieving PM dates available for $OFFICE
		`curl -sSo $PM_DIR/$OFFICE/$DATE_FILE "$URL?COUNTRY=$COUNTRY&CUSTOMER=$CUSTOMER&Office=$OFFICE&BUTTON=XML_PRESENT"`
	fi
done
