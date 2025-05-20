data "aws_ami" "most_recent" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "local_file" "htpasswd_hash" {
  filename = "${path.root}/local/htpasswd.hash"
  content = sha256(join("\n", [for user in var.users : "${user.login}:${user.passord}"]))
}

resource "local_file" "htpasswd" {
  filename = "${path.root}/local/htpasswd"
  content = join("\n", [for user in var.users : "${user.login}:${bcrypt(user.passord)}"])

  lifecycle {
    ignore_changes = [content]
    # replace_triggered_by = [for user in var.users : "${user.login}:${user.passord}"]
    replace_triggered_by = [local_file.htpasswd_hash]
  }
}

data "cloudinit_config" "igc_server_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/configs/cloud-config.yaml.tftpl", {
      app_file_b64 = base64encode(templatefile("${path.module}/configs/app.service.tftpl", {
        docker_ecr_url = var.docker_ecr.repository_url
        aws_region     = var.docker_ecr.aws_region
      }))

      htpassords_file_b64 = base64encode(local_file.htpasswd.content)

      nginx_conf_main_file_b64 = filebase64("${path.module}/configs/nginx.conf")
      nginx_conf_d_default_file_b64 = base64encode(templatefile("${path.module}/configs/nginx.default.conf.tftpl", {
          server_name = var.server_config.name
        }))
      ssl_key_file_b64 = base64encode(var.server_config.key)
      ssl_certs_file_b64 = base64encode("${var.server_config.cert}${var.server_config.issuer_chain}")
    })
  }

  part {
    filename     = "install-app.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/configs/install-app.sh")
  }
}

resource "aws_instance" "igc_server" {
  subnet_id         = var.subnet.id
  availability_zone = var.subnet.availability_zone
  ami               = data.aws_ami.most_recent.image_id
  instance_type     = "t3.nano"

  vpc_security_group_ids = [var.admin_ssh_security_group, aws_security_group.igc.id]

  associate_public_ip_address = true
  key_name                    = var.admin_key_pair_name

  user_data                   = data.cloudinit_config.igc_server_config.rendered
  user_data_replace_on_change = true

  iam_instance_profile = aws_iam_instance_profile.igc_instance_profile.name

  root_block_device {
    volume_size           = 4
  }

  tags = {
    Name = "igc-server"
  }
}

data "aws_iam_policy_document" "igc_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecr_read_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "igc_instance_role" {
  name = "igc-instance-role"

  assume_role_policy = data.aws_iam_policy_document.igc_assume_role.json

  inline_policy {
    name   = "ecr-read-policy"
    policy = data.aws_iam_policy_document.ecr_read_policy.json
  }
}

resource "aws_route53_record" "dns_record_igc" {
  name    = var.server_config.name
  type    = "A"
  ttl     = 300
  zone_id = var.domain_zone
  records = [aws_instance.igc_server.public_ip]
}

resource "aws_iam_instance_profile" "igc_instance_profile" {
  name = "igc-instance-profile"
  role = aws_iam_role.igc_instance_role.name
}

resource "aws_security_group" "igc" {
  vpc_id = var.vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 4353
    to_port   = 4353
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "igc"
  }
}
