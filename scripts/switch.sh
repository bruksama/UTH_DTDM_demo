#!/usr/bin/env bash
set -e

# Usage: ./switch.sh <target_color> <image_tag>
# Example: ./switch.sh green v2.0.1

TARGET_COLOR=$1
IMAGE_TAG=$2

if [[ -z "$TARGET_COLOR" || -z "$IMAGE_TAG" ]]; then
  echo "Error: Missing arguments."
  echo "Usage: $0 <target_color> <image_tag>"
  exit 1
fi

if [[ "$TARGET_COLOR" != "blue" && "$TARGET_COLOR" != "green" ]]; then
  echo "Error: target_color must be 'blue' or 'green'"
  exit 1
fi

IDLE_CONTAINER="app-${TARGET_COLOR}"
NGINX_CONF="./nginx/nginx.conf"

echo "=== [1/4] Starting deployment to $TARGET_COLOR with image tag $IMAGE_TAG ==="
# Export biến cho docker-compose đọc
export IMAGE_TAG="$IMAGE_TAG"

# Chỉ khởi động/cập nhật container mục tiêu
docker compose up -d --no-deps --build "$IDLE_CONTAINER"

echo "=== [2/4] Running health check on $IDLE_CONTAINER ==="
# Chờ container khởi động một chút
sleep 3
if ! bash ./scripts/health-check.sh "http://$IDLE_CONTAINER:80"; then
  echo "❌ Health check failed for $IDLE_CONTAINER. Aborting switch."
  exit 1
fi
echo "✅ Health check passed."

echo "=== [3/4] Switching Nginx traffic to $TARGET_COLOR ==="
if [ ! -f "$NGINX_CONF" ]; then
  echo "Error: nginx.conf not found at $NGINX_CONF"
  exit 1
fi

# Reset tất cả về comment
sed -i 's/server app-blue:80;/# server app-blue:80;/g' "$NGINX_CONF"
sed -i 's/server app-green:80;/# server app-green:80;/g' "$NGINX_CONF"

# Bật active cho target color
sed -i "s/# server ${IDLE_CONTAINER}:80;/server ${IDLE_CONTAINER}:80;/g" "$NGINX_CONF"

# Reload nginx để áp dụng
docker compose exec -T nginx nginx -s reload
echo "✅ Traffic switched to $TARGET_COLOR."

echo "=== [4/4] Deployment successful ==="
echo "Note: The old container is intentionally left running for fast rollback."
