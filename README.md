# temporal-ts-example

Example of a Temporal Typescript SDK on a dockerized development environment.

This uses Yarn workspaces, Parcel Bundler, and Tilt + docker-compose to
demonstrate a usable live-reload environment.

In this demo, editing source files in the monorepo will automatically trigger
live updates of images which should take on the order of a few seconds after
the environment is initially warmed up.

## Setup

- Install [tilt](https://docs.tilt.dev/install.html)
- Install [docker-compose](https://docs.docker.com/compose/install/linux/)
- Check out the repository and start it up:
  ```bash
  git clone --recursive https://github.com/psigen/temporal-ts-example.git
  cd temporal-ts-example
  tilt up
  ```

## Questions

### Why yarn instead of npm?

When creating a multi-stage build for the application, it is useful to be able
to create a single pre-fetched layer with all of the dependencies that might
be needed for the various builders.

Yarn has a convenient feature where dependencies are "inherited" from the root
repository, i.e. any packages from the root package.json are made available to
the nested workspaces. This is used to centralize the location of all package
versioning, making it easier to perform version upgrades across the monorepo.
