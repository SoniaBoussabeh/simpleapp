# Unprivileged nginx: runs as non-root and listens on 8080 by default
FROM nginxinc/nginx-unprivileged:1.27-alpine

# Version is passed in at build time (CI reads it from the VERSION file)
ARG APP_VERSION=0.1.1

# Static content + nginx config
COPY app/ /usr/share/nginx/html/
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Bake the version into a file served at /version and into the page itself
USER root
RUN printf '%s' "${APP_VERSION}" > /usr/share/nginx/html/version.txt
USER nginx

EXPOSE 8080
