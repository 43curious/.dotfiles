#!/bin/bash

STATUS=$(tailscale status 2>/dev/null)

if echo "$STATUS" | grep -q "Logged out"; then
    echo "Starting Tailscale..."
    tailscale up
elif echo "$STATUS" | grep -q "100."; then
    echo "Stopping Tailscale..."
    tailscale down
else
    echo "Starting Tailscale..."
    tailscale up
fi
