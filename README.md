# s3-mysql-backsup

Backup a mysql database server to S3. This script is inspired by [oodavid](https://gist.github.com/oodavid/2206527) but uses the AWS CLI tools and also GPG symmetric encrypts the file. See the [dariancabot](https://dariancabot.com/2017/05/07/aws-s3-uploading-and-downloading-from-linux-command-line/) blog fore more details. 

## Usage

To run the script the following environment variables are required: 

 * DB_USER
 * DB_PASSWORD
 * DB_HOST
 * DB_PORT
 * S3_BUCKET (e.g. my-bucket)
 * SECRET_KEY (i.e. strong random encryption key)

The aws cli for S3 uploads also needs a `~/.aws/credentials` which can be created using `aws configure`. You then simply run: 

```
s3mysqlbackup.sh
```

## Restoring the database

If you need to restore the files you first need to decrypt them with something like: 

```
gpg --batch --no-tty --yes --decrypt --passphrase $secret_key "$tmpfile"
```

Then load them with something like: 

```
find . -name '*.sql' | awk '{ print "source",$0 }' | mysql -u root -p$mysqlpass -h you.host.com -P 3306 --batch
```

## Building

Build the docker image with:

```
docker build  -t s3-mysql-backups .
```
