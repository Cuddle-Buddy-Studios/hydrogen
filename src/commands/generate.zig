const std = @import("std");
const zlap = @import("zlap");
const products = @import("../products.zig");
const codegen = @import("../codegen.zig");
const config = @import("../config.zig");

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

    // raw products file
    const products_file = products.loadProducts(io, allocator, product_path.?) catch |err| {
        subparser.logger.err("Something went wrong while getting products\n{any}", .{err});
        return;
    };
    const defined_products = products_file.products;

    codegen.generateCodeFromInput(io, allocator, config.config.File.ProductsOutputPath.?, defined_products) catch |err| {
        subparser.logger.err("Failed to generate code: {any}", .{err});
        return;
    };

    subparser.logger.success("Successfully generated code", .{});
}
