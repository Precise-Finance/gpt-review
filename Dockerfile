
# Step 1: Build Stage
FROM node:18.14.0-alpine AS builder

WORKDIR /app
# Copy the package.json, package-lock.json, .npmrc, and prisma folder initially
COPY package*.json .npmrc ./
COPY prisma/ ./prisma/
COPY .env ./

# Install the npm dependencies 
RUN npm ci --no-audit --no-progress && npm cache clean --force

# Now copy the rest of your application 
COPY src/ ./src/
COPY tsconfig.json ./
COPY tsconfig.build.json ./
COPY nest-cli.json ./
COPY .eslintrc.js ./

RUN if [ -f ./prisma/seed.ts ]; then npx tsc ./prisma/seed.ts; fi

RUN npm run-script build

# Prune dev dependencies
RUN npm prune --omit=dev

# remove unused dependencies
RUN rm -rf node_modules/rxjs/src/
RUN rm -rf node_modules/rxjs/bundles/
RUN rm -rf node_modules/rxjs/_esm5/
RUN rm -rf node_modules/rxjs/_esm2015/
RUN rm -rf node_modules/swagger-ui-dist/*.map

# Step 2: Runtime Stage
FROM node:18.14.0-alpine

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR /app

COPY --from=builder /app/.npmrc /app/
COPY --from=builder /app/prisma/ /app/prisma/
COPY --from=builder /app/.env /app/
COPY --from=builder /app/package*.json /app/
COPY --from=builder /app/dist/ /app/dist/
COPY --from=builder /app/node_modules/ /app/node_modules/

EXPOSE 3000

CMD ["npm", "run-script", "start:prod"]

