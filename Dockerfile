###################################################
# Stage: base
###################################################
FROM node:22 AS base
# Set the working directory inside the container
WORKDIR /usr/src/app


################## CLIENT STAGES ##################
# Frontend - NEXTJS
###################################################
# Stage: client-base
FROM base AS client-base
COPY nsc-events-nextjs/ .
RUN npm install 
# Stage: client-dev
FROM client-base AS client-dev
CMD ["npm", "run", "dev"]
# Stage client-build
FROM client-base AS client-build
RUN npm run build 


################  BACKEND STAGES  #################
# Backend - NESTJS
###################################################
# Stage: backend-base
FROM base AS backend-dev
COPY nsc-events-nestjs/ .
RUN npm install
CMD ["npm", "run", "dev"]
# Stage: test
FROM backend-dev AS test
# Keep runInBand to avoid OOM in Docker Desktop
RUN npm run test -- --runInBand


###################################################
# Stage: final (production backend)
FROM base AS final-image
ENV NODE_ENV=production
COPY --from=test  /usr/local/app/package.json /usr/local/app/package-lock.json ./
RUN npm ci --production && \
    npm cache clean --force
COPY nsc-events-nestjs/src ./src
COPY --from=client-build /usr/src/app/.dist ./dist/static
EXPOSE 3000
CMD ["node", "src/index.js"]