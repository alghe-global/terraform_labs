#!/usr/bin/env python

import os
import sys

import logging
from datetime import datetime

from flask import Flask
import boto3

app = Flask(__name__)

AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.environ.get("AWS_REGION")

AWS_DYNAMODB_TABLE = os.environ.get("AWS_DYNAMODB_TABLE")
AWS_DYNAMODB_KEY = os.environ.get("AWS_DYNAMODB_KEY")
AWS_DYNAMODB_VALUE = os.environ.get("AWS_DYNAMODB_VALUE")

LOG_FORMATTER = logging.Formatter(
    '[%(asctime)s.%(msecs)06dZ] [%(levelname)s] %(message)s',
    datefmt="%Y-%m-%dT%H:%M:%S")

logger = logging.getLogger(__name__)

handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(LOG_FORMATTER)

logger.addHandler(handler)
logger.setLevel(logging.DEBUG)

@app.route("/")
def hello_world():
    if not all([AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, AWS_DYNAMODB_TABLE, AWS_DYNAMODB_KEY, AWS_DYNAMODB_VALUE]):
        logger.critical("Either one or all missing: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, AWS_DYNAMODB_TABLE, AWS_DYNAMODB_KEY, AWS_DYNAMODB_VALUE as environment variables.")
        return "Internal server error", 500

    client = boto3.client(
        "dynamodb",
        AWS_REGION,
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY
    )

    response = client.get_item(
        TableName=AWS_DYNAMODB_TABLE,
        Key={
            AWS_DYNAMODB_KEY: {
                "S": AWS_DYNAMODB_VALUE
            }
        }
    )

    if not response.get("Item"):
        return f"Requested item not found. Key: {AWS_DYNAMODB_KEY}, value: {AWS_DYNAMODB_VALUE}", 404

    result = response.get("Item")[list(response.get("Item").keys())[0]]['S']
    return result, 200
