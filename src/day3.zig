const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const file_path = if (args.len >= 2) args[1] else "day3.in";

    const content = try std.fs.cwd().readFileAlloc(alloc, file_path, 64 * 1024);
    defer alloc.free(content);

    var bateries: BateryBankIterator = .init(content);

    var jolts: u64 = 0;
    while (bateries.next_batery()) |bank| {
        var indices: [12]usize = undefined;
        find_biggest_indices(bank, &indices);
        const value = sum_indices(bank, &indices);
        std.debug.print("{s} | ", .{bank});
        for (indices) |index| {
            std.debug.print("{d} -> {c} | ", .{ index, bank[index] });
        }
        std.debug.print("{d}\n", .{value});
        jolts += value;
    }
    std.debug.print("{d}\n", .{jolts});
}

pub fn sum_indices(number: []const u8, indices: []const usize) u64 {
    var sum: u64 = 0;
    for (indices) |index| {
        sum = sum * 10 + (number[index] - '0');
    }
    return sum;
}

pub fn find_biggest_indices(number: []const u8, indices: []usize) void {
    var current_index: usize = 0;
    var iter: usize = 0;
    var reserve: usize = indices.len - 1;
    while (true) {
        const index = find_biggest_number_index(number[current_index .. number.len - reserve]) + current_index;
        indices[iter] = index;
        current_index = index + 1;
        iter += 1;
        if (reserve == 0) {
            break;
        }
        reserve -= 1;
    }
}

pub fn find_biggest_number_index(number: []const u8) usize {
    var biggest_index: usize = 0;
    for (1..number.len) |index| {
        if (number[index] > number[biggest_index]) {
            biggest_index = index;
        }
    }
    return biggest_index;
}

const BateryBankIterator = struct {
    bateries_iterator: std.mem.TokenIterator(u8, .scalar),

    pub fn init(content: []u8) BateryBankIterator {
        return BateryBankIterator{
            .bateries_iterator = std.mem.tokenizeScalar(u8, content, '\n'),
        };
    }

    pub fn next_batery(self: *BateryBankIterator) ?[]const u8 {
        const opart = self.bateries_iterator.next();
        if (opart) |part| {
            return part;
        } else {
            return null;
        }
    }
};
