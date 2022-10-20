# syntax=docker/dockerfile:1

ARG NODE_IMAGE=node:18@sha256:61c3919293bd4031b6e3eb14114afa0ccb19db03addbae056e9d821d0d079a42
ARG RUNTIME_IMAGE=gcr.io/distroless/nodejs:18@sha256:12a8f15129f08a8455fc35d3de801c1e6def65fb53c72af264b07e73aee761d2

#----------------------------------------------------------------------------
FROM $NODE_IMAGE as builder

ARG PNPM_VERSION=7.13.6
RUN npm --no-update-notifier --no-fund --global install "pnpm@${PNPM_VERSION}"

WORKDIR /src
COPY --link pnpm-lock.yaml package.json /src/
RUN pnpm fetch
COPY --link . /src/

#----------------------------------------------------------------------------
FROM builder as workflows-builder

WORKDIR /src/packages/workflows
RUN pnpm install --reporter=append-only
RUN pnpm run build
RUN pnpm "--filter=@example/workflows" deploy --prod /app

#----------------------------------------------------------------------------
FROM builder as worker-builder

WORKDIR /src/packages/worker
RUN pnpm install --reporter=append-only
RUN pnpm run build
RUN pnpm "--filter=@example/worker" deploy --prod /app

#----------------------------------------------------------------------------
FROM $NODE_IMAGE as worker-runtime

COPY --link --from=worker-builder /app /app
CMD [ "/app/index.js" ]
