const std = @import("std");

pub fn Graph(comptime T: type) type {
    return struct {
        const Self = @This();

        vertices: usize,
        set_edge_fn: *const fn (self: *Self, from: usize, to: usize, weight: ?T) void,
        get_edge_fn: *const fn (self: *Self, from: usize, to: usize) ?T,

        pub fn set_edge(self: *Self, from: usize, to: usize, weight: ?T) void {
            self.set_edge_fn(self, from, to, weight);
        }

        pub fn get_edge(self: *Self, from: usize, to: usize) ?T {
            return self.get_edge_fn(self, from, to);
        }

        pub fn floyd_warshall(self: *Self, allocator: std.mem.Allocator) ![][]T {
            const out_matrix: [][]T = try allocator.alloc([]T, self.vertices);
            for (out_matrix, 0..) |*row, i| {
                row.* = try allocator.alloc(T, self.vertices);
                for (row.*, 0..) |*cell, j| {
                    cell.* = self.get_edge(i, j) orelse std.math.inf(T);
                }
            }
            for (out_matrix, 0..) |_, k| {
                for (out_matrix, 0..) |_, i| {
                    for (out_matrix, 0..) |_, j| {
                        if (out_matrix[i][j] > out_matrix[i][k] + out_matrix[k][j]) {
                            out_matrix[i][j] = out_matrix[i][k] + out_matrix[k][j];
                        }
                    }
                }
            }
            return out_matrix;
        }
    };
}

pub fn MatrixGraph(comptime T: type) type {
    return struct {
        const Self = @This();

        graph: Graph(T),

        matrix: [][]?T,

        pub fn init(vertices: usize, allocator: std.mem.Allocator) !Self {
            const matrix: [][]?T = try allocator.alloc([]?T, vertices);
            for (matrix) |*row| {
                row.* = try allocator.alloc(?T, vertices);
                for (row.*) |*cell| {
                    cell.* = null;
                }
            }
            return Self{
                .matrix = matrix,
                .graph = Graph(T){
                    .set_edge_fn = set_edge,
                    .get_edge_fn = get_edge,
                    .vertices = vertices,
                },
            };
        }

        pub fn set_edge(graph: *Graph(T), from: usize, to: usize, weight: ?T) void {
            const self: *Self = @fieldParentPtr("graph", graph);
            self.matrix[from][to] = weight;
        }

        pub fn get_edge(graph: *Graph(T), from: usize, to: usize) ?T {
            const self: *Self = @fieldParentPtr("graph", graph);
            return self.matrix[from][to];
        }
    };
}
