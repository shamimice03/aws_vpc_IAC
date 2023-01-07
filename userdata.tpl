#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y 
sudo systemctl enable nginx
sudo systemctl start nginx
sudo rm -rf /usr/share/nginx/html/*
sudo yum install git -y
sudo git clone https://github.com/shamimice03/restaurant-website.git /usr/share/nginx/html
