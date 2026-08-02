#!/bin/bash

# generate hedgedoc secret

SECRET=$(openssl rand -hex 32)
docker secret create hedgedoc_session_secret - <<<"$SECRET"
