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

resource "aws_subnet" "public_subnet2" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
    cider_block = "10.0.1.0/24"
    tags = {
        Name = "public-subnet2"
    }
}
resource "aws_internet_gateway" "vpc-igw" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
}

resource "aws_network_acl" "public-acl" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
    subnet_ids = ["${aws_subnet.public_subnet.id}", "${aws_subnet.custom_subnet2.id}"]
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
    egress{
        from_port = 22
        to_port = 22
        cider_block = "0.0.0.0/0"
        protocol = "tcp"
    }
}

resource "aws_security_group" "abl_security_group" {
    name = "alb-sg"
    description = "specific to alb"

    ingress {
        from = 80
        to = 80
        protocol = "tcp"
        cider_block = "0.0.0.0/0"
    }
    egress {
        from = 80
        to = 80
        protocol = "tcp"
        cider_block = "0.0.0.0/0"
    }

}

resource "ec2_instance" "web-server1" {
    ami = ""
    ec2_instance = "t2.micro"
    vpc_security_group_id = ["${aws_security_group.webserver-sg.id}"]
    key_name = "somekeyname.pem"
    user_data = "${file("script.sh")}"
    subnet_ids = "${aws_subnet.public_subnet.id}"
}

resource "ec2_instance" "web-server2" {
    ami = ""
    ec2_instance = "t2.micro"
    vpc_security_group_id = ["${aws_security_group.webserver-sg.id}"]
    key_name = "somekeyname.pem"
    user_data = "${file("script2.sh")}"
    subnet_ids = "${aws_subnet.public_subnet2.id}"
}

resource "aws_lb_target_group" "web-tg"{
    name = "web-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = "${aws_vpc.custom_vpc.id}"
}

# for application load balancer we need minimum of 2 subnets.
resource "aws_lb" "web-lb" {
    name="web-lb"
    internal = false
    load_balancer_type = "application"
    subnets = ["${aws_subnet.public_subnet.id}", "${aws_subnet.public_subnet2.id}"]
    security_groups    = ["${aws_security_group.abl_security_group.id}"]
}

resource "aws_lb_listner" "web-lb-listner"  {
    load_balancer_arn = "${aws_lb.web-lb.arn}"
    port = 80
    protocol   = "http"
    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    }
}

# Now attatch ec2 instances with target group

resource "aws_lb_target_group_attachment" "web-tg-attatch1"{
    target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    target_id        = "${ec2_instance.web.web-server1.id}"
    port             = 80
}

resource "aws_lb_target_group_attachment" "web-tg-attatch2"{
    target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    target_id        = "${ec2_instance.web.web-server2.id}"
    port             = 80
}

# launch RDS instance

# to launch mysql db in a subnet we need to create dbsubnet group

resource "aws_db_subnet_group" "mysql-subnet-group" {
    name       = "main"
    subnet_ids = ["${aws_subnet.public_subnet.id}", "${aws_subnet.public_subnet2.id}"]
}

resource "aws_security_group" "mysql-sg" {
    name = "mysql-sg"
    description = "SG for MySQL"

    ingress {
        from = 3306
        to = 3306
        protocol = "tcp"
        cider_block = "0.0.0.0/0"
    }
}

resource "aws_db_instance" "mysql-db" {
    allocated_storage    = 10
    engine               = "mysql"
    engine_version       = "8.0"
    storage_type         = "gp2" # general purpose SSD
    instance_class       = "db.t2.micro"
    name                 = "mysqldb"
    username             = "myuser"
    password             = "mysql_password"
    skip_final_snapshot  = true
    db_subnet_group_name = "${aws_db_subnet_group.mysql-subnet-group.id}"
    vpc_security_group_id = "${aws_security_group.mysql-sg.id}"
}