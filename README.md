# Introduction

This repository holds lab examples of deployments I've made in order to play with AWS, Terraform, Kubernetes, Docker and OpenAPI 3 (OAS).

## Terraform

For AWS authentication, there must be variable population either through environment variable or other ways (e.g. external data).

Environment variables is the preferred way. Check the `main.tf` files for each project to see the variables required. Usually they are:

* `TF_VAR_AWS_USEAST1_ACCESS_KEY` (`AWS_USEAST1_ACCESS_KEY` in HCL Terraform file)
* `TF_VAR_AWS_USEAST1_SECRET_KEY` (`AWS_USEAST1_SECRET_KEY` in HCL Terraform file)
* `TF_VAR_AWS_EUWEST1_ACCESS_KEY` (`AWS_EUWEST1_ACCESS_KEY` in HCL Terraform file)
* `TF_VAR_AWS_EUWEST1_SECRET_KEY` (`AWS_EUWEST1_SECRET_KEY` in HCL Terraform file)

## Kubernetes and Docker

The project will either spin up a minikube cluster (WARNING: this is done on instances that are NOT free), or, will run docker locally (done on a Free Tier EC2 instance [at the moment of writing this, 2025-05-26 IST]).

## Apps

Apps usually will (using OpenAPI 3 or not): CRUD a key value from DynamoDB (usually in a region different than the one the app is running in)

These can be find in the `docker/` folder alongside the respective `Dockerfile`.

### OAS

To use the OAS generated Python client, follow the following steps:

1. Set up an env in working directory:
   ```console
   cd aws_oas/docker/clients/python
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
1. Install ipython:
   ```console
   pip install -U ipython
   ipython
   ```
1. Launch ipython and execute API calls with the NLB DNS name you've got after creating AWS resources with Terraform (replace `{{NLB_FQDN}}` with the NLB DNS name):
   ```python
   import openapi_client
   from openapi_client.api.default_api import DefaultApi
   from openapi_client.api_client import ApiClient
   configuration = openapi_client.configuration.Configuration()
   configuration.host = "{{NLB_FQDN}}"
   client = openapi_client.ApiClient(configuration)
   api_service = DefaultApi(client)
   ```
   ```python
   # Get all entries in the database for given key
   api_service.entries_get()
   # Put an entry in the database for a given key
   api_service.entries_post(entry=dict(key="message", value="test"))
   # Get the entry just inserted in the database
   api_service.entry_key_get(key="message", value="test")
   # Get all entries in the database for given key
   api_service.entries_get()
   ```

## License

[Apache-2.0 license](https://raw.githubusercontent.com/alghe-global/terraform_labs/refs/heads/master/LICENSE)
