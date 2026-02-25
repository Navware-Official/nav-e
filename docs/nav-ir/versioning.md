# Nav-IR versioning

## schema_version

The top-level **Route** object has a `schema_version` field (unsigned integer). It identifies the Nav-IR schema used by that route.

- **Current version:** 1 (constant `Route::CURRENT_SCHEMA_VERSION` in `native/nav_ir/src/types.rs`).

## When to bump

Bump `schema_version` when you make **breaking** changes, for example:

- Changing a field from required to optional (or vice versa) in a way that changes interpretation.
- Renaming or removing fields.
- Changing the type or semantics of a field (e.g. polyline encoding format).
- Changing the meaning of an enum variant.

Adding **new optional** fields or new enum variants (that consumers can ignore) is backward compatible and does not require a bump. Existing consumers can keep using the same version.

## Compatibility

- **New optional fields** – Backward compatible. Producers can add them; consumers that ignore unknown fields continue to work.
- **Unknown schema_version** – Consumers may reject routes with an unknown version or ignore them. Document supported versions (e.g. in nav_core/device pipeline).
- **Forward compatibility** – When reading, ignore unknown fields so that future optional extensions do not break old parsers.
