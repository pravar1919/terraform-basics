provided "aws" {
    profile="${var.profile}"
    regin="${var.region}"
}

resource "aws_instance" "demo_instance" {
    ami = "${var.ami-id}"
    instace_type = "t2.micro"
    key_name = "${var.private_key_name}"
    vpc_security_group_ids = ["from_vpc"]

    tags {
        Name = "DemoInstance"
    }

    provisioner "file" {
        source = "script.sh"
        destination = "destination_to_the_script.sh_file"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/scripts.sh",
            "sudo /temp/scripts.sh"
        ]
    }

    connection { # connect remote machine
        host = "${aws_instance.demo_instance.public_ip}"
        user = "ec2-user"
        private_key = "${file("${var.private_key_path}")}"
    }

    output "name" {
        value = "${aws_instance.demo_instance.public_ip}"
    }

    output "instnce_arn" {
        value = "${aws_instance.demo_instance.arn}"
    }
}