
variable "ami_id" {
   description = "EC2 Ubuntu AMI"
   type        = string
}
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "dynamo_DB" {
  description = "dynamo db"
  type = string

}

variable "key_name" {
  description = "Key value"
  type = string
}
variable "region_name" {
  description = "region name"
  type = string
}

variable "role_name" {
  description = "role value"
  type = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL of the SQS queue"
  type        = string
}
variable "assign_public_ip" {
  description = "Specify if the instance should have a public IP address."
  type        = bool
  default     = true
}
variable "TF_VAR_botToken" {
  description = "telegram token"
  type = string
}
