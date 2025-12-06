const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const file_path = if (args.len >= 2) args[1] else "day2.in";

    const content = try std.fs.cwd().readFileAlloc(alloc, file_path, 64 * 1024);
    defer alloc.free(content);

    var ranges: RangeIterator = .init(content);
    var part_one: u64 = 0;
    var part_two: u64 = 0;
    while (try ranges.next_range()) |range| {
        //std.debug.print("[{d}, {d}]\n", .{ range.min, range.max });
        analyze_range(range, &part_one, &part_two);
    }

    std.debug.print("Solution part one: {d}\nSolution part two: {d}\n", .{ part_one, part_two });
}

const Range = struct {
    min: u64,
    max: u64,
};

pub fn analyze_range(range: Range, part_one_solution: *u64, part_two_solution: *u64) void {
    for (range.min..range.max) |value| {
        var buffer: [64]u8 = undefined;
        const length = std.fmt.printInt(&buffer, value, 10, .lower, .{});
        if (is_symetric(buffer[0..length])) {
            part_one_solution.* += value;
        }

        if (is_repeating(buffer[0..length])) {
            part_two_solution.* += value;
        }
    }
}

pub fn chunks_equal(str: []u8, chunk_size: u64) bool {
    var equal = true;
    for (0..str.len / chunk_size) |i| {
        equal &= std.mem.eql(u8, str[0..chunk_size], str[chunk_size * i .. chunk_size * (i + 1)]);
    }
    return equal;
}

pub fn is_repeating(number: []u8) bool {
    if (number.len < 2) {
        return false;
    }
    for (1..(number.len / 2) + 1) |sub_part| {
        if (number.len % sub_part == 0 and chunks_equal(number, sub_part)) {
            return true;
        }
    }
    return false;
}

pub fn is_symetric(number: []u8) bool {
    return std.mem.eql(u8, number[0 .. number.len / 2], number[number.len / 2 .. number.len]);
}

const RangeIterator = struct {
    ranges_iterator: std.mem.TokenIterator(u8, .scalar),

    pub fn init(content: []u8) RangeIterator {
        return RangeIterator{
            .ranges_iterator = std.mem.tokenizeScalar(u8, content, ','),
        };
    }

    pub fn next_range(self: *RangeIterator) !?Range {
        const opart = self.ranges_iterator.next();
        if (opart) |part| {
            var numbers = std.mem.splitAny(u8, part, "-");
            return Range{
                .min = try std.fmt.parseInt(u64, numbers.next().?, 10),
                .max = try std.fmt.parseInt(u64, numbers.next().?, 10),
            };
        } else {
            return null;
        }
    }
};
