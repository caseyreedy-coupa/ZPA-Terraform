data "aws_ami" "zpa_ami" {
  owners = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["zpa-connector-*"]
  }
}

/*
data "templatefile" "zpa_key" {
    template = "${file("userdata.sh.tpl")}"

    vars = {
    zpa_key = "${var.zpa_key}"
    }    
}
*/

locals {
    tags_dest = ["instance", "volume", "network-interface"]
}

resource "aws_security_group" "zpa_connector" {
  name        = "ZScaler Private Access Connector"
  description = "ZScaler Private Access Connector"
  vpc_id      = var.vpc_id

  ingress {
    description      = "SSH from 10-Net"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/8"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ZScaler Private Access Connector"
    c_status = "true"
    c_role = "coupa_scdp_zpa"
    c_deployment = "devzpa"
    c_pci = "false"
    c_application = "scdp"
    c_active = "true"
    c_team = "sre-lm"
    c_stack_version = "scdp32.0.0"
    c_environment = "dev"
    c_fedramp = "false"
  }
}

/*
resource "aws_iam_instance_profile" "zpa_connector" {
  name = "zpa_connector"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name = "zpa_connector_role"
  path = "/"

  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ssm:DescribeParameters"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ssm:GetParameters"
                ],
                "Resource": "arn:aws:ssm:us-east-1:927623560008:parameter/zscaler*"
            },
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                "Service": "ec2.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }
    EOF
} */
/*
resource "aws_instance" "test_cjr" {
        ami = "ami-09d3b3274b6c5d4aa"
//        iam_instance_profile = aws_iam_instance_profile.zpa_connector.name
        instance_type = "t2.micro"
        key_name = var.key_name
        subnet_id = "subnet-06677fba897d72122"
        tags = { 
            Name = "Casey Test"

        }
        vpc_security_group_ids = ["sg-08c41b2d7e5789c55"]
}
*/


resource "aws_launch_template" "zpa_launch_template" {
  name = "ZScaler-Private-Access-Connector"
  ebs_optimized = true
  image_id = data.aws_ami.zpa_ami.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.zpa_connector.id ]

  dynamic "tag_specifications" {
    for_each = toset(local.tags_dest)
    content {
      resource_type = tag_specifications.key
      tags = {
            Name = "ZScaler Private Access Connector"
            c_status = "true"
            c_role = "coupa_scdp_zpa"
            c_deployment = "devzpa"
            c_pci = "false"
            c_application = "scdp"
            c_active = "true"
            c_team = "sre-lm"
            c_stack_version = "scdp32.0.0"
            c_environment = "dev"
            c_fedramp = "false"
           }
       }
    }
  user_data = base64encode(templatefile("userdata.sh.tftpl", {
    zpa_key = var.zpa_key
    }))
}

resource "aws_autoscaling_group" "zpa_asg" {
  desired_capacity   = 2
  max_size           = 2
  min_size           = 2
  name = "ZScaler-Connector-ASG"
  vpc_zone_identifier = var.subnets[*]

  launch_template {
    id      = aws_launch_template.zpa_launch_template.id
    version = aws_launch_template.zpa_launch_template.latest_version
  }
}
