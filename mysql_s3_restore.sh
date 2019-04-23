#!/bin/bash

# Basic variables
mysqlpass="$MYSQL_PASSWORD"
mysqlname="$MYSQL_NAME"
mysqluser="$MYSQL_USER"
mysqlhost="$MYSQL_HOST"
mysqlport="$MYSQL_PORT"
siteurl="$SITE_URL"
object="$AWS_BUCKET_PATH"
location="$LOCATION"
method="$METHODS"
backuppath=""

find_latest_bk() {
    if [ -z "$1" ]
    then
        echo No variable found
        exit 1
    else
        dirbackup=$1
        nearest=""
        for i in "${dirbackup[@]}"; do
            IFS="_"
            read -ra FILE_DATE <<< "$i"
            result="${FILE_DATE[0]}/${FILE_DATE[1]}/${FILE_DATE[2]} ${FILE_DATE[3]}:${FILE_DATE[4]}:${FILE_DATE[5]}"
            result=`echo "$result" | sed -r 's/[.sql]+//g'`
            stamptemp=`date -d $result +"%s"`
            if [ "$nearest" = "" ]; then
                nearest=$stamptemp
            fi
            if [ "$stamptemp" -gt "$nearest" ]; then
                nearest=$stamptemp
                nearestfile=$i
            fi
            IFS=""
        done
        echo $nearestfile
    fi
}

case "$method" in
    "s3") echo "Starting s3 restore..."
        echo "Setup environment"
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"

        echo Getting object from "$object"

        aws s3 cp "$object" "backup.sql"

        if [ $? -eq 0 ]; then
          backuppath="backup.sql"
          echo "  Download successful!"
        else
            IFS="/"
            read -ra ADDR <<< "$object"
            len=${#ADDR[@]}
            bucketstr="s3://"
            if (( $(($len - 1)) <= 3 )); then
                bucketstr+=${ADDR[2]}
            else
                for ((i=2;i<=$(($len - 2));i++)); do
                    bucketstr+=${ADDR[$i]}/
                done
            fi
            if aws s3 ls "$bucketstr" 2>&1 | grep -q 'NoSuchBucket\|AllAccessDisabled'; then
                echo This bucket is not exist or access denied
            else
                echo FAILED Could not get from s3 "backup.sql" from "$object". Finding latest backup at "$bucketstr"...
                dirbackup=(`aws s3 ls "$bucketstr" | awk '{ print $4 }'`)
                filteredFile=()
                for i in ${dirbackup[@]}; do
                    element=(`echo "$i" | awk "/[0-9]*_[0-9]*_[0-9]*_[0-9]*_[0-9]*_[0-9]*.sql/"`)
                    filteredFile+=($element)
                done
                nearestfile="$(find_latest_bk $filteredFile)"
                echo Found latest path: $bucketstr/$nearestfile
                echo "Downloading..."
                aws s3 cp "$bucketstr/$nearestfile" "backup.sql"
                backuppath="backup.sql"
            fi
        fi
        ;;
    "pvc") echo "Starting pvc restore..."
        if [ ! -f $location ]; then
            echo "Backup file not found! Finding latest backup..."
            cd /data/backup/$mysqlname
            now=`date +"%s"`
            dirbackup=(`ls -d [0-9]*_[0-9]*_[0-9]*_[0-9]*_[0-9]*.sql`)
            if (( ${#dirbackup[@]} > 0 )); then
                nearest=""
                nearestfile="$(find_latest_bk $dirbackup)"
                backuppath="/data/backup/$mysqlname/$nearestfile"
                echo Found latest path: $backuppath
            else
                echo "Can't found backup file"
                backuppath=$location
            fi
        else
            echo "Backup file found"
            backuppath=$location
        fi
        echo
        ;;
    *) echo "Method is none or invalid"
	    exit 2
		;;
    esac
if [ $? -eq 0 ]; then
    
	/opt/rh/rh-mysql57/root/usr/bin/mysqladmin -u $mysqluser -P $mysqlport -h $mysqlhost -p$mysqlpass --force drop $mysqlname

	/opt/rh/rh-mysql57/root/usr/bin/mysqladmin -u $mysqluser -P $mysqlport -h $mysqlhost -p$mysqlpass --force create $mysqlname

	if [ $? -eq 0 ]; then
		/opt/rh/rh-mysql57/root/usr/bin/mysql -u $mysqluser -P $mysqlport -h $mysqlhost -p$mysqlpass --force $mysqlname < $backuppath &

		BACK_PID=$!
		wait $BACK_PID


		sleep 2m

		if [ "$siteurl" != "" ] || [ "$siteurl" == "none" ]; then
			/opt/rh/rh-mysql57/root/usr/bin/mysql -u $mysqluser -P $mysqlport -h $mysqlhost -p$mysqlpass --force -D $mysqlname -e "UPDATE wp_options SET option_value = '$siteurl' where option_name = 'siteurl' or option_name = 'home'"
		fi
		echo Done
	else
		echo FAILED to Import data;
		exit 3
	fi
fi


