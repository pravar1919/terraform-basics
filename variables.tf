variable "profile" {
    default = "demo"
}

variable "region"{
    default = "us-east-1"
}

# variable "ami-id"{
#     default= "id-form-aws"
# }

variable "ami-id"{
    type = "map"
    default = {
        us-east-1 = ""
        us-west-1 = ""
    }
}