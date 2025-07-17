# Base image
FROM node:20

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Build Strapi admin panel
RUN npm run build

# Expose the default Strapi port
EXPOSE 1337

# Start the app
CMD ["npm", "run", "develop"]
