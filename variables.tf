variable "profile" {
    default = "pravar"
}

variable "region"{
    default = "ap-south-1"
}

# variable "ami-id"{
#     default= "id-form-aws"
# }

variable "ami-id"{
    default = {
        ap-south-1 = "ami-08df646e18b182346"
    }
}