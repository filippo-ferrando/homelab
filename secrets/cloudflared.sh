#!/bin/bash

# This script is used to create a Cloudflare tunnel and store the credentials in a secret file

CLOUDFLARE=""
read -p "Enter the Cloudflare API key: " CLOUDFLARE

docker secret create cf_tunnel_token - <<<"$CLOUDFLARE"
