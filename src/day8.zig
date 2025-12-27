const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const file_path = if (args.len >= 2) args[1] else "day8.in";

    const content = try std.fs.cwd().readFileAlloc(alloc, file_path, 64 * 1024);
    defer alloc.free(content);

    var grid = try parse_nodes(alloc, content);
    defer grid.deinit(alloc);
    std.debug.print("Loaded {d} nodes\n", .{grid.nodes.len});

    for (0..999) |i| {
        const start_link = std.time.nanoTimestamp();
        const nodes = grid.connect_closest().?;
        const end_link = std.time.nanoTimestamp();
        const time_diff: f64 = @floatFromInt(end_link - start_link);
        const time_s = time_diff / 1e9;

        const a = grid.nodes[nodes.@"0"];
        const b = grid.nodes[nodes.@"1"];
        std.debug.print("{d} Connected ({d}, {d}, {d}) and ({d}, {d}, {d}) in {d} s\n", .{ i, a.x, a.y, a.z, b.x, b.y, b.z, time_s });
    }
    const circuits = try grid.compute_circuits(alloc);
    defer {
        for (circuits) |c| {
            alloc.free(c);
        }
        alloc.free(circuits);
    }

    std.mem.sort([]const usize, circuits, {}, struct {
        pub fn inner(_: void, lhs: []const usize, rhs: []const usize) bool {
            return lhs.len > rhs.len;
        }
    }.inner);

    for (circuits) |c| {
        for (c) |n| {
            std.debug.print("{d} ", .{n});
        }
        std.debug.print("\n", .{});
    }

    const largest_to_sum = 3;
    var part_one: usize = 1;
    for (0..largest_to_sum) |i| {
        part_one *= circuits[i].len;
    }
    std.debug.print("Part one: {d}\n", .{part_one});
}

const NodeGrid = struct {
    const Cell = struct {
        distance: f64,
        connected: bool,
    };
    const NodesAndDistance = struct {
        i: usize,
        j: usize,
        distance: f64,
    };

    nodes: []const Node,
    adjacency_matrix: []Cell,
    sorted_by_closest_distance: []NodesAndDistance,
    last_conected_index: usize,

    fn cell_at(self: *const NodeGrid, a: usize, b: usize) *Cell {
        return &self.adjacency_matrix[a * self.nodes.len + b];
    }

    fn is_reachable_from(self: *const NodeGrid, a: usize, b: usize, skip: ?usize) bool {
        // if (skip) |s| {
        //     std.debug.print("Is {d} reachable from {d} skipping {d}?\n", .{ a, b, s });
        // } else {
        //     std.debug.print("Is {d} reachable from {d}?\n", .{ a, b });
        // }
        const cell = self.cell_at(a, b);
        if (cell.connected) {
            return true;
        }
        for (0..self.nodes.len) |i| {
            if (i == a or i == b or (skip != null and skip.? == i)) {
                continue;
            }
            if (self.cell_at(i, b).connected and self.is_reachable_from(a, i, b)) {
                return true;
            }
        }
        return false;
    }

    fn connect_closest(self: *NodeGrid) ?struct { usize, usize } {
        // var best: ?NodesAndDistance = null;
        // for (0..self.nodes.len) |i| {
        //     for (0..self.nodes.len) |j| {
        //         // std.debug.print("Looking at ({d}, {d})\n", .{ i, j });
        //         const cell = self.cell_at(i, j);
        //         if (cell.connected or self.is_reachable_from(i, j, null)) {
        //             continue;
        //         }
        //         if (best == null or best.?.distance > cell.distance) {
        //             best = .{
        //                 .i = i,
        //                 .j = j,
        //                 .distance = cell.distance,
        //             };
        //         }
        //     }
        // }
        // if (best) |b| {
        //     self.cell_at(b.i, b.j).connected = true;
        //     self.cell_at(b.j, b.i).connected = true;
        //     return .{ b.i, b.j };
        // } else {
        //     return null;
        // }

        for (self.last_conected_index..self.sorted_by_closest_distance.len) |i| {
            const closest = self.sorted_by_closest_distance[i];
            if (!self.is_reachable_from(closest.i, closest.j, null)) {
                self.cell_at(closest.i, closest.j).connected = true;
                self.cell_at(closest.j, closest.i).connected = true;
                self.last_conected_index = i;
                return .{ closest.i, closest.j };
            }
        }

        return null;
    }

    fn compute_circuits(self: *const NodeGrid, alloc: std.mem.Allocator) ![][]const usize {
        const evaluated = try alloc.alloc(bool, self.nodes.len);
        defer alloc.free(evaluated);
        for (evaluated) |*b| {
            b.* = false;
        }
        var circuits = try std.ArrayList([]const usize).initCapacity(alloc, 0);

        while (std.mem.indexOf(bool, evaluated, &[1]bool{false})) |i| {
            var current_circuit = try std.ArrayList(usize).initCapacity(alloc, 0);
            for (0..self.nodes.len) |n| {
                if (self.is_reachable_from(i, n, null)) {
                    evaluated[n] = true;
                    try current_circuit.append(alloc, n);
                }
            }
            try circuits.append(alloc, try current_circuit.toOwnedSlice(alloc));
        }

        return circuits.toOwnedSlice(alloc);
    }

    fn deinit(self: *NodeGrid, alloc: std.mem.Allocator) void {
        alloc.free(self.nodes);
        alloc.free(self.adjacency_matrix);
        alloc.free(self.sorted_by_closest_distance);
    }
};

const Node = struct {
    x: i64,
    y: i64,
    z: i64,
};

pub fn parse_nodes(alloc: std.mem.Allocator, content: []const u8) !NodeGrid {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    var node_list = try std.ArrayList(Node).initCapacity(alloc, 0);
    while (lines.next()) |line| {
        var coords = std.mem.tokenizeScalar(u8, line, ',');
        try node_list.append(alloc, .{
            .x = try std.fmt.parseInt(i64, coords.next().?, 10),
            .y = try std.fmt.parseInt(i64, coords.next().?, 10),
            .z = try std.fmt.parseInt(i64, coords.next().?, 10),
        });
    }

    const nodes = try node_list.toOwnedSlice(alloc);
    var matrix = try alloc.alloc(NodeGrid.Cell, nodes.len * nodes.len);
    var closest_nodes = try std.ArrayList(NodeGrid.NodesAndDistance).initCapacity(alloc, nodes.len * 2);

    for (0..nodes.len) |i| {
        const a = &nodes[i];
        for (0..nodes.len) |j| {
            const b = &nodes[j];
            const dx = a.x - b.x;
            const dy = a.y - b.y;
            const dz = a.z - b.z;
            const tmp: f64 = @floatFromInt(dx * dx + dy * dy + dz * dz);
            const distance = @sqrt(tmp);
            matrix[i * nodes.len + j] = NodeGrid.Cell{
                .distance = distance,
                .connected = i == j,
            };
            try closest_nodes.append(alloc, .{
                .distance = distance,
                .i = i,
                .j = j,
            });
        }
    }

    const sorted_by_closest_distance = try closest_nodes.toOwnedSlice(alloc);
    std.mem.sort(NodeGrid.NodesAndDistance, sorted_by_closest_distance, {}, struct {
        fn inner(_: void, lhs: NodeGrid.NodesAndDistance, rhs: NodeGrid.NodesAndDistance) bool {
            return lhs.distance > rhs.distance;
        }
    }.inner);

    return NodeGrid{
        .adjacency_matrix = matrix,
        .nodes = nodes,
        .sorted_by_closest_distance = sorted_by_closest_distance,
        .last_conected_index = 0,
    };
}
