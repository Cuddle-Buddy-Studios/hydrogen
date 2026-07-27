const std = @import("std");
const zlap = @import("zlap");
const config = @import("../config.zig");

pub fn handler(subparser: *zlap.Parser) zlap.ParseError!void {
    const init = config.init;
    const io = init.io;

    const cwd = std.Io.Dir.cwd();

    const config_file = cwd.createFile(io, config.CONFIG_FILE_NAME, .{ .exclusive = true }) catch |err| {
        switch (err) {
            error.PathAlreadyExists => {
                subparser.logger.err("Config file already initialized", .{});
                return;
            },
            else => {
                subparser.logger.err("Error occured: {}", .{err});
                return;
            },
        }
    };
    defer config_file.close(io);

    const file_config = config.FileConfig.default();

    var config_writer: std.Io.Writer.Allocating = .init(subparser.allocator);
    defer config_writer.deinit();

    std.json.Stringify.value(file_config, .{
        .whitespace = .indent_4,
        .emit_null_optional_fields = true,
    }, &config_writer.writer) catch |err| {
        subparser.logger.err("Failed to write config: {}", .{err});
        return;
    };

    const bytes = config_writer.toOwnedSlice() catch |err| {
        subparser.logger.err("Failed to get bytes: {}", .{err});
        return;
    };

    var file_writer = config_file.writer(io, &.{});
    const writer = &file_writer.interface;

    _ = writer.write(bytes) catch |err| {
        subparser.logger.err("{}", .{err});
    };

    subparser.logger.success("Successfully created config", .{});
}
