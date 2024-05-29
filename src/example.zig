const std = @import("std");
const graph = @import("./graph.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var mg = try graph.MatrixGraph(f16).init(10, allocator);
    var g = &mg.graph;
    g.set_edge(0, 1, 127);
    g.set_edge(1, 2, 127);

    const fw_result = try g.floyd_warshall(allocator);
    std.log.info("edge [0, 1]: {?}, fw: {}", .{ g.get_edge(0, 1), fw_result[0][2] });

    allocator.free(fw_result);
}
