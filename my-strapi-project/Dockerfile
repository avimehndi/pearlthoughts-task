# === Build Stage ===
FROM node:20-alpine as build

WORKDIR /app

# Copy dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy rest of the app
COPY . .

# Build admin panel
RUN npm run build

# === Production Stage ===
FROM node:20-alpine

WORKDIR /app

# Add SQLite dependencies
RUN apk add --no-cache sqlite sqlite-libs

# Copy from build stage
COPY --from=build /app ./

# Create necessary folders
RUN mkdir -p /app/.tmp /app/public/uploads

# Install only production dependencies
RUN npm install --omit=dev

EXPOSE 1337

CMD ["npm", "start"]
