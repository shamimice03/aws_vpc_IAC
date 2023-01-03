data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name = "name"
    values = [
      "amzn2-ami-kernel-*-hvm-*-x86_64-gp2"
    ]
  }

}
