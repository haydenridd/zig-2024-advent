const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

fn UniquePairsIter(T: type) type {
    return struct {
        items: []const T,
        _idx0: usize = 0,
        _idx1: usize = 1,
        const Self = @This();

        pub fn next(self: *Self) ?[2]T {
            assert(self.items.len >= 2);
            if (self._idx0 >= self.items.len - 1) return null;
            const ret = [2]T{ self.items[self._idx0], self.items[self._idx1] };
            if (self._idx1 == self.items.len - 1) {
                self._idx0 += 1;
                self._idx1 = self._idx0 + 1;
            } else {
                self._idx1 += 1;
            }
            return ret;
        }
    };
}

test "UniquePairsIter" {
    const UPI = UniquePairsIter(u8);
    const items: []const u8 = &.{ 'a', 'b', 'c', 'd' };
    var upi: UPI = .{ .items = items };
    try std.testing.expectEqualSlices(u8, &.{ 'a', 'b' }, &(upi.next().?));
    try std.testing.expectEqualSlices(u8, &.{ 'a', 'c' }, &(upi.next().?));
    try std.testing.expectEqualSlices(u8, &.{ 'a', 'd' }, &(upi.next().?));
    try std.testing.expectEqualSlices(u8, &.{ 'b', 'c' }, &(upi.next().?));
    try std.testing.expectEqualSlices(u8, &.{ 'b', 'd' }, &(upi.next().?));
    try std.testing.expectEqualSlices(u8, &.{ 'c', 'd' }, &(upi.next().?));
    try std.testing.expectEqual(null, upi.next());
}

var memory_buf: [65536]u8 = undefined;
var fb_alloc = std.heap.FixedBufferAllocator.init(&memory_buf);
var arena_alloc = std.heap.ArenaAllocator.init(fb_alloc.allocator());

const Point = struct { row: i32, col: i32 };
const PointArr = std.ArrayList(Point);
const AntennaPoints = std.AutoHashMap(u8, PointArr);
const Input = struct { antenna_points: AntennaPoints, bounds: Point };

fn parseInput(comptime test_input: bool, allocator: std.mem.Allocator) !Input {
    var ret = AntennaPoints.init(allocator);

    var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(8, test_input);
    defer file_line_reader.deinit();
    var row: i32 = 0;
    var col_len: ?i32 = null;

    while (file_line_reader.next()) |line| {
        if (col_len) |_| {} else col_len = @as(i32, @intCast(line.len));
        if (!std.mem.allEqual(u8, line, '.')) {
            for (line, 0..) |char, col| {
                if (char != '.') {
                    const gop = try ret.getOrPut(char);
                    if (!gop.found_existing) {
                        gop.value_ptr.* = PointArr.init(allocator);
                    }
                    try gop.value_ptr.append(.{ .row = row, .col = @as(i32, @intCast(col)) });
                }
            }
        }
        row += 1;
    }

    return .{ .antenna_points = ret, .bounds = .{ .row = row, .col = col_len.? } };
}

fn outOfBounds(point: Point, bounds: Point) bool {
    return (point.col < 0) or
        (point.row < 0) or
        (point.col >= bounds.col) or
        (point.row >= bounds.row);
}

const part1 = struct {
    fn answer(comptime test_input: bool, allocator: std.mem.Allocator) !usize {
        const in = try parseInput(test_input, allocator);
        const ap = in.antenna_points;
        var ap_iter = ap.iterator();

        var point_tracker = std.AutoHashMap(Point, void).init(allocator);

        while (ap_iter.next()) |entry| {
            var pt_combo_iter = UniquePairsIter(Point){ .items = entry.value_ptr.items };

            while (pt_combo_iter.next()) |pt_combo| {
                // Find slope in terms of the smallest whole integer delta row, delta col number
                var slope: Point = .{
                    .row = pt_combo[0].row - pt_combo[1].row,
                    .col = pt_combo[0].col - pt_combo[1].col,
                };

                if ((@rem(slope.row, slope.col) == 0)) {
                    slope.row = @divExact(slope.row, slope.col);
                    slope.col = @divExact(slope.col, slope.col);
                } else if (@rem(slope.col, slope.row) == 0) {
                    slope.col = @divExact(slope.col, slope.row);
                    slope.row = @divExact(slope.row, slope.row);
                }

                // Iterate negatively, then positively in multiples of 1x slope from first antenna point until out of bounds
                inline for (&.{ -1, 1 }) |dir| {
                    var pos: Point = .{ .row = pt_combo[0].row + dir * slope.row, .col = pt_combo[0].col + dir * slope.col };
                    while (!outOfBounds(pos, in.bounds)) {
                        const dist_antenna1: Point = .{ .row = @intCast(@abs(pos.row - pt_combo[0].row)), .col = @intCast(@abs(pos.col - pt_combo[0].col)) };
                        const dist_antenna2: Point = .{ .row = @intCast(@abs(pos.row - pt_combo[1].row)), .col = @intCast(@abs(pos.col - pt_combo[1].col)) };

                        // Check if one is 2x distance multiple of other
                        if (((dist_antenna1.row == 2 * dist_antenna2.row) and (dist_antenna1.col == 2 * dist_antenna2.col)) or
                            ((dist_antenna2.row == 2 * dist_antenna1.row) and (dist_antenna2.col == 2 * dist_antenna1.col)))
                        {
                            try point_tracker.put(pos, {});
                        }
                        pos.row += dir * slope.row;
                        pos.col += dir * slope.col;
                    }
                }
            }
        }
        return point_tracker.count();
    }

    test "part1" {
        try std.testing.expectEqual(14, try answer(true, arena_alloc.allocator()));
    }
};

const part2 = struct {
    fn answer(comptime test_input: bool, allocator: std.mem.Allocator) !usize {
        const in = try parseInput(test_input, allocator);
        const ap = in.antenna_points;
        var ap_iter = ap.iterator();

        var point_tracker = std.AutoHashMap(Point, void).init(allocator);

        while (ap_iter.next()) |entry| {
            var pt_combo_iter = UniquePairsIter(Point){ .items = entry.value_ptr.items };

            while (pt_combo_iter.next()) |pt_combo| {
                // Find slope in terms of the smallest whole integer delta row, delta col number
                var slope: Point = .{
                    .row = pt_combo[0].row - pt_combo[1].row,
                    .col = pt_combo[0].col - pt_combo[1].col,
                };

                if ((@rem(slope.row, slope.col) == 0)) {
                    slope.row = @divExact(slope.row, slope.col);
                    slope.col = @divExact(slope.col, slope.col);
                } else if (@rem(slope.col, slope.row) == 0) {
                    slope.col = @divExact(slope.col, slope.row);
                    slope.row = @divExact(slope.row, slope.row);
                }

                // Iterate negatively, then positively in multiples of 1x slope from first antenna point until out of bounds
                inline for (&.{ -1, 1 }) |dir| {
                    var pos: Point = .{ .row = pt_combo[0].row, .col = pt_combo[0].col };
                    while (!outOfBounds(pos, in.bounds)) {

                        // Any point on this line is valid
                        try point_tracker.put(pos, {});

                        pos.row += dir * slope.row;
                        pos.col += dir * slope.col;
                    }
                }
            }
        }
        return point_tracker.count();
    }

    test "part2" {
        try std.testing.expectEqual(34, try answer(true, arena_alloc.allocator()));
    }
};

fn calculateAnswer() ![2]usize {
    const answer1: usize = try part1.answer(false, arena_alloc.allocator());
    _ = arena_alloc.reset(.retain_capacity);
    const answer2: usize = try part2.answer(false, arena_alloc.allocator());

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
