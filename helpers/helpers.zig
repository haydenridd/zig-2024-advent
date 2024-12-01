const std = @import("std");
const File = std.fs.File;

pub fn fpFromAdventDay(comptime day: usize, comptime test_input: bool) []const u8 {
    return (if (test_input) "./test_inputs/" else "./inputs/") ++ std.fmt.comptimePrint("day{}", .{day}) ++ "_input.txt";
}

/// Helpers for file IO
pub const file = struct {
    /// Iterator that returns string items from a file given a delimiter.
    ///
    /// Note that hitting EOF before an additional delimiter returns the remainder of the file, and is not considered an error
    pub fn DelimitedIterator(delim: u8, buffer_size: usize) type {
        return struct {
            const BufferArray = std.BoundedArray(u8, buffer_size);
            const Self = @This();
            current_item: BufferArray,
            file: File,
            _eos_with_remainder: bool = false,

            pub fn fromAdventDay(comptime day: usize, comptime test_input: bool) !Self {
                return Self.init(fpFromAdventDay(day, test_input));
            }

            pub fn init(path: []const u8) !Self {
                return Self{ .current_item = try BufferArray.init(0), .file = try std.fs.cwd().openFile(path, .{}) };
            }

            pub fn deinit(self: *Self) void {
                self.file.close();
            }

            pub fn next(self: *Self) ?[]const u8 {
                if (self._eos_with_remainder) return null;
                self.current_item.resize(0) catch unreachable;

                self.file.reader().streamUntilDelimiter(self.current_item.writer(), delim, null) catch |err| switch (err) {
                    error.EndOfStream => {
                        if (self.current_item.len > 0) {
                            // Hitting EndOfStream without seeing another delimiter is not considered an error!
                            self._eos_with_remainder = true;
                            return self.current_item.constSlice();
                        } else {
                            return null;
                        }
                    },
                    else => unreachable,
                };
                return self.current_item.constSlice();
            }

            pub fn skip(self: *Self, num: usize) void {
                for (0..num) |_| {
                    _ = self.next() orelse return;
                }
            }
        };
    }

    pub fn LineIterator(buffer_size: usize) type {
        return DelimitedIterator('\n', buffer_size);
    }

    pub fn CsvIterator(buffer_size: usize) type {
        return DelimitedIterator(',', buffer_size);
    }

    test "Read Lines Iteratively" {
        var file_reader = try LineIterator(100).init("test_inputs/test_file.txt");
        defer file_reader.deinit();

        var i: usize = 0;
        const expected_test_contents = [_][]const u8{ "hello", "from", "test", "file" };
        while (file_reader.next()) |line| : (i += 1) {
            try std.testing.expectEqualStrings(expected_test_contents[i], line);
        }
        try std.testing.expectEqual(4, i);
    }

    test "Read CSV Iteratively" {
        var file_reader = try CsvIterator(100).init("test_inputs/test_file.csv");
        defer file_reader.deinit();

        var i: usize = 0;
        const expected_test_contents = [_][]const u8{ "hello", "from", "test", "file" };
        while (file_reader.next()) |line| : (i += 1) {
            try std.testing.expectEqualStrings(expected_test_contents[i], line);
        }
        try std.testing.expectEqual(4, i);
    }

    /// Convenience type for collecting a file's contents into an array of strings per a specified delimiter
    pub fn DelimitedArray(delim: u8, max_item_width: usize, max_num_items: usize) type {
        return struct {
            _internal_buffer: OverallBuffer,
            _outer_slice_mem: [max_num_items][]u8,

            const Self = @This();
            pub const BufferPerLine = std.BoundedArray(u8, max_item_width);
            pub const OverallBuffer = std.BoundedArray(BufferPerLine, max_num_items);

            pub fn init(fp: []const u8) !Self {
                var delim_reader = try DelimitedIterator(delim, max_item_width).init(fp);
                defer delim_reader.deinit();

                var ret: Self = undefined;

                ret._internal_buffer = OverallBuffer.init(0) catch unreachable;

                var idx: usize = 0;
                while (delim_reader.next()) |item| : (idx += 1) {
                    const entry = try ret._internal_buffer.addOne();
                    entry.* = BufferPerLine.init(0) catch unreachable;
                    try entry.*.appendSlice(item);
                }

                return ret;
            }

            pub fn fromAdventDay(comptime day: usize, comptime test_input: bool) !Self {
                return Self.init(fpFromAdventDay(day, test_input));
            }

            pub fn slice(self: *Self) []const []u8 {
                for (self._internal_buffer.slice(), 0..) |*itm, idx| {
                    self._outer_slice_mem[idx] = itm.*.slice();
                }
                return self._outer_slice_mem[0..self._internal_buffer.len];
            }
        };
    }
};

comptime {
    std.testing.refAllDecls(file);
}
