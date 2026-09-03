# coil-uuid

RFC 4122 UUID for [coil](https://github.com/ardax-corp/coil-lang). Package name is `uuid`, so `use uuid::{v4, parse, Uuid, UuidError}` resolves here.

This repository is **private**. v4 entropy comes from public [coil-crypto](https://github.com/ardax-corp/coil-crypto) `random_bytes` (CSPRNG).

## API

```coil
use uuid::{v4, parse, Uuid, UuidError};

let id = v4()?;
let s = id.to_string();
let again = parse(s)?;
```

`Uuid` is 16 bytes. Coil `int` is i64 — the octets are a `Vec<byte>`, not one integer. `to_string` is lowercase `8-4-4-4-12` hex (not `Show`). `parse` requires that hyphenated form (hex case-insensitive). `v4` sets version nibble `4` and RFC 4122 variant bits `10xx`. Crypto failure is `UuidError::Entropy`.

| Name | Role |
|------|------|
| `v4()` | RFC 4122 version 4 (`Result<Uuid, UuidError>`) |
| `parse(string)` | Hyphenated hex (`Result<Uuid, UuidError>`) |
| `Uuid.to_string` | Canonical lowercase hex |
| `Uuid.version` / `Uuid.variant` | RFC nibbles (`variant == 2` is `10xx`) |
| `Uuid.bytes` | The 16 octets (`Vec<byte>`) |
| `UuidError` | `Invalid`, `Entropy` |

v7 (unix-ms + random) is omitted: it would add coil-time native `dload` next to crypto. v1/v5 are omitted.

## Layout

| Path | Role |
|------|------|
| `src/uuid.hy` | `Uuid`, `UuidError`, `v4`, `parse` |
| `coil.toml` | `[package] name = "uuid"` so `use uuid::{…}` resolves |

## Consume

Sibling checkout of this private repo plus coil-crypto. Typecheck grant is `--allow-dload crypto`. Details in [docs/consume.md](docs/consume.md).

```toml
[dependencies]
uuid = { git = "https://github.com/ardax-corp/coil-uuid.git" }
crypto = { git = "https://github.com/ardax-corp/coil-crypto.git", trusted = true }
```

`{ git }` is the parseable form. `version` is optional schema, not a tag. The pin is `coil.lock` `rev` + `content_hash`. The compiler does not follow path deps; `--root` / roots must include crypto `src/`.

## License

MIT. See [LICENSE](LICENSE).
