output "vpc_id" {
  value = module.polybot_app_vpc.vpc_id
}
output "public_subnet_ids" {
  value = module.polybot_app_vpc.public_subnets
}
