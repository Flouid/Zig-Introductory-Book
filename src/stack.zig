const std = @import("std");

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,
        capacity: usize,
        length: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, capacity: usize) error{OutOfMemory}!Stack(T) {
            var buffer = try allocator.alloc(T, capacity);
            return .{
                .items = buffer[0..],
                .capacity = capacity,
                .length = 0,
                .allocator = allocator
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        pub fn push(self: *Self, item: T) error{OutOfMemory}!void {
            if (self.length + 1 > self.capacity) {
                var new_buf = try self.allocator.alloc(T, 2 * self.capacity);
                @memcpy(new_buf[0..self.capacity], self.items);
                self.allocator.free(self.items);
                self.items = new_buf;
                self.capacity *= 2;
            }

            self.items[self.length] = item;
            self.length += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.length == 0) return null;

            const item: T = self.items[self.length - 1];
            self.items[self.length - 1] = undefined;
            self.length -= 1;
            return item;
        }
    };
}

test "stack push/pop" {
    const allocator = std.testing.allocator;
    var stack = try Stack(u8).init(allocator, 1);
    defer stack.deinit();
    const items = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    for (items) |item| {
        try stack.push(item);
    }
    try std.testing.expect(stack.length == 10);
    try std.testing.expect(stack.capacity == 16);
    for (0..10) |i| {
        try std.testing.expect(9 - i == stack.pop().?);
    }
    try std.testing.expect(stack.pop() == null);
}