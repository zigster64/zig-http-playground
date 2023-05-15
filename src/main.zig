const std = @import("std");
const usage = @import("usage.zig").print;
const enums = @import("enums.zig");

const singleThreadedServer = @import("single_thread.zig");
const threadPerConnectionServer = @import("thread_madness.zig");
const threadPoolServer = @import("thread_pool.zig");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"std.http.Server"});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 4) return usage();

    const port = try std.fmt.parseInt(u16, args[3], 10);

    var thread_mode = std.meta.stringToEnum(enums.ThreadModes, args[1]) orelse return usage();
    var file_mode = std.meta.stringToEnum(enums.FileModes, args[2]) orelse return usage();

    switch (thread_mode) {
        .singlethread => {
            std.debug.print("Singlethread mode\n", .{});
            try singleThreadedServer.run(port, file_mode);
        },
        .threadperconnection => {
            std.debug.print("Spawn a new thread per new connection, should go real quick, then die in a meltdown\n", .{});
            try threadPerConnectionServer.run(file_mode, port);
        },
        .threadpool2 => {
            std.debug.print("Use a pair of threadpools - should be less throughput than singlethread, but better concurrency\n", .{});
            try threadPoolServer.run(2, file_mode, port);
        },
        .threadpoolmax => {
            std.debug.print("Use a pool of as many threads as there are CPU cores - should be bit quicker than 2 threads, with much better concurrency\n", .{});
            try threadPoolServer.run(try std.Thread.getCpuCount(), file_mode, port);
        },
    }
    std.debug.print("Serving files on port {}\n", .{port});
}
