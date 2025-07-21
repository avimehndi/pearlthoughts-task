FROM node:20

WORKDIR /app

COPY . .

RUN npm install

RUN npm run build

EXPOSE 1337

CMD ["npm", "run", "start"]

# This Dockerfile sets up a Node.js application.