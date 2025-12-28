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

    const nodes = try loadNodes(alloc, content);
    defer alloc.free(nodes);

    const ds = try distances(alloc, nodes);
    defer alloc.free(ds);

    var dsu = try DisjointSetUnion.init(alloc, nodes.len);
    defer dsu.deinit(alloc);

    // for (ds) |dis| {
    //     const a = nodes[dis.i];
    //     const b = nodes[dis.j];
    //     std.debug.print("({d}, {d}, {d}) - ({d}, {d}, {d})\n", .{ a.x, a.y, a.z, b.x, b.y, b.z });
    // }

    var last_joined: usize = 0;
    for (0.., ds[0..1000]) |i, distance| {
        // std.debug.print("\nJoining\n", .{});
        last_joined = i;
        dsu.join(distance.i, distance.j);
    }

    dsu.flatten();

    const sizes = try dsu.computeSetSizes(alloc);
    defer alloc.free(sizes);

    std.mem.sort(usize, sizes, {}, std.sort.desc(usize));

    // for (0.., dsu.parents) |i, p| {
    //     std.debug.print("{d} --> {d} \n", .{ i, p });
    // }
    // std.debug.print("\nSizes: ", .{});
    // for (sizes) |s| {
    //     std.debug.print("{d} ", .{s});
    // }
    // std.debug.print("\n", .{});

    var part_one: usize = 1;
    for (0..3) |i| {
        part_one *= sizes[i];
    }

    std.debug.print("Part one: {d}\n", .{part_one});

    while (!dsu.allInSameCircuit()) {
        last_joined += 1;
        dsu.join(ds[last_joined].i, ds[last_joined].j);
    }

    std.debug.print("Part two: {d}\n", .{nodes[ds[last_joined].i].x * nodes[ds[last_joined].j].x});
}

const DisjointSetUnion = struct {
    parents: []usize,

    fn init(alloc: std.mem.Allocator, size: usize) !DisjointSetUnion {
        const parents = try alloc.alloc(usize, size);
        for (0..size) |i| {
            parents[i] = i;
        }
        return .{ .parents = parents };
    }

    fn deinit(self: *DisjointSetUnion, alloc: std.mem.Allocator) void {
        return alloc.free(self.parents);
    }

    fn find(self: *DisjointSetUnion, x: usize) usize {
        if (self.parents[x] != x) {
            self.parents[x] = self.find(self.parents[x]);
        }
        return self.parents[x];
    }

    fn flatten(self: *DisjointSetUnion) void {
        for (0..self.parents.len) |i| {
            _ = self.find(i);
        }
    }

    fn computeSetSizes(self: *const DisjointSetUnion, alloc: std.mem.Allocator) ![]usize {
        var sizes = try alloc.alloc(usize, self.parents.len);
        for (sizes) |*s| {
            s.* = 0;
        }
        for (self.parents) |p| {
            sizes[p] += 1;
        }
        return sizes;
    }

    fn join(self: *DisjointSetUnion, parent: usize, subset: usize) void {
        self.parents[self.find(subset)] = self.find(parent);
    }

    fn allInSameCircuit(self: *DisjointSetUnion) bool {
        const parent = self.find(0);
        for (1..self.parents.len) |i| {
            if (parent != self.find(i)) {
                return false;
            }
        }
        return true;
    }
};

const Node = struct {
    x: i64,
    y: i64,
    z: i64,
};

const NodesAndDistance = struct {
    i: usize,
    j: usize,
    distance_squared: u64,
};

fn distances(alloc: std.mem.Allocator, nodes: []const Node) ![]NodesAndDistance {
    var list = try std.ArrayList(NodesAndDistance).initCapacity(alloc, 0);
    for (0..nodes.len) |i| {
        for (0..i) |j| {
            const dx: i64 = nodes[i].x - nodes[j].x;
            const dy: i64 = nodes[i].y - nodes[j].y;
            const dz: i64 = nodes[i].z - nodes[j].z;
            const distance_squared: u64 = @intCast(dx * dx + dy * dy + dz * dz);
            try list.append(alloc, .{
                .i = i,
                .j = j,
                .distance_squared = distance_squared,
            });
        }
    }
    const d = try list.toOwnedSlice(alloc);
    std.mem.sort(NodesAndDistance, d, {}, struct {
        fn lessThan(_: void, lhs: NodesAndDistance, rhs: NodesAndDistance) bool {
            return lhs.distance_squared < rhs.distance_squared;
        }
    }.lessThan);

    return d;
}

fn loadNodes(alloc: std.mem.Allocator, content: []const u8) ![]Node {
    var iter = std.mem.tokenizeScalar(u8, content, '\n');
    var nodes = try std.ArrayList(Node).initCapacity(alloc, 0);
    while (iter.next()) |i| {
        var numbers = std.mem.tokenizeScalar(u8, i, ',');
        try nodes.append(alloc, .{
            .x = try std.fmt.parseInt(i64, numbers.next().?, 10),
            .y = try std.fmt.parseInt(i64, numbers.next().?, 10),
            .z = try std.fmt.parseInt(i64, numbers.next().?, 10),
        });
    }
    return nodes.toOwnedSlice(alloc);
}
