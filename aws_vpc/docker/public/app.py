#!/usr/bin/env python

import os
import datetime

from fastapi import FastAPI
from fastapi import HTTPException

import json
from bson import ObjectId
from bson import json_util

from urllib.parse import quote_plus

from pymongo import AsyncMongoClient
from pymongo.results import InsertOneResult

from async_lru import alru_cache

MONGODB_USER = os.getenv("MONGODB_USER")
MONGODB_PASSWORD = os.getenv("MONGODB_PASSWORD")
MONGODB_HOST = os.getenv("MONGODB_HOST")

@alru_cache()
async def get_mongodb_client():
    """
    Gets a MongoDB client and returns it (cached) 

    :return: client
    """
    CONNECTION_STRING = "mongodb://%s:%s@%s" % (
        quote_plus(MONGODB_USER), quote_plus(MONGODB_PASSWORD), MONGODB_HOST
    )

    return AsyncMongoClient(CONNECTION_STRING)

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello, World!"}

@app.get("/items")
async def read_items():
    mongodb_client = await get_mongodb_client()

    db = mongodb_client.main
    collection = db.messages
    cursor = collection.find()

    data = await cursor.to_list()

    return json.loads(json_util.dumps(data)) if data is not None else \
        HTTPException(status_code=404, detail="No items found")

@app.get("/items/{item_id}")
async def read_item(item_id: str):
    mongodb_client = await get_mongodb_client()

    db = mongodb_client.main
    collection = db.messages
    cursor = await collection.find_one(dict(_id=ObjectId(item_id)))

    return json.loads(json_util.dumps(cursor)) if cursor is not None else \
        HTTPException(status_code=404, detail="Not found")


@app.put("/items/{message}")
async def put_item(message: str):
    mongodb_client = await get_mongodb_client()

    db = mongodb_client.main
    collection = db.messages
    cursor = await collection.insert_one(dict(message=message))

    return json.loads(json_util.dumps(cursor.inserted_id)) if cursor is not None else \
        HTTPException(status_code=500, detail="Internal Server Error")

@app.delete("/items/{item_id}")
async def delete_item(item_id: str):
    mongodb_client = await get_mongodb_client()

    db = mongodb_client.main
    collection = db.messages
    cursor = await collection.delete_one(dict(_id=ObjectId(item_id)))

    return cursor.raw_result if cursor is not None and cursor.deleted_count > 0 else HTTPException(status_code=404, detail="Item not found")
