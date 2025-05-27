# openapi_client.DefaultApi

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**entries_get**](DefaultApi.md#entries_get) | **GET** /entries | 
[**entries_post**](DefaultApi.md#entries_post) | **POST** /entries | 
[**entry_key_get**](DefaultApi.md#entry_key_get) | **GET** /entry/{key} | 


# **entries_get**
> List[Entry] entries_get()

Fetch all entries stored in the database

### Example


```python
import openapi_client
from openapi_client.models.entry import Entry
from openapi_client.rest import ApiException
from pprint import pprint

# Defining the host is optional and defaults to http://localhost
# See configuration.py for a list of all supported configuration parameters.
configuration = openapi_client.Configuration(
    host = "http://localhost"
)


# Enter a context with an instance of the API client
with openapi_client.ApiClient(configuration) as api_client:
    # Create an instance of the API class
    api_instance = openapi_client.DefaultApi(api_client)

    try:
        api_response = api_instance.entries_get()
        print("The response of DefaultApi->entries_get:\n")
        pprint(api_response)
    except Exception as e:
        print("Exception when calling DefaultApi->entries_get: %s\n" % e)
```



### Parameters

This endpoint does not need any parameter.

### Return type

[**List[Entry]**](Entry.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

### HTTP response details

| Status code | Description | Response headers |
|-------------|-------------|------------------|
**200** | Successful pull of entries |  -  |
**404** | Empty table or table not found. |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **entries_post**
> entries_post(entry)

Put an entry into the database

### Example


```python
import openapi_client
from openapi_client.rest import ApiException
from pprint import pprint

# Defining the host is optional and defaults to http://localhost
# See configuration.py for a list of all supported configuration parameters.
configuration = openapi_client.Configuration(
    host = "http://localhost"
)


# Enter a context with an instance of the API client
with openapi_client.ApiClient(configuration) as api_client:
    # Create an instance of the API class
    api_instance = openapi_client.DefaultApi(api_client)
    entry = {'key': openapi_client.Entry()} # Entry | 

    try:
        api_instance.entries_post(entry)
    except Exception as e:
        print("Exception when calling DefaultApi->entries_post: %s\n" % e)
```



### Parameters


Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **entry** | [**Entry**](Entry.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

### HTTP response details

| Status code | Description | Response headers |
|-------------|-------------|------------------|
**200** | Successfully created an entry in the database |  -  |
**500** | Internal Server Error occurred while trying to write entry to the database. |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **entry_key_get**
> Entry entry_key_get(key, value)

Fetch a specific entry from the database

### Example


```python
import openapi_client
from openapi_client.rest import ApiException
from pprint import pprint

# Defining the host is optional and defaults to http://localhost
# See configuration.py for a list of all supported configuration parameters.
configuration = openapi_client.Configuration(
    host = "http://localhost"
)


# Enter a context with an instance of the API client
with openapi_client.ApiClient(configuration) as api_client:
    # Create an instance of the API class
    api_instance = openapi_client.DefaultApi(api_client)
    key = 'message' # str | 
    value = 'Hello, world!' # str | 

    try:
        api_response = api_instance.entry_key_get(key, value)
        print("The response of DefaultApi->entry_key_get:\n")
        pprint(api_response)
    except Exception as e:
        print("Exception when calling DefaultApi->entry_key_get: %s\n" % e)
```



### Parameters


Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **key** | **str**|  | 
 **value** | **str**|  | 

### Return type

[**Entry**](Entry.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

### HTTP response details

| Status code | Description | Response headers |
|-------------|-------------|------------------|
**200** | Successful pull of entry |  -  |
**404** | Entry not found |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

