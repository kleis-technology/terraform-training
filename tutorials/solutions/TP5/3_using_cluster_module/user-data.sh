#!/bin/bash
set -e

apt update
apt -y install nginx

cat >/var/www/html/index.html <<EOF
<h1>Hello, World</h1>
<h2>My name is ${server_name}!</h2>
EOF
