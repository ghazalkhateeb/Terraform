
variable "region" {
   description = "AWS region"
   type        = string
}

variable "ami_id" {
   description = "EC2 Ubuntu AMI"
   type        = string
}
variable "availability_zones" {
   description = "List of availability zones"
   type        = list(string)
}
variable "public_subnets" {
   description = "List of public subnet CIDR blocks"
   type        = list(string)
}
variable "image_bucket_name" {
   description = "s3 bucket name"
   type        = string
}
variable "sqs_name" {
   description = "the sqs name"
   type        = string
}
variable "TF_VAR_botToken" {
  description = "telegram token"
  type = string
}

