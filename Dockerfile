FROM node:20

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Expose Strapi default port
EXPOSE 1337

# Run Strapi in development mode
CMD ["npm", "run", "develop"]
