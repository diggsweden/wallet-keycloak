# Development Guide

This guide outlines core essentials for developing in this project.

## Table of Contents

- [Setup and Configuration](#setup-and-configuration)
  - [Prerequisites](#prerequisites)
  - [IDE Setup](#ide-setup)
- [Development Workflow](#development-workflow)
  - [Available Commands](#available-commands)
  - [Building the Image](#building-the-container-image)
  - [Running Tests](#running-smoke-tests)
  - [Quality Checks](#quality-checks)
  - [Realm Configuration](#realm-configuration)
  - [Pull Request Workflow](#pull-request-workflow)

## Setup and Configuration

### Prerequisites

1. Install [mise](https://mise.jdx.dev/) (manages tools and linters):

   ```bash
   curl https://mise.run | sh
   ```

2. Activate mise in your shell:

   ```bash
   # For bash - add to ~/.bashrc
   eval "$(mise activate bash)"

   # For zsh - add to ~/.zshrc
   eval "$(mise activate zsh)"
   ```

3. Install project tools:

   ```bash
   mise install
   just install
   ```

4. Install a container engine: [Podman](https://podman.io/) (recommended) or [Docker](https://www.docker.com/).

### IDE Setup

Run quality checks to verify your setup:

```bash
just verify
```

## Development Workflow

### Available Commands

List all available recipes:

```bash
just --list
```

### Building the Container Image

Build the optimized Keycloak image locally with Podman (or Docker):

```bash
just build
```

This packages Keycloak with Quarkus `--optimized`, enabling DPoP and the EUDI ABCA extension (`eu.europa.ec.eudi:abca-keycloak-ext:0.2.2`).

### Running Smoke Tests

Run automated container smoke tests:

```bash
just test
```

The test script:

1. Starts a temporary Keycloak container from `wallet-keycloak:local`.
2. Polls `http://localhost:19000/idp/health/ready` until `UP`.
3. Asserts the OpenID configuration at `http://localhost:18080/idp/realms/pid-issuer-realm/.well-known/openid-configuration`.
4. Confirms `challenge_endpoint`, `attest_jwt_client_auth`, and `dpop` support.
5. Cleans up the test container.

### Quality Checks

Run all linters and the smoke test:

```bash
just verify
```

To run only linters:

```bash
just lint-all
```

To auto-fix formatting issues:

```bash
just lint-fix
```

### Realm Configuration

Realm configuration files are located in `config/realms/`:

- `master-realm.json`: Master realm configuration.
- `pid-issuer-realm-realm.json`: PID Issuer realm configuration with ABCA authenticator flow and client mapper.
- `pid-issuer-realm-users-*.json`: Seed user datasets.

Configurations support environment variable substitution with fallback defaults:

- `PID_ISSUER_SRV_SECRET`: Client secret for `pid-issuer-srv` client.
- `KEYCLOAK_ABCA_TRUST_VALIDATOR_URL`: Trust validator service endpoint (default: `http://trust-validator:8080/trust-validator/trust`).
- `KEYCLOAK_STATUS_LIST_URI`: Status list JWT URL (default: `http://trust-source/signed/status-list.jwt`).
- `KEYCLOAK_WEBAUTHN_RP_ENTITY_NAME`: WebAuthn Relying Party entity name.
- `KEYCLOAK_WEBAUTHN_RP_ID`: WebAuthn Relying Party identifier.

### Pull Request Workflow

1. Create a feature branch from `main`:

   ```bash
   git checkout -b feat/my-change
   ```

2. Make your changes and run `just lint-fix`.
3. Ensure all checks pass:

   ```bash
   just verify
   ```

4. Commit using Conventional Commits with GPG signature (`-S`) and DCO sign-off (`-s`):

   ```bash
   git commit -S -s -m "feat(realm): describe change"
   ```
