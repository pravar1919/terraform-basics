#!bin/bash

yum update -y
yum install httpd -y
echo "hello world" > /var/www/html/index.html
service https restart