#!/bin/bash

# setup API key for dynu and cloudflare (traefik)

DYNU=$(read -p "Enter your Dynu API key: " DYNU_API_KEY && echo $DYNU_API_KEY)
CLOUDFLARE=$(read -p "Enter your Cloudflare API key: " CLOUDFLARE_API_KEY && echo $CLOUDFLARE_API_KEY)

docker secret create traefik_cf_api_key - <<<"$CLOUDFLARE"
docker secret create traefik_dynu_api_key - <<<"$DYNU"
