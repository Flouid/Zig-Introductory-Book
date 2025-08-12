const std = @import("std");
const skt = @import("socket.zig");
const req = @import("request.zig");
const res = @import("response.zig");

pub fn main() !void {
    const socket = try skt.Socket.init();
    var server = try socket.address.listen(.{});
    const connection = try server.accept();
    var buffer = [_]u8{0} ** 1000;
    try req.read_request(connection, buffer[0..]);
    const request = req.parse_request(buffer[0..]);
    if (std.mem.eql(u8, request.uri, "/")) {
        try res.send_200(connection);
    } else try res.send_404(connection);
}