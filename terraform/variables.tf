variable "aws_region" {
  default = "us-east-1"
}

variable "instance_count" {
  default = 2
  type = number
}

variable "instance_type" {
  default = "t2.micro"
}