const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const file_path = if (args.len >= 2) args[1] else "day6.in";

    const content = try std.fs.cwd().readFileAlloc(alloc, file_path, 64 * 1024);
    defer alloc.free(content);

    const problems_part_one = try parse_puzzles_part_one(alloc, content);
    defer {
        for (problems_part_one) |*problem| {
            problem.numbers.deinit(alloc);
        }
    }
    defer alloc.free(problems_part_one);

    var part_one: isize = 0;
    for (problems_part_one) |problem| {
        part_one += problem.operate();
    }

    std.debug.print("Part one: {d}\n", .{part_one});

    const problems_part_two = try parse_puzzles_part_two(alloc, content);
    defer {
        for (problems_part_two) |*problem| {
            problem.numbers.deinit(alloc);
        }
    }
    defer alloc.free(problems_part_two);

    var part_two: isize = 0;
    for (problems_part_two) |problem| {
        part_two += problem.operate();
        // problem.print();
        // std.debug.print("\n", .{});
    }

    std.debug.print("Part two: {d}\n", .{part_two});
}

const Problem = struct {
    numbers: std.ArrayList(isize),
    operation: enum { add, multiply },

    fn operate(self: *const Problem) isize {
        var result: isize = if (self.operation == .add) 0 else 1;
        for (self.numbers.items) |n| {
            switch (self.operation) {
                .add => {
                    result += n;
                },
                .multiply => {
                    result *= n;
                },
            }
        }
        return result;
    }

    fn print(self: *const Problem) void {
        for (0.., self.numbers.items) |i, n| {
            std.debug.print(" {d}", .{n});
            if (i != self.numbers.items.len - 1) {
                const char: u8 = if (self.operation == .add) '+' else '*';
                std.debug.print(" {c}", .{char});
            }
        }
    }
};

pub fn count_problems(content: []const u8) usize {
    var counting_spaces = true;
    var problems: usize = 0;
    for (content) |char| {
        if (char == '\n') {
            return problems;
        } else if (counting_spaces and char == ' ') {
            continue;
        } else if (counting_spaces and '0' <= char and char <= '9') {
            problems += 1;
            counting_spaces = false;
        } else if (!counting_spaces and char == ' ') {
            counting_spaces = true;
        } else if (!counting_spaces and '0' <= char and char <= '9') {
            continue;
        } else {
            unreachable;
        }
    }
    unreachable;
}

pub fn parse_puzzles_part_one(alloc: std.mem.Allocator, content: []const u8) ![]Problem {
    var problems = try std.ArrayList(Problem).initCapacity(alloc, count_problems(content));
    for (0..problems.capacity) |_| {
        var problem = try problems.addOne(alloc);
        problem.numbers = try std.ArrayList(isize).initCapacity(alloc, 0);
        problem.operation = .add;
    }

    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    while (lines.next()) |line| {
        var numbers = std.mem.tokenizeScalar(u8, line, ' ');
        var problem_index: usize = 0;
        while (numbers.next()) |number| {
            var problem = &problems.items[problem_index];
            if (number[0] == '*') {
                problem.operation = .multiply;
            } else if (number[0] == '+') {
                problem.operation = .add;
            } else {
                try problem.numbers.append(alloc, try std.fmt.parseInt(isize, number, 10));
            }
            problem_index += 1;
        }
    }
    return problems.toOwnedSlice(alloc);
}

pub fn split_lines(content: []const u8, lines: [][]const u8) void {
    var ls = std.mem.tokenizeScalar(u8, content, '\n');
    var i: usize = 0;
    while (ls.next()) |l| {
        lines[i] = l;
        i += 1;
    }
}

pub fn measure_problems(problem_sizes: []usize, last_line: []const u8) void {
    var spaces = std.mem.tokenizeAny(u8, last_line, "*+");
    var i: usize = 0;
    while (spaces.next()) |s| {
        problem_sizes[i] = s.len;
        i += 1;
    }
    problem_sizes[problem_sizes.len - 1] += 1;
}

pub fn parse_puzzles_part_two(alloc: std.mem.Allocator, content: []const u8) ![]Problem {
    const problem_count = count_problems(content);
    const problem_sizes = try alloc.alloc(usize, problem_count);
    defer alloc.free(problem_sizes);
    const lines = try alloc.alloc([]const u8, std.mem.count(u8, content, "\n") + 1);
    defer alloc.free(lines);
    split_lines(content, lines);
    measure_problems(problem_sizes, lines[lines.len - 1]);

    var problems = try std.ArrayList(Problem).initCapacity(alloc, problem_count);
    for (problem_sizes) |size| {
        var problem = try problems.addOne(alloc);
        problem.numbers = try std.ArrayList(isize).initCapacity(alloc, size);
        for (0..size) |_| {
            (try problem.numbers.addOne(alloc)).* = 0;
        }
        problem.operation = .add;
    }

    var problem_start: usize = 0;
    for (problems.items, problem_sizes) |*problem, problem_size| {
        for (0..problem_size) |number| {
            for (0.., lines) |line_idx, line| {
                if (line_idx == lines.len - 1) {
                    problem.operation = if (line[problem_start] == '*') .multiply else .add;
                } else {
                    if (line[problem_start + number] != ' ') {
                        problem.numbers.items[number] *= 10;
                        problem.numbers.items[number] += line[problem_start + number] - '0';
                    }
                }
            }
        }
        problem_start += problem_size + 1;
    }
    return problems.toOwnedSlice(alloc);
}
