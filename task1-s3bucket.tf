terraform {
  backend "s3" {
    bucket         = "veena-test1234"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "upgrad"
  }
}
