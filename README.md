# temporal-ts-example

Example of a temporal typescript dockerized development environment.

This uses pnpm workspaces and Tilt to demonstrate a usable live-reload environment.

## Questions

### Why `pnpm` instead of yarn or npm?

When using workspaces, it is impossible to mount only a subset of the workspace
into a docker container when performing a build, since one package may reference
another internally, and the transitive dependency tree is not known a-priori.

The dependencies of each package are described in the tree of package.json files
littered throughput this space. npm and yarn must be able to see all package.json
files in the entire workspace to be able to install the correct dependencies.

This means that npm and yarn cannot successfully perform an install without first
mounting the subtree of all package.json files in the workspace. Since this is
naturally going to mount (or at least evaluate) all source files, this layer is
going to be very slow to regenerate.

pnpm flattens all possible dependencies into its lockfile at the root of the repo.
All packages that might be needed for a build can be installed by just mounting
this lockfile and installing from it.

See: https://pnpm.io/cli/fetch#usage-scenario
