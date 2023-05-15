// This file is called thread_madness for a reason
// Its only there to deliberate overload the server, and find out where it breaks in different scenarios
// DO NOT use this as a model for your shiny new Zig web framework !!

const std = @import("std");
const enums = @import("enums.zig");
const handler = @import("handler.zig");

pub fn run(file_mode: enums.FileModes, port: u16) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var server = std.http.Server.init(allocator, .{ .reuse_address = true, .kernel_backlog = 64 });
    defer server.deinit();

    var listen_address = try std.net.Address.resolveIp("0.0.0.0", port);
    try server.listen(listen_address);

    while (true) {
        const res = try server.accept(.{ .allocator = allocator });
        // in thread madness mode, spawn a whole new thread for every single connection !!
        // This unconstrained threading will quickly bring the machine to its knees when it gets a tonne of requests

        // make a copy of the response just in case its external lifecycle is on the stack and gets colbbered each accept
        var response_clone = try allocator.create(std.http.Server.Response);
        _ = response_clone;
        switch (file_mode) {
            .code => {
                spawn_thread(handler.handle, res, allocator, "Thread Madness with Zig file IO") catch |err| std.debug.print("handler failed with {}\n", .{err});
            },
            .os => {
                spawn_thread(handler.handle_with_sendfile, res, allocator, "Thread Madness with OS sendfile IO") catch |err| std.debug.print("handler failed with {}\n", .{err});
            },
        }
    }
}

fn thread_wrapper(comptime func: anytype, res: *std.http.Server.Response, allocator: std.mem.Allocator, server_name: []const u8) !void {
    defer allocator.destroy(res);
    return @call(.auto, func, .{ res, allocator, server_name });
}

fn spawn_thread(comptime func: anytype, res: std.http.Server.Response, allocator: std.mem.Allocator, server_name: []const u8) !void {
    // make a copy of the response just in case its external lifecycle is on the stack and gets colbbered each accept
    var response_clone = try allocator.create(std.http.Server.Response);
    response_clone.* = res;
    const t = try std.Thread.spawn(.{}, thread_wrapper, .{ func, response_clone, allocator, server_name });
    t.detach();
}
