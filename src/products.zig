const std = @import("std");

const DeveloperProductDefaults = struct {
    isForSale: ?bool = null,
    isManagedPricingEnabled: ?bool = null,
    description: ?[]const u8 = null,
};

pub const DeveloperProductFile = struct {
    defaults: ?DeveloperProductDefaults = .{},
    products: []DeveloperProductDetails,
};

pub const DeveloperProductDetails = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    price: i64,
    isForSale: ?bool = null,
    isManagedPricingEnabled: ?bool = null,
    productId: ?u64 = null,
};

pub fn loadProducts(io: std.Io, allocator: std.mem.Allocator, file_path: []const u8) !DeveloperProductFile {
    const cwd = std.Io.Dir.cwd();

    const bytes = try cwd.readFileAlloc(io, file_path, allocator, .unlimited);
    defer allocator.free(bytes);

    const product_file = try std.json.parseFromSlice(DeveloperProductFile, allocator, bytes, .{ .ignore_unknown_fields = true });
    defer product_file.deinit();

    const product_data = product_file.value;

    const defaults_copy: ?DeveloperProductDefaults = if (product_data.defaults) |default| .{
        .isForSale = default.isForSale,
        .isManagedPricingEnabled = default.isManagedPricingEnabled,
        .description = if (default.description) |desc| try allocator.dupe(u8, desc) else null,
    } else null;

    var products_copy = try allocator.alloc(DeveloperProductDetails, product_data.products.len);
    for (product_data.products, 0..) |product, i| {
        products_copy[i] = .{
            .name = try allocator.dupe(u8, product.name),
            .description = if (product.description) |desc| try allocator.dupe(u8, desc) else null,
            .price = product.price,
            .isForSale = product.isForSale,
            .isManagedPricingEnabled = product.isManagedPricingEnabled,
            .productId = product.productId,
        };
    }

    return .{
        .defaults = defaults_copy,
        .products = products_copy,
    };
}

pub fn saveProducts(io: std.Io, allocator: std.mem.Allocator, file_path: []const u8, defaults: ?DeveloperProductDefaults, products: []DeveloperProductDetails) !void {
    const file_data = DeveloperProductFile{
        .defaults = defaults,
        .products = products,
    };

    var writer_alloc: std.Io.Writer.Allocating = .init(allocator);
    defer writer_alloc.deinit();
    try std.json.Stringify.value(file_data, .{
        .whitespace = .indent_4,
        .emit_null_optional_fields = false,
    }, &writer_alloc.writer);

    const cwd = std.Io.Dir.cwd();
    try cwd.writeFile(io, .{ .sub_path = file_path, .data = writer_alloc.written() });
}

pub fn mergeDefaults(
    allocator: std.mem.Allocator,
    product: DeveloperProductDetails,
    defaults: ?DeveloperProductDefaults,
) !DeveloperProductDetails {
    var description: ?[]const u8 = undefined;
    var isForSale: ?bool = undefined;
    var isManagedPricingEnabled: ?bool = undefined;

    if (defaults == null) {
        description = product.description;
        isForSale = product.isForSale;
        isManagedPricingEnabled = product.isManagedPricingEnabled;
    } else {
        description = product.description orelse defaults.?.description orelse "";
        isForSale = product.isForSale orelse defaults.?.isForSale orelse true;
        isManagedPricingEnabled = product.isManagedPricingEnabled orelse defaults.?.isManagedPricingEnabled orelse false;
    }

    return DeveloperProductDetails{
        .name = try allocator.dupe(u8, product.name), // required
        .price = product.price, // required
        .productId = product.productId,
        .description = if (description) |d| try allocator.dupe(u8, d) else null,
        .isForSale = isForSale,
        .isManagedPricingEnabled = isManagedPricingEnabled,
    };
}

pub fn validateProducts(allocator: std.mem.Allocator, products: []DeveloperProductDetails) !void {
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
