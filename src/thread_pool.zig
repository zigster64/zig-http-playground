const std = @import("std");
const enums = @import("enums.zig");
const handler = @import("handler.zig");

pub fn run(thread_count: usize, file_mode: enums.FileModes, port: u16) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var server = std.http.Server.init(allocator, .{ .reuse_address = true, .kernel_backlog = 64 });
    defer server.deinit();

    var listen_address = try std.net.Address.resolveIp("0.0.0.0", port);
    try server.listen(listen_address);

    var thread_pool: std.Thread.Pool = undefined;
    var pool = &thread_pool;
    try std.Thread.Pool.init(pool, .{ .allocator = allocator, .n_jobs = @intCast(u32, thread_count) });

    while (true) {
        const res = try server.accept(.{ .allocator = allocator });

        switch (file_mode) {
            .code => {
                spawn_pool(pool, handler.handle, res, allocator, "Thread Pool with Zig file IO") catch |err| std.debug.print("handler failed with {}\n", .{err});
            },
            .os => {
                spawn_pool(pool, handler.handle_with_sendfile, res, allocator, "Thread Pool with OS Sendfile IO") catch |err| std.debug.print("handler failed with {}\n", .{err});
            },
        }
    }
}

fn pool_wrapper(comptime func: anytype, res: *std.http.Server.Response, allocator: std.mem.Allocator, server_name: []const u8) void {
    defer allocator.destroy(res);
    @call(.auto, func, .{ res, allocator, server_name }) catch {};
}

fn spawn_pool(pool: *std.Thread.Pool, comptime func: anytype, res: std.http.Server.Response, allocator: std.mem.Allocator, server_name: []const u8) !void {
    // make a copy of the response just in case its external lifecycle is on the stack and gets colbbered each accept
    var response_clone = try allocator.create(std.http.Server.Response);
    response_clone.* = res;
    try pool.spawn(pool_wrapper, .{ func, response_clone, allocator, server_name });
}
