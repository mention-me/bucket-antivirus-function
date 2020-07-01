#!/bin/sh

INPUT=$1

BUCKET=`echo $INPUT | cut -d'/' -f1`

FILE_AND_PATH=${INPUT#"$BUCKET/"}

echo $BUCKET
echo $FILE_AND_PATH

JSON_STRING=$( jq -n \
                  --arg b "$BUCKET" \
                  --arg f "$FILE_AND_PATH" \
                  '{ "Records": [{ "s3": { "bucket": { "name": $b }, "object": { "key": $f } } } ] }')

echo $JSON_STRING

FILE=`basename "$FILE_AND_PATH"`
FOLDER=`dirname "$FILE_AND_PATH"`

echo $FILE
URL_ENCODED_FILE=`php -r "echo urlencode('$FILE');"`

echo "https://s3.console.aws.amazon.com/s3/buckets/$BUCKET/$FOLDER/?region=eu-west-1&tab=overview&prefixSearch=${URL_ENCODED_FILE}"

aws lambda invoke --cli-binary-format raw-in-base64-out --function-name bucket-antivirus-function --payload "$JSON_STRING" /tmp/lambda_invoke
