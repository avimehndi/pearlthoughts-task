# Use Node.js base image
FROM node:20

# Set working directory
WORKDIR /app

# Copy only package.json and package-lock.json
COPY package*.json package-lock.json ./

# Install dependencies inside Docker (builds native modules here)
RUN npm install

# Copy the rest of the app
COPY . .

# Rebuild better-sqlite3 inside container
RUN npm rebuild better-sqlite3

# Expose port
EXPOSE 1337

# Start the app
CMD ["npm", "run", "develop"]