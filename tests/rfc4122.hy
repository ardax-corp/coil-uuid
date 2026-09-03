// Parse round-trip and RFC 4122 v4 version / variant bits.
use uuid::{v4, parse, Uuid, UuidError};

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

test("parse round-trip canonical") {
    let s = "550e8400-e29b-41d4-a716-446655440000";
    let u = must_parse(s);
    assert(u.to_string() == s, "round-trip")?;
}

test("parse upper case") {
    let u = must_parse("550E8400-E29B-41D4-A716-446655440000");
    assert(u.to_string() == "550e8400-e29b-41d4-a716-446655440000", "lower")?;
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
    assert(u.version() == 4, "version")?;
    let s = u.to_string();
    let again = must_parse(s);
    assert(again.to_string() == s, "v4 round-trip")?;
    assert(again.version() == 4, "parsed version")?;
}

test("v4 rfc variant bits 10xx") {
    let u = must_v4();
    assert(u.variant() == 2, "variant 10")?;
    let b = u.bytes;
    assert(len(b) == 16, "16 bytes")?;
    let nibble = (b[8] as int) / 16;
    assert(nibble >= 8, "variant nibble 8-b")?;
    assert(nibble <= 11, "variant nibble not c-f")?;
}

test("eq same octets") {
    let a = must_parse("550e8400-e29b-41d4-a716-446655440000");
    let b = must_parse("550E8400-E29B-41D4-A716-446655440000");
    assert(a.bytes == b.bytes, "octets")?;
    assert(a.to_string() == b.to_string(), "hex")?;
}

test("two v4 draws differ") {
    let a = must_v4();
    let b = must_v4();
    assert(a.to_string() != b.to_string(), "distinct")?;
}
