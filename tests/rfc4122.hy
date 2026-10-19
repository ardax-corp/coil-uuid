// Parse round-trip and RFC 4122 / 9562 version / variant bits.
use tests::assert;
use uuid::{v1, v4, v6, v7, parse, Uuid, UuidError};
use time::{sleep_ms};

fn must_parse(string s) -> Uuid {
    return match parse(s) {
        Result::Ok(u) => u,
        Result::Err(_) => panic "parse failed",
    };
}

fn must_v4() -> Uuid {
    return match v4() {
        Result::Ok(u) => u,
        Result::Err(_) => panic "v4 failed",
    };
}

fn must_v1() -> Uuid {
    return match v1() {
        Result::Ok(u) => u,
        Result::Err(_) => panic "v1 failed",
    };
}

fn must_v6() -> Uuid {
    return match v6() {
        Result::Ok(u) => u,
        Result::Err(_) => panic "v6 failed",
    };
}

fn must_v7() -> Uuid {
    return match v7() {
        Result::Ok(u) => u,
        Result::Err(_) => panic "v7 failed",
    };
}

fn unix_ms48(Uuid u) -> int {
    let b = u.bytes;
    let v = 0;
    let i = 0;
    while i < 6 {
        v = (v * 256) + (b[i] as int);
        i = i + 1;
    }
    return v;
}

test("parse round-trip canonical") {
    let s = "550e8400-e29b-41d4-a716-446655440000";
    let u = must_parse(s);
    assert!(u.to_string() == s, "round-trip");
}

test("parse upper case") {
    let u = must_parse("550E8400-E29B-41D4-A716-446655440000");
    assert!(u.to_string() == "550e8400-e29b-41d4-a716-446655440000", "lower");
}

test("parse rejects short") {
    match parse("550e8400") {
        Result::Ok(_) => panic "expected Invalid",
        Result::Err(e) => match e {
            UuidError::Invalid => {},
            default => panic "wrong error",
        },
    };
}

test("parse rejects missing hyphens") {
    match parse("550e8400e29b41d4a716446655440000") {
        Result::Ok(_) => panic "expected Invalid",
        Result::Err(e) => match e {
            UuidError::Invalid => {},
            default => panic "wrong error",
        },
    };
}

test("parse rejects bad hex") {
    match parse("550e8400-e29b-41d4-a716-44665544000g") {
        Result::Ok(_) => panic "expected Invalid",
        Result::Err(e) => match e {
            UuidError::Invalid => {},
            default => panic "wrong error",
        },
    };
}

test("v4 version nibble is 4") {
    let u = must_v4();
    assert!(u.version() == 4, "version");
    let s = u.to_string();
    let again = must_parse(s);
    assert!(again.to_string() == s, "v4 round-trip");
    assert!(again.version() == 4, "parsed version");
}

test("v4 rfc variant bits 10xx") {
    let u = must_v4();
    assert!(u.variant() == 2, "variant 10");
    let b = u.bytes;
    assert!(b.len() == 16, "16 bytes");
    let nibble = (b[8] as int) / 16;
    assert!(nibble >= 8, "variant nibble 8-b");
    assert!(nibble <= 11, "variant nibble not c-f");
}

test("eq same octets") {
    let a = must_parse("550e8400-e29b-41d4-a716-446655440000");
    let b = must_parse("550E8400-E29B-41D4-A716-446655440000");
    assert!(a.bytes == b.bytes, "octets");
    assert!(a.to_string() == b.to_string(), "hex");
}

test("two v4 draws differ") {
    let a = must_v4();
    let b = must_v4();
    assert!(a.to_string() != b.to_string(), "distinct");
}

test("v1 version nibble and variant") {
    let u = must_v1();
    assert!(u.version() == 1, "version");
    assert!(u.variant() == 2, "variant 10");
    let s = u.to_string();
    let again = must_parse(s);
    assert!(again.to_string() == s, "v1 round-trip");
    let node0: int = u.bytes[10] as int;
    assert!((node0 & 1) == 1, "multicast node");
}

test("v6 version nibble and variant") {
    let u = must_v6();
    assert!(u.version() == 6, "version");
    assert!(u.variant() == 2, "variant 10");
    let s = u.to_string();
    let again = must_parse(s);
    assert!(again.to_string() == s, "v6 round-trip");
}

test("v1 and v6 share clock seq and node") {
    let a = must_v1();
    let b = must_v6();
    let i = 8;
    while i < 16 {
        assert!(a.bytes[i] == b.bytes[i], "shared clock/node");
        i = i + 1;
    }
}

test("v7 version nibble and variant") {
    let u = must_v7();
    assert!(u.version() == 7, "version");
    assert!(u.variant() == 2, "variant 10");
    let s = u.to_string();
    let again = must_parse(s);
    assert!(again.to_string() == s, "v7 round-trip");
}

test("v7 unix ms not decreasing across sleep_ms") {
    let a = must_v7();
    match sleep_ms(5) {
        Result::Ok(_) => {},
        Result::Err(_) => panic "sleep_ms failed",
    };
    let b = must_v7();
    let t0 = unix_ms48(a);
    let t1 = unix_ms48(b);
    assert!(t1 >= t0, "v7 time not decreasing");
}
