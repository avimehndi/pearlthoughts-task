# === Build Stage ===
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Build admin only (can be skipped for develop mode, but it's OK to keep)
RUN npm run build

# === Development Stage ===
FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache sqlite sqlite-libs

COPY --from=build /app ./

RUN mkdir -p /app/.tmp /app/public/uploads

RUN npm ci

EXPOSE 1337

ENV NODE_ENV=development

# <-- THIS is the key difference for development mode!
CMD ["npm", "run", "develop"]
