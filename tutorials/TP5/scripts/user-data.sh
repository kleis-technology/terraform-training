#!/bin/bash
set -e

apt update
apt -y install nginx

if [[ "${server_name}" == "mighty_panda" ]]; then
  echo "<h1>Roar!</h1>"
elif [[ "${server_name}" == "giant_owl" ]]; then
  echo "<h1>Skriiii, from above!</h1>"
elif [[ "${server_name}" == "cute_beaver" ]]; then
  echo "<h1>Nomnomnom, hey there. I'm a beaver!</h1>"
else
  echo "<h1>Hello world!<h1>"
fi >/var/www/html/index.html

echo "<p>My name is <q>${server_name}</q>.</p>" >>/var/www/html/index.html
