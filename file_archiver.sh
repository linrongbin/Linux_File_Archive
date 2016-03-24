#!/bin/sh
#
#############################################

FILE_NAME=`basename $0 .sh`
log=/LGAMK8/log/${FILE_NAME}.log

PATH_DATALOG="PATH_A"
PATH_ARCHIVE="PATH_B"

if [ ! -d ${PATH_ARCHIVE} ]; then
	mkdir ${PATH_ARCHIVE}
fi
if [ ! -d ${PATH_ARCHIVE} ]; then
	exit -1
fi

timestamp=`date +%Y%m%d%H%M`

cd ${PATH_DATALOG}

GZ_FOUND=`find *.gz -print | head -1`
while [  -s ${GZ_FOUND}  ]
do

	echo "========================================================" |tee -a $log
	echo "PROCESSING GZ FILE: $GZ_FOUND!" |tee -a $log
	LOT_ID=`echo $GZ_FOUND | awk -F'_' '{print $1}'`
	FILE_TAR=`echo ${PATH_ARCHIVE}/${LOT_ID}_${timestamp}.tar`
	LOG_TAR=`echo ${PATH_ARCHIVE}/${LOT_ID}_${timestamp}.log`
	NO_FILES_TO_BE_TAR=`ls ${LOT_ID}*.gz | wc -l`
	echo "Get Lot ID from file name: $LOT_ID" |tee -a $log
	echo "No. of files to be tar: $NO_FILES_TO_BE_TAR" |tee -a $log

	nice -n14 ls ${LOT_ID}*.gz | xargs tar -cvf ${FILE_TAR} >$LOG_TAR

	if [ $? -ne 0 ]; then
		echo "+++ Failed to tar the files to ${FILE_TAR}. Abort this archive +++" |tee -a $log
		nice -n14 /usr/bin/rm -rf $LOG_TAR $FILE_TAR
	else
		NO_FILES_TARED=`wc -l<$LOG_TAR|awk '{print $1}'`
		echo "No. of files have been tared: $NO_FILES_TARED" |tee -a $log
		if [ $NO_FILES_TO_BE_TAR -eq $NO_FILES_TARED ]; then
			echo "Successfully tar files for lot ${LOT_ID} to ${FILE_TAR} " |tee -a $log
			nice -n14 /usr/bin/rm -rf $LOG_TAR
			echo " !Remove all files belong to lot ${LOT_ID}" |tee -a $log
			nice -n14 /usr/bin/rm -rf ${LOT_ID}*.gz
			if [ -s ${GZ_FOUND} ]; then
				echo " +++++ Failed to remove all files belong to ${LOT_ID} since ${GZ_FOUND} is still there. Abort this archive +++" |tee -a $log
				exit -1
			fi
		else
			echo " +++ Number of files tared ($NO_FILES_TARED) not equal to the one of files to be tared ($NO_FILES_TO_BE_TAR). Abort this archive +++" |tee -a $log
			nice -n14 /usr/bin/rm -rf  $LOG_TAR $FILE_TAR
		fi
	fi

	GZ_FOUND=`find *.gz -print | head -1`

done
