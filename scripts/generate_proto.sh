#!/bin/bash
# Generate Dart protobuf files from .proto definitions

set -e

echo "Generating Dart protobuf files..."

# Create output directory
mkdir -p lib/core/device_comm/proto

# Generate Dart files
protoc \
  --dart_out=grpc:lib/core/device_comm/proto \
  --proto_path=proto \
  proto/navigation.proto

echo "✓ Dart protobuf generation complete"
echo "Generated files in: lib/core/device_comm/proto"
