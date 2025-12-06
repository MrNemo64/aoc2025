const std = @import("std");

const DialSize: usize = 100;

const Direction = enum { left, right };

const LineContent = struct {
    direction: Direction,
    amount: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const file_path = if (args.len >= 2) args[1] else "day1.in";

    const content = try std.fs.cwd().readFileAlloc(alloc, file_path, 64 * 1024);
    defer alloc.free(content);

    var lines = try std.ArrayList(LineContent).initCapacity(alloc, 0);
    defer lines.deinit(alloc);

    var it = std.mem.tokenizeScalar(u8, content, '\n');
    while (it.next()) |raw_line| {
        if (raw_line.len == 0) continue;

        // Strip possible '\r' from Windows line endings.
        var line = raw_line;
        if (line[line.len - 1] == '\r') {
            line = line[0 .. line.len - 1];
            if (line.len == 0) continue;
        }

        const dir_char = line[0];
        const direction: Direction = switch (dir_char) {
            'L' => .left,
            'R' => .right,
            else => unreachable,
        };

        const amount = try std.fmt.parseInt(usize, line[1..], 10);

        try lines.append(alloc, .{
            .direction = direction,
            .amount = amount,
        });
    }

    // ---------------- Part 1: count times dial ends at 0 ----------------
    var pos1: u8 = 50;
    var zeros_end: usize = 0;

    for (lines.items) |rot| {
        pos1 = advanceDialPart1(rot, pos1, &zeros_end);
    }

    std.debug.print("Part 1 password (end-of-rotation zeros): {d}\n", .{zeros_end});

    // ---------------- Part 2: count every click that hits 0 ----------------
    var pos2: u8 = 50;
    var zeros_all_clicks: usize = 0;

    for (lines.items) |rot| {
        pos2 = advanceDialPart2(rot, pos2, &zeros_all_clicks);
    }

    std.debug.print("Part 2 password (all clicks at 0): {d}\n", .{zeros_all_clicks});
}

// Shared helper: compute final dial position after a rotation.
fn computeEndPosition(amount: LineContent, current: u8) u8 {
    const dir_sign: isize = switch (amount.direction) {
        .left => -1,
        .right => 1,
    };

    const start: usize = current;
    const steps: isize = @intCast(amount.amount);

    const signed_steps: isize = steps * dir_sign;
    var pos: isize = @intCast(start);

    // @mod gives a non-negative result in 0..DialSize-1
    pos = @mod(pos + signed_steps, @as(isize, DialSize));

    return @intCast(pos); // safe: always in 0..99
}

// ---------------- Part 1 ----------------
// Only count when the dial is at 0 at the *end* of a rotation.
fn advanceDialPart1(amount: LineContent, current: u8, times_zero: *usize) u8 {
    const result = computeEndPosition(amount, current);
    if (result == 0) {
        times_zero.* += 1;
    }
    return result;
}

// ---------------- Part 2 ----------------
// Count every click where the dial points at 0 (method 0x434C49434B).
fn advanceDialPart2(amount: LineContent, current: u8, times_zero: *usize) u8 {
    const start: usize = current;
    const steps: usize = amount.amount;

    // Count hits on 0 during the rotation:
    //
    // For direction right:
    //   positions visited: start+1, start+2, ..., start+steps (mod 100)
    // For direction left:
    //   positions visited: start-1, start-2, ..., start-steps (mod 100)
    //
    // Strategy: compute distance to the *next* 0 in that direction.
    // If the rotation is long enough to reach it, that’s 1 hit,
    // plus one extra for every full 100 clicks beyond that.
    if (steps > 0) {
        const first_distance: usize = switch (amount.direction) {
            .right => blk: {
                const off = (DialSize - start) % DialSize;
                // If already at 0, first 0 in this direction is 100 clicks away.
                break :blk if (off == 0) DialSize else off;
            },
            .left => blk: {
                const off = start % DialSize;
                // If already at 0, first 0 in this direction is 100 clicks away.
                break :blk if (off == 0) DialSize else off;
            },
        };

        if (steps >= first_distance) {
            const remaining_after_first = steps - first_distance;
            // 1 hit for the first time we reach 0, plus one per extra full loop.
            times_zero.* += 1 + remaining_after_first / DialSize;
        }
    }

    // Then compute final position
    return computeEndPosition(amount, current);
}
