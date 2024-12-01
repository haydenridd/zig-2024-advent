const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const part1 = struct {
    test "part1" {}
};

const part2 = struct {
    test "part2" {}
};

fn calculateAnswer() ![2]usize {
    var answer1: usize = 0;
    var answer2: usize = 0;

    var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(1, false);
    defer file_line_reader.deinit();
    while (file_line_reader.next()) |line| {
        _ = line;
    }

    answer1 = 0;
    answer2 = 0;

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
