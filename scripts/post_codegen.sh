#!/bin/bash
# Post-codegen cleanup script
# Removes internal implementation files that shouldn't be exposed to Flutter

echo "Running post-codegen cleanup..."

# Remove internal infrastructure files
rm -rf lib/bridge/infrastructure/
rm -rf lib/bridge/application/

# Remove imports from frb_generated files
sed -i "/^import 'application\//d" lib/bridge/frb_generated.dart 2>/dev/null || true
sed -i "/^import 'infrastructure\//d" lib/bridge/frb_generated.dart 2>/dev/null || true
sed -i "/^import 'application\//d" lib/bridge/frb_generated.io.dart 2>/dev/null || true
sed -i "/^import 'infrastructure\//d" lib/bridge/frb_generated.io.dart 2>/dev/null || true
sed -i "/^import 'application\//d" lib/bridge/frb_generated.web.dart 2>/dev/null || true
sed -i "/^import 'infrastructure\//d" lib/bridge/frb_generated.web.dart 2>/dev/null || true

# Recreate analysis_options.yaml to suppress errors in generated code
cat > lib/bridge/analysis_options.yaml << 'EOF'
# Analysis options for generated Flutter Rust Bridge code
# This file suppresses errors in auto-generated code that references internal Rust modules

analyzer:
  errors:
    # Suppress errors from internal module code generation
    implements_non_class: ignore
    conflicting_field_and_method: ignore
    conflicting_method_and_field: ignore
    duplicate_definition: ignore
    uri_does_not_exist: ignore
    undefined_class: ignore
    argument_type_not_assignable: ignore
    extends_non_class: ignore
    undefined_annotation: ignore
EOF

echo "Post-codegen cleanup complete!"
echo "- Removed lib/bridge/infrastructure/"
echo "- Removed lib/bridge/application/"
echo "- Removed imports from frb_generated files"
echo "- Recreated lib/bridge/analysis_options.yaml"
