# syntax=docker/dockerfile:1@sha256:9ba7531bd80fb0a858632727cf7a112fbfd19b17e94c4e84ced81e24ef1a0dbc

# This image is used for building, it is a larger image with more tooling
# for package installation, scripting, etc.
ARG BUILDER_IMAGE=node:18@sha256:61c3919293bd4031b6e3eb14114afa0ccb19db03addbae056e9d821d0d079a42

# This image is used for runtime, it is a smaller image that does not include
# any tools to minimize production image size and surface area.
ARG RUNTIME_IMAGE=gcr.io/distroless/nodejs:18@sha256:473aac262e217acd570d223b557bcc25b9cffb92e3590a4a0b0cc67fd13e81ee

#----------------------------------------------------------------------------
FROM $BUILDER_IMAGE as builder

# Install all node modules for all packages.
#
# Yarn allows inheritance of dependencies from the root package.json in a
# monorepo, so we centralize versioning there and use that package.json to
# control the installed dependencies.
WORKDIR /src
COPY --link yarn.lock package.json /src/
RUN yarn install --frozen-lockfile --non-interactive

#----------------------------------------------------------------------------
FROM builder as packagejson-cache

# Copy the entire packages directory, but strip contents down to only package.json.
#
# This builds an image cache which only changes when package.json files changes.
# See: https://github.com/moby/moby/issues/15771#issuecomment-1210085951
COPY --link ./packages /src/packages
RUN find packages \! -name "package.json" -mindepth 2 -maxdepth 2 -print | xargs rm -rf

#----------------------------------------------------------------------------
FROM builder as workflows-builder

WORKDIR /src/packages/workflows
COPY --from=packagejson-cache /src /src
RUN yarn install --offline --frozen-lockfile --non-interactive

COPY --link . /src
RUN yarn build

#----------------------------------------------------------------------------
FROM builder as worker-builder

WORKDIR /src/packages/worker
COPY --from=packagejson-cache /src /src
RUN yarn install --offline --frozen-lockfile --non-interactive

COPY --link . /src
RUN --mount=type=cache,target=/src/.parcel-cache yarn build

#----------------------------------------------------------------------------
FROM builder as client-builder

WORKDIR /src/packages/client
COPY --from=packagejson-cache /src /src
RUN yarn install --offline --frozen-lockfile --non-interactive

COPY --link . /src
RUN --mount=type=cache,target=/src/.parcel-cache yarn build

#----------------------------------------------------------------------------
FROM $BUILDER_IMAGE as temporal-cache
WORKDIR /app

# Since temporal can't be embedded inside the bundle, we separately install
# it into the node_modules and then mount it to the runtime image.
#
# We then manually remove @swc/core because we are not bundling at runtime.
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn \
    yarn add \
        @temporalio/activity@1.4.3 \
        @temporalio/client@1.4.3 \
        @temporalio/worker@1.4.3 \
        @temporalio/workflow@1.4.3 && \
    rm -rf ./node_modules/@swc

#----------------------------------------------------------------------------
FROM $RUNTIME_IMAGE as worker-runtime
WORKDIR /app

COPY --link --from=temporal-cache /app/node_modules /app/node_modules
COPY --link --from=worker-builder /src/packages/worker/dist /app/worker
COPY --link --from=workflows-builder /src/packages/workflows/dist /app/workflows

CMD [ "./worker/index.js" ]

#----------------------------------------------------------------------------
FROM $RUNTIME_IMAGE as client-runtime
WORKDIR /app

COPY --link --from=temporal-cache /app/node_modules /app/node_modules
COPY --link --from=client-builder /src/packages/client/dist /app/client

CMD [ "./client/index.js" ]
