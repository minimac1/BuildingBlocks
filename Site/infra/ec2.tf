resource "aws_instance" "testec2" {
  ami = "ami-06202e06492f46177"
  instance_type = "t2.micro"
}