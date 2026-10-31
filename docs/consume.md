# Consuming coil-uuid

This package is `uuid`. `use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError}` resolves from `src/uuid.hy`.

Generators call [coil-crypto](https://github.com/ardax-corp/coil-crypto) `random_bytes` (CSPRNG). Time-based versions call [coil-time](https://github.com/ardax-corp/coil-time) `timestamp()` (`Result<Timestamp, TimeError>`). Use `ts.millis()`, `ts.nanos()`, and `ts.secs()` on that value. coil reads no `coil.toml`: `--root` must include crypto `src/` and time `src/` so `use crypto` / `use time` resolve. The crypto grant is `--allow-dload crypto` plus `--dload-trusted crypto` (or `--dload-pin crypto=SHA256`); `--ffi-search-path` locates `libcrypto`. coil-time is pure Coil (HostInvoke clocks); there is no `--allow-dload time` and no `libtime`.

## Versions

| Fn | Layout | Notes |
|----|--------|--------|
| `v4()` | random | RFC 4122 |
| `v1()` | Gregorian 100ns + clock seq + 48-bit node | Node is 6 random bytes with the multicast bit set. Not a host MAC. |
| `v6()` | time-reordered v1 | RFC 9562. Shares v1 clock seq and node. |
| `v7()` | unix milliseconds + random | RFC 9562. Millis from `timestamp().millis()`. |

`Uuid` is 16 `byte`s. `parse` / `to_string` are hyphenated `8-4-4-4-12`. RFC variant bits are `10xx` (`variant() == 2`). Version nibble is 1, 4, 6, or 7.

**v3 / v5 are not shipped.** coil-crypto has sha256, sha512, blake3, hmac, and random — not MD5 or SHA-1. Name-based UUIDs stay omitted rather than adding a hash native.

v2 (DCE) and v8 (custom) are omitted.

Clock failure is `UuidError::Time(TimeError)`. CSPRNG failure is `UuidError::Entropy(CryptoError)`. Malformed input is `UuidError::Invalid`.

## Sibling checkout

Clone this repo, coil-crypto, and coil-time next to your project. Build `libcrypto` from the crypto package root (`make -C ../coil-crypto`). Grant only crypto dload:

```bash
coil test \
  --allow-dload crypto --dload-trusted crypto \
  --ffi-search-path ../coil-crypto/native \
  --root ../coil-uuid/src --root ../coil-crypto/src --root ../coil-time/src \
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

This repo has no tags yet, so pin a commit with `--rev`. spool writes `coil.lock`, links `.spool/deps/{uuid,crypto,time}` and passes their `--root`s; this repo's `coil.toml` follows the default branch of coil-crypto and coil-time (`version = "latest"`). spool does not build natives: build `libcrypto` in a coil-crypto checkout (`make`) and give the consumer `coil.toml` the crypto grant and search path:

```toml
[ffi]
search_paths = ["../coil-crypto/native"]
allow = ["crypto"]
```

plus `trusted = true` on a `crypto` dependency (or a `[[package.native]]` `sha256` row for it in `coil.lock`).

## Call it

Signatures are in [`src/uuid.hy`](../src/uuid.hy). Call patterns are in [`tests/rfc4122.hy`](../tests/rfc4122.hy).

```coil
use uuid::{v7, parse, Uuid, UuidError};

match v7() {
    Result::Ok(u) => {
        let _ = u.version() == 7 && u.variant() == 2;
    },
    Result::Err(e) => match e {
        UuidError::Entropy(_) => {},
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
