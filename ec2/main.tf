data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    # values = ["CoreOS Container Linux stable *"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  # filter {
  #   name   = "architecture"
  #   values = ["x86_64"]
  # }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_autoscaling_group" "app" {
  name                 = var.autoscaling_group_name
  vpc_zone_identifier  = var.vpc_zone_identifier
  min_size             = var.autoscaling_min_size
  max_size             = var.autoscaling_max_size
  desired_capacity     = var.autoscaling_desired_size
  launch_configuration = aws_launch_configuration.app.name
}

data "template_file" "cloud_config" {
  template = file("${path.module}/templates/cloud-config.tpl")

  vars = {
    aws_region         = "${var.aws_region}"
    ecs_cluster_name   = "${var.ecs_cluster_name}"
    ecs_log_level      = "${var.ecs_log_level}"
    ecs_agent_version  = "latest"
    ecs_log_group_name = "${var.ecs_log_group_name}"
  }
}

resource "aws_launch_configuration" "app" {
  security_groups = [
    "${var.instance_sg_id}",
  ]

  key_name                    = var.key_name
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  iam_instance_profile        = var.app_iam_instance_profile_name
  user_data                   = data.template_file.cloud_config.rendered
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "tls_private_key" "genkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "genkey" {
  key_name   = var.key_name
  public_key = tls_private_key.genkey.public_key_openssh
}
