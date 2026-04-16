#!/usr/bin/env bash
set -e

# Usage: ./health-check.sh <url>
# Example: ./health-check.sh http://app-green:80

URL="${1:-http://localhost:8080}"
RETRIES=5
SLEEP_SEC=2

echo "Testing $URL from inside nginx network..."

for i in $(seq 1 $RETRIES); do
  # Dùng mạng của docker-compose thông qua container nginx để ping trực tiếp container con
  if docker compose exec -T nginx sh -c "wget -q -S -O /dev/null \"$URL\""; then
    echo "Health check passed at attempt $i"
    exit 0
  fi
  echo "Attempt $i failed, retrying in $SLEEP_SEC seconds..."
  sleep $SLEEP_SEC
done

echo "Health check failed after $RETRIES attempts"
exit 1
