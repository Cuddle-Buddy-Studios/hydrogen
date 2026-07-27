const std = @import("std");

const DeveloperProductDefaults = struct {
    isForSale: ?bool = false,
    isManagedPricingEnabled: ?bool = false,
    description: ?[]const u8 = "",
};

pub const DeveloperProductFile = struct {
    defaults: ?DeveloperProductDefaults = .{},
    products: []DeveloperProductDetails,
};

pub const DeveloperProductDetails = struct {
    name: []const u8,
    description: ?[]const u8,
    price: i64,
    isForSale: ?bool,
    isManagedPricingEnabled: ?bool,
};

pub fn loadProducts(io: std.Io, allocator: std.mem.Allocator, file_path: []const u8) ![]DeveloperProductDetails {
    const cwd = std.Io.Dir.cwd();

    const bytes = try cwd.readFileAlloc(io, file_path, allocator, .unlimited);
    defer allocator.free(bytes);

    const product_file = try std.json.parseFromSlice(DeveloperProductFile, allocator, bytes, .{ .ignore_unknown_fields = true });
    defer product_file.deinit();

    const product_data = product_file.value;

    var merged_products: std.ArrayList(DeveloperProductDetails) = try .initCapacity(allocator, product_data.products.len);

    for (product_data.products) |product| {
        const merged = mergeDefaults(allocator, product, product_data.defaults) catch |err| {
            std.log.warn("Could not merge due to error: {any}", .{err});
            continue;
        };
        _ = merged_products.append(allocator, merged) catch |err| {
            std.log.warn("Could not append due to error: {any}", .{err});
            continue;
        };
    }

    try validateProducts(allocator, merged_products.items);

    return merged_products.toOwnedSlice(allocator);
}

fn mergeDefaults(
    allocator: std.mem.Allocator,
    product: DeveloperProductDetails,
    defaults: ?DeveloperProductDefaults,
) !DeveloperProductDetails {
    const description = if (defaults == null)
        product.description
    else
        product.description orelse defaults.?.description;

    const isForSale = if (defaults == null)
        product.isForSale
    else
        product.isForSale orelse defaults.?.isForSale;

    const isManagedPricingEnabled = if (defaults == null)
        product.isManagedPricingEnabled
    else
        product.isManagedPricingEnabled orelse defaults.?.isManagedPricingEnabled;

    return DeveloperProductDetails{
        .name = try allocator.dupe(u8, product.name), // required
        .price = product.price, // required
        .description = if (description) |d| try allocator.dupe(u8, d) else null,
        .isForSale = isForSale,
        .isManagedPricingEnabled = isManagedPricingEnabled,
    };
}

fn validateProducts(allocator: std.mem.Allocator, products: []DeveloperProductDetails) !void {
    var seen_names: std.StringHashMapUnmanaged(void) = .empty;
    defer seen_names.deinit(allocator);

    for (products, 0..) |product, index| {
        // check for empty string
        if (std.mem.eql(u8, product.name, "")) {
            std.log.err("Product failed check: entry {any} is missing a name", .{index});
            return error.InvalidProductName;
        }

        if (product.price <= 0) {
            std.log.err("Product failed check: entry {any} has an invalid price {any}", .{ product.name, product.price });
            return error.InvalidProductPrice;
        }

        if (seen_names.contains(product.name)) {
            std.log.err("Product failed check: duplicate product name {any}", .{product.name});
            return error.DuplicateProduct;
        }
        _ = seen_names.put(allocator, product.name, {}) catch continue;

        if (product.isForSale == null) {
            // log error: "products.json: '{product.name}' has no isForSale (set on product or in defaults)"
            std.log.err("Product failed check: {any} has no isForSale (set on product or in defaults)", .{product.name});
            return error.InvalidProduct;
        }

        if (product.isManagedPricingEnabled == null) {
            std.log.err("Product failed check: {any} has no isManagedPricingEnabled (set on product or in defaults)", .{product.name});
            return error.InvalidProduct;
        }
    }
}
