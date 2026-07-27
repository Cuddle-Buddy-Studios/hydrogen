const std = @import("std");
const zlap = @import("zlap");
const config = @import("config.zig");

// SubCommands
const init_cmd = @import("commands/init.zig");

// Main handler
fn handler(subparser: *zlap.Parser) zlap.ParseError!void {
    subparser.printHelp();
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    // load vars
    try config.load(init);

    // CLI STUFF
    // Initialize logger
    var logger = zlap.Logger{};

    // Create parser
    var parser = zlap.Parser.init(allocator, "hydrogen", "A minimal asset uploader", &logger);
    defer parser.deinit();

    {
        // init sub command
        _ = try parser.subCommand(
            "init",
            "initialize the toml",
            init_cmd.handler,
        );
    }

    _ = parser.setHandler(handler);

    const args = try init.minimal.args.toSlice(allocator);

    try parser.parse(args);
    try parser.execute();
}
