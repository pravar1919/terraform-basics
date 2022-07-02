provider "aws"{
    profile = "pravar"
    region = "ap-south-1"
}

resource "aws_vpc" "custom_vpc"{
    cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public_subnet" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    tags = {
        Name = "public-subnet"
    }
}

resource "aws_subnet" "public_subnet2" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
    tags = {
        Name = "public-subnet2"
    }
}
resource "aws_internet_gateway" "vpc-igw" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
}

resource "aws_network_acl" "public-acl" {
    vpc_id = "${aws_vpc.custom_vpc.id}"
    subnet_ids = ["${aws_subnet.public_subnet.id}", "${aws_subnet.public_subnet2.id}"]
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
        rule_no    = 300
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
    vpc_id = "${aws_vpc.custom_vpc.id}"
    ingress{
        from_port = 80
        to_port = 80
        security_groups  = ["${aws_security_group.abl_security_group.id}"]
        protocol = "tcp"
    }
    ingress{
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "abl_security_group" {
    name = "alb-sg"
    description = "specific to alb"
    vpc_id = "${aws_vpc.custom_vpc.id}"
    ingress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress{
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_instance" "web-server1" {
    ami = "ami-08df646e18b182346"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.webserver-sg.id}"]
    key_name = "gl1"
    user_data = "${file("scripts.sh")}"
    subnet_id = "${aws_subnet.public_subnet.id}"
}

resource "aws_instance" "web-server2" {
    ami = "ami-08df646e18b182346"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.webserver-sg.id}"]
    key_name = "gl1"
    user_data = "${file("scripts2.sh")}"
    subnet_id = "${aws_subnet.public_subnet2.id}"
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

resource "aws_lb_listener" "web-lb-listner"  {
    load_balancer_arn = "${aws_lb.web-lb.arn}"
    port = 80
    protocol   = "HTTP"
    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.web-tg.id}"
    }
}

# Now attatch ec2 instances with target group

resource "aws_lb_target_group_attachment" "web-tg-attatch1"{
    target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    target_id        = "${aws_instance.web-server1.id}"
    port             = 80
}

resource "aws_lb_target_group_attachment" "web-tg-attatch2"{
    target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    target_id        = "${aws_instance.web-server2.id}"
    port             = 80
}
# route table

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-igw.id
  }

  tags = {
    Name = "CustomRT"
  }
}

resource "aws_route_table_association" "rtb1" {
  route_table_id = "${aws_route_table.rt.id}"
  subnet_id      = "${aws_subnet.public_subnet.id}"
}

resource "aws_route_table_association" "rtb2" {
  route_table_id = "${aws_route_table.rt.id}"
  subnet_id      = "${aws_subnet.public_subnet2.id}"
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
    vpc_id = "${aws_vpc.custom_vpc.id}"
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_db_instance" "mysql-db" {
    allocated_storage    = 10
    engine               = "mysql"
    engine_version       = "8.0"
    storage_type         = "gp2" # general purpose SSD
    instance_class       = "db.t2.micro"
    db_name              = "mysqldb"
    username             = "myuser"
    password             = "mysql_password"
    skip_final_snapshot  = true
    db_subnet_group_name = "${aws_db_subnet_group.mysql-subnet-group.id}"
    vpc_security_group_ids = ["${aws_security_group.mysql-sg.id}"]
}