# === Build Stage ===
FROM node:20-alpine as build

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Build admin panel
RUN npm run build

# === Production Stage ===
FROM node:20-alpine

WORKDIR /app

# Add SQLite support (optional alpine dependencies)
RUN apk add --no-cache sqlite sqlite-libs

# Copy from build stage
COPY --from=build /app .

RUN mkdir -p /app/.tmp /app/public/uploads

# Install only production dependencies
RUN npm install --omit=dev

EXPOSE 1337
CMD ["npm", "start"]
