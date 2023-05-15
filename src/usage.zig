const std = @import("std");

pub fn print() void {
    std.debug.print("USAGE: zig-http-playground THREADMODE FILEMODE PORT\n", .{});
    std.debug.print("  THREADMODE = one of [singlethread, threadmadness, threadpool2, threadpoolmax]\n", .{});
    std.debug.print("  FILEMODE = one of [code, os]\n", .{});
    std.debug.print("  PORT = Port number to run it on (ie - 8080)\n", .{});
}
