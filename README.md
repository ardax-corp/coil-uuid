# coil-uuid

RFC 4122 / RFC 9562 UUIDs for [coil](https://github.com/ardax-corp/coil-lang): generate versions 1, 4, 6 and 7, parse the hyphenated form and format it back. Package name is `uuid`, so `use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError}` resolves here.

Entropy comes from [coil-crypto](https://github.com/ardax-corp/coil-crypto) `random_bytes` (the OS CSPRNG, through coil-crypto's native library). Time-based versions use [coil-time](https://github.com/ardax-corp/coil-time) `timestamp()`.

## Example

```coil
use uuid::{v4, v7, parse, Uuid, UuidError};
use io::sync::{println};

fn must(Result<Uuid, UuidError> r) -> Uuid {
    return match r {
        Result::Ok(u) => u,
        Result::Err(_) => panic "uuid failed",
    };
}

fn main() {
    let id = must(v7());
    println("v7: " + id.to_string())?;
    println("v4: " + must(v4()).to_string())?;

    let again = must(parse(id.to_string()));
    println("round-trips: " + (again == id).show())?;
    println("rejects junk: " + parse("not-a-uuid").is_err().show())?;
}
```

`Uuid` is 16 bytes. Coil `int` is i64, so the octets are a `Vec<byte>`, not one integer. `to_string` is lowercase `8-4-4-4-12` hex (not `Show`). `parse` requires that hyphenated form (hex case-insensitive). Generators set the version nibble and RFC variant bits `10xx`. Crypto failure is `UuidError::Entropy(CryptoError)`. Clock failure is `UuidError::Time(TimeError)`.

## API

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
| `coil.toml` | spool manifest (`[package] name = "uuid"`); coil does not read it |

## Consume

With [spool](https://github.com/ardax-corp/spool):

```bash
spool add uuid --git https://github.com/ardax-corp/coil-uuid.git --rev <commit SHA>
```

This repo has no tags yet, so pin a commit with `--rev`. spool also fetches coil-crypto and coil-time. coil-crypto's native library has to be built and granted (`--allow-dload crypto` plus `--dload-trusted crypto` or `--dload-pin`); coil-time is pure Coil.

With plain coil, clone this repo, coil-crypto and coil-time next to your project, build `libcrypto` (`make -C ../coil-crypto`) and pass each `src/` as `--root`:

```bash
coil --root ../coil-uuid/src --root ../coil-crypto/src --root ../coil-time/src \
  --root ../coil-stdlib/src \
  --ffi-search-path ../coil-crypto/native \
  --allow-dload crypto --dload-trusted crypto main.hy
```

Details in [docs/consume.md](docs/consume.md).

## License

MIT. See [LICENSE](LICENSE).
