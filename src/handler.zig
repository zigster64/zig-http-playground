const std = @import("std");

// handle a response, using zig code to read in the file, and write the file out the socket
pub fn handle(response: *std.http.Server.Response, allocator: std.mem.Allocator, server_name: []const u8) !void {
    defer {
        // cleanup resources owned by this thread
        response.deinit();
    }

    // Whatever the request is, just send back the index.html file
    var index_file = try std.fs.cwd().openFile("index.html", .{});
    defer index_file.close();
    var stat = try index_file.stat();

    var index_file_buffer = try allocator.alloc(u8, stat.size);
    defer allocator.free(index_file_buffer);

    var file_size = try index_file.readAll(index_file_buffer);

    while (true) {
        try response.wait();
        try response.headers.append("server", server_name);

        switch (response.request.method) {
            .GET => {
                try response.headers.append("mime-type", "text/html");
                response.transfer_encoding = .{ .content_length = file_size };
                try response.do();
                try response.writeAll(index_file_buffer);
                try response.finish();
            },
            else => {
                response.status = .bad_request;
                try response.do();
            },
        }

        if (response.reset() == .closing) {
            break;
        }
    }
}

pub fn handle_pool_with_sendfile(response: *std.http.Server.Response, allocator: std.mem.Allocator, server_name: []const u8) void {
    handle(response, allocator, server_name) catch {};
}

// handle a response, but use OS sendfile to send the file
pub fn handle_with_sendfile(response: *std.http.Server.Response, allocator: std.mem.Allocator, server_name: []const u8) !void {
    _ = allocator;
    defer {
        // cleanup resources owned by this thread
        response.deinit();
    }

    // Whatever the request is, just send back the index.html file
    var index_file = try std.fs.cwd().openFile("index.html", .{});
    defer index_file.close();
    var stat = try index_file.stat();

    while (true) {
        try response.wait();
        try response.headers.append("server", server_name);

        switch (response.request.method) {
            .GET => {
                try response.headers.append("mime-type", "text/html");
                response.transfer_encoding = .{ .content_length = stat.size };
                try response.do();

                const zero_iovec = &[0]std.os.iovec_const{};
                var send_offset: usize = 0;
                while (true) {
                    const bytes_sent = try std.os.sendfile(
                        response.connection.conn.stream.handle,
                        index_file.handle,
                        send_offset,
                        stat.size,
                        zero_iovec,
                        zero_iovec,
                        0,
                    );
                    if (bytes_sent == 0)
                        break;
                    send_offset += bytes_sent;
                }
                // manually finish this one off
                response.state = .finished;
                try response.connection.flush();
            },
            else => {
                response.status = .bad_request;
                try response.do();
            },
        }

        if (response.reset() == .closing) {
            break;
        }
    }
}
