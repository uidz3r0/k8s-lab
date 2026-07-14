#!/bin/bash

set -euo pipefail

ACTION=${1:-}

case "$ACTION" in
    stop)
        echo "Stopping kubelet..."
        sudo systemctl stop kubelet
        ;;
    start)
        echo "Starting kubelet..."
        sudo systemctl start kubelet
        ;;
    restart)
        echo "Restarting kubelet..."
        sudo systemctl restart kubelet
        ;;
    *)
        echo "Usage:"
        echo "  $0 stop"
        echo "  $0 start"
        echo "  $0 restart"
        exit 1
        ;;
esac