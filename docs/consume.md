# Consuming coil-uuid

This package is `uuid`. `use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError}` resolves from `src/uuid.hy`. This GitHub repository is **private**; clone with credentials that can read `ardax-corp/coil-uuid`.

Generators call public [coil-crypto](https://github.com/ardax-corp/coil-crypto) `random_bytes` (CSPRNG). Time-based versions call public [coil-time](https://github.com/ardax-corp/coil-time) `timestamp()` (`Result<Timestamp, TimeError>`). Use `ts.millis()`, `ts.nanos()`, and `ts.secs()` on that value. The compiler does not follow path deps: `roots` / `--root` must include crypto `src/` and time `src/` so `use crypto` / `use time` resolve. Typecheck grants are CLI `--allow-dload crypto` and `--allow-dload time`. Do not treat `[ffi] allow` as a compiler grant. `[ffi] search_paths` locates `libcrypto` and `libtime`. Runtime integrity is `trusted = true` on those deps (or `coil.lock` native `sha256`).

Coil-to-Coil deps will be spool-owned once a public `spool` CLI exists. Until [COI-219](https://linear.app/ardax/issue/COI-219) `{ git }` parses and the pin is `coil.lock` `rev` + `content_hash`. Do not run `spool add`.

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

Clock failure is `UuidError::Time`. CSPRNG failure is `UuidError::Entropy`. Malformed input is `UuidError::Invalid`.

## Sibling checkout

Clone this private repo next to your project, coil-crypto, and coil-time. In the consumer `coil.toml`:

```toml
[module]
roots = ["./src", "../coil-uuid/src", "../coil-crypto/src", "../coil-time/src"]

[ffi]
search_paths = ["../coil-crypto/native", "../coil-time/native"]

[dependencies]
uuid = { path = "../coil-uuid" }
crypto = { path = "../coil-crypto", trusted = true }
time = { path = "../coil-time", trusted = true }
```

`[dependencies] … path` is spool metadata. The compiler does not follow path deps for discovery. `roots` is what loads `src/uuid.hy`, `src/crypto.hy`, and `src/time.hy`. Build each native library from that package root (`make`). Pass both dload grants:

```bash
coil test \
  --allow-dload crypto --allow-dload time \
  --ffi-search-path ../coil-crypto/native --ffi-search-path ../coil-time/native \
  --root ../coil-crypto/src --root ../coil-time/src
```

Then:

```coil
use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError};

let id = v7()?;
let s = id.to_string();
let again = parse("550e8400-e29b-41d4-a716-446655440000")?;
```

`parse` takes hyphenated `8-4-4-4-12` hex. `to_string` emits that form in lowercase.

## Git dep and coil.lock

`{ git }` is the parseable form. `version` is optional schema, not a tag. `rev` on the dep is stored only. Do not run `spool add`. This uuid repo is private; crypto and time are public.

```toml
[dependencies]
uuid = { git = "https://github.com/ardax-corp/coil-uuid.git" }
crypto = { git = "https://github.com/ardax-corp/coil-crypto.git", trusted = true }
time = { git = "https://github.com/ardax-corp/coil-time.git", trusted = true }

[module]
roots = ["./src", "./.spool/deps/uuid/src", "./.spool/deps/crypto/src", "./.spool/deps/time/src"]

[ffi]
search_paths = ["./.spool/deps/crypto/native", "./.spool/deps/time/native"]
```

Neither public dep has tags. The pin is `coil.lock` `rev` + `content_hash`. Omit `tag`. Use sibling checkout until spool materializes `.spool/deps`. The compiler does not read `coil.lock` for module roots and does not inject them.

```
# spool lockfile v1
[[package]]
name = 'uuid'
git = 'https://github.com/ardax-corp/coil-uuid.git'
rev = '<commit SHA>'
content_hash = '<tree SHA>'

[[package]]
name = 'crypto'
git = 'https://github.com/ardax-corp/coil-crypto.git'
rev = '9050ef96c04e05950a17b9aa4ab3d1ece58dd486'
content_hash = '1ce39b8d0b64c2b66e76034d0b6f033f7ed800c1'

[[package]]
name = 'time'
git = 'https://github.com/ardax-corp/coil-time.git'
rev = '97666a40dd5812dfbc66991793834e697bc93b5c'
content_hash = '7896c84e44db7007ca24d06b2915b41bc0478f29'
```

`rev` is the commit. `content_hash` is that commit’s git tree (`git rev-parse 'HEAD^{tree}'`). Replace both when you move the pin. Crypto values above are `main` at `9050ef9`. Time values are `main` at `97666a4`. Examples, not releases.

If you vendor those revs yourself, `.spool/deps/{uuid,crypto,time}` matches the later spool layout. `make -C .spool/deps/crypto` and `make -C .spool/deps/time` copy the `.so` into each `native/` dir.

## Call it

Signatures are in [`src/uuid.hy`](../src/uuid.hy). Call patterns are in [`tests/rfc4122.hy`](../tests/rfc4122.hy).

```coil
use uuid::{v7, parse, Uuid, UuidError};

match v7() {
    Result::Ok(u) => {
        let _ = u.version() == 7 && u.variant() == 2;
    },
    Result::Err(e) => match e {
        UuidError::Entropy => {},
        UuidError::Time => {},
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
