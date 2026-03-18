FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src/ src/
RUN npm run build

FROM node:22-slim
RUN apt-get update && apt-get install -y --no-install-recommends tini && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts
COPY --from=build /app/dist dist/
COPY container/ container/
COPY groups/ groups/

VOLUME ["/app/data", "/app/groups"]

ENV NODE_ENV=production
ENTRYPOINT ["tini", "--"]
CMD ["node", "dist/index.js"]
