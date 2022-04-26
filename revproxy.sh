#!/bin/bash
# A basic script to reverse-proxy with Nginx & Certbot

# Check if the user is root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root!"
    exit
fi

# Get arguments
for arg in "$@"; do
    key=$(echo $arg | sed -e "s/^--//" | cut -f1 -d=)
    key_length=${#key}
    value="${arg:$key_length+3}"
    export "$key"="$value"
done

# Get input if not provided
if [ "${#ip}" -eq 0 ] && [ "${#domain}" -eq 0 ]; then
    echo "Please enter the domain: "
    read domain

    echo "Please enter the IP address and port: "
    read ip
fi

if [ "${#ip}" -eq 0 ] && [ "${#domain}" -eq 0 ]; then
    echo "ERROR: Invalid domain or IP provided!"
    exit
fi

# Create config
echo "
    server {
        server_name $domain;
        listen 80;
        listen [::]:80;
        access_log /var/log/nginx/reverse-access.log;
        error_log /var/log/nginx/reverse-error.log;
        location / {
            proxy_pass http://$ip;
        }
    }
    " > /etc/nginx/sites-available/$domain.conf

ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf

# Run certbot
certbot --nginx

echo "DONE: Successfully reverse-proxied $domain!"