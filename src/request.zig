const std = @import("std");

const Map = std.static_string_map.StaticStringMap;
const MethodMap = Map(Method).initComptime(.{
    .{ "GET", Method.GET },
});

pub const Method = enum {
    GET,

    pub fn init(text: []const u8) !Method {
        return MethodMap.get(text).?;
    }
};

pub const Request = struct {
    method: Method,
    version: []const u8,
    uri: []const u8,
};

pub fn read_request(conn: std.net.Server.Connection, buffer: []u8) !void {
    _ = try conn.stream.read(buffer);
}

pub fn parse_request(text: []const u8) Request {
    const line_end = std.mem.indexOfScalar(u8, text, '\n') orelse text.len;
    var it = std.mem.splitScalar(u8, text[0..line_end], ' ');
    const method = try Method.init(it.next().?);
    const uri = it.next().?;
    const version = it.next().?;
    return .{ .method = method, .uri = uri, .version = version };
}