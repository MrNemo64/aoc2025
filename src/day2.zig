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
    var value = range.min;
    while (value <= range.max) : (value += 1) {
        var buffer: [64]u8 = undefined;
        const len = std.fmt.printInt(&buffer, value, 10, .lower, .{});

        const str = buffer[0..len];

        if (is_symetric(str)) {
            part_one_solution.* += value;
        }

        if (is_repeating(str)) {
            part_two_solution.* += value;
        }
    }
}

pub fn chunks_equal(str: []const u8, chunk_size: usize) bool {
    const first = str[0..chunk_size];
    var i: usize = 1;
    const count = str.len / chunk_size;

    while (i < count) : (i += 1) {
        const start = i * chunk_size;
        const end = start + chunk_size;
        if (!std.mem.eql(u8, first, str[start..end])) {
            return false;
        }
    }
    return true;
}

pub fn is_repeating(number: []const u8) bool {
    if (number.len < 2) {
        return false;
    }

    const max_chunk = number.len / 2;
    var chunk_size: usize = 1;
    while (chunk_size <= max_chunk) : (chunk_size += 1) {
        if (number.len % chunk_size == 0 and chunks_equal(number, chunk_size)) {
            return true;
        }
    }
    return false;
}

pub fn is_symetric(number: []const u8) bool {
    if (number.len % 2 != 0) {
        return false;
    }

    const half = number.len / 2;
    return std.mem.eql(u8, number[0..half], number[half..]);
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
