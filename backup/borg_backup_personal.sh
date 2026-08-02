#!/bin/bash

borg create \
  --verbose \
  --filter AME \
  --list \
  --stats \
  --show-rc \
  --compression zstd \
  --exclude '**/appdata_*' \
  $REPO::'{hostname}-{now:%Y-%m-%d}' \
  /mnt/casper-data

borg prune \
  --list \
  --keep-daily=5 \
  --keep-weekly=3 \
  --keep-monthly=3 \
  $REPO

borg compact $REPO

exit 0
