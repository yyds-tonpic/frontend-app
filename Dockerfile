# -----------------------
# Stage 1 — build (Node 24, Alpine)
# -----------------------
FROM node:24-alpine AS build-stage

# set working directory
WORKDIR /app

# copy package manifests first (cache npm install)
COPY package*.json ./

# install dependencies (use npm ci for reproducible install)
RUN npm ci

# copy source
COPY . .

# build production assets (Vite will output to ./dist)
RUN npm run build

# -----------------------
# Stage 2 — runtime (NGINX stable Alpine)
# -----------------------
FROM nginx:1.29-alpine AS production-stage

# set working dir for nginx html
WORKDIR /usr/share/nginx/html

# remove default static files
RUN rm -rf ./*

# copy custom nginx config if you have one (optional)
# NOTE: keep path /etc/nginx/nginx.conf only if you provided custom file.
COPY nginx.conf /etc/nginx/nginx.conf

# copy built assets from build-stage
COPY --from=build-stage /app/dist/ ./

# (Optional) set a non-root user for security — official nginx:stable-alpine already runs as nginx user by default
# Expose port (informational; docker run -p ... still required)
EXPOSE 80

# start nginx in foreground
ENTRYPOINT ["nginx", "-g", "daemon off;"]