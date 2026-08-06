#!/bin/bash

echo "Load initiated in the background. Please do not terminate this process."

timeout 1000s bash -c 'for i in {1..10}; do (while true; do curl -s http://controlplane:30080 > /dev/null; done) & done; wait'
