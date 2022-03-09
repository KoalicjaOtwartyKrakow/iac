# Architecture

Please check details in [KOK](https://github.com/KoalicjaOtwartyKrakow/kokon)

# Terraform

## Version

The required version of terraform is ~>1.1.2
Code is tested against terraform is 1.1.6 - please use it

## Setup

Visit [Terraform setup gcp](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build?in=terraform/gcp-get-started#set-up-gcp)

## Folder structure

This project follow [Main-module approach](https://dev.to/piotrgwiazda/main-module-approach-for-handling-multiple-environments-in-terraform-1oln)

## Code formating

Please keep in mind the official format of the code. Or just go to main directory of the repo and run
```terraform fmt -recursive```
There is no hook to do it right now so you need to perform this manually.

## How to run the code

Go to env/dev and perform:
- terraform init
- terraform plan
- terraform apply
to init terraform and apply the code

For dev environment there is no pipeline to upload things. Do it manually.
For prod - to be defined
