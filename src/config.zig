const std = @import("std");
const dotenv = @import("dotenv");

pub const CONFIG_FILE_NAME = "hydrogen.json";
const ENV_KEYS = enum { HYDROGEN_API_KEY };

pub var init: std.process.Init = undefined;
pub var config: Config = undefined;

pub const FileConfig = struct {
    UniverseId: ?u64,
    PublisherId: ?u64,
    PublisherType: ?enum { Group, User },
    ProductsInputPath: ?[]const u8,
    ProductsOutputPath: ?[]const u8,
    AssetsInputPath: ?[]const u8,
    AssetsOutputPath: ?[]const u8,

    pub fn default() FileConfig {
        return .{
            .UniverseId = 0,
            .PublisherId = 0,
            .PublisherType = .User,
            .ProductsInputPath = "",
            .ProductsOutputPath = "",
            .AssetsInputPath = "",
            .AssetsOutputPath = "",
        };
    }
};

pub const Config = struct {
    File: FileConfig,
    ApiKey: []const u8,
};

pub fn load(process_init: std.process.Init) !void {
    init = process_init;

    var env_manager = dotenv.init(init, ENV_KEYS);
    defer env_manager.deinit();

    try env_manager.loadCurrentProcessEnvs();

    const file_config = loadConfig() catch FileConfig.default();
    const api_key = env_manager.key(.HYDROGEN_API_KEY);

    config = Config{
        .File = file_config,
        .ApiKey = api_key,
    };
}

fn loadConfig() !FileConfig {
    const io = init.io;
    const allocator = init.arena.allocator();

    const cwd = std.Io.Dir.cwd();
    const config_file = try cwd.openFile(io, CONFIG_FILE_NAME, .{ .mode = .read_only });
    defer config_file.close(io);

    var read_buf: [4096]u8 = undefined;
    var file_reader = config_file.reader(io, &read_buf);
    const interface = &file_reader.interface;

    const bytes = try interface.allocRemaining(allocator, .unlimited);

    const parsed = try std.json.parseFromSlice(FileConfig, allocator, bytes, .{});
    defer parsed.deinit();

    return parsed.value;
}
