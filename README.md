<!-- markdownlint-disable MD041 -->
![OQTOPUS logo](https://raw.githubusercontent.com/oqtopus-team/artwork/refs/heads/main/SVG/oqtopus-normal_hn.svg)

# OQTOPUS Backend Setup

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![slack](https://img.shields.io/badge/slack-OQTOPUS-pink.svg?logo=slack&style=plastic)](https://join.slack.com/t/oqtopus/shared_invite/zt-3bpjb7yc3-Vg8IYSMY1m5wV3DR~TMSnw)

## Overview

This repository provides Docker Compose environments for deploying
the OQTOPUS backend.

The repository is intended to be cloned on the machine where the
environment will run. This can be either a server or a local development
machine.

Application repositories are cloned by the installation script so that
updating the repositories is straightforward using standard Git
operations (for example `git pull`).

Each application repository contains a `Dockerfile.dev`, which is used
to build the Docker images for the backend services. This repository is
designed around that convention.

The backend environment can be constructed from either the `main`
branch or the `develop` branch of the application repositories,
depending on the selected environment.

> [!NOTE]
> This repository installs application code directly from the
> current `main` or `develop` branches rather than from GitHub release tags.
> It is intended as a tool for quickly setting up an OQTOPUS backend
> environment in an ad-hoc manner.
>
> An installation tool that installs backend components from
> official release tags is planned and will be provided in the future.

## Backend Components

The OQTOPUS backend is composed of multiple microservices.

At the center of the system is the OQTOPUS Engine core, which is responsible
for processing quantum jobs. The engine coordinates with other backend
services to perform tasks.

The following services constitute the backend system:

- `core`  
  OQTOPUS Engine core service responsible for job execution.

- `sse_engine`  
  A lightweight variant of the OQTOPUS Engine core used for SSE (Server-Side Execution),  
  designed to execute hybrid classical–quantum computations efficiently.

- `sse_runtime`  
  A Docker container used to execute SSE programs.

- `mitigator`  
  A service that performs computations using quantum error mitigation.

- `estimator`  
  A service used to compute expectation values of quantum circuits.

- `combiner`  
  A service that enables multi-programming. 
  It combines multiple quantum circuits into a single circuit.

- `tranqu (tranqu server)`  
  Provides transpilation services.

- `gateway (device gateway)`  
  Communicates with the target quantum device or simulator.

## Repository Structure

```text
backend-setup/
├─ oqtopus-dev/  # directory for development environment
└─ oqtopus-prod/ # directory for production environment
```

Initially, each environment directory only contains configuration files
and helper scripts:

```text
oqtopus-xxx/
├─ config/.env.local
├─ docker-compose.yml
├─ install.sh
└─ Makefile
```

When `install.sh` is executed, the required OQTOPUS application
repositories are cloned into this directory, and several runtime
directories are created. The resulting structure becomes similar to
the following:

```text
oqtopus-xxx/
├─ combiner/          # OQTOPUS Engine combiner service
├─ config/
│  ├─ .env            # global environment configuration (network, ports, ...)
│  └─ .env.local      # template for .env (copy to .env before editing)
├─ core/              # OQTOPUS Engine core service
├─ device-gateway/    # device gateway service
├─ estimator/         # OQTOPUS Engine estimator service
├─ logs/              # log directory for backend service
├─ mitigator/         # OQTOPUS Engine mitigator service
├─ sse_engine/        # OQTOPUS Engine SSE engine service
├─ sse_runtime/       # Docker build environment for SSE runtime
├─ sse_work/          # working directory used by SSE runtime
├─ tranqu-server/     # transpiler service
├─ docker-compose.yml # Docker Compose configuration
├─ install.sh         # installation script (clones repositories and prepares the environment)
└─ Makefile           # helper commands for build, start, stop, logs, ...
```

These service directories contain the source code for each
backend component. They are retrieved automatically by `install.sh`
from the corresponding upstream repositories.

### Environments

Two environments are currently provided:

| Directory      | Purpose                 | Branch policy                                   |
|----------------|-------------------------|-------------------------------------------------|
| `oqtopus-dev`  | Development environment | `develop` branch if available, otherwise `main` |
| `oqtopus-prod` | Production environment  | `main` branch                                   |

The `install.sh` script clones required repositories and checks out the
appropriate branch automatically.

### Prerequisites

This environment requires Docker with Buildx support. Standard Docker installations may not include the Buildx plugin by default.

- Docker Engine (20.10.0+)
- Docker Buildx Plugin (See: [Docker Build Overview](https://docs.docker.com/build/install-buildx/))
- Docker Compose V2
- Git (2.25+ for sparse-checkout support)
- Make

To check if the required tools are installed, run:

```bash
docker compose version
docker buildx version
git --version
make --version
```

## Installing Tools and Applications

Download and execute `install.sh` from this repository.

This repository contains configuration files for multiple environments.
To avoid confusion, only the files required for the target environment
should be checked out using Git sparse-checkout.

The following example retrieves the `oqtopus-dev` environment.

```bash
git clone --filter=blob:none --no-checkout https://github.com/oqtopus-team/backend-setup.git
cd backend-setup
git sparse-checkout set oqtopus-dev
git checkout
cd oqtopus-dev
bash install.sh
```

The `install.sh` script performs the following tasks:

- clones required OQTOPUS application repositories
- checks out the appropriate branch

## Service Configuration

### Edit the global configuration file

First, create `config/.env` from the provided template and configure the global settings.
This file manages environment-wide variables such as networking, subnets, and service connection details.

```bash
cd config
cp .env.local .env
```

Then edit `config/.env` to match your environment.

The `config/.env` file contains several important settings used by the backend services.

- `UID`  
  The user ID used to run the backend service containers.  
  This value must match the user ID defined in `/etc/passwd`.

- `GID`  
  The group ID used to run the backend service containers.  
  This value must match the group ID defined in `/etc/group`.

- `DOCKER_GID`  
  The group ID of the `docker` group used by the backend services to run Docker commands.  
  This value must match the Docker group ID defined in `/etc/group`.

- `SUBNET_PREFIX`  
  The first 24 bits of the network subnet used by the backend services.  
  This subnet must not overlap with other Docker networks or networks used on the host.

- `JOB_REPOSITORY_URL`  
  The provider API URL of the Job Repository, which manages quantum jobs.  
  In most deployments this is the OQTOPUS Cloud service.

- `JOB_REPOSITORY_API_KEY`  
  The API key used to authenticate when accessing the Job Repository.

- `SSE_CONTAINER_NETWORK`  
  The name of the Docker network.

### Service Configurations

Once `config/.env` is properly set up, the following services are designed to inherit those settings,
and their individual configuration files generally **do not** require manual modification:

- core: `core/core/config/config.yaml`
- sse_engine: `sse_engine/core/config/sse_engine_config.yaml`
- mitigator: `mitigator/mitigator/config/config.yaml`
- estimator: `estimator/estimator/config/config.yaml`
- combiner: `combiner/combiner/config/config.yaml`
- tranqu-server: `tranqu-server/config/config.yaml`

The `sse_runtime` component does not have a configuration file.
It only provides the Docker runtime environment used to execute SSE programs.

The device-gateway requires manual configuration to specify the target device details:

- device-gateway: `device-gateway/config`

For detailed parameters, refer to the [Device Gateway Documentation](https://device-gateway.readthedocs.io/).

To quickly initialize the Device Gateway with a pre-configured template, run the following script:

```bash
bash setup_gateway_defaults.sh [device_id]
```

Executing this script will configure the gateway with the following default parameters:

- plugin: `QulacsBackend`
- device_id: `qulacs`
- Number of Qubits: `16`

If an argument is provided, it will be used as the `device_id`, overriding the default value.

The `device_id` can be configured in the following files:

- `device-gateway/config/config.yaml` → `device_info.device_id`
- `device-gateway/config/device_topology_sim.json` → `device_id`

The number of qubits can be configured in the following files:

- `device-gateway/config/config.yaml` → `device_info.max_qubits`
- `device-gateway/config/device_topology_sim.json` → size of the `qubits` array

## Starting, Stopping, and Building Services

You can use the `make` command to start, stop, and build each service.

The following services are available:

- `core`
- `sse_engine`
- `sse_runtime`
- `mitigator`
- `estimator`
- `combiner`
- `tranqu`
- `gateway`

The `sse_runtime` service is not started directly by the operator.
Instead, it is launched automatically by `core`.
For this reason, `sse_runtime` does not provide commands such as start or stop.

For each service, the following `make` command options are commonly available.
Replace `<app>` with one of the service names listed above.

- `up-<app>`: Start the `<app>` service container in the background.
- `stop-<app>`: Stop the `<app>` service container.
- `restart-<app>`: Restart the `<app>` service container (runs stop followed by up).
- `logs-<app>`: Show logs of the `<app>` service container.
- `rm-<app>`: Remove the stopped `<app>` service container.
- `build-<app>`: Run `git pull` for the `<app>` service and build its container.
- `exec-<app>`: Enter the `<app>` service container for interactive operations.

> [!NOTE]
> When you run `up-<app>` for the first time, Docker will automatically start the build process.
> Please be aware that this is a heavy task and may take some time depending on your environment.

> [!IMPORTANT]
> When installing for the first time or updating an application, run `make build-<app>` before starting the service.
> This ensures the latest source code is pulled and the Docker image is rebuilt with the most recent changes.

The `device-gateway` service provides additional commands that are not listed here.
For details, refer to the `Makefile`.

## Contact

You can contact us by creating an issue in this repository or by email:

- [oqtopus-team[at]googlegroups.com](mailto:oqtopus-team[at]googlegroups.com)

## License

OQTOPUS Backend Setup is released under the [Apache License 2.0](LICENSE).
