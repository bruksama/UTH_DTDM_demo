FROM nginx:alpine

# Xóa trang HTML mặc định của Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copy trang HTML của dự án vào image
COPY src/index.html /usr/share/nginx/html/index.html

# Mặc định color là blue, version là dev. Có thể ghi đè lúc chạy container.
ENV APP_COLOR=blue
ENV APP_VERSION=dev

# Chạy một script nhỏ lúc start để tạo file config.json cho Frontend đọc biến môi trường
CMD echo "{\"color\": \"$APP_COLOR\", \"version\": \"$APP_VERSION\"}" > /usr/share/nginx/html/config.json && nginx -g "daemon off;"
