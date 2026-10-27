# Wallet Keycloak

Keycloak container image and PID Issuer realm configuration for the Swedish EU Digital Identity Wallet (EUDIW) ecosystem.

This repository packages an optimized Keycloak distribution configured as the PID Issuer Authorization Server under the EU Digital Identity Architecture and Reference Framework (ARF), supporting:

- **Attestation-Based Client Authentication (ABCA):** `eu.europa.ec.eudi:abca-keycloak-ext` (`abca-draft07`).
- **Demonstrating Proof of Possession (DPoP):** RFC 9449 for sender-constrained access tokens.
- **Pre-configured Realms:** Baked `/opt/keycloak/data/import/` realm files with environment variable overrides for zero-drift deployments between local development (`wallet-ecosystem`) and OpenShift (`wallet-config`).

## Architecture & Features

Keycloak is built ahead-of-time (AOT) with Quarkus `--optimized`:

- Extensions are installed into `/opt/keycloak/providers/`.
- `dpop`, health, and metrics features are compiled directly into the image.
- Both `postgres` and `dev-file` database backends are supported.
- Realm configuration in `/opt/keycloak/data/import/` is imported automatically at container startup.

## Environment Variable Overrides

The baked `pid-issuer-realm-realm.json` supports runtime substitution with standard defaults:

| Variable                            | Default Value                                       | Description                                        |
| :---------------------------------- | :-------------------------------------------------- | :------------------------------------------------- |
| `PID_ISSUER_SRV_SECRET`             | `${KEYCLOAK_PID_ISSUER_CLIENT_SECRET:cow3go...}`    | Client secret for `pid-issuer-srv`                 |
| `KEYCLOAK_ABCA_TRUST_VALIDATOR_URL` | `http://trust-validator:8080/trust-validator/trust` | Trust Validator endpoint for validating WIA chains |
| `KEYCLOAK_STATUS_LIST_URI`          | `http://trust-source/signed/status-list.jwt`        | URI of Token Status List for WIA status check      |
| `KEYCLOAK_WEBAUTHN_RP_ID`           | `localhost`                                         | WebAuthn Relying Party ID                          |
| `KEYCLOAK_WEBAUTHN_RP_ENTITY_NAME`  | `https://localhost/idp`                             | WebAuthn Relying Party Entity Name                 |

## Local Development

Requirements:

- `mise` and `just`
- Podman or Docker

### Commands

```bash
# Build the container image locally
just build

# Run local smoke tests
just test

# Fix formatting
just lint-fix

# Run the complete verification suite
just verify
```

## License

This project is licensed under the EUPL-1.2. See [LICENSES/EUPL-1.2.txt](LICENSES/EUPL-1.2.txt). Documentation and configuration files are CC0-1.0.
