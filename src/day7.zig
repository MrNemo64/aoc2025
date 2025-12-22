const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const file_path = if (args.len >= 2) args[1] else "day7.in";

    const content_p1 = try std.fs.cwd().readFileAlloc(alloc, file_path, 64 * 1024);
    defer alloc.free(content_p1);

    const content_p2 = try alloc.alloc(u8, content_p1.len);
    defer alloc.free(content_p2);

    @memcpy(content_p2, content_p1);

    std.debug.print("Part one: {d}\n", .{part_one(content_p1)});
    std.debug.print("Part two: {d}\n", .{try part_two(alloc, content_p2)});
}

fn part_one(content: []u8) usize {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    const first_line = @constCast(lines.next().?);
    var previous_line = first_line;
    std.mem.replaceScalar(u8, first_line, 'S', '|');
    var splits: usize = 0;
    while (lines.next()) |cline| {
        var line = @constCast(cline);
        for (0.., line) |i, c| {
            if (c == '.' and previous_line[i] == '|') {
                line[i] = '|';
            } else if (c == '^' and previous_line[i] == '|') {
                var counts = false;
                if (i > 0) {
                    line[i - 1] = '|';
                    counts = true;
                }
                if (i < line.len - 1) {
                    line[i + 1] = '|';
                    counts = true;
                }
                if (counts) {
                    splits += 1;
                }
            }
        }
        previous_line = line;
    }
    return splits;
}

const Key = struct {
    line: usize,
    column: usize,
};

fn part_two(alloc: std.mem.Allocator, content: []const u8) !usize {
    var memory = std.AutoHashMap(Key, usize).init(alloc);
    defer memory.deinit();
    const start = std.mem.indexOfScalar(u8, content, 'S').?;
    var lines = try std.ArrayList([]const u8).initCapacity(alloc, std.mem.count(u8, content, "\n") + 1);
    var iter = std.mem.tokenizeScalar(u8, content, '\n');
    while (iter.next()) |line| {
        try lines.append(alloc, line);
    }
    const owned_lines = try lines.toOwnedSlice(alloc);
    defer alloc.free(owned_lines);
    return descend(&memory, owned_lines, start, 0);
}

fn descend(memory: *std.AutoHashMap(Key, usize), lines: []const []const u8, position: usize, line: usize) !usize {
    const key: Key = .{
        .line = line,
        .column = position,
    };
    if (memory.contains(key)) {
        return memory.get(key).?;
    } else {
        var splits: usize = 0;
        if (lines.len == 0) {
            splits = 1;
        } else {
            if (lines[0][position] == '^' and lines.len > 0) {
                if (position > 0) {
                    splits += try descend(memory, lines[1..], position - 1, line + 1);
                }
                if (position < lines[0].len) {
                    splits += try descend(memory, lines[1..], position + 1, line + 1);
                }
            } else {
                splits = try descend(memory, lines[1..], position, line + 1);
            }
        }
        try memory.put(key, splits);
        return splits;
    }
}
