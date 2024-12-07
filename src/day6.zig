const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const Location = struct { row: usize, col: usize, dir: enum { N, E, S, W } };
const LocArray = std.BoundedArray(Location, 10000);
const Position = struct { row: usize, col: usize };
const PosArray = std.BoundedArray(Position, 10000);

const part1 = struct {
    fn guardsPath(comptime test_input: bool) !PosArray {
        var dla = try helpers.file.DelimitedArray('\n', 130, 130).fromAdventDay(6, test_input);
        const slice = dla.slice();

        var ret = PosArray.init(0) catch unreachable;

        var guard_loc: Location = v: {
            for (slice, 0..) |row, row_idx| {
                if (std.mem.indexOfAny(u8, row, &.{ '^', '>', 'v', '<' })) |col_idx| {
                    break :v .{ .row = row_idx, .col = col_idx, .dir = switch (slice[row_idx][col_idx]) {
                        '^' => .N,
                        '>' => .E,
                        'v' => .S,
                        '<' => .W,
                        else => unreachable,
                    } };
                }
            }
            unreachable;
        };

        loop: while (true) {
            const pos: Position = .{ .col = guard_loc.col, .row = guard_loc.row };
            if (!inPath(pos, ret.constSlice())) try ret.append(pos);
            switch (guard_loc.dir) {
                .N => {
                    if (guard_loc.row == 0) break :loop;
                    if (slice[guard_loc.row - 1][guard_loc.col] == '#') {
                        guard_loc.dir = .E;
                    } else {
                        guard_loc.row -= 1;
                    }
                },
                .E => {
                    if (guard_loc.col == slice[0].len - 1) break :loop;
                    if (slice[guard_loc.row][guard_loc.col + 1] == '#') {
                        guard_loc.dir = .S;
                    } else {
                        guard_loc.col += 1;
                    }
                },
                .S => {
                    if (guard_loc.row == slice.len - 1) break :loop;
                    if (slice[guard_loc.row + 1][guard_loc.col] == '#') {
                        guard_loc.dir = .W;
                    } else {
                        guard_loc.row += 1;
                    }
                },
                .W => {
                    if (guard_loc.col == 0) break :loop;
                    if (slice[guard_loc.row][guard_loc.col - 1] == '#') {
                        guard_loc.dir = .N;
                    } else {
                        guard_loc.col -= 1;
                    }
                },
            }
        }

        return ret;
    }

    fn inPath(loc: Position, path: []const Position) bool {
        for (path) |v| {
            if ((v.col == loc.col) and (v.row == loc.row)) return true;
        }
        return false;
    }

    fn answer(comptime test_input: bool) !usize {
        const ret = try guardsPath(test_input);
        return ret.len;
    }

    test "part1" {
        try std.testing.expectEqual(41, answer(true));
    }
};

const part2 = struct {
    var location_tracker = LocArray.init(0) catch unreachable;

    fn inLocationTracker(loc: Location) bool {
        for (location_tracker.constSlice()) |v| {
            if ((v.col == loc.col) and (v.row == loc.row) and (v.dir == loc.dir)) return true;
        }
        return false;
    }

    fn answer(comptime test_input: bool) !usize {
        const guard_path = (try part1.guardsPath(test_input)).constSlice();

        var dla = try helpers.file.DelimitedArray('\n', 130, 130).fromAdventDay(6, test_input);
        const slice = dla.slice();

        var ans: usize = 0;

        var init_loc: Location = .{ .row = guard_path[0].row, .col = guard_path[0].col, .dir = .N };
        switch (slice[guard_path[0].row][guard_path[0].col]) {
            '^' => init_loc.dir = .N,
            '>' => init_loc.dir = .E,
            'v' => init_loc.dir = .S,
            '<' => init_loc.dir = .W,
            else => unreachable,
        }

        for (guard_path) |gp| {

            // Skip existing obstacles/starting pos
            if (slice[gp.row][gp.col] != '.') continue;

            // Change current item to obstacle
            slice[gp.row][gp.col] = '#';

            // Reset tracker for this run
            try location_tracker.resize(0);

            var guard_loc = init_loc;

            const is_loop = loop: while (true) {
                if (inLocationTracker(guard_loc)) {
                    break true;
                }
                try location_tracker.append(guard_loc);
                switch (guard_loc.dir) {
                    .N => {
                        if (guard_loc.row == 0) break :loop false;
                        if (slice[guard_loc.row - 1][guard_loc.col] == '#') {
                            guard_loc.dir = .E;
                        } else {
                            guard_loc.row -= 1;
                        }
                    },
                    .E => {
                        if (guard_loc.col == slice[0].len - 1) break :loop false;
                        if (slice[guard_loc.row][guard_loc.col + 1] == '#') {
                            guard_loc.dir = .S;
                        } else {
                            guard_loc.col += 1;
                        }
                    },
                    .S => {
                        if (guard_loc.row == slice.len - 1) break :loop false;
                        if (slice[guard_loc.row + 1][guard_loc.col] == '#') {
                            guard_loc.dir = .W;
                        } else {
                            guard_loc.row += 1;
                        }
                    },
                    .W => {
                        if (guard_loc.col == 0) break :loop false;
                        if (slice[guard_loc.row][guard_loc.col - 1] == '#') {
                            guard_loc.dir = .N;
                        } else {
                            guard_loc.col -= 1;
                        }
                    },
                }
            };

            // Revert
            slice[gp.row][gp.col] = '.';

            if (is_loop) {
                ans += 1;
            }
        }
        return ans;
    }

    fn answer2(comptime test_input: bool) !usize {
        var dla = try helpers.file.DelimitedArray('\n', 130, 130).fromAdventDay(6, test_input);
        const slice = dla.slice();

        const orig_guard_loc: Location = v: {
            for (slice, 0..) |row, row_idx| {
                if (std.mem.indexOfAny(u8, row, &.{ '^', '>', 'v', '<' })) |col_idx| {
                    break :v .{ .row = row_idx, .col = col_idx, .dir = switch (slice[row_idx][col_idx]) {
                        '^' => .N,
                        '>' => .E,
                        'v' => .S,
                        '<' => .W,
                        else => unreachable,
                    } };
                }
            }
            unreachable;
        };

        var ans: usize = 0;

        for (slice, 0..) |row, row_idx| {
            for (row, 0..) |val, col_idx| {

                // Skip existing obstacles/starting pos
                if (val != '.') continue;

                // Change current item to obstacle
                slice[row_idx][col_idx] = '#';

                // Reset tracker for this run
                try location_tracker.resize(0);

                var guard_loc = orig_guard_loc;

                const is_loop = loop: while (true) {
                    if (inLocationTracker(guard_loc)) {
                        break true;
                    }
                    try location_tracker.append(guard_loc);
                    switch (guard_loc.dir) {
                        .N => {
                            if (guard_loc.row == 0) break :loop false;
                            if (slice[guard_loc.row - 1][guard_loc.col] == '#') {
                                guard_loc.dir = .E;
                            } else {
                                guard_loc.row -= 1;
                            }
                        },
                        .E => {
                            if (guard_loc.col == slice[0].len - 1) break :loop false;
                            if (slice[guard_loc.row][guard_loc.col + 1] == '#') {
                                guard_loc.dir = .S;
                            } else {
                                guard_loc.col += 1;
                            }
                        },
                        .S => {
                            if (guard_loc.row == slice.len - 1) break :loop false;
                            if (slice[guard_loc.row + 1][guard_loc.col] == '#') {
                                guard_loc.dir = .W;
                            } else {
                                guard_loc.row += 1;
                            }
                        },
                        .W => {
                            if (guard_loc.col == 0) break :loop false;
                            if (slice[guard_loc.row][guard_loc.col - 1] == '#') {
                                guard_loc.dir = .N;
                            } else {
                                guard_loc.col -= 1;
                            }
                        },
                    }
                };

                // Revert
                slice[row_idx][col_idx] = '.';

                if (is_loop) {
                    ans += 1;
                }
            }
        }
        return ans;
    }

    test "part2" {
        try std.testing.expectEqual(6, try answer(true));
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
