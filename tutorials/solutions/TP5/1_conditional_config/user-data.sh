#!/bin/bash
set -e

apt update
apt -y install nginx

cat >/var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
  <h1>Hello, World</h1>
  <p>My name is <q>${server_name}</q>!<p>
</html>
EOF
