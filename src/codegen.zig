const std = @import("std");
const products = @import("products.zig");

pub fn generateCodeFromInput(io: std.Io, allocator: std.mem.Allocator, file_path: []const u8, all_products: []products.DeveloperProductDetails) !void {
    var writer_alloc: std.Io.Writer.Allocating = .init(allocator);
    defer writer_alloc.deinit();
    const writer = &writer_alloc.writer;

    try writer.writeAll(
        \\-- SERVICES
        \\const MarketplaceService = game:GetService "MarketplaceService"
        \\
        \\-- TYPES
        \\type ProductInfo = {
        \\    AssetTypeId: number,
        \\    UniverseId: number,
        \\    Description: string,
        \\    UserBasePriceInRobux: number,
        \\    IsNew: boolean,
        \\    Updated: string,
        \\    AssetId: number,
        \\    DisplayDescription: string,
        \\    ProductId: number,
        \\    MinimumMembershipLevel: number,
        \\    Created: string,
        \\    DeveloperProductId: number,
        \\    ProductType: string,
        \\    IsLimited: boolean,
        \\    DisplayIconImageAssetId: number,
        \\    TargetId: number,
        \\    DisplayName: string,
        \\    IsPublicDomain: boolean,
        \\    Name: string,
        \\    PriceInRobux: number,
        \\    IsForSale: boolean,
        \\    DisplayIcon: number,
        \\    IconImageAssetId: number,
        \\    IsLimitedUnique: boolean,
        \\    PriceDiscountDetails: {
        \\        -- string, -- Type
        \\        -- number, -- AmountInRobux
        \\        -- number, -- Percent
        \\    },
        \\    Creator: {
        \\        CreatorType: Enum.CreatorType,
        \\        CreatorTargetId: number,
        \\        HasVerifiedBadge: boolean,
        \\        Name: string,
        \\        Id: number,
        \\    },
        \\}
        \\
        \\-- PRIVATE STATE
        \\const _products = {
        \\
    );

    for (all_products) |product| {
        if (product.productId == null) continue;
        try writer.print("\t[\"{s}\"] = {d},\n", .{ product.name, product.productId.? });
    }

    try writer.writeAll(
        \\}
        \\
        \\-- PRIVATE FUNCTIONS
        \\local function getProductInfo(id: number): ProductInfo
        \\    return MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.Product)
        \\end
        \\
        \\-- PUBLIC MODULE
        \\local Products = {}
        \\
        \\Products.Products = _products
        \\
        \\Products.GetProductInfoAsync = getProductInfo
        \\
        \\function Products.GetNameAsync(id: number): string
        \\    local info = getProductInfo(id)
        \\
        \\    return info.Name
        \\end
        \\
        \\function Products.GetDescriptionAsync(id: number): string
        \\    local info = getProductInfo(id)
        \\
        \\    return info.Description
        \\end
        \\
        \\function Products.GetBasePriceAsync(id: number): number
        \\    local info = getProductInfo(id)
        \\
        \\    return info.UserBasePriceInRobux
        \\end
        \\
        \\function Products.GetDiscountedPriceAsync(id: number)
        \\    local info = getProductInfo(id)
        \\
        \\    return info.PriceInRobux
        \\end
        \\
        \\return Products
    );

    const cwd = std.Io.Dir.cwd();
    try cwd.writeFile(io, .{ .sub_path = file_path, .data = writer_alloc.written() });
}

test "written file is good" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;

    try generateCodeFromInput(io, allocator, "test.luau", undefined);
}
