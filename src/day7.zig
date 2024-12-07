const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const OperandArray = std.BoundedArray(usize, 20);

const part1 = struct {
    fn isPossible(result: usize, operands: OperandArray) bool {

        // End Condition
        const oslice = operands.constSlice();
        if (operands.len == 2) {
            if (oslice[0] * oslice[1] == result) return true;
            return oslice[0] + oslice[1] == result;
        }

        // *
        const mult_arr = v: {
            var tmp = OperandArray.init(0) catch unreachable;
            tmp.append(oslice[0] * oslice[1]) catch unreachable;
            tmp.appendSlice(oslice[2..]) catch unreachable;
            break :v tmp;
        };
        if (isPossible(result, mult_arr)) return true;

        // +
        const plus_arr = v: {
            var tmp = OperandArray.init(0) catch unreachable;
            tmp.append(oslice[0] + oslice[1]) catch unreachable;
            tmp.appendSlice(oslice[2..]) catch unreachable;
            break :v tmp;
        };
        return isPossible(result, plus_arr);
    }

    fn answer(comptime test_input: bool) !usize {
        var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(7, test_input);
        defer file_line_reader.deinit();
        var ans: usize = 0;
        while (file_line_reader.next()) |line| {
            const col_idx = std.mem.indexOfScalar(u8, line, ':').?;
            const test_val = try std.fmt.parseInt(usize, line[0..col_idx], 10);
            var tok = std.mem.tokenizeScalar(u8, line[col_idx + 1 ..], ' ');
            var operand_arr = OperandArray.init(0) catch unreachable;
            while (tok.next()) |v| {
                try operand_arr.append(try std.fmt.parseInt(usize, v, 10));
            }
            if (isPossible(test_val, operand_arr)) ans += test_val;
        }
        return ans;
    }
    test "part1" {
        try std.testing.expectEqual(3749, answer(true));
    }
};

const part2 = struct {
    fn concatInt(one: usize, two: usize) usize {
        var combined = std.BoundedArray(u8, 50).init(0) catch unreachable;
        std.fmt.formatInt(one, 10, .lower, .{}, combined.writer()) catch unreachable;
        std.fmt.formatInt(two, 10, .lower, .{}, combined.writer()) catch unreachable;
        return std.fmt.parseInt(usize, combined.constSlice(), 10) catch unreachable;
    }

    test "concatInt" {
        try std.testing.expectEqual(12, concatInt(1, 2));
        try std.testing.expectEqual(1224, concatInt(12, 24));
    }

    fn isPossible(result: usize, operands: OperandArray) bool {

        // End Condition
        const oslice = operands.constSlice();
        if (operands.len == 2) {
            if (oslice[0] * oslice[1] == result) return true;
            if (oslice[0] + oslice[1] == result) return true;
            return concatInt(oslice[0], oslice[1]) == result;
        }

        // *
        const mult_arr = v: {
            var tmp = OperandArray.init(0) catch unreachable;
            tmp.append(oslice[0] * oslice[1]) catch unreachable;
            tmp.appendSlice(oslice[2..]) catch unreachable;
            break :v tmp;
        };
        if (isPossible(result, mult_arr)) return true;

        // +
        const plus_arr = v: {
            var tmp = OperandArray.init(0) catch unreachable;
            tmp.append(oslice[0] + oslice[1]) catch unreachable;
            tmp.appendSlice(oslice[2..]) catch unreachable;
            break :v tmp;
        };
        if (isPossible(result, plus_arr)) return true;

        // ||
        const concat_arr = v: {
            var tmp = OperandArray.init(0) catch unreachable;
            tmp.append(concatInt(oslice[0], oslice[1])) catch unreachable;
            tmp.appendSlice(oslice[2..]) catch unreachable;
            break :v tmp;
        };
        return isPossible(result, concat_arr);
    }

    fn answer(comptime test_input: bool) !usize {
        var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(7, test_input);
        defer file_line_reader.deinit();
        var ans: usize = 0;
        while (file_line_reader.next()) |line| {
            const col_idx = std.mem.indexOfScalar(u8, line, ':').?;
            const test_val = try std.fmt.parseInt(usize, line[0..col_idx], 10);
            var tok = std.mem.tokenizeScalar(u8, line[col_idx + 1 ..], ' ');
            var operand_arr = OperandArray.init(0) catch unreachable;
            while (tok.next()) |v| {
                try operand_arr.append(try std.fmt.parseInt(usize, v, 10));
            }
            if (isPossible(test_val, operand_arr)) ans += test_val;
        }
        return ans;
    }
    test "part2" {
        try std.testing.expectEqual(11387, answer(true));
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
