#!/bin/bash

# Based on https://gist.github.com/2206527

# Be pretty
echo -e " "
echo -e " .  ____  .    ______________________________"
echo -e " |/      \|   |                              |"
echo -e "[| \e[1;31m♥    ♥\e[00m |]  | S3 MySQL Backup Script v.0.1 |"
echo -e " |___==___|  /                © oodavid 2012 |"
echo -e "              |______________________________|"
echo -e " "

# Basic variables
mysqlpass="$DB_PASSWORD"
mysqluser="$DB_USER"
mysqlhost="$DB_HOST"
mysqlport="$DB_PORT"
bucket="s3://$S3_BUCKET"
secret_key="$SECRET_KEY"

# Timestamp (sortable AND readable)
stamp=`date +"%s - %A %d %B %Y @ %H%M"`

# List all the databases
databases=`mysql -u $DB_USER -p$mysqlpass -P $DB_PORT -h $DB_HOST -e "SHOW DATABASES;" | tr -d "| " | grep -v "\(Database\|information_schema\|performance_schema\|sys\|mysql\|test\)"`

# Feedback
echo -e "Dumping to \e[1;32m$bucket/$stamp/\e[00m"

# Loop the databases
for db in $databases; do

  # Define our filenames
  filename="$stamp - $db.sql.gpg"
  tmpfile="/tmp/$filename"
  object="$bucket/$stamp/$filename"

  # Feedback
  echo -e "\e[1;34m$db\e[00m"

  # Dump and zip
  echo -e "  creating \e[0;35m$tmpfile\e[00m"
  mysqldump -u $mysqluser -p$mysqlpass -h $mysqlhost -P $mysqlport --force --opt --databases "$db" | gpg --batch --no-tty --yes --output "$tmpfile" --symmetric --passphrase $secret_key 

  # Upload
  echo -e "  uploading..."
  aws s3 cp "$tmpfile" "$object"

  # Delete
  rm -f "$tmpfile"

done;

# Jobs a goodun
echo -e "\e[1;32mJobs a goodun\e[00m"