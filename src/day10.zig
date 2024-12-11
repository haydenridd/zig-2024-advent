const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

var memory_buf: [1024]u8 = undefined;
var fb_alloc = std.heap.FixedBufferAllocator.init(&memory_buf);
var arena_alloc = std.heap.ArenaAllocator.init(fb_alloc.allocator());

const Point = struct {
    row: u32,
    col: u32,
};

const ValidMovementIter = struct {
    const DirToTry = enum(u3) { N = 0, E = 1, S = 2, W = 3, DONE = 4 };
    point: Point,
    array: []const []const u8,
    _curr_dir_to_try: DirToTry = .N,

    pub fn next(self: *ValidMovementIter) ?Point {
        while (self._curr_dir_to_try != .DONE) {
            if (self.isValid(self._curr_dir_to_try)) |pt| {
                self._curr_dir_to_try = @enumFromInt(@intFromEnum(self._curr_dir_to_try) + 1);
                return pt;
            } else {
                self._curr_dir_to_try = @enumFromInt(@intFromEnum(self._curr_dir_to_try) + 1);
            }
        }
        return null;
    }

    fn isValid(self: ValidMovementIter, dir: DirToTry) ?Point {
        const curr_val = std.fmt.parseUnsigned(u4, self.array[self.point.row][self.point.col .. self.point.col + 1], 10) catch |err| {
            switch (err) {
                error.InvalidCharacter => {
                    std.debug.panic("Invalid character: {c}", .{self.array[self.point.row][self.point.col]});
                },
                else => unreachable,
            }
        };
        const next_pt: Point = v: {
            switch (dir) {
                .N => {
                    if (self.point.row == 0) return null;
                    break :v .{ .row = self.point.row - 1, .col = self.point.col };
                },
                .E => {
                    if (self.point.col == self.array[0].len - 1) return null;
                    break :v .{ .row = self.point.row, .col = self.point.col + 1 };
                },
                .S => {
                    if (self.point.row == self.array.len - 1) return null;
                    break :v .{ .row = self.point.row + 1, .col = self.point.col };
                },
                .W => {
                    if (self.point.col == 0) return null;
                    break :v .{ .row = self.point.row, .col = self.point.col - 1 };
                },
                else => unreachable,
            }
        };
        const next_val = std.fmt.parseInt(u4, self.array[next_pt.row][next_pt.col .. next_pt.col + 1], 10) catch |err| {
            switch (err) {
                error.InvalidCharacter => {
                    std.debug.panic("Invalid character: {c}", .{self.array[next_pt.row][next_pt.col]});
                },
                else => unreachable,
            }
        };
        if (next_val != (curr_val + 1)) return null else return next_pt;
    }
};

test "ValidMovementIter" {
    const arr: []const []const u8 = &.{
        &.{ '0', '1', '2' },
        &.{ '1', '2', '3' },
    };

    var vmi: ValidMovementIter = .{ .point = .{ .row = 0, .col = 0 }, .array = arr };
    try std.testing.expectEqual(Point{ .row = 0, .col = 1 }, vmi.next());
    try std.testing.expectEqual(Point{ .row = 1, .col = 0 }, vmi.next());
    vmi = .{ .point = .{ .row = 0, .col = 2 }, .array = arr };
    try std.testing.expectEqual(Point{ .row = 1, .col = 2 }, vmi.next());
    try std.testing.expectEqual(null, vmi.next());
}

const part1 = struct {
    const PeaksHash = std.AutoHashMap(Point, void);

    fn answer(comptime test_input: bool) !usize {
        var dla = try helpers.file.DelimitedArray('\n', 54, 54).fromAdventDay(10, test_input);
        const array = dla.slice();
        var ans: usize = 0;
        for (array, 0..) |row, row_idx| {
            for (row, 0..) |val, col_idx| {
                if (val == '0') {
                    var phash = PeaksHash.init(arena_alloc.allocator());
                    defer phash.deinit();
                    ans += try countPeaks(.{ .row = @as(u32, @truncate(row_idx)), .col = @as(u32, @truncate(col_idx)) }, array, &phash);
                }
            }
        }
        return ans;
    }

    fn countPeaks(point: Point, array: []const []u8, peaks: *PeaksHash) !usize {
        var ans: usize = 0;
        var vmi: ValidMovementIter = .{ .point = point, .array = array };
        // std.debug.print("    Examine: {d},{d}\n", .{ point.row, point.col });
        while (vmi.next()) |pt| {
            ans += try countPeaks(pt, array, peaks);
        }
        // End condition
        if (array[point.row][point.col] == '9') {
            const gop = try peaks.getOrPut(point);
            if (!gop.found_existing) {
                ans += 1;
                // std.debug.print("        Found peak: {d},{d}\n", .{ point.row, point.col });
            }
        }
        return ans;
    }

    test "part1" {
        try std.testing.expectEqual(36, try answer(true));
    }
};

const part2 = struct {
    fn countPeaksDistinct(point: Point, array: []const []u8) !usize {
        var ans: usize = 0;
        var vmi: ValidMovementIter = .{ .point = point, .array = array };
        // std.debug.print("    Examine: {d},{d}\n", .{ point.row, point.col });
        while (vmi.next()) |pt| {
            ans += try countPeaksDistinct(pt, array);
        }
        // End condition
        if (array[point.row][point.col] == '9') {
            ans += 1;
        }
        return ans;
    }

    fn answer(comptime test_input: bool) !usize {
        var dla = try helpers.file.DelimitedArray('\n', 54, 54).fromAdventDay(10, test_input);
        const array = dla.slice();
        var ans: usize = 0;
        for (array, 0..) |row, row_idx| {
            for (row, 0..) |val, col_idx| {
                if (val == '0') {
                    ans += try countPeaksDistinct(.{ .row = @as(u32, @truncate(row_idx)), .col = @as(u32, @truncate(col_idx)) }, array);
                }
            }
        }
        return ans;
    }

    test "part2" {
        try std.testing.expectEqual(81, try answer(true));
    }
};

fn calculateAnswer() ![2]usize {
    const answer1: usize = try part1.answer(false);
    const answer2: usize = try part2.answer(false);

    return .{ answer1, answer2 };
}

pub fn main() !void {
    const answer = try calculateAnswer();
    std.log.info("Answer part 1: {d}", .{answer[0]});
    std.log.info("Answer part 2: {?}", .{answer[1]});
}

comptime {
    std.testing.refAllDecls(part1);
    std.testing.refAllDecls(part2);
}
