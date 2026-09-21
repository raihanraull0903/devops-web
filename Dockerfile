FROM nginx:alpine

# Hapus skrip otomatisasi IPv6 bawaan Nginx Alpine yang sering memicu reset connection
RUN rm -f /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh

# Copy konfigurasi Nginx dan asset website
COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css

EXPOSE 80
