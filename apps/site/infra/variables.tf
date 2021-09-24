variable "aws_secret_key" {
  type        = string
  description = "Secret key to connect with aws"
}

variable "aws_access_key" {
  type        = string
  description = "Access key to connect with aws"
}

variable "aws_region" {
  type        = string
  description = "Aws region to deploy resource to"
}

variable "current_date" {
  type        = string
  description = "The time the resource was deployed"
}

variable "instance_name" {
  type        = string
  description = "Name of instance"
}
