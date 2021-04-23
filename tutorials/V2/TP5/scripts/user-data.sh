#!/bin/bash
set -e

mkdir -p /tmp/web
cd /tmp/web

if [ "${server_name}" = "mighty_panda" ]; then
  echo "<h1>Roar!</h1>" > index.html
elif [ "${server_name}" = "giant_owl" ]; then
  echo "<h1>Skriiii, from above!</h1>" > index.html
elif [ "${server_name}" = "cute_beaver" ]; then
  echo "<h1>Nomnomnom, hey there. I'm a beaver!</h1>" > index.html
else
  echo "<h1>Hello world!<h1>" > index.html
fi

echo "<h2>My name is ${server_name}.</h2>" >> index.html

nohup python3 -m http.server ${server_port} --directory /tmp/web

