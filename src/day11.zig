const std = @import("std");
const assert = std.debug.assert;
const helpers = @import("helpers");

pub const std_options: std.Options = .{
    .log_level = .info,
};

var memory_buf: [1024 * 20000]u8 = undefined;
var fb_alloc = std.heap.FixedBufferAllocator.init(&memory_buf);
var arena_alloc = std.heap.ArenaAllocator.init(fb_alloc.allocator());

const BlinksAndStone = struct {
    blinks: usize,
    stone: usize,
};

const StoneToCount = std.AutoHashMap(BlinksAndStone, usize);

fn parse(comptime test_input: bool) !std.BoundedArray(usize, 10) {
    var file_line_reader = try helpers.file.LineIterator(100).fromAdventDay(11, test_input);
    defer file_line_reader.deinit();
    const line = file_line_reader.next().?;
    assert(file_line_reader.next() == null);
    var tok = std.mem.tokenizeScalar(u8, line, ' ');
    var ret = std.BoundedArray(usize, 10).init(0) catch unreachable;
    while (tok.next()) |itm| {
        try ret.append(try std.fmt.parseInt(usize, itm, 10));
    }
    return ret;
}

const part1 = struct {
    fn numStones(blinks: usize, stone: usize, hash: *StoneToCount) !usize {
        // std.debug.print("Blink: {d}, stone: {d}\n", .{ blinks, stone });
        if (hash.get(.{ .blinks = blinks, .stone = stone })) |v| return v;

        // End Condition
        if (blinks == 0) return 1;

        const ret = v: {
            if (stone == 0) {
                break :v try numStones(blinks - 1, 1, hash);
            } else {
                var buf: [128]u8 = undefined;
                const len = std.fmt.formatIntBuf(&buf, stone, 10, .lower, .{});
                if (len % 2 == 0) {
                    const stone1 = try std.fmt.parseUnsigned(usize, buf[0 .. len / 2], 10);
                    const stone2 = try std.fmt.parseUnsigned(usize, buf[len / 2 .. len], 10);
                    break :v try numStones(blinks - 1, stone1, hash) + try numStones(blinks - 1, stone2, hash);
                } else {
                    break :v try numStones(blinks - 1, stone * 2024, hash);
                }
            }
        };
        try hash.put(.{ .blinks = blinks, .stone = stone }, ret);
        return ret;
    }

    fn answer_internal(comptime test_input: bool, comptime blinks: usize) !usize {
        const arr = try parse(test_input);
        var hash = StoneToCount.init(arena_alloc.allocator());
        var ans: usize = 0;
        for (arr.constSlice()) |stone| {
            ans += try numStones(blinks, stone, &hash);
        }
        return ans;
    }

    fn answer(comptime test_input: bool) !usize {
        return answer_internal(test_input, 25);
    }

    test "part1" {
        try std.testing.expectEqual(55312, answer(true));
    }
};

const part2 = struct {
    fn answer(comptime test_input: bool) !usize {
        return part1.answer_internal(test_input, 75);
    }
};

fn calculateAnswer() ![2]usize {
    const answer1: usize = try part1.answer(false);
    _ = arena_alloc.reset(.retain_capacity);
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
