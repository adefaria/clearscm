#!/usr/bin/python

import boto3, sys
from botocore.exceptions import ClientError

from display import *
import cmd

# Create an S3 client
s3 = boto3.client('s3')

def AWSError(msg, exception, errno = 0):
  error(msg + "\n" + str(exception.response['Error']['Message']), errno)

def listBuckets():
  # Call S3 to list current buckets
  response = s3.list_buckets()

  # Get a list of all bucket names from the response
  buckets = [bucket['Name'] for bucket in response['Buckets']]

  # Print out the bucket list
  display ('Bucket List: {0}'.format(buckets))

def createBucket(name):
  try:
    s3.create_bucket(Bucket=name, CreateBucketConfiguration={
      'LocationConstraint': 'us-west-1'})
  except ClientError as e:
    AWSError('Unable to create bucket {0}'.format(name), e, 1)

def cli():
  #display (__name__ + ':', nolinefeed=True)

  while True:
    cmd = input('awss3:')
    print 'Command entered' + cmd

    display ('Command entered ' + cmd)

    if cmd == 'quit' or cmd == 'exit':
      sys.exit()

cli()

listBuckets()
createBucket('defaria-aws.com2')
listBuckets()