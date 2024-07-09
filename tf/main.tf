terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0"
    }
  }

  backend "s3" {
    bucket = "ghazal-tf-state-bucket"
    key    = "tfstate.json"
    region = "eu-north-1"
  }

  required_version = ">= 1.7.0"
}

provider "aws" {
  region  = var.region
}

module "polybot_app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "ghazal-polybot-vpc"
  cidr = "10.0.0.0/16"

  azs             = var.availability_zones
  public_subnets  = var.public_subnets

  enable_nat_gateway = false
}

resource "aws_key_pair" "deployer" {
  key_name   = "ghazal-polybot-key"
  public_key = file("./my_key.pub")
}


resource "aws_iam_role" "ec2_role" {
  name = "ghazal-polybot_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_sqs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_secretsmanager" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "attach_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ghazal-polybot_ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}
resource "aws_s3_bucket" "image_bucket" {
  bucket = var.image_bucket_name
}

resource "aws_sqs_queue" "sqs_name" {
  name = var.sqs_name
}

resource "aws_dynamodb_table" "predictions" {
  name           = "yolo5-predictions"
  hash_key       = "prediction_id"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "prediction_id"
    type = "S"
  }
}

module "polybot" {
  source = "./modules/polybot"
  ami_id = var.ami_id
  vpc_id         = module.polybot_app_vpc.vpc_id
  public_subnets = module.polybot_app_vpc.public_subnets
  dynamo_DB = aws_dynamodb_table.predictions.name
  key_name = aws_key_pair.deployer.key_name
  role_name = aws_iam_instance_profile.ec2_instance_profile.name
  bucket_name    = aws_s3_bucket.image_bucket.bucket
  sqs_queue_url = aws_sqs_queue.sqs_name.name
  region_name = var.region
  TF_VAR_botToken = var.TF_VAR_botToken
}

module "yolo5" {
  source = "./modules/yolo5"
  ami_id = var.ami_id
  vpc_id             = module.polybot_app_vpc.vpc_id
  bucket_name    = aws_s3_bucket.image_bucket.bucket
  sqs_queue_url = aws_sqs_queue.sqs_name.name
  dynamo_DB = aws_dynamodb_table.predictions.name
  key_name = aws_key_pair.deployer.key_name
  public_subnets = module.polybot_app_vpc.public_subnets
  role_name = aws_iam_instance_profile.ec2_instance_profile.name
  polybot_loadbalancer_dns = module.polybot.polybot_loadbalancer_dns
  region_name = var.region
}





