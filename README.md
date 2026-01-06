#
#### Bilvanties_Task-3


terraform init -no-color
terraform plan -no-color

export TF_VAR_runner_token="REPLACE_WITH_TOKEN"
terraform apply