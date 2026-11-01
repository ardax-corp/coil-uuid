# Consuming coil-uuid

This package is `uuid`. `use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError}` resolves from `src/uuid.coil`.

Random bits come from coil's builtin `entropy::bytes(n)` (the OS CSPRNG, a HostInvoke like `clock`: no native library, no `dload`, no `--allow-*` grant). Time-based versions call [coil-time](https://github.com/ardax-corp/coil-time) `timestamp()` (`Result<Timestamp, TimeError>`). Use `ts.millis()`, `ts.nanos()`, and `ts.secs()` on that value. coil reads no `coil.toml`: `--root` must include time `src/` so `use time` resolves. coil-time is pure Coil too, so the whole package is.

## Versions

| Fn | Layout | Notes |
|----|--------|--------|
| `v4()` | random | RFC 4122 |
| `v1()` | Gregorian 100ns + clock seq + 48-bit node | Node is 6 random bytes with the multicast bit set. Not a host MAC. |
| `v6()` | time-reordered v1 | RFC 9562. Shares v1 clock seq and node. |
| `v7()` | unix milliseconds + random | RFC 9562. Millis from `timestamp().millis()`. |

`Uuid` is 16 `byte`s. `parse` / `to_string` are hyphenated `8-4-4-4-12`. RFC variant bits are `10xx` (`variant() == 2`). Version nibble is 1, 4, 6, or 7.

**v3 / v5 are not shipped.** They need MD5 / SHA-1, which nothing in the coil ecosystem provides yet. Both are plain computation, so they can be added in pure Coil.

v2 (DCE) and v8 (custom) are omitted.

Clock failure is `UuidError::Time(TimeError)`. Malformed input is `UuidError::Invalid`. A failing OS random source panics: `entropy::bytes` never falls back to a weaker source.

## Sibling checkout

Clone this repo and coil-time next to your project:

```bash
coil test \
  --root ../coil-uuid/src --root ../coil-time/src \
  --root ../coil-stdlib/src
```

Then:

```coil
use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError};

let id = v7()?;
let s = id.to_string();
let again = parse("550e8400-e29b-41d4-a716-446655440000")?;
```

`parse` takes hyphenated `8-4-4-4-12` hex. `to_string` emits that form in lowercase.

## With spool

```bash
spool add uuid --git https://github.com/ardax-corp/coil-uuid.git --rev <commit SHA>
```

This repo has no tags yet, so pin a commit with `--rev`. spool writes `coil.lock`, links `.spool/deps/{uuid,time}` and passes their `--root`s; this repo's `coil.toml` follows the default branch of coil-time (`version = "latest"`). Nothing needs building or granting.

## Call it

Signatures are in [`src/uuid.coil`](../src/uuid.coil). Call patterns are in [`tests/rfc4122.coil`](../tests/rfc4122.coil).

```coil
use uuid::{v7, parse, Uuid, UuidError};

match v7() {
    Result::Ok(u) => {
        let _ = u.version() == 7 && u.variant() == 2;
    },
    Result::Err(e) => match e {
        UuidError::Time(_) => {},
        default => {},
    },
}

match parse("not-a-uuid") {
    Result::Ok(_) => false,
    Result::Err(e) => match e {
        UuidError::Invalid => true,
        default => false,
    },
};
```

`Uuid` is a class holding 16 `byte`s (`pub bytes`). `#[derive(Eq)]` is present for same-module use; tests compare `.bytes` / `.to_string()`. `#[derive(Hash)]` is omitted: prelude `Hash` is primitives only.
