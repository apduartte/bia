resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.env}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.env}-ec2-ssm-role"
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.env}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name

  tags = merge(var.tags, {
    Name = "${var.env}-ec2-profile"
  })
}

resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.env}-ec2-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env}-ec2-sg"
  })
}

resource "aws_instance" "ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids      = concat([aws_security_group.ec2_sg.id], var.security_groups)
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  tags = merge(var.tags, {
    Name = "${var.env}-ec2-instance"
  })
}

resource "aws_lb" "alb" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = var.alb_subnets

  tags = merge(var.tags, {
    Name = "${var.env}-alb"
  })
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.env}-tg"
  port        = 5678
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name = "${var.env}-tg"
  })
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ec2.id
  port             = 5678
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name = "${var.env}-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "main" {
  name = var.domain

  tags = merge(var.tags, {
    Name = "${var.env}-zone"
  })
}

resource "aws_route53_record" "app_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
