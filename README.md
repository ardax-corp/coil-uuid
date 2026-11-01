# coil-uuid

RFC 4122 / RFC 9562 UUIDs for [coil](https://github.com/ardax-corp/coil-lang): generate versions 1, 4, 6 and 7, parse the hyphenated form and format it back. Package name is `uuid`, so `use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError}` resolves here.

Entropy comes from coil's builtin `entropy::bytes` (the OS CSPRNG; no native library and no `--allow-*` grant). Time-based versions use [coil-time](https://github.com/ardax-corp/coil-time) `timestamp()`. The package is pure Coil.

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

`Uuid` is 16 bytes. Coil `int` is i64, so the octets are a `Vec<byte>`, not one integer. `to_string` is lowercase `8-4-4-4-12` hex (not `Show`). `parse` requires that hyphenated form (hex case-insensitive). Generators set the version nibble and RFC variant bits `10xx`. A failing OS random source panics (it never falls back to a weaker one). Clock failure is `UuidError::Time(TimeError)`.

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
| `UuidError` | `Invalid`, `Time` |

v3 / v5 (MD5 / SHA-1 name-based), v2 and v8 are omitted.

## Layout

| Path | Role |
|------|------|
| `src/uuid.coil` | `Uuid`, `UuidError`, `v1` / `v4` / `v6` / `v7`, `parse` |
| `coil.toml` | spool manifest (`[package] name = "uuid"`); coil does not read it |

## Consume

With [spool](https://github.com/ardax-corp/spool):

```bash
spool add uuid --git https://github.com/ardax-corp/coil-uuid.git --rev <commit SHA>
```

This repo has no tags yet, so pin a commit with `--rev`. spool also fetches coil-time (pure Coil). Nothing needs building or granting.

With plain coil, clone this repo and coil-time next to your project and pass each `src/` as `--root`:

```bash
coil --root ../coil-uuid/src --root ../coil-time/src \
  --root ../coil-stdlib/src main.coil
```

The builtin `entropy` module needs a coil built from main after coil-lang#COILPR (archive 6.15).

Details in [docs/consume.md](docs/consume.md).

## License

MIT. See [LICENSE](LICENSE).
