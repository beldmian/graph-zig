const std = @import("std");

pub fn Graph(comptime T: type) type {
    return struct {
        const Self = @This();

        vertices: usize,
        set_edge_fn: *const fn (self: *Self, from: usize, to: usize, weight: ?T) anyerror!void,
        get_edge_fn: *const fn (self: *Self, from: usize, to: usize) ?T,

        pub fn set_edge(self: *Self, from: usize, to: usize, weight: ?T) !void {
            try self.set_edge_fn(self, from, to, weight);
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

        pub fn set_edge(graph: *Graph(T), from: usize, to: usize, weight: ?T) !void {
            const self: *Self = @fieldParentPtr("graph", graph);
            self.matrix[from][to] = weight;
        }

        pub fn get_edge(graph: *Graph(T), from: usize, to: usize) ?T {
            const self: *Self = @fieldParentPtr("graph", graph);
            return self.matrix[from][to];
        }
    };
}

test "matrix graph basic" {
    const allocator = std.heap.page_allocator;
    var mg = try MatrixGraph(f16).init(4, allocator);
    var g = &mg.graph;
    try g.set_edge(0, 1, 127);
    try g.set_edge(1, 2, 5);

    try std.testing.expect(mg.matrix[0][1] == 127);
    try std.testing.expect(mg.matrix[1][2] == 5);

    try std.testing.expect(mg.matrix[0][1] == g.get_edge(0, 1));
    try std.testing.expect(mg.matrix[1][2] == g.get_edge(1, 2));
}

pub fn CSREdge(comptime T: type) type {
    return struct {
        from: usize,
        to: usize,
        weight: ?T,
    };
}

pub fn CSRMatrixGraph(comptime T: type) type {
    return struct {
        const Self = @This();

        graph: Graph(T),

        csr_matrix: []CSREdge(T),
        allocator: std.mem.Allocator,
        capacity: usize = 4,
        edge_count: usize = 0,

        pub fn init(vertices: usize, allocator: std.mem.Allocator) !Self {
            const matrix: []CSREdge(T) = try allocator.alloc(CSREdge(T), 4);
            return Self{
                .csr_matrix = matrix,
                .allocator = allocator,
                .graph = Graph(T){
                    .set_edge_fn = set_edge,
                    .get_edge_fn = get_edge,
                    .vertices = vertices,
                },
            };
        }

        pub fn set_edge(graph: *Graph(T), from: usize, to: usize, weight: ?T) !void {
            const self: *Self = @fieldParentPtr("graph", graph);
            if (self.capacity == self.edge_count) {
                self.capacity *= 2;
                self.csr_matrix = try self.allocator.realloc(self.csr_matrix, self.capacity);
            }
            self.csr_matrix[self.edge_count] = CSREdge(T){
                .from = from,
                .to = to,
                .weight = weight,
            };
            self.edge_count += 1;
        }

        pub fn get_edge(graph: *Graph(T), from: usize, to: usize) ?T {
            const self: *Self = @fieldParentPtr("graph", graph);
            for (self.csr_matrix) |edge| {
                if ((edge.from == from) and (edge.to == to)) {
                    return edge.weight;
                }
            }
            return null;
        }
    };
}

test "csr matrix graph basic" {
    const allocator = std.heap.page_allocator;
    var mg = try CSRMatrixGraph(f16).init(4, allocator);
    var g = &mg.graph;
    try g.set_edge(0, 1, 127);
    try g.set_edge(1, 2, 5);

    try std.testing.expect(127 == g.get_edge(0, 1));
    try std.testing.expect(5 == g.get_edge(1, 2));
}
