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

## Connecting to the db from your computer
In general this should not be needed regularly. If you have a use case for manually connecting to the db
please ping the devops team in the #general-tech channel on discord.

Requirements:
- `gcloud` CLI: https://cloud.google.com/sdk/docs/install
- `sops`: https://github.com/mozilla/sops
- `cloud_sql_proxy`: https://cloud.google.com/sql/docs/postgres/connect-admin-proxy#install
- `vim`, `vi`, `nano`, `emacs` editor configured with `EDITOR` environment variable.

Steps:
1. Make sure you have all the requirements installed
2. Start the proxy:
   * Dev: `cloud_sql_proxy -instances=salamlab-development:europe-central2:main-v2=tcp:127.0.0.1:5432`
   * Prod: TBD
3. `gcloud auth application-default login`, select your kok account
4. `sops env/dev/apartments-db-creds.enc.json` – this will print the username and password
5. Connect your db browser (psql/jetbrains/dbeaver/…) to `127.0.0.1:5432` and use the creds from step 4.

## Troubleshooting

### Just applying this code in an empty project does not work
Unfortunately there's a mess of dependencies between resources that are not expressed in terraform, and
not always can.

To work around that we could look into adding stages to the deployment, you'd set stage to 0, apply, set
stage to 1, apply etc. See #52.

### Endpoint calls inexplicably return 403
Check cloud run instance logs for `PERMISSION_DENIED:Calling Google Service Control API failed with: 403 and body`.
If you see that, you need to enable the `Service Control API`. See #51.