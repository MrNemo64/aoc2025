const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const file_path = if (args.len >= 2) args[1] else "day4.in";

    const content = try std.fs.cwd().readFileAlloc(alloc, file_path, 64 * 1024);
    defer alloc.free(content);

    const size = measure_grid(content);
    const grid_cells = try alloc.alloc(Grid.Cell, size.rows * size.columns);
    defer alloc.free(grid_cells);

    populate_grid(content, grid_cells);

    var grid = Grid.init(grid_cells, size);

    //grid.show(false);

    var movable: usize = 0;
    for (0..size.rows) |row| {
        for (0..size.columns) |column| {
            if (grid.can_be_moved(row, column)) {
                movable += 1;
            }
        }
    }
    std.debug.print("Solution part one: {d}\n", .{movable});

    movable = 0;
    const buff: []Position = try alloc.alloc(Position, grid_cells.len);
    defer alloc.free(buff);

    var to_remove = std.ArrayList(Position).initBuffer(buff);
    while (true) {
        for (0..size.rows) |row| {
            for (0..size.columns) |column| {
                if (grid.can_be_moved(row, column)) {
                    movable += 1;
                    try to_remove.append(alloc, Position{ .row = row, .column = column });
                }
            }
        }
        if (to_remove.items.len == 0) {
            break;
        }
        for (to_remove.items) |pos| {
            grid.access_slot(pos.row, pos.column).?.* = .empty;
        }
        to_remove.clearRetainingCapacity();
    }

    std.debug.print("Solution part two: {d}\n", .{movable});
}

pub fn populate_grid(content: []const u8, grid: []Grid.Cell) void {
    var i: usize = 0;
    for (content) |char| {
        if (char == '@') {
            grid[i] = .paper;
            i += 1;
        } else if (char == '.') {
            grid[i] = .empty;
            i += 1;
        }
    }
}

const GridSize = struct {
    rows: usize,
    columns: usize,
};

const Position = struct {
    row: usize,
    column: usize,
};

pub fn measure_grid(content: []const u8) GridSize {
    var size: usize = 0;
    var row_size: ?usize = null;
    for (content) |char| {
        if (char == '@' or char == '.') {
            size += 1;
        }
        if (char == '\n' and row_size == null) {
            row_size = size;
        }
    }
    return GridSize{
        .rows = size / row_size.?,
        .columns = row_size.?,
    };
}

const Grid = struct {
    const Cell = enum {
        paper,
        empty,
    };

    grid: []Cell,
    size: GridSize,

    pub fn init(grid: []Cell, size: GridSize) Grid {
        return Grid{
            .grid = grid,
            .size = size,
        };
    }

    pub fn slot(self: *const Grid, row: usize, column: usize) ?Cell {
        const position = row * self.size.columns + column;
        return if (position < self.grid.len) self.grid[position] else null;
    }

    pub fn access_slot(self: *Grid, row: usize, column: usize) ?*Cell {
        const position = row * self.size.columns + column;
        return if (position < self.grid.len) &self.grid[position] else null;
    }

    pub fn slot_with_offset(self: *const Grid, row: usize, column: usize, row_offset: isize, column_offset: isize) ?Cell {
        const signed_row: isize = @intCast(row);
        const signed_column: isize = @intCast(column);

        if (signed_row + row_offset < 0 or signed_row + row_offset >= self.size.rows) {
            return null;
        }
        if (signed_column + column_offset < 0 or signed_column + column_offset >= self.size.columns) {
            return null;
        }

        const final_row: usize = @intCast(signed_row + row_offset);
        const final_column: usize = @intCast(signed_column + column_offset);

        return self.slot(final_row, final_column);
    }

    pub fn can_be_moved(self: *const Grid, row: usize, column: usize) bool {
        if (self.slot(row, column)) |cell| {
            if (cell == .empty) {
                return false;
            }
        }

        var papers_arround: u8 = 0;

        var neighbour_row_offset: isize = -1;

        while (neighbour_row_offset < 2) {
            var neighbour_column_offset: isize = -1;
            while (neighbour_column_offset < 2) {
                if (neighbour_column_offset != 0 or neighbour_row_offset != 0) {
                    if (self.slot_with_offset(row, column, neighbour_row_offset, neighbour_column_offset)) |cell| {
                        if (cell == .paper) {
                            papers_arround += 1;
                        }
                    }
                }
                neighbour_column_offset += 1;
            }
            neighbour_row_offset += 1;
        }
        return papers_arround < 4;
    }

    pub fn show(self: *const Grid, mark_movable: bool) void {
        for (0..self.size.rows) |row| {
            for (0..self.size.columns) |column| {
                var char: u8 = if (self.slot(row, column).? == .empty) '.' else '@';
                if (mark_movable and self.can_be_moved(row, column)) {
                    char = 'x';
                }
                std.debug.print("{c}", .{char});
            }
            std.debug.print("\n", .{});
        }
    }
};
