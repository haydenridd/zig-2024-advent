const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const part1 = struct {
    fn reportIsSafe(report: []const usize) bool {
        assert(report.len >= 2);
        const dir: enum { INC, DEC } = if (report[0] > report[1]) .DEC else if (report[0] < report[1]) .INC else return false;
        for (0..report.len - 1) |idx| {
            const curr = report[idx];
            const next = report[idx + 1];
            if (curr == next) return false;
            switch (dir) {
                .INC => if (next < curr) return false,
                .DEC => if (next > curr) return false,
            }
            const delta = @abs(@as(isize, @intCast(next)) - @as(isize, @intCast(curr)));
            if (delta > 3) return false;
        }

        return true;
    }

    fn countSafeReports(comptime test_input: bool) !usize {
        var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(2, test_input);
        defer file_line_reader.deinit();
        var safe_count: usize = 0;
        while (file_line_reader.next()) |line| {
            var report_buf = std.BoundedArray(usize, 20).init(0) catch unreachable;
            var iter = std.mem.tokenizeScalar(u8, line, ' ');
            while (iter.next()) |tok| {
                try report_buf.append(try std.fmt.parseInt(usize, tok, 10));
            }
            if (reportIsSafe(report_buf.constSlice())) safe_count += 1;
        }
        return safe_count;
    }

    test "reportIsSafe" {
        try std.testing.expectEqual(true, reportIsSafe(&.{ 7, 6, 4, 2, 1 }));
        try std.testing.expectEqual(false, reportIsSafe(&.{ 1, 2, 7, 8, 9 }));
        try std.testing.expectEqual(false, reportIsSafe(&.{ 1, 3, 2, 4, 5 }));
    }

    test "part1" {
        try std.testing.expectEqual(2, countSafeReports(true));
    }
};

const part2 = struct {
    fn reportIsSafeWithSingleException(report: []const usize) bool {
        if (part1.reportIsSafe(report)) return true;

        for (0..report.len) |idx_to_remove| {
            var report_buf = std.BoundedArray(usize, 20).init(0) catch unreachable;
            report_buf.appendSlice(report) catch unreachable;
            _ = report_buf.orderedRemove(idx_to_remove);
            if (part1.reportIsSafe(report_buf.constSlice())) return true;
        }
        return false;
    }

    fn countSafeReports(comptime test_input: bool) !usize {
        var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(2, test_input);
        defer file_line_reader.deinit();
        var safe_count: usize = 0;
        while (file_line_reader.next()) |line| {
            var report_buf = std.BoundedArray(usize, 20).init(0) catch unreachable;
            var iter = std.mem.tokenizeScalar(u8, line, ' ');
            while (iter.next()) |tok| {
                try report_buf.append(try std.fmt.parseInt(usize, tok, 10));
            }

            const safe = reportIsSafeWithSingleException(report_buf.constSlice());
            // std.debug.print("Report: {s} Safe: {}\n", .{ line, safe });
            if (safe) safe_count += 1;
        }
        return safe_count;
    }

    test "reportIsSafeWithSingleException" {
        try std.testing.expectEqual(true, reportIsSafeWithSingleException(&.{ 7, 6, 4, 2, 1 }));
        try std.testing.expectEqual(false, reportIsSafeWithSingleException(&.{ 1, 2, 7, 8, 9 }));
        try std.testing.expectEqual(false, reportIsSafeWithSingleException(&.{ 9, 7, 6, 2, 1 }));
        try std.testing.expectEqual(true, reportIsSafeWithSingleException(&.{ 1, 3, 2, 4, 5 }));
        try std.testing.expectEqual(true, reportIsSafeWithSingleException(&.{ 8, 6, 4, 4, 1 }));
        try std.testing.expectEqual(true, reportIsSafeWithSingleException(&.{ 1, 3, 6, 7, 9 }));
        try std.testing.expectEqual(true, reportIsSafeWithSingleException(&.{ 1, 1, 4, 7, 9 }));
        try std.testing.expectEqual(true, reportIsSafeWithSingleException(&.{ 1, 2, 4, 7, 7 }));
        try std.testing.expectEqual(true, reportIsSafeWithSingleException(&.{ 1, 2, 4, 7, 12 }));
    }

    test "part2" {
        try std.testing.expectEqual(4, countSafeReports(true));
    }
};

fn calculateAnswer() ![2]usize {
    const answer1: usize = try part1.countSafeReports(false);
    const answer2: usize = try part2.countSafeReports(false);

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
