const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const file_path = if (args.len >= 2) args[1] else "day5.in";

    const content = try std.fs.cwd().readFileAlloc(alloc, file_path, 64 * 1024);
    defer alloc.free(content);

    const split = std.mem.indexOf(u8, content, "\n\n").?;

    const ranges = try alloc.alloc(InclusiveRange, std.mem.count(u8, content[0..split], "\n") + 1);
    defer alloc.free(ranges);

    try parse_ranges(content[0..split], ranges);

    var total: usize = 0;
    var iterator = std.mem.tokenizeScalar(u8, content[split + 2 ..], '\n');
    while (iterator.next()) |line| {
        if (in_any_range(try std.fmt.parseInt(usize, line, 10), ranges) != null) {
            total += 1;
        }
    }
    std.debug.print("Solution part one: {d}\n", .{total});

    const joined_ranges = try join_ranges(alloc, ranges);
    defer alloc.free(joined_ranges);

    total = 0;
    for (joined_ranges) |range| {
        total += range.max - range.min + 1;
    }
    std.debug.print("Solution part two: {d}\n", .{total});
}

const InclusiveRange = struct {
    min: usize,
    max: usize,
};

pub fn max(a: usize, b: usize) usize {
    return if (a > b) a else b;
}
pub fn min(a: usize, b: usize) usize {
    return if (a < b) a else b;
}

pub fn inside(n: usize, r: InclusiveRange) bool {
    return r.min <= n and n <= r.max;
}

pub fn index_to_merge_with(ranges: []InclusiveRange, range: InclusiveRange) ?usize {
    for (0.., ranges) |i, r| {
        if (inside(range.min, r) or inside(range.max, r) or inside(r.min, range)) {
            return i;
        }
    }
    return null;
}

pub fn add_range_to_joined_list(alloc: std.mem.Allocator, ranges: *std.ArrayList(InclusiveRange), range: InclusiveRange) !void {
    if (index_to_merge_with(ranges.items, range)) |i| {
        var existing_range = ranges.swapRemove(i);
        existing_range.min = min(existing_range.min, range.min);
        existing_range.max = max(existing_range.max, range.max);
        try add_range_to_joined_list(alloc, ranges, existing_range);
    } else {
        try ranges.append(alloc, range);
    }
}

pub fn join_ranges(alloc: std.mem.Allocator, ranges: []const InclusiveRange) ![]InclusiveRange {
    var list = try std.ArrayList(InclusiveRange).initCapacity(alloc, 0);

    for (ranges) |range| {
        try add_range_to_joined_list(alloc, &list, range);
    }

    return try list.toOwnedSlice(alloc);
}

pub fn in_any_range(number: usize, ranges: []const InclusiveRange) ?usize {
    for (0.., ranges) |i, range| {
        if (range.min <= number and number <= range.max) {
            return i;
        }
    }
    return null;
}

pub fn parse_ranges(content: []const u8, out_ranges: []InclusiveRange) !void {
    var iterator = std.mem.tokenizeScalar(u8, content, '\n');
    var i: usize = 0;
    while (iterator.next()) |line| {
        var spliterator = std.mem.splitAny(u8, line, "-");

        out_ranges[i] = InclusiveRange{
            .min = try std.fmt.parseInt(usize, spliterator.next().?, 10),
            .max = try std.fmt.parseInt(usize, spliterator.next().?, 10),
        };

        i += 1;
    }
}
