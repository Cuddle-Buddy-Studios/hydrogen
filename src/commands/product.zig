const std = @import("std");
const zlap = @import("zlap");
const config = @import("../config.zig");
const products = @import("../products.zig");
const roblox = @import("../roblox.zig");

pub fn handler(subparser: *zlap.Parser) zlap.ParseError!void {
    const init = config.init;
    const io = init.io;
    const allocator = subparser.allocator;

    const api_key = config.config.ApiKey;
    const universe_id = config.config.File.UniverseId;

    // check for empty api key string
    if (std.mem.eql(u8, api_key, "")) {
        subparser.logger.err("Api-Key not set\n{any}", .{api_key});
        return;
    }

    if (universe_id.? <= 0) {
        subparser.logger.err("Invalid UniverseId: {any}", .{universe_id});
        return;
    }

    const product_path = config.config.File.ProductsInputPath;
    if (product_path == null) {
        subparser.logger.err("ProductsInputPath not set in config", .{});
        return;
    }

    const defined_products = products.loadProducts(io, allocator, product_path.?) catch |err| {
        subparser.logger.err("Something went wrong while getting products\n{any}", .{err});
        return;
    };

    var created_count: i64 = 0;
    for (defined_products) |product| {
        // TODO: create lockfile from the details
        _ = roblox.createDeveloperProduct(allocator, universe_id.?, product, api_key) catch continue;
        created_count += 1;
    }

    if (created_count == 0) {
        subparser.logger.err("No products were created", .{});
        return;
    }

    subparser.logger.success("Successfully created {any} product(s)", .{created_count});
}
