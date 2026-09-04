# coil-uuid

RFC 4122 / RFC 9562 UUID for [coil](https://github.com/ardax-corp/coil-lang). Package name is `uuid`, so `use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError}` resolves here.

This repository is **private**. Entropy comes from public [coil-crypto](https://github.com/ardax-corp/coil-crypto) `random_bytes` (CSPRNG). Time-based versions use public [coil-time](https://github.com/ardax-corp/coil-time) `timestamp()`.

## API

```coil
use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError};

let id = v7()?;
let s = id.to_string();
let again = parse(s)?;
```

`Uuid` is 16 bytes. Coil `int` is i64 — the octets are a `Vec<byte>`, not one integer. `to_string` is lowercase `8-4-4-4-12` hex (not `Show`). `parse` requires that hyphenated form (hex case-insensitive). Generators set the version nibble and RFC variant bits `10xx`. Crypto failure is `UuidError::Entropy`. Clock failure is `UuidError::Time`.

| Name | Role |
|------|------|
| `v4()` | RFC 4122 version 4 (random) |
| `v1()` | Gregorian 100ns + clock seq + random multicast node |
| `v6()` | RFC 9562 time-reordered v1 (shares v1 clock/node) |
| `v7()` | RFC 9562 unix milliseconds + random |
| `parse(string)` | Hyphenated hex (`Result<Uuid, UuidError>`) |
| `Uuid.to_string` | Canonical lowercase hex |
| `Uuid.version` / `Uuid.variant` | RFC nibbles (`variant == 2` is `10xx`) |
| `Uuid.bytes` | The 16 octets (`Vec<byte>`) |
| `UuidError` | `Invalid`, `Entropy`, `Time` |

v3 / v5 are omitted: coil-crypto has no MD5 or SHA-1. v2 and v8 are omitted.

## Layout

| Path | Role |
|------|------|
| `src/uuid.hy` | `Uuid`, `UuidError`, `v1` / `v4` / `v6` / `v7`, `parse` |
| `coil.toml` | `[package] name = "uuid"` so `use uuid::{…}` resolves |

## Consume

Sibling checkout of this private repo plus coil-crypto and coil-time. Typecheck grant is `--allow-dload crypto` only. coil-time is pure Coil (HostInvoke clocks; no `libtime`). Details in [docs/consume.md](docs/consume.md).

```toml
[dependencies]
uuid = { git = "https://github.com/ardax-corp/coil-uuid.git" }
crypto = { git = "https://github.com/ardax-corp/coil-crypto.git", trusted = true }
time = { git = "https://github.com/ardax-corp/coil-time.git" }
```

`{ git }` is the parseable form. `version` is optional schema, not a tag. The pin is `coil.lock` `rev` + `content_hash`. The compiler does not follow path deps; `--root` / roots must include crypto and time `src/`.

## License

MIT. See [LICENSE](LICENSE).
