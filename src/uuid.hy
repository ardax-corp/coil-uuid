// RFC 4122 UUID. `Uuid` is 16 bytes (`int` is i64 — never one 128-bit int).
// v4 entropy is `crypto::random_bytes` (CSPRNG). Hex format is 8-4-4-4-12.

use crypto::{random_bytes};
use string::{from_bytes, to_bytes};

/// Parse / entropy failure.
enum UuidError {
    Invalid,
    Entropy,
}

/// 16-octet RFC 4122 UUID. Field is `pub` so `#[derive(Eq)]` can compare it
/// (`Hash` is not derived: prelude `Hash` covers primitives, not `Vec<byte>`).
#[derive(Eq)]
class Uuid {
    pub bytes: Vec<byte>,
}

fn hex_val(byte c) -> int {
    let zero: int = "0" as byte as int;
    let nine: int = "9" as byte as int;
    let la: int = "a" as byte as int;
    let lf: int = "f" as byte as int;
    let ua: int = "A" as byte as int;
    let uf: int = "F" as byte as int;
    let code: int = c as int;
    if code >= zero && code <= nine {
        return code - zero;
    }
    if code >= la && code <= lf {
        return code - la + 10;
    }
    if code >= ua && code <= uf {
        return code - ua + 10;
    }
    return 0 - 1;
}

fn hex_digit(int n) -> byte {
    let zero: int = "0" as byte as int;
    let a: int = "a" as byte as int;
    if n < 10 {
        let code: int = zero + n;
        return code as byte;
    }
    let code: int = a + (n - 10);
    return code as byte;
}

fn push_hex(Vec<byte> out, byte b) {
    let v: int = b as int;
    out.push(hex_digit(v / 16));
    out.push(hex_digit(v % 16));
}

fn copy16(Vec<byte> src) -> Vec<byte> {
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < 16 {
        out.push(src[i]);
        i = i + 1;
    }
    return out;
}

fn take16(Vec<byte> src) -> Result<Uuid, UuidError> {
    if len(src) != 16 {
        raise UuidError::Invalid;
    }
    return new Uuid(copy16(src));
}

fn set_rfc_bits(Vec<byte> b, int version) {
    let v: int = b[6] as int;
    let nv: int = (v & 15) | (version * 16);
    b[6] = nv as byte;
    let c: int = b[8] as int;
    let nc: int = (c & 63) | 128;
    b[8] = nc as byte;
}

fn parse_hyphenated(Vec<byte> raw) -> Result<Uuid, UuidError> {
    if len(raw) != 36 {
        raise UuidError::Invalid;
    }
    if raw[8] != "-" || raw[13] != "-" || raw[18] != "-" || raw[23] != "-" {
        raise UuidError::Invalid;
    }
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < 36 {
        if i == 8 || i == 13 || i == 18 || i == 23 {
            i = i + 1;
        } else {
            if i + 1 >= 36 {
                raise UuidError::Invalid;
            }
            let hi: int = hex_val(raw[i]);
            let lo: int = hex_val(raw[i + 1]);
            if hi < 0 {
                raise UuidError::Invalid;
            }
            if lo < 0 {
                raise UuidError::Invalid;
            }
            let packed: int = (hi * 16) + lo;
            out.push(packed as byte);
            i = i + 2;
        }
    }
    return take16(out)?;
}

/// RFC 4122 version-4 UUID (random). Entropy is `crypto::random_bytes`.
fn v4() -> Result<Uuid, UuidError> {
    let raw = match random_bytes(16) {
        Result::Ok(b) => b,
        Result::Err(_) => raise UuidError::Entropy,
    };
    if len(raw) != 16 {
        raise UuidError::Entropy;
    }
    let b = copy16(raw);
    set_rfc_bits(b, 4);
    return new Uuid(b);
}

/// Parse `8-4-4-4-12` hex (hyphens required). Case-insensitive.
fn parse(string s) -> Result<Uuid, UuidError> {
    return parse_hyphenated(to_bytes(s))?;
}

impl Uuid {
    /// Canonical lowercase `8-4-4-4-12` hex. Not `Show` (scalar enums print ints).
    pub fn to_string() -> string {
        let out: Vec<byte> = Vec::new();
        let i = 0;
        while i < 16 {
            if i == 4 || i == 6 || i == 8 || i == 10 {
                out.push("-" as byte);
            }
            push_hex(out, self.bytes[i]);
            i = i + 1;
        }
        return match from_bytes(out) {
            Result::Ok(s) => s,
            Result::Err(_) => "",
        };
    }

    /// RFC 4122 version nibble (high nibble of octet 6).
    pub fn version() -> int {
        let v: int = self.bytes[6] as int;
        return v / 16;
    }

    /// High two bits of octet 8 (`2` is RFC 4122 variant `10xx`).
    pub fn variant() -> int {
        let v: int = self.bytes[8] as int;
        return v / 64;
    }
}
