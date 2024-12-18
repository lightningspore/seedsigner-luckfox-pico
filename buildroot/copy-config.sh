#!/bin/bash

# Get the current timestamp
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Copy the config file to the configs folder with a timestamp
cp luckfox-pico/sysdrv/source/buildroot/buildroot-2023.02.6/.config ./configs/config_$TIMESTAMP.config
