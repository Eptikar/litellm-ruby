#!/bin/bash

if [ -f "$(pwd)/../.env" ]; then
  source "$(pwd)/../.env"
else
  echo "Warning: .env file not found in parent directory"
fi

CONFIG_PATH="$(pwd)/litellm_config.yaml"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Error: litellm_config.yaml not found in $(pwd)"
  exit 1
fi

docker run \
  -v "$CONFIG_PATH":/app/config.yaml \
  -e OPENAI_API_KEY="$OPENAI_API_KEY" \
  -p 8000:4000 \
  ghcr.io/berriai/litellm:main-latest \
  --config /app/config.yaml --detailed_debug