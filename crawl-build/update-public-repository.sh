#!/bin/bash

set -e

echo "Refreshing public repository:"
echo "-----------------------------"
sudo -H -u git /var/cache/git/crawl-ref.git/update.sh
echo

