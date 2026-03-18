FROM node:22-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src/ src/

RUN npm run build


FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    gnupg \
    ca-certificates && \
    update-ca-certificates && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /tmp/docker.asc && \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    rm /tmp/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts

COPY --from=build /app/dist ./dist
COPY container/ ./container
COPY groups/ ./groups

VOLUME ["/app/data", "/app/groups"]

ENV NODE_ENV=production

ENTRYPOINT ["tini", "--"]
CMD ["node", "dist/index.js"]