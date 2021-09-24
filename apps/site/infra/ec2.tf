resource "aws_instance" "testec2" {
  # can eventually replace ami with launch template to run start scripts additonally?
  # to configuring ami within the template
  ami                         = "ami-0210560cedcb09f07"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet_a.id
  key_name                    = "web_key"
  security_groups             = [aws_security_group.allow_tls.id]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.web_key.private_key_pem
      host        = aws_instance.testec2.public_ip
    }
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = merge(local.tags, {
    service = "ec2"
  })
}

resource "aws_ebs_volume" "testebs" {
  availability_zone = aws_instance.testec2.availability_zone
  size              = 1
  tags = merge(local.tags, {
    service = "ebs"
  })
}

resource "aws_volume_attachment" "attach_ebs" {
  depends_on   = [aws_ebs_volume.testebs]
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.testebs.id
  instance_id  = aws_instance.testec2.id
  force_detach = true
}

resource "null_resource" "nullmount" {
  depends_on = [aws_volume_attachment.attach_ebs]
  triggers = {
    ebs_id = aws_ebs_volume.testebs.id
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.web_key.private_key_pem
    host        = aws_instance.testec2.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/vineets300/Webpage1.git web-server-image",
    ]
  }
}

#obviously bucket names are global so this cannot be deployed more than once
resource "aws_s3_bucket" "test_bucket123" {
  bucket = "testbucket1234123s"
  acl    = "public-read-write"
  versioning {
    enabled = true
  }
  provisioner "local-exec" {
    command = "git clone https://github.com/vineets300/Webpage1.git web-server-image || true"
  }
  tags = merge(local.tags, {
    service = "s3"
  })
}

resource "aws_s3_bucket_public_access_block" "public_storage" {
  depends_on          = [aws_s3_bucket.test_bucket123]
  bucket              = "testbucket1234123s"
  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_object" "object1" {
  depends_on = [aws_s3_bucket.test_bucket123]
  bucket     = "testbucket1234123s"
  acl        = "public-read-write"
  key        = "Demo1.png"
  source     = "img/5UzHvbw.png"
}

resource "aws_cloudfront_distribution" "testcloudfront" {
  depends_on = [aws_s3_bucket_object.object1]
  origin {
    domain_name = aws_s3_bucket.test_bucket123.bucket_domain_name
    origin_id   = local.s3_origin
  }
  enabled = true
  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "null_resource" "write_image" {
  depends_on = [aws_cloudfront_distribution.testcloudfront, null_resource.nullmount]
  triggers = {
    ec2_instance = aws_instance.testec2.id
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.web_key.private_key_pem
    host        = aws_instance.testec2.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo su << EOF",
      "echo \"<img src='http://${aws_cloudfront_distribution.testcloudfront.domain_name}/${aws_s3_bucket_object.object1.key}' width='300' height='380'>\" >>/var/www/html/index.html",
      "echo \"</body>\" >>/var/www/html/index.html",
      "echo \"</html>\" >>/var/www/html/index.html",
      "EOF",
    ]
  }
}

output "instance_ip_addr" {
  value = aws_instance.testec2.public_ip
}