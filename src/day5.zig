const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const part1 = struct {
    fn answer(comptime test_input: bool) !usize {
        var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(5, test_input);
        defer file_line_reader.deinit();
        var in_lists = false;

        var rule_arr: [100]std.BoundedArray(u8, 40) = undefined;
        for (&rule_arr) |*itm| {
            itm.* = std.BoundedArray(u8, 40).init(0) catch unreachable;
        }

        var ans: usize = 0;
        while (file_line_reader.next()) |line| {
            if (in_lists) {
                var arr_to_check = std.BoundedArray(u8, 40).init(0) catch unreachable;
                var itr = std.mem.tokenizeScalar(u8, line, ',');
                while (itr.next()) |v| {
                    try arr_to_check.append(try std.fmt.parseInt(u8, v, 10));
                }

                const valid = v: {
                    for (arr_to_check.constSlice(), 0..) |v, idx| {
                        for (arr_to_check.constSlice()[idx + 1 ..]) |other_v| {
                            if (rule_arr[other_v].len > 0) {
                                if (std.mem.indexOfScalar(u8, rule_arr[other_v].constSlice(), v)) |_| break :v false;
                            }
                        }
                    }
                    break :v true;
                };

                if (valid) ans += arr_to_check.constSlice()[arr_to_check.len / 2];
            } else {
                if (line.len == 0) {
                    in_lists = true;
                } else {
                    var itr = std.mem.tokenizeScalar(u8, line, '|');
                    const key = try std.fmt.parseInt(usize, itr.next().?, 10);
                    const val = try std.fmt.parseInt(u8, itr.next().?, 10);
                    try rule_arr[key].append(val);
                }
            }
        }
        return ans;
    }
    test "part1" {
        try std.testing.expectEqual(143, answer(true));
    }
};

const part2 = struct {
    fn answer(comptime test_input: bool) !usize {
        var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(5, test_input);
        defer file_line_reader.deinit();
        var in_lists = false;

        var rule_arr: [100]std.BoundedArray(u8, 40) = undefined;
        for (&rule_arr) |*itm| {
            itm.* = std.BoundedArray(u8, 40).init(0) catch unreachable;
        }

        var ans: usize = 0;
        while (file_line_reader.next()) |line| {
            if (in_lists) {
                var arr_to_check = std.BoundedArray(u8, 40).init(0) catch unreachable;
                var itr = std.mem.tokenizeScalar(u8, line, ',');
                while (itr.next()) |v| {
                    try arr_to_check.append(try std.fmt.parseInt(u8, v, 10));
                }

                const valid = v: {
                    for (arr_to_check.constSlice(), 0..) |v, idx| {
                        for (arr_to_check.constSlice()[idx + 1 ..]) |other_v| {
                            if (rule_arr[other_v].len > 0) {
                                if (std.mem.indexOfScalar(u8, rule_arr[other_v].constSlice(), v)) |_| break :v false;
                            }
                        }
                    }
                    break :v true;
                };

                if (!valid) {
                    a: while (true) {
                        const swap_indices: ?struct { first: usize, second: usize } = v: {
                            for (arr_to_check.constSlice(), 0..) |v, idx| {
                                for (arr_to_check.constSlice()[idx + 1 ..], 0..) |other_v, other_idx| {
                                    if (rule_arr[other_v].len > 0) {
                                        if (std.mem.indexOfScalar(u8, rule_arr[other_v].constSlice(), v)) |_| {
                                            break :v .{ .first = idx, .second = other_idx + idx + 1 };
                                        }
                                    }
                                }
                            }
                            break :v null;
                        };
                        if (swap_indices) |si| {
                            const repl = arr_to_check.orderedRemove(si.first);
                            try arr_to_check.insert(si.second, repl);
                        } else break :a;
                    }
                    ans += arr_to_check.constSlice()[arr_to_check.len / 2];
                }
            } else {
                if (line.len == 0) {
                    in_lists = true;
                } else {
                    var itr = std.mem.tokenizeScalar(u8, line, '|');
                    const key = try std.fmt.parseInt(usize, itr.next().?, 10);
                    const val = try std.fmt.parseInt(u8, itr.next().?, 10);
                    try rule_arr[key].append(val);
                }
            }
        }
        return ans;
    }

    test "part2" {
        try std.testing.expectEqual(123, try answer(true));
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
