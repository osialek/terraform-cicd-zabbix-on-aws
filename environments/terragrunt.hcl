remote_state {
  backend = "s3"
  generate = {
    path = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "terragrunt-state-osial"     # Configure your own S3 Bucket
    key            = "${path_relative_to_include()}/terraform.tfstate" # tf state file location - change if you need
    region         = "eu-central-1" # change the region for deployment targer region if required
  }
}
