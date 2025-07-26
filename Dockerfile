# === Build stage ===
FROM node:20-alpine as build

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json yarn.lock ./
RUN yarn install

# Copy all files and build admin panel
COPY . .
RUN yarn build

# === Production stage ===
FROM node:20-alpine as production

# Set working directory
WORKDIR /app

# Copy only necessary files from build
COPY --from=build /app ./

# Install only production dependencies
RUN yarn install --production

# Expose Strapi port
EXPOSE 1337

# Start Strapi
CMD ["yarn", "start"]