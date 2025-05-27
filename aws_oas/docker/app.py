#!/usr/bin/env python

import os
import sys

import logging
from datetime import datetime

from flask import Flask, request, jsonify
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

if not all([AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, AWS_DYNAMODB_TABLE, AWS_DYNAMODB_KEY, AWS_DYNAMODB_VALUE]):
    logger.critical("Either one or all missing: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, AWS_DYNAMODB_TABLE, AWS_DYNAMODB_KEY, AWS_DYNAMODB_VALUE as environment variables.")
    sys.exit(1)

client = boto3.client(
    "dynamodb",
    AWS_REGION,
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY
)

@app.route("/")
def hello_world():
    """
    Fetch AWS_DYNAMODB_KEY=AWS_DYNAMODB_VALUE and return the item

    Useful for health-check as well.
    """

    response = {}
    try:
        response = client.get_item(
            TableName=AWS_DYNAMODB_TABLE,
            Key={
                AWS_DYNAMODB_KEY: {
                    "S": AWS_DYNAMODB_VALUE
                }
            }
        )
    except:
        logger.debug(f"Failed to fetch item. Key: {AWS_DYNAMODB_KEY}, value: {AWS_DYNAMODB_VALUE}")

    if not response.get("Item"):
        return f"Requested item not found. Key: {AWS_DYNAMODB_KEY}, value: {AWS_DYNAMODB_VALUE}", 404

    result = response.get("Item")[list(response.get("Item").keys())[0]]['S']
    return result, 200

@app.route("/entries", methods=["GET", "POST"])
def entries():
    """
    Do a table scan and return entries found.
    Post an entry in the table.

    :return: Items from response or 404 if nothing found
    :rtype: jsonified list
    """

    if request.method == "GET":
        response = {}
        try:
            response = client.scan(TableName=AWS_DYNAMODB_TABLE)
        except:
            logger.debug(f"Failed to scan table for items. Table: {AWS_DYNAMODB_TABLE}")

        items = response.get("Items")
        if not items:
            return f"Empty table or table not found", 404

        ret = []
        for item in items:
            k = list(item.keys())[0]
            v = item[k]["S"]
            ret.append(dict(key=k, value=v))
        return jsonify(ret), 200
    elif request.method == "POST":
        data = request.get_json()
        key = data.get("key")
        value = data.get("value")

        response = {}
        try:
            response = client.put_item(
                    TableName=AWS_DYNAMODB_TABLE,
                    Item={
                        key: {
                            'S': value
                        }
                    }
            )
        except:
            logger.critical(f"Failed to put item: {key} with value: {value} in table: {AWS_DYNAMODB_TABLE}")
            return "Write failed. Make sure your key matches the one DynamoDB was provisioned with", 500

        return jsonify(response.get("ResponseMetadata")), 200
    else:
        return "Invalid HTTP method used", 501

@app.route("/entry/<key>")
def fetch_entry(key):
    """
    Fetch a specific entry from the database in the given AWS_DYNAMODB_TABLE

    :return: Item from response or 404 if not found
    :rtype: jsonified dict
    """

    value = request.args.get("value")

    response = {}
    try:
        response = client.get_item(
            TableName=AWS_DYNAMODB_TABLE,
            Key={
                key: {
                    "S": value
                }
            }
        )
    except:
        logger.debug(f"Failed to fetch item. Key: {key}, value: {value}")

    item = response.get("Item")
    if not item:
        return f"Requested item not found. Key: {key}, value: {value}", 404

    k = list(item.keys())[0]
    v = item[k]["S"]
    ret = {"key": k, "value": v}

    return jsonify(ret), 200
