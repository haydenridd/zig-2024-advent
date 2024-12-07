const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const part1 = struct {
    fn answer(comptime test_input: bool) !usize {
        var dla = try helpers.file.DelimitedArray('\n', 145, 140).fromAdventDay(4, test_input);
        const arr = dla.slice();

        var ans: usize = 0;

        const max_col = arr[0].len;
        const max_row = arr.len;
        for (arr, 0..) |row, row_idx| {
            for (row, 0..) |letter, col_idx| {
                if (letter == 'X') {

                    // N
                    if (row_idx >= 3) {
                        if ((arr[row_idx - 1][col_idx] == 'M') and
                            (arr[row_idx - 2][col_idx] == 'A') and
                            (arr[row_idx - 3][col_idx] == 'S'))
                            ans += 1;
                    }

                    // NE
                    if ((row_idx >= 3) and (col_idx + 3 < max_col)) {
                        if ((arr[row_idx - 1][col_idx + 1] == 'M') and
                            (arr[row_idx - 2][col_idx + 2] == 'A') and
                            (arr[row_idx - 3][col_idx + 3] == 'S'))
                            ans += 1;
                    }

                    // E
                    if (col_idx + 3 < max_col) {
                        if ((arr[row_idx][col_idx + 1] == 'M') and
                            (arr[row_idx][col_idx + 2] == 'A') and
                            (arr[row_idx][col_idx + 3] == 'S'))
                            ans += 1;
                    }

                    // SE
                    if ((row_idx + 3 < max_row) and (col_idx + 3 < max_col)) {
                        if ((arr[row_idx + 1][col_idx + 1] == 'M') and
                            (arr[row_idx + 2][col_idx + 2] == 'A') and
                            (arr[row_idx + 3][col_idx + 3] == 'S'))
                            ans += 1;
                    }

                    // S
                    if (row_idx + 3 < max_row) {
                        if ((arr[row_idx + 1][col_idx] == 'M') and
                            (arr[row_idx + 2][col_idx] == 'A') and
                            (arr[row_idx + 3][col_idx] == 'S'))
                            ans += 1;
                    }

                    // SW
                    if ((row_idx + 3 < max_row) and (col_idx >= 3)) {
                        if ((arr[row_idx + 1][col_idx - 1] == 'M') and
                            (arr[row_idx + 2][col_idx - 2] == 'A') and
                            (arr[row_idx + 3][col_idx - 3] == 'S'))
                            ans += 1;
                    }

                    // W
                    if (col_idx >= 3) {
                        if ((arr[row_idx][col_idx - 1] == 'M') and
                            (arr[row_idx][col_idx - 2] == 'A') and
                            (arr[row_idx][col_idx - 3] == 'S'))
                            ans += 1;
                    }

                    // NW
                    if ((row_idx >= 3) and (col_idx >= 3)) {
                        if ((arr[row_idx - 1][col_idx - 1] == 'M') and
                            (arr[row_idx - 2][col_idx - 2] == 'A') and
                            (arr[row_idx - 3][col_idx - 3] == 'S'))
                            ans += 1;
                    }
                }
            }
        }
        return ans;
    }

    test "part1" {
        try std.testing.expectEqual(18, try answer(true));
    }
};

const part2 = struct {
    fn answer(comptime test_input: bool) !usize {
        var dla = try helpers.file.DelimitedArray('\n', 145, 140).fromAdventDay(4, test_input);
        const arr = dla.slice();

        var ans: usize = 0;

        const max_col = arr[0].len;
        const max_row = arr.len;
        for (arr, 0..) |row, row_idx| {
            for (row, 0..) |letter, col_idx| {
                if (letter == 'M') {
                    if ((row_idx + 2 < max_row) and (col_idx + 2 < max_col)) {

                        // M.S
                        // .A.
                        // M.S
                        if ((arr[row_idx][col_idx + 2] == 'S') and
                            (arr[row_idx + 1][col_idx + 1] == 'A') and
                            (arr[row_idx + 2][col_idx] == 'M') and
                            (arr[row_idx + 2][col_idx + 2] == 'S'))
                            ans += 1;

                        // M.M
                        // .A.
                        // S.S
                        if ((arr[row_idx][col_idx + 2] == 'M') and
                            (arr[row_idx + 1][col_idx + 1] == 'A') and
                            (arr[row_idx + 2][col_idx] == 'S') and
                            (arr[row_idx + 2][col_idx + 2] == 'S'))
                            ans += 1;
                    }

                    if ((row_idx + 2 < max_row) and (col_idx >= 2)) {

                        // S.M
                        // .A.
                        // S.M
                        if ((arr[row_idx][col_idx - 2] == 'S') and
                            (arr[row_idx + 1][col_idx - 1] == 'A') and
                            (arr[row_idx + 2][col_idx] == 'M') and
                            (arr[row_idx + 2][col_idx - 2] == 'S'))
                            ans += 1;
                    }

                    if ((row_idx >= 2) and (col_idx + 2 < max_col)) {

                        // S.S
                        // .A.
                        // M.M
                        if ((arr[row_idx][col_idx + 2] == 'M') and
                            (arr[row_idx - 1][col_idx + 1] == 'A') and
                            (arr[row_idx - 2][col_idx] == 'S') and
                            (arr[row_idx - 2][col_idx + 2] == 'S'))
                            ans += 1;
                    }
                }
            }
        }
        return ans;
    }
    test "part2" {
        try std.testing.expectEqual(9, try answer(true));
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
