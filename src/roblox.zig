const std = @import("std");
const httpx = @import("httpx");
const products = @import("products.zig");

const DeveloperProductResponse = struct {
    productId: u64,
    name: []const u8,
    description: []const u8,
    iconImageAssetId: u64,
    universeId: i64,
    isForSale: bool,
    priceInformation: struct {
        defaultPriceInRobux: i64,
    },
    isImmutable: bool,
    createdTimestamp: []const u8,
    updatedTimestamp: []const u8,
    isManagedPricingEnabled: bool,
};

const DEVELOPER_PRODUCT_URL = "https://apis.roblox.com/developer-products/v2/universes/{universeId}/developer-products";

fn subUniverseId(allocator: std.mem.Allocator, comptime fmt: []const u8, value: anytype) ![]u8 {
    const id_str = try std.fmt.allocPrint(allocator, fmt, .{value});
    defer allocator.free(id_str);
    return std.mem.replaceOwned(u8, allocator, DEVELOPER_PRODUCT_URL, "{universeId}", id_str);
}

pub fn createDeveloperProduct(gpa: std.mem.Allocator, universe_id: u64, product_details: products.DeveloperProductDetails, api_key: []const u8) !DeveloperProductResponse {
    const url = try subUniverseId(gpa, "{d}", universe_id);

    var client = httpx.Client.init(gpa);
    defer client.deinit();

    var builder = httpx.MultipartBuilder.init(gpa, "Hydrogen");
    defer builder.deinit();

    var price_buf: [32]u8 = undefined;
    const price_string = try std.fmt.bufPrint(&price_buf, "{d}", .{product_details.price});

    const fields = [_]httpx.MultipartField{
        .{ .name = "name", .value = product_details.name },
        .{ .name = "price", .value = price_string },
        .{ .name = "isForSale", .value = if (product_details.isForSale.?) "true" else "false" },
        .{ .name = "description", .value = product_details.name },
        .{ .name = "isManagedPricingEnabled", .value = if (product_details.isManagedPricingEnabled.?) "true" else "false" },
    };

    const opts = httpx.RequestOptions.defaults()
        .withMultipartFields(&fields)
        .withHeaders(&.{.{ "x-api-key", api_key }});

    var response = try client.post(url, opts);
    defer response.deinit();

    if (!response.ok()) {
        std.log.err("Request has failed: {d}\n{s}", .{ response.status.code, response.text() orelse "" });
        return error.ProductCreationFailed;
    }

    const product = try response.json(DeveloperProductResponse, .{ .ignore_unknown_fields = true });
    defer product.deinit();

    return product.value;
}

test "developer product subbing" {
    const allocator = std.testing.allocator;

    const url_num = try subUniverseId(allocator, "{d}", @as(u64, 12345));
    defer allocator.free(url_num);
    try std.testing.expectEqualStrings(
        "https://apis.roblox.com/developer-products/v2/universes/12345/developer-products",
        url_num,
    );

    const url_str = try subUniverseId(allocator, "{s}", "abc123");
    defer allocator.free(url_str);
    try std.testing.expectEqualStrings(
        "https://apis.roblox.com/developer-products/v2/universes/abc123/developer-products",
        url_str,
    );
}
