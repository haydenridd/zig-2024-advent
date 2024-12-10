const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

const FileThing = struct {
    file: u4,
    free: u4,
};

const FileThingArr = std.BoundedArray(FileThing, 1024 * 10);

fn parseInput(comptime test_input: bool) !FileThingArr {
    const fh = try std.fs.cwd().openFile((if (test_input) "test_inputs" else "inputs") ++ "/day9.txt", .{});
    defer fh.close();
    var ret = FileThingArr.init(0) catch unreachable;
    while (true) {
        var buf: [1]u8 = undefined;
        var bytes_read = try fh.read(&buf);
        if ((bytes_read == 0) or ((bytes_read == 1) and (buf[0] == '\n'))) break;
        const file_blocks = try std.fmt.parseInt(u4, &buf, 10);

        var free_blocks: u4 = 0;
        bytes_read = try fh.read(&buf);
        if ((bytes_read == 1) and (buf[0] != '\n')) {
            free_blocks = try std.fmt.parseInt(u4, &buf, 10);
        }
        try ret.append(.{ .file = file_blocks, .free = free_blocks });
    }
    return ret;
}

const part1 = struct {
    fn answer(comptime test_input: bool) !usize {
        var thing_arr = try parseInput(test_input);
        const slice = thing_arr.slice();
        var end_idx: usize = slice.len - 1;
        var start_idx: usize = 0;
        var overall_idx: usize = slice[start_idx].file;

        var ans: usize = 0;
        while (true) {
            if (start_idx == end_idx) break;
            assert(start_idx < end_idx);
            if (slice[start_idx].free >= slice[end_idx].file) {
                slice[start_idx].free -= slice[end_idx].file;
                for (overall_idx..overall_idx + slice[end_idx].file) |mult_idx| {
                    ans += end_idx * mult_idx;
                }
                overall_idx += slice[end_idx].file;
                end_idx -= 1;
            } else {
                for (overall_idx..overall_idx + slice[start_idx].free) |mult_idx| {
                    ans += end_idx * mult_idx;
                }
                overall_idx += slice[start_idx].free;
                slice[end_idx].file -= slice[start_idx].free;
                slice[start_idx].free = 0;
            }

            if (slice[start_idx].free == 0) {
                start_idx += 1;
                for (overall_idx..overall_idx + slice[start_idx].file) |mult_idx| {
                    ans += start_idx * mult_idx;
                }
                overall_idx += slice[start_idx].file;
            }
        }
        return ans;
    }

    test "part1" {
        try std.testing.expectEqual(1928, try answer(true));
    }
};

const part2 = struct {
    const AdditionalData = struct {
        abs_idx: usize,
        orig_free: u4,
    };

    fn answer(comptime test_input: bool) !usize {
        var thing_arr = try parseInput(test_input);
        const slice = thing_arr.slice();

        var add_data_arr = try std.BoundedArray(AdditionalData, 1024 * 10).init(0);
        var offset: usize = 0;
        for (0..slice.len) |idx| {
            try add_data_arr.append(.{ .abs_idx = offset, .orig_free = slice[idx].free });
            offset += @as(usize, slice[idx].file) + @as(usize, slice[idx].free);
        }
        const add_data_slice = add_data_arr.constSlice();

        var end_idx: usize = slice.len - 1;
        var start_idx: usize = 0;
        var ans: usize = 0;

        // First do the file movements
        while (true) {
            // End conditions
            if (start_idx == end_idx) {
                start_idx = 0;
                end_idx -= 1;
                if (end_idx == 0) break;
            }

            if (slice[start_idx].free >= slice[end_idx].file) {
                const abs_idx = add_data_slice[start_idx].abs_idx + slice[start_idx].file + (add_data_slice[start_idx].orig_free - slice[start_idx].free);
                for (abs_idx..abs_idx + slice[end_idx].file) |mult_idx| {
                    ans += mult_idx * end_idx;
                }
                slice[start_idx].free -= slice[end_idx].file;
                slice[end_idx].file = 0;
                end_idx -= 1;
                start_idx = 0;
            } else {
                start_idx += 1;
            }
        }

        // Now loop back through and account for any files that still have file space (haven't moved)
        for (slice, add_data_slice, 0..) |orig, additional, file_id| {
            if (orig.file > 0) {
                for (additional.abs_idx..additional.abs_idx + orig.file) |mult_idx| {
                    ans += file_id * mult_idx;
                }
            }
        }

        return ans;
    }

    test "part2" {
        try std.testing.expectEqual(2858, try answer(true));
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
