const std = @import("std");
const zlap = @import("zlap");
const config = @import("../config.zig");
const products = @import("../products.zig");
const roblox = @import("../roblox.zig");
const codegen = @import("../codegen.zig");

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
    const defined_defaults = products_file.defaults;

    // merged defaults
    var merged_products: std.ArrayList(products.DeveloperProductDetails) = try .initCapacity(allocator, defined_products.len);

    for (defined_products) |product| {
        const merged = products.mergeDefaults(allocator, product, defined_defaults) catch |err| {
            subparser.logger.err("Could not merge due to error: {any}", .{err});
            continue;
        };
        _ = merged_products.append(allocator, merged) catch |err| {
            subparser.logger.err("Could not append due to error: {any}", .{err});
            continue;
        };
    }

    products.validateProducts(allocator, merged_products.items) catch |err| {
        subparser.logger.err("Product validity failed: {any}", .{err});
        return;
    };

    var created_count: i64 = 0;
    for (0..merged_products.items.len) |index| {
        const product = &defined_products[index];

        // already uploaded
        if (product.productId != null) continue;

        const data = roblox.createDeveloperProduct(allocator, universe_id.?, product.*, api_key) catch |err| {
            std.log.err("Error while creating product: {any}", .{err});
            continue;
        };

        product.productId = data.productId;

        created_count += 1;
    }

    if (created_count == 0) {
        subparser.logger.err("No products were created", .{});
        return;
    }

    products.saveProducts(io, allocator, product_path.?, defined_defaults, defined_products) catch |err| {
        subparser.logger.err("Failed to write products to file: {any}", .{err});
        return;
    };

    if (!std.mem.eql(u8, config.config.File.ProductsOutputPath.?, "")) {
        codegen.generateCodeFromInput(io, allocator, config.config.File.ProductsOutputPath.?, defined_products);
    }

    subparser.logger.success("Successfully created {any} product(s)", .{created_count});
}
