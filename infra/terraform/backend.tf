terraform {
  backend "s3" {
    bucket         = "csv-processor-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "csv-processor-terraform-locks"
    encrypt        = true
  }
}
