#!/bin/bash
set -e

mkdir -p /tmp/web
cd /tmp/web

cat > index.html <<EOF
<h1>Hello, World</h1>
<h2>My name is ${server_name}!</h2>
EOF

nohup python3 -m http.server ${server_port} --directory /tmp/web

