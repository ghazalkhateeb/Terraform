
resource "aws_security_group" "yolo5-sg" {
  name        = "ghazal-yolo5-sg"
  description = "Security group for Yolo5 instances"
  vpc_id      = var.vpc_id

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  # Adjust to allow only specific IPs for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "yolo5-template" {
  name_prefix   = "ghazal-yolo5-template"
  instance_type = "t2.medium"
  image_id           = var.ami_id
  key_name      = var.key_name


  //vpc_security_group_ids = [aws_security_group.yolo5-sg.id]
  iam_instance_profile {
    name = var.role_name
  }


  user_data = base64encode(templatefile("./modules/yolo5/user_data.sh", {
    bucket_name    = var.bucket_name
    sqs_queue_url  = var.sqs_queue_url
    polybot_url    = var.polybot_loadbalancer_dns
    region_name = var.region_name
    dynamodb = var.dynamo_DB
  }))
   network_interfaces {

     associate_public_ip_address = var.assign_public_ip
     security_groups = [aws_security_group.yolo5-sg.id]
     delete_on_termination       = true
     device_index                = 0
  }


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ghazal-yolo5"
    }
  }
}

resource "aws_autoscaling_group" "yolo5-asg" {
  name                = "ghazal-yolo5-asg"
  vpc_zone_identifier = var.public_subnets
  health_check_type   = "EC2"

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.yolo5-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "yolo5"
    propagate_at_launch = true
  }
}



resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "yolo5-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.yolo5-asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

