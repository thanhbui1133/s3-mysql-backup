# s3-mysql-backsup

Backup a mysql database server to S3. This script is inspired by [oodavid](https://gist.github.com/oodavid/2206527) but uses the AWS CLI tools and also GPG symmetric encrypts the file. See the [dariancabot](https://dariancabot.com/2017/05/07/aws-s3-uploading-and-downloading-from-linux-command-line/) blog fore more details. 

## Usage

To run the script the following environment variables are required: 

 * DB_USER
 * DB_PASSWORD
 * DB_HOST
 * DB_PORT
 * S3_BUCKET (e.g. my-bucket)

The aws cli for S3 uploads also needs a `~/.aws/credentials` which can be created using `aws configure`. You then simply run

```
s3mysqlbackup.sh
```

## Building

Build the docker image with:

```
docker build  -t s3-mysql-backups .
```
