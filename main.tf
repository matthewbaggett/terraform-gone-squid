data "aws_ami" "base_ami" {
  most_recent = true
  name_regex  = var.base_ami_regexp
  owners      = ["amazon", "self"]
}

resource "aws_instance" "proxy" {
  depends_on             = [aws_security_group.proxy-ssh, aws_security_group.proxy-squid]
  ami                    = data.aws_ami.base_ami.id
  instance_type          = var.instance_type
  user_data_base64       = data.template_cloudinit_config.proxy.rendered
  monitoring             = false
  subnet_id              = aws_subnet.proxy.id
  vpc_security_group_ids = [aws_security_group.proxy-ssh.id, aws_security_group.proxy-squid.id]

  tags = merge(map("Name", var.tag_name), var.tags_extra)

  root_block_device {
    volume_size = 8
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

resource "aws_subnet" "proxy" {
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.cidr_block, 8, var.cidr_block_offset, )
  map_public_ip_on_launch = true

  tags = merge(map("Name", var.tag_name), var.tags_extra)
}

resource "aws_eip" "proxy" {
  depends_on = [aws_instance.proxy]
  instance   = aws_instance.proxy.id
  vpc        = true
  tags       = merge(map("Name", var.tag_name), var.tags_extra)
}

resource "aws_security_group" "proxy-ssh" {
  name   = "proxy-ssh"
  vpc_id = var.vpc_id
  
  tags = merge(map("Name", var.tag_name), var.tags_extra)
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "proxy-squid" {
  name   = "proxy-squid"
  vpc_id = var.vpc_id
  
  tags = merge(map("Name", var.tag_name), var.tags_extra)
  
  ingress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "squid_securitygroup" {
  value = aws_security_group.proxy-squid.id
}

data "template_file" "proxy" {
  template = file("${path.module}/proxy.py")

  vars = {
    hostname        = var.hostname,
    slack_hook      = var.slack-hook,
    swapsize        = 1,
    authorized_keys = var.ssh_authorized_keys
    proxy_username  = var.proxy_username
    proxy_password  = var.proxy_password
  }
}

data "template_cloudinit_config" "proxy" {
  gzip          = "true"
  base64_encode = "true"

  part {
    content = file("${path.module}/cloud-config.yaml")
  }

  part {
    filename = "dockerd.py"
    content  = file("${path.module}/dockerd.py")
  }

  part {
    filename = "slack.py"
    content  = file("${path.module}/slack.py")
  }

  part {
    filename = "tfutil.py"
    content  = file("${path.module}/tfutil.py")
  }

  part {
    filename = "uptime.py"
    content  = file("${path.module}/uptime.py")
  }

  part {
    filename     = "proxy.py"
    content      = data.template_file.proxy.rendered
    content_type = "text/x-shellscript"
  }
}
