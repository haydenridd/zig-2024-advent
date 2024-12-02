const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const FileLineIterator = helpers.file.LineIterator(20);

const part1 = struct {
    const Arr = std.BoundedArray(isize, 1100);

    fn sortedInsert(arr: *Arr, item: isize) !void {
        for (arr.constSlice(), 0..) |v, idx| {
            if (item < v) {
                try arr.insert(idx, item);
                return;
            }
        }
        try arr.append(item);
    }

    fn inputIntoArrays(comptime test_input: bool) !struct { l: Arr, r: Arr } {
        var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(1, test_input);
        defer file_line_reader.deinit();

        var left_arr = Arr.init(0) catch unreachable;
        var right_arr = Arr.init(0) catch unreachable;

        while (file_line_reader.next()) |ln| {
            const first_space_idx = std.mem.indexOfScalar(u8, ln, ' ') orelse return error.BadFormat;
            const left_int = try std.fmt.parseInt(isize, ln[0..first_space_idx], 10);
            try sortedInsert(&left_arr, left_int);
            const last_space_idx = std.mem.lastIndexOfScalar(u8, ln, ' ') orelse return error.BadFormat;
            const right_int = try std.fmt.parseInt(isize, ln[last_space_idx + 1 ..], 10);
            try sortedInsert(&right_arr, right_int);
        }

        assert(left_arr.len == right_arr.len);
        return .{ .l = left_arr, .r = right_arr };
    }

    fn answer(comptime test_input: bool) !usize {
        const arrays = try inputIntoArrays(test_input);
        var ans: usize = 0;
        for (arrays.l.constSlice(), arrays.r.constSlice()) |l, r| {
            ans += @abs(l - r);
        }
        return ans;
    }

    test "part1" {
        try std.testing.expectEqual(11, try answer(true));
    }
};

const part2 = struct {
    fn countInSortedSlice(item: isize, slice: []const isize) usize {
        var count: usize = 0;
        for (slice) |v| {
            if (item == v) count += 1;
            if (v > item) return count;
        }
        return count;
    }

    fn answer(comptime test_input: bool) !usize {
        const arrays = try part1.inputIntoArrays(test_input);

        var ans: usize = 0;

        for (arrays.l.constSlice()) |v| {
            ans += @as(usize, @intCast(v)) * countInSortedSlice(v, arrays.r.constSlice());
        }

        return ans;
    }

    test "part2" {
        try std.testing.expectEqual(31, answer(true));
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
