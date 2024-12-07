const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const part1 = struct {
    fn isDig(byte: u8) bool {
        return (byte >= '0') and (byte <= '9');
    }

    fn answer(comptime test_input: bool) !usize {
        const fh = try std.fs.cwd().openFile((if (test_input) "test_inputs" else "inputs") ++ "/day3.txt", .{});
        defer fh.close();

        var state: enum { M, U, L, @"(", DIG1, DIG2 } = .M;
        var dig_buf = std.BoundedArray(u8, 3).init(0) catch unreachable;
        var arg1: usize = 0;
        var ans: usize = 0;

        wl: while (true) {
            var byte_buf = [1]u8{0};
            const bytes_read = try fh.read(&byte_buf);
            if (bytes_read == 0) break :wl;
            const byte = byte_buf[0];

            switch (state) {
                .M => {
                    if (byte == 'm') {
                        state = .U;
                    }
                },
                .U => {
                    if (byte == 'u') {
                        state = .L;
                    } else {
                        state = .M;
                    }
                },
                .L => {
                    if (byte == 'l') {
                        state = .@"(";
                    } else {
                        state = .M;
                    }
                },
                .@"(" => {
                    if (byte == '(') {
                        state = .DIG1;
                    } else {
                        state = .M;
                    }
                },
                .DIG1 => {
                    if (isDig(byte)) {
                        dig_buf.append(byte) catch |err| switch (err) {
                            error.Overflow => {
                                dig_buf.resize(0) catch unreachable;
                                state = .M;
                            },
                            else => return err,
                        };
                    } else if (byte == ',') {
                        arg1 = try std.fmt.parseInt(usize, dig_buf.constSlice(), 10);
                        dig_buf.resize(0) catch unreachable;
                        state = .DIG2;
                    } else {
                        dig_buf.resize(0) catch unreachable;
                        state = .M;
                    }
                },
                .DIG2 => {
                    if (isDig(byte)) {
                        dig_buf.append(byte) catch |err| switch (err) {
                            error.Overflow => {
                                dig_buf.resize(0) catch unreachable;
                                state = .M;
                            },
                            else => return err,
                        };
                    } else if (byte == ')') {
                        const arg2 = try std.fmt.parseInt(usize, dig_buf.constSlice(), 10);
                        ans += arg1 * arg2;
                        dig_buf.resize(0) catch unreachable;
                        state = .M;
                    } else {
                        dig_buf.resize(0) catch unreachable;
                        state = .M;
                    }
                },
            }
        }
        return ans;
    }

    test "part1" {
        try std.testing.expectEqual(161, answer(true));
    }
};

const part2 = struct {
    fn answer(comptime test_input: bool) !usize {
        const fh = try std.fs.cwd().openFile((if (test_input) "test_inputs" else "inputs") ++ "/day3.txt", .{});
        defer fh.close();

        var state: enum { SCAN, O, N, @"'", T, @"do)", @"dont(", @"dont)", U, L, @"(", DIG1, DIG2 } = .SCAN;
        var dig_buf = std.BoundedArray(u8, 3).init(0) catch unreachable;
        var arg1: usize = 0;
        var ans: usize = 0;

        var mul_allowed = true;

        wl: while (true) {
            var byte_buf = [1]u8{0};
            const bytes_read = try fh.read(&byte_buf);
            if (bytes_read == 0) break :wl;
            const byte = byte_buf[0];

            switch (state) {
                .SCAN => {
                    if ((byte == 'm') and mul_allowed) {
                        state = .U;
                    } else if (byte == 'd') {
                        state = .O;
                    }
                },
                .O => {
                    if (byte == 'o') {
                        state = .N;
                    } else {
                        state = .SCAN;
                    }
                },
                .N => {
                    if (byte == 'n') {
                        state = .@"'";
                    } else if (byte == '(') {
                        state = .@"do)";
                    } else {
                        state = .SCAN;
                    }
                },

                // do() end case
                .@"do)" => {
                    if (byte == ')') {
                        mul_allowed = true;
                    }
                    state = .SCAN;
                },

                .@"'" => {
                    if (byte == '\'') {
                        state = .T;
                    } else {
                        state = .SCAN;
                    }
                },
                .T => {
                    if (byte == 't') {
                        state = .@"dont(";
                    } else {
                        state = .SCAN;
                    }
                },
                .@"dont(" => {
                    if (byte == '(') {
                        state = .@"dont)";
                    } else {
                        state = .SCAN;
                    }
                },
                .@"dont)" => {
                    if (byte == ')') {
                        mul_allowed = false;
                    }
                    state = .SCAN;
                },
                .U => {
                    if (byte == 'u') {
                        state = .L;
                    } else {
                        state = .SCAN;
                    }
                },
                .L => {
                    if (byte == 'l') {
                        state = .@"(";
                    } else {
                        state = .SCAN;
                    }
                },
                .@"(" => {
                    if (byte == '(') {
                        state = .DIG1;
                    } else {
                        state = .SCAN;
                    }
                },
                .DIG1 => {
                    if (part1.isDig(byte)) {
                        dig_buf.append(byte) catch |err| switch (err) {
                            error.Overflow => {
                                dig_buf.resize(0) catch unreachable;
                                state = .SCAN;
                            },
                            else => return err,
                        };
                    } else if (byte == ',') {
                        arg1 = try std.fmt.parseInt(usize, dig_buf.constSlice(), 10);
                        dig_buf.resize(0) catch unreachable;
                        state = .DIG2;
                    } else {
                        dig_buf.resize(0) catch unreachable;
                        state = .SCAN;
                    }
                },
                .DIG2 => {
                    if (part1.isDig(byte)) {
                        dig_buf.append(byte) catch |err| switch (err) {
                            error.Overflow => {
                                dig_buf.resize(0) catch unreachable;
                                state = .SCAN;
                            },
                            else => return err,
                        };
                    } else if (byte == ')') {
                        const arg2 = try std.fmt.parseInt(usize, dig_buf.constSlice(), 10);
                        ans += arg1 * arg2;
                        dig_buf.resize(0) catch unreachable;
                        state = .SCAN;
                    } else {
                        dig_buf.resize(0) catch unreachable;
                        state = .SCAN;
                    }
                },
            }
        }
        return ans;
    }

    test "part2" {
        try std.testing.expectEqual(48, answer(true));
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
    std.log.info("Answer part 2: {d}", .{answer[1]});
}

comptime {
    std.testing.refAllDecls(part1);
    std.testing.refAllDecls(part2);
}
