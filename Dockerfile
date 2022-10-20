# syntax=docker/dockerfile:1@sha256:9ba7531bd80fb0a858632727cf7a112fbfd19b17e94c4e84ced81e24ef1a0dbc

ARG NODE_IMAGE=node:18@sha256:61c3919293bd4031b6e3eb14114afa0ccb19db03addbae056e9d821d0d079a42

#----------------------------------------------------------------------------
FROM $NODE_IMAGE as builder

WORKDIR /src
COPY --link yarn.lock package.json /src/
RUN yarn install --frozen-lockfile
COPY --link . /src/

#----------------------------------------------------------------------------
FROM $NODE_IMAGE as runtime

WORKDIR /app
RUN npm install @temporalio/activity@1.4.3 @temporalio/worker@1.4.3

#----------------------------------------------------------------------------
FROM builder as workflows-builder

WORKDIR /src/packages/workflows
RUN yarn install --offline --frozen-lockfile
RUN yarn build
RUN find /src/packages/workflows/dist

#----------------------------------------------------------------------------
FROM builder as worker-builder

WORKDIR /src/packages/worker
RUN yarn install --offline --frozen-lockfile
RUN yarn build

#----------------------------------------------------------------------------
FROM runtime as worker-runtime

COPY --link --from=worker-builder /src/packages/worker/dist /app
COPY --link --from=workflows-builder /src/packages/workflows/dist /app/workflows

CMD [ "./index.js" ]

#----------------------------------------------------------------------------
FROM builder as client-builder

WORKDIR /src/packages/client
RUN yarn install --offline --frozen-lockfile
RUN yarn build

#----------------------------------------------------------------------------
FROM runtime as client-runtime

# I tried using --enable-sourcemap-support in node, and it dumped a lot of
# extra useless minified code.  So I put this in for CLI calls.
RUN npm install source-map-support

COPY --link --from=client-builder /src/packages/client/dist /app

CMD [ "./index.js" ]
