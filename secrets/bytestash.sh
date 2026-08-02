#!/bin/bash
# This script is used to create a jwt token for bytestash

SECRET=$(openssl rand -hex 32)
docker sercre create bytestash_jwt - <<<"$SECRET"
