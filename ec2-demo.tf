# WhenEver get stuck always use Terraform Documentation
# ${} is interpollotion syntex
#variables are provided in vaiable.tf file
provided "aws" { # either choose access_key or use profile by creating a user and then using cli configure and then give the profile name( recommended method)
    # access_key=""
    # secret_key=""
    profile="${var.profile}"
    regin="${var.region}"
}

resource "aws_instance" "demo_instance" {
    ami = "${var.ami-id}" # ami id of the instance from aws
    instace_type = "t2.micro"

    tags { # optional
        Name = "DemoInstance"
    }
}