# Architecture

Please check details in [KOK](https://github.com/KoalicjaOtwartyKrakow/kokon)

# Terraform

## Version

The required version of terraform is ~>1.1.2
Code is tested against terraform is 1.1.6 - please use it

## Folder structure

This project follows [Main-module approach](https://dev.to/piotrgwiazda/main-module-approach-for-handling-multiple-environments-in-terraform-1oln)

## Code formatting

Please keep in mind the official format of the code. Or just go to main directory of the repo and run
```terraform fmt -recursive```
There is no hook to do it right now so you need to perform this manually.

## How to run the code

Requirements:
- `gcloud` CLI: https://cloud.google.com/sdk/docs/install

Go to env/dev and perform:
- `gcloud auth application-default login`
- `terraform init` (only for the first run, or after dependency updates)
- `terraform plan`
- `terraform apply`
to init terraform and apply the code

For dev environment there is no pipeline to upload things. Do it manually.
For prod - to be defined

## Working with secrets in the repo
Files that are named `*.enc.` are encrypted using GCP KMS via https://github.com/mozilla/sops 

To create/edit them:
1. Follow the sops installation steps from their GitHub README.
2. `gcloud auth application-default login`
3. To encrypt a file:
   1. dev: `sops -e -i --gcp-kms projects/salamlab-development/locations/global/keyRings/terraform-sops-keyring/cryptoKeys/terraform-sops-key <path>`
   2. prod (not setup yet): `sops -e -i --gcp-kms projects/salamlab-production/locations/global/keyRings/terraform-sops-keyring/cryptoKeys/terraform-sops-key <path>`
4. To edit an encrypted file with `$EDITOR`: `sops <path>`
