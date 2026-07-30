const std = @import("std");
const products = @import("products.zig");

pub fn generateCodeFromInput(io: std.Io, allocator: std.mem.Allocator, file_path: []const u8, all_products: []products.DeveloperProductDetails) !void {
    var writer_alloc: std.Io.Writer.Allocating = .init(allocator);
    defer writer_alloc.deinit();
    const writer = &writer_alloc.writer;

    try writer.writeAll("-- SERVICES\n");
    try writer.writeAll("local MarketplaceService = game:GetService \"MarketplaceService\"\n");
    try writer.writeAll("\n");
    try writer.writeAll("-- TYPES\n");
    try writer.writeAll("type ProductInfo = {\n");
    try writer.writeAll("\tAssetTypeId: number,\n");
    try writer.writeAll("\tUniverseId: number,\n");
    try writer.writeAll("\tDescription: string,\n");
    try writer.writeAll("\tUserBasePriceInRobux: number,\n");
    try writer.writeAll("\tIsNew: boolean,\n");
    try writer.writeAll("\tUpdated: string,\n");
    try writer.writeAll("\tAssetId: number,\n");
    try writer.writeAll("\tDisplayDescription: string,\n");
    try writer.writeAll("\tProductId: number,\n");
    try writer.writeAll("\tMinimumMembershipLevel: number,\n");
    try writer.writeAll("\tCreated: string,\n");
    try writer.writeAll("\tDeveloperProductId: number,\n");
    try writer.writeAll("\tProductType: string,\n");
    try writer.writeAll("\tIsLimited: boolean,\n");
    try writer.writeAll("\tDisplayIconImageAssetId: number,\n");
    try writer.writeAll("\tTargetId: number,\n");
    try writer.writeAll("\tDisplayName: string,\n");
    try writer.writeAll("\tIsPublicDomain: boolean,\n");
    try writer.writeAll("\tName: string,\n");
    try writer.writeAll("\tPriceInRobux: number,\n");
    try writer.writeAll("\tIsForSale: boolean,\n");
    try writer.writeAll("\tDisplayIcon: number,\n");
    try writer.writeAll("\tIconImageAssetId: number,\n");
    try writer.writeAll("\tIsLimitedUnique: boolean,\n");
    try writer.writeAll("\tPriceDiscountDetails: {\n");
    try writer.writeAll("\t\t-- string, -- Type\n");
    try writer.writeAll("\t\t-- number, -- AmountInRobux\n");
    try writer.writeAll("\t\t-- number, -- Percent\n");
    try writer.writeAll("\t},\n");
    try writer.writeAll("\tCreator: {\n");
    try writer.writeAll("\t\tCreatorType: Enum.CreatorType,\n");
    try writer.writeAll("\t\tCreatorTargetId: number,\n");
    try writer.writeAll("\t\tHasVerifiedBadge: boolean,\n");
    try writer.writeAll("\t\tName: string,\n");
    try writer.writeAll("\t\tId: number,\n");
    try writer.writeAll("\t},\n");
    try writer.writeAll("}\n");
    try writer.writeAll("\n");
    try writer.writeAll("-- PRIVATE STATE\n");
    try writer.writeAll("const _products = {\n");

    for (all_products) |product| {
        if (product.productId == null) continue;
        try writer.print("\t[\"{s}\"] = {d},\n", .{ product.name, product.productId.? });
    }

    try writer.writeAll("}\n");
    try writer.writeAll("\n");
    try writer.writeAll("-- PRIVATE FUNCTIONS\n");
    try writer.writeAll("local function getProductInfo(id: number): ProductInfo\n");
    try writer.writeAll("\treturn MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.Product)\n");
    try writer.writeAll("end\n");
    try writer.writeAll("\n");
    try writer.writeAll("-- PUBLIC MODULE\n");
    try writer.writeAll("local Products = {}\n");
    try writer.writeAll("\n");
    try writer.writeAll("Products.Products = _products\n");
    try writer.writeAll("\n");
    try writer.writeAll("Products.GetProductInfoAsync = getProductInfo\n");
    try writer.writeAll("\n");
    try writer.writeAll("function Products.GetNameAsync(id: number): string\n");
    try writer.writeAll("\tlocal info = getProductInfo(id)\n");
    try writer.writeAll("\n");
    try writer.writeAll("\treturn info.Name\n");
    try writer.writeAll("end\n");
    try writer.writeAll("\n");
    try writer.writeAll("function Products.GetDescriptionAsync(id: number): string\n");
    try writer.writeAll("\tlocal info = getProductInfo(id)\n");
    try writer.writeAll("\n");
    try writer.writeAll("\treturn info.Description\n");
    try writer.writeAll("end\n");
    try writer.writeAll("\n");
    try writer.writeAll("function Products.GetBasePriceAsync(id: number): number\n");
    try writer.writeAll("\tlocal info = getProductInfo(id)\n");
    try writer.writeAll("\n");
    try writer.writeAll("\treturn info.UserBasePriceInRobux\n");
    try writer.writeAll("end\n");
    try writer.writeAll("\n");
    try writer.writeAll("function Products.GetDiscountedPriceAsync(id: number)\n");
    try writer.writeAll("\tlocal info = getProductInfo(id)\n");
    try writer.writeAll("\n");
    try writer.writeAll("\treturn info.PriceInRobux\n");
    try writer.writeAll("end\n");
    try writer.writeAll("\n");
    try writer.writeAll("return Products\n");

    const cwd = std.Io.Dir.cwd();
    try cwd.writeFile(io, .{ .sub_path = file_path, .data = writer_alloc.written() });
}

test "written file is good" {
    const io = std.testing.io;
    const allocator = std.testing.allocator;

    try generateCodeFromInput(io, allocator, "test.luau", undefined);
}
