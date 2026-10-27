#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Digg - Agency for Digital Government
#
# SPDX-License-Identifier: EUPL-1.2

set -euo pipefail

CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
if ! command -v "$CONTAINER_ENGINE" >/dev/null 2>&1; then
  if command -v docker >/dev/null 2>&1; then
    CONTAINER_ENGINE="docker"
  else
    echo "Error: Neither podman nor docker found in PATH" >&2
    exit 1
  fi
fi

IMAGE_TAG="${1:-wallet-keycloak:local}"
CONTAINER_NAME="wallet-keycloak-test-$$"
HTTP_PORT="${TEST_HTTP_PORT:-18080}"
MGMT_PORT="${TEST_MGMT_PORT:-19000}"

cleanup() {
  echo "Cleaning up container $CONTAINER_NAME..."
  "$CONTAINER_ENGINE" rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Starting Keycloak container $CONTAINER_NAME from image $IMAGE_TAG..."
"$CONTAINER_ENGINE" run -d \
  --name "$CONTAINER_NAME" \
  -p "${HTTP_PORT}:8080" \
  -p "${MGMT_PORT}:9000" \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -e KC_HTTP_ENABLED=true \
  -e KC_HOSTNAME_STRICT=false \
  "$IMAGE_TAG"

echo "Waiting for Keycloak readiness at http://localhost:${MGMT_PORT}/idp/health/ready..."
MAX_ATTEMPTS=45
for i in $(seq 1 "$MAX_ATTEMPTS"); do
  if curl -sf "http://localhost:${MGMT_PORT}/idp/health/ready" | grep -q '"status": "UP"'; then
    echo "Keycloak is ready (attempt $i/$MAX_ATTEMPTS)!"
    break
  fi
  if [[ "$i" -eq "$MAX_ATTEMPTS" ]]; then
    echo "Error: Timed out waiting for Keycloak to become ready." >&2
    "$CONTAINER_ENGINE" logs "$CONTAINER_NAME" >&2
    exit 1
  fi
  sleep 1
done

echo "Verifying OpenID configuration for pid-issuer-realm..."
CONFIG_URL="http://localhost:${HTTP_PORT}/idp/realms/pid-issuer-realm/.well-known/openid-configuration"
RESPONSE=$(curl -sf "$CONFIG_URL")

echo "Asserting issuer claim..."
echo "$RESPONSE" | grep -q '"issuer":'

echo "Asserting ABCA challenge endpoint..."
echo "$RESPONSE" | grep -q '"challenge_endpoint":'

echo "Asserting attest_jwt_client_auth support..."
echo "$RESPONSE" | grep -q 'attest_jwt_client_auth'

echo "Asserting DPoP support..."
echo "$RESPONSE" | grep -q '"dpop_signing_alg_values_supported":'

echo "All smoke tests passed successfully!"
