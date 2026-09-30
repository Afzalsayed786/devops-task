#!/bin/bash

ENVIRONMENT="${ENVIRONMENT:-local}"

echo "Environment: $ENVIRONMENT"

if [ -z "$APP_TOKEN" ]; then
    echo "ERROR: APP_TOKEN is not set"
    exit 2
else
    echo "APP_TOKEN is set"
fi

CONFIG_FILE="${1:-}"

if [ -n "$CONFIG_FILE" ]; then
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ERROR: Config file not found: $CONFIG_FILE"
        exit 2
    fi

    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

DISK_THRESHOLD="${DISK_THRESHOLD:-80}"

echo "===== SERVER HEALTH ====="

echo "Hostname:"
hostname

echo "Uptime:"
uptime -p

echo "Load Average:"
uptime | awk -F'load average:' '{print $2}'

echo "CPU:"
top -b -n 1 | grep "%Cpu" | awk '{print "User:", $2 "%", "System:", $4 "%", "Idle:", $8 "%"}'

echo "Memory:"
free -h | awk '/Mem:/ {print "Total:", $2, "Used:", $3, "Available:", $7}'

echo "Disk:"
df -h / | awk 'NR==2 {
    print "Filesystem:", $1, "Used:", $3, "Available:", $4, "Usage:", $5
}'

DISK_USAGE=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    echo "WARNING: Disk usage is ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)"
    HEALTH_FAILED=1
fi

echo "Top CPU Process:"
ps aux --sort=-%cpu | awk 'NR==2 {
    print $11, "(PID:", $2 ", CPU:", $3 "%)"
}'

echo "Top Memory Process:"
ps aux --sort=-%mem | awk 'NR==2 {
    print $11, "(PID:", $2 ", Memory:", $4 "%)"
}'

echo "Listening Ports:"
ss -ltn | tail -n +2

echo "Failed Services:"
systemctl --failed --no-legend

echo "========================="

if [ "$HEALTH_FAILED" = "1" ]; then
    exit 1
fi

exit 0
