const std = @import("std");
const graph = @import("./graph.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var mg = try graph.CSRMatrixGraph(f16).init(10, allocator);
    var g = &mg.graph;
    try g.set_edge(0, 1, 127);
    try g.set_edge(1, 2, 127);
    try g.set_edge(2, 3, 127);
    try g.set_edge(3, 4, 127);
    try g.set_edge(4, 5, 127);

    const fw_result = try g.floyd_warshall(allocator);
    std.log.info("edge [0, 1]: {?}, fw: {}", .{ g.get_edge(0, 1), fw_result[0][5] });

    allocator.free(fw_result);
}
