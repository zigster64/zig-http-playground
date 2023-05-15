const std = @import("std");
const enums = @import("enums.zig");
const handler = @import("handler.zig");

pub fn run(port: u16, file_mode: enums.FileModes) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var server = std.http.Server.init(allocator, .{ .reuse_address = true, .kernel_backlog = 64 });
    defer server.deinit();

    var listen_address = try std.net.Address.resolveIp("0.0.0.0", port);
    try server.listen(listen_address);

    while (true) {
        var res = try server.accept(.{ .allocator = allocator });
        switch (file_mode) {
            .code => {
                handler.handle(&res, allocator, "SingleTreaded Server using Zig file IO") catch {};
            },
            .os => {
                handler.handle_with_sendfile(&res, allocator, "SingleThreaded Server using OS sendfile IO") catch {};
            },
        }
    }
}
