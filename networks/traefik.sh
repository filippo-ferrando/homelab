#!/bin/bash

# create docker network for traefik

docker network create --driver overlay --attachable traefik-net
