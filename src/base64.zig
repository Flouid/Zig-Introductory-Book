const std = @import("std");

pub fn encode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    if (input.len == 0) return "";
    const len_out = try calcEncodeLength(input);
    var out = try allocator.alloc(u8, len_out);
    var buf = [3]u8{ 0, 0, 0 };
    var i_buf: u8 = 0;
    var i_out: usize = 0;

    for (input, 0..) |_, i| {
        buf[i_buf] = input[i];
        i_buf += 1;
        if (i_buf == 3) {
            out[i_out] = try indexToChar(buf[0] >> 2);
            out[i_out + 1] = try indexToChar(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
            out[i_out + 2] = try indexToChar(((buf[1] & 0x0f) << 2) + (buf[2] >> 6));
            out[i_out + 3] = try indexToChar(((buf[2] & 0x3f)));
            i_out += 4;
            i_buf = 0;
        }
    }
    if (i_buf == 1) {
        out[i_out] = try indexToChar(buf[0] >> 2);
        out[i_out + 1] = try indexToChar((buf[0] & 0x03) << 4);
        out[i_out + 2] = '=';
        out[i_out + 3] = '=';
    }
    if (i_buf == 2) {
        out[i_out] = try indexToChar(buf[0] >> 2);
        out[i_out + 1] = try indexToChar(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
        out[i_out + 2] = try indexToChar((buf[1] & 0x0f) << 2);
        out[i_out + 3] = '=';
    }
    return out;
}

pub fn decode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    if (input.len == 0) return "";
    const len_out = try calcDecodeLength(input);
    var out = try allocator.alloc(u8, len_out);
    var buf = [4]u8{ 0, 0, 0, 0 };
    var i_buf: u8 = 0;
    var i_out: usize = 0;

    for (0..input.len) |i| {
        buf[i_buf] = try charToIndex(input[i]);
        i_buf += 1;
        if (i_buf == 4) {
            out[i_out] = (buf[0] << 2) + (buf[1] >> 4);
            if (buf[2] == 64) break;
            out[i_out + 1] = (buf[1] << 4) + (buf[2] >> 2);
            if (buf[3] == 64) break;
            out[i_out + 2] = (buf[2] << 6) + buf[3];
            i_out += 3;
            i_buf = 0;
        }
    }
    return out;
}

fn calcEncodeLength(input: []const u8) !usize {
    if (input.len < 3) return 4;
    const n_groups: usize = try std.math.divCeil(usize, input.len, 3);
    return 4 * n_groups;
}

fn calcDecodeLength(input: []const u8) !usize {
    if (input.len < 4) return 3;
    const n_groups: usize = try std.math.divFloor(usize, input.len, 4);
    var n_chars = 3 * n_groups;
    var i: usize = input.len - 1;
    while (i > 0 and input[i] == '=') : (i -= 1) n_chars -= 1;
    return n_chars;
}

fn indexToChar(index: u8) error{IndexTooLarge}!u8 {
    return switch (index) {
        0...25 => 'A' + index,
        26...51 => 'a' + index - 26,
        52...61 => '0' + index - 52,
        62 => '+',
        63 => '/',
        else => error.IndexTooLarge,
    };
}

fn charToIndex(char: u8) error{InvalidCharacter}!u8 {
    return switch (char) {
        'A'...'Z' => char - 'A',
        'a'...'z' => char - 'a' + 26,
        '0'...'9' => char - '0' + 52,
        '+' => 62,
        '/' => 63,
        '=' => 64,
        else => error.InvalidCharacter,
    };
}

test "encode" {
    const alloc = std.testing.allocator;
    const input = "the quick brown fox jumps over the lazy dog.";
    const output = "dGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4=";
    const encoded = try encode(alloc, input);
    defer alloc.free(encoded);
    try std.testing.expect(std.mem.eql(u8, encoded, output));
}

test "decode" {
    const alloc = std.testing.allocator;
    const input = "the quick brown fox jumps over the lazy dog.";
    const output = "dGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4=";
    const decoded = try decode(alloc, output);
    defer alloc.free(decoded);
    try std.testing.expect(std.mem.eql(u8, decoded, input));
}