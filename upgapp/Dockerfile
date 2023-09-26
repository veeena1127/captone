FROM node:12.18.1
ENV NODE_ENV=production

WORKDIR /app

COPY ["package.json", "package-lock.json*", "server.js", "./"]

RUN npm init -y
RUN npm install --production

CMD [ "node", "server.js" ]
