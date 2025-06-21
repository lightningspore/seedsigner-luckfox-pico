#!/bin/bash

# Configuration
MAX_RETRIES=5
RETRY_DELAY=10  # seconds
LOG_FILE="/tmp/startup.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to cleanup on exit
cleanup() {
    log_message "Stopping SeedSigner..."
    killall rkipc 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Kill any existing rkipc processes
killall rkipc 2>/dev/null

# Change to SeedSigner directory
cd /seedsigner

# Retry loop
retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
    log_message "Starting SeedSigner (attempt $((retry_count + 1))/$MAX_RETRIES)"
    
    # Start SeedSigner
    if python main.py; then
        log_message "SeedSigner exited successfully"
        exit 0
    else
        retry_count=$((retry_count + 1))
        exit_code=$?
        log_message "SeedSigner failed with exit code $exit_code"
        
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_message "Retrying in $RETRY_DELAY seconds..."
            sleep $RETRY_DELAY
        else
            log_message "Maximum retries reached. SeedSigner failed to start."
            exit 1
        fi
    fi
done
