# Consuming coil-uuid

This package is `uuid`. `use uuid::{v4, parse, Uuid, UuidError}` resolves from `src/uuid.hy`. This GitHub repository is **private**; clone with credentials that can read `ardax-corp/coil-uuid`.

v4 calls public [coil-crypto](https://github.com/ardax-corp/coil-crypto) `random_bytes`. That is a CSPRNG. The compiler does not follow path deps: `roots` / `--root` must include crypto `src/` so `use crypto` resolves. Typecheck grant is CLI `--allow-dload crypto`. Do not treat `[ffi] allow` as a compiler grant (crypto’s own toml may still list `allow = ["crypto"]` — that is stale). `[ffi] search_paths` locates `libcrypto.so` / `.dylib` / `crypto.dll`. Runtime integrity is `trusted = true` on the crypto dep (or a `coil.lock` native `sha256`).

Coil-to-Coil deps will be spool-owned once a public `spool` CLI exists. Until [COI-219](https://linear.app/ardax/issue/COI-219) `{ git }` parses and the pin is `coil.lock` `rev` + `content_hash`. Do not run `spool add`.

## Sibling checkout

Clone this private repo next to your project and next to coil-crypto. In the consumer `coil.toml`:

```toml
[module]
roots = ["./src", "../coil-uuid/src", "../coil-crypto/src"]

[ffi]
search_paths = ["../coil-crypto/native"]

[dependencies]
uuid = { path = "../coil-uuid" }
crypto = { path = "../coil-crypto", trusted = true }
```

`[dependencies] … path` is spool metadata. The compiler does not follow path deps for discovery. `roots` is what loads `src/uuid.hy` and `src/crypto.hy`. Build crypto’s native library from that package root (`make`), so `libcrypto.so` sits on `[ffi] search_paths`. Pass `--allow-dload crypto` on typecheck and test:

```bash
coil test --allow-dload crypto --ffi-search-path ../coil-crypto/native --root ../coil-crypto/src
```

Then:

```coil
use uuid::{v4, parse, Uuid, UuidError};

let id = v4()?;
let s = id.to_string();
let again = parse("550e8400-e29b-41d4-a716-446655440000")?;
```

`parse` takes hyphenated `8-4-4-4-12` hex. `to_string` emits that form in lowercase. `v4` is `Result<Uuid, UuidError>` because CSPRNG can fail (`UuidError::Entropy`). Malformed input is `UuidError::Invalid`.

## Git dep and coil.lock

`{ git }` is the parseable form. `version` is optional schema, not a tag. `rev` on the dep is stored only. Do not run `spool add`. This uuid repo is private; crypto is public.

```toml
[dependencies]
uuid = { git = "https://github.com/ardax-corp/coil-uuid.git" }
crypto = { git = "https://github.com/ardax-corp/coil-crypto.git", trusted = true }

[module]
roots = ["./src", "./.spool/deps/uuid/src", "./.spool/deps/crypto/src"]

[ffi]
search_paths = ["./.spool/deps/crypto/native"]
```

Neither repo has tags. The pin is `coil.lock` `rev` + `content_hash`. Omit `tag`. Use sibling checkout until spool materializes `.spool/deps`. The compiler does not read `coil.lock` for module roots and does not inject them.

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
```

`rev` is the commit. `content_hash` is that commit’s git tree (`git rev-parse 'HEAD^{tree}'`). Replace both when you move the pin. Crypto values above are `main` at `9050ef9` (example, not a release).

If you vendor those revs yourself, `.spool/deps/{uuid,crypto}` matches the later spool layout. `make -C .spool/deps/crypto` copies `libcrypto.so` into that `native/` dir.

## Call it

Signatures are in [`src/uuid.hy`](../src/uuid.hy). Call patterns are in [`tests/rfc4122.hy`](../tests/rfc4122.hy).

```coil
use uuid::{v4, parse, Uuid, UuidError};

match v4() {
    Result::Ok(u) => {
        let _ = u.version() == 4 && u.variant() == 2;
    },
    Result::Err(e) => match e {
        UuidError::Entropy => {},
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

v7 is not shipped (coil-time native `dload` next to crypto). v1/v5 are not shipped.
