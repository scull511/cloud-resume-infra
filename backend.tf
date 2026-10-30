terraform {
  backend "s3" {
    bucket       = "simoncull-terraform-state"
    key          = "cloud-resume-challenge/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}