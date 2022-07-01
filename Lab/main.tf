provider "aws"{
    profile = ""
    region = ""
}

resource "aws_vpc" "custom_vpc"{
    cider_block = "10.0.0.1/16"
}
resource "aws_subnet" "public_subnet" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
    cider_block = "10.0.1.0/24"
    tags = {
        Name = "public-subnet"
    }
}
resource "aws_internet_gateway" "vpc-igw" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
}

resource "aws_network_acl" "public-acl" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
    subnet_ids = ["${aws_subnet.public_subnet.id}"]
    # egress and ingress both are necessary in order to flow.
    ingress { # port 80
        rule_no    = 100
        protocol   = "tcp"
        from_port  = 80
        to_port    = 80
        action     = "allow"
        cidr_block = "0.0.0.0/0"
    }
    egress { # port 80
        rule_no    = 100
        protocol   = "tcp"
        from_port  = 80
        to_port    = 80
        action     = "allow"
        cidr_block = "0.0.0.0/0"
    }
    ingress { # port rest
        rule_no    = 200
        protocol   = "tcp"
        from_port  = 1024
        to_port    = 65535
        action     = "allow"
        cidr_block = "0.0.0.0/0"
    }
    egress { # port rest
        rule_no    = 200
        protocol   = "tcp"
        from_port  = 1024
        to_port    = 65535
        action     = "allow"
        cidr_block = "0.0.0.0/0"
    }
    ingress { # port 22
        rule_no    = 300
        protocol   = "tcp"
        from_port  = 22
        to_port    = 22
        action     = "allow"
        cidr_block = "0.0.0.0/0"
    }
    egress { # port 22
        ule_no    = 300
        protocol   = "tcp"
        from_port  = 22
        to_port    = 22
        action     = "allow"
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_security_group" "webserver-sg" {
    name = "WebDMZ"
    description = "Security group for web server"

    ingress{
        from_port = 80
        to_port = 80
        cider_block = "0.0.0.0/0"
        protocol = "tcp"
    }
    ingress{
        from_port = 22
        to_port = 22
        cider_block = "0.0.0.0/0"
        protocol = "tcp"
    }
}

resource "ec2_instance" "web-server1" {
    ami = ""
    ec2_instance = "t2.micro"
    vpc_security_group_id = ["${aws_security_group.webserver-sg.id}"]
    key_name = "somekeyname.pem"
    user_data = "${file("script.sh")}"     
}

resource "ec2_instance" "web-server2" {
    ami = ""
    ec2_instance = "t2.micro"
    vpc_security_group_id = ["${aws_security_group.webserver-sg.id}"]
    key_name = "somekeyname.pem"
    user_data = "${file("script2.sh")}"
}