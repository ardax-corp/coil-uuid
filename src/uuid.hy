// RFC 4122 / RFC 9562 UUID. `Uuid` is 16 bytes (`int` is i64 — never one 128-bit int).
// Entropy is `crypto::random_bytes`. Time is coil-time `timestamp()`. Hex is 8-4-4-4-12.

use crypto::{random_bytes, CryptoError};
use string::{from_bytes, to_bytes};
use time::{timestamp, Timestamp, TimeError};

/// Parse, entropy, or clock failure.
enum UuidError {
    /// Not a hyphenated `8-4-4-4-12` UUID.
    Invalid,
    /// The CSPRNG failed (or returned too few bytes: `CryptoError::InvalidLength`).
    Entropy(CryptoError),
    /// The clock failed.
    Time(TimeError),
}

fn gregorian_offset() -> int {
    return 122192928000000000;
}

static let v1_ready = 0;
static let clock_seq = 0;
static let node0 = 0;
static let node1 = 0;
static let node2 = 0;
static let node3 = 0;
static let node4 = 0;
static let node5 = 0;

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
    if src.len() != 16 {
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

fn entropy(int n) -> Result<Vec<byte>, UuidError> {
    let raw = match random_bytes(n) {
        Result::Ok(b) => b,
        Result::Err(e) => raise UuidError::Entropy(e),
    };
    if raw.len() != n {
        raise UuidError::Entropy(CryptoError::InvalidLength);
    }
    return raw;
}

fn now_ts() -> Result<Timestamp, UuidError> {
    return match timestamp() {
        Result::Ok(t) => t,
        Result::Err(e) => raise UuidError::Time(e),
    };
}

fn set_be(Vec<byte> b, int off, int value, int n) {
    let i = 0;
    while i < n {
        let shift: int = (n - 1 - i) * 8;
        let v: int = (value >> shift) & 255;
        b[off + i] = v as byte;
        i = i + 1;
    }
}

fn zeros16() -> Vec<byte> {
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < 16 {
        out.push(0 as byte);
        i = i + 1;
    }
    return out;
}

fn gregorian_100ns(Timestamp ts) -> int {
    return (ts.nanos() / 100) + gregorian_offset();
}

fn ensure_v1_node() -> Result<(), UuidError> {
    if v1_ready != 0 {
        return ();
    }
    let raw = entropy(8)?;
    let first: int = raw[0] as int;
    node0 = first | 1;
    node1 = raw[1] as int;
    node2 = raw[2] as int;
    node3 = raw[3] as int;
    node4 = raw[4] as int;
    node5 = raw[5] as int;
    let hi: int = raw[6] as int;
    let lo: int = raw[7] as int;
    clock_seq = ((hi * 256) + lo) & 16383;
    v1_ready = 1;
    return ();
}

fn fill_clock_node(Vec<byte> b) {
    set_be(b, 8, clock_seq, 2);
    b[10] = node0 as byte;
    b[11] = node1 as byte;
    b[12] = node2 as byte;
    b[13] = node3 as byte;
    b[14] = node4 as byte;
    b[15] = node5 as byte;
}

fn parse_hyphenated(Vec<byte> raw) -> Result<Uuid, UuidError> {
    if raw.len() != 36 {
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
    let raw = entropy(16)?;
    let b = copy16(raw);
    set_rfc_bits(b, 4);
    return new Uuid(b);
}

/// RFC 4122 version-1 UUID (Gregorian 100ns + clock seq + 48-bit node).
/// Node is 6 random bytes with the multicast bit set (not a host MAC).
fn v1() -> Result<Uuid, UuidError> {
    ensure_v1_node()?;
    let ts = now_ts()?;
    let ticks: int = gregorian_100ns(ts);
    let time_low: int = ticks & 4294967295;
    let time_mid: int = (ticks >> 32) & 65535;
    let time_hi: int = (ticks >> 48) & 4095;
    let b = zeros16();
    set_be(b, 0, time_low, 4);
    set_be(b, 4, time_mid, 2);
    set_be(b, 6, time_hi, 2);
    fill_clock_node(b);
    set_rfc_bits(b, 1);
    return new Uuid(b);
}

/// RFC 9562 version-6 UUID (time-reordered v1). Shares v1 clock seq and node.
fn v6() -> Result<Uuid, UuidError> {
    ensure_v1_node()?;
    let ts = now_ts()?;
    let ticks: int = gregorian_100ns(ts);
    let time_high: int = ticks >> 28;
    let time_mid: int = (ticks >> 12) & 65535;
    let time_low: int = ticks & 4095;
    let b = zeros16();
    set_be(b, 0, time_high, 4);
    set_be(b, 4, time_mid, 2);
    set_be(b, 6, time_low, 2);
    fill_clock_node(b);
    set_rfc_bits(b, 6);
    return new Uuid(b);
}

/// RFC 9562 version-7 UUID (unix milliseconds + random).
fn v7() -> Result<Uuid, UuidError> {
    let ts = now_ts()?;
    let ms: int = ts.millis();
    let raw = entropy(16)?;
    let b = copy16(raw);
    set_be(b, 0, ms, 6);
    set_rfc_bits(b, 7);
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
