const std = @import("std");
const io = std.io;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;
const test_allocator = std.testing.allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    var allocator = &gpa.allocator;
    var list = try loadFile(allocator, "input.txt");
    defer {
        for (list) |item| {
            item.deinit();
        }
        allocator.free(list);
    }
    var part1 = countValidLength(list);
    var part2 = countValidIndex(list);
    // for (list) |item| {
    //     if (item.isValidCount()) {
    //         part1 += 1;
    //     }
    //     // std.log.info("Min, Max: {d}, {d}", .{ item.min, item.max });
    //     // std.log.info("Letter: {c}", .{item.letter});
    //     // std.log.info("Password: {s}", .{item.password});
    //     // std.log.info("Valid? {b}", .{item.isValidCount()});
    //     // std.log.info("------------------------------------", .{});
    // }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{part1});
    try stdout.print("Part 2: {d}\n", .{part2});
}

const Password = struct {
    min: u32,
    max: u32,
    letter: u8,
    password: []u8,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator, str: []const u8) !Password {
        var split_iter = std.mem.split(u8, str, " ");

        var range_str = split_iter.next();
        var range_iter = std.mem.split(u8, range_str.?, "-");
        const min = try std.fmt.parseInt(u32, range_iter.next().?, 10);
        const max = try std.fmt.parseInt(u32, range_iter.next().?, 10);

        const letter = split_iter.next().?[0];

        const password = std.mem.trimRight(u8, split_iter.next().?, "\n");

        var heap_pass = try allocator.alloc(u8, password.len);
        std.mem.copy(u8, heap_pass, password);

        return Password{ .min = min, .max = max, .letter = letter, .password = heap_pass, .allocator = allocator };
    }

    pub fn deinit(self: *const Password) void {
        self.allocator.free(self.password);
    }

    pub fn isValidCount(self: *const Password) bool {
        var count: u32 = 0;
        for (self.password) |c| {
            if (c == self.letter) {
                count += 1;
            }
        }
        return (count >= self.min) and (count <= self.max);
    }

    pub fn isValidIndex(self: *const Password) bool {
        var num: u8 = 0;
        if (self.password[self.min - 1] == self.letter) {
            num += 1;
        }
        if (self.password[self.max - 1] == self.letter) {
            num += 1;
        }
        return (num == 1);
    }
};

pub fn countValidLength(list: []Password) u32 {
    var count: u32 = 0;
    for (list) |item| {
        if (item.isValidCount()) {
            count += 1;
        }
    }
    return count;
}

pub fn countValidIndex(list: []Password) u32 {
    var count: u32 = 0;
    for (list) |item| {
        if (item.isValidIndex()) {
            count += 1;
        }
    }
    return count;
}

pub fn loadFile(allocator: *Allocator, path: []const u8) ![]Password {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var list = ArrayList(Password).init(allocator);

    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // std.log.info("line: {s}", .{line});
        var p = try Password.init(allocator, line);
        try list.append(p);
    }

    return list.toOwnedSlice();
}

const test_input =
    \\ 1-3 a: abcde
    \\ 1-3 b: cdefg
    \\ 2-9 c: ccccccccc
;

test "parsing" {
    var test_pass: Password = try Password.init(test_allocator, "1-3 a: abcde");
    defer test_pass.deinit();
    try expect(test_pass.min == 1);
    try expect(test_pass.max == 3);
    try expect(test_pass.letter == 'a');
    try expect(std.mem.eql(u8, "abcde", test_pass.password));
}

test "file reading" {
    var list = try loadFile(test_allocator, "test.txt");
    defer {
        for (list) |item| {
            item.deinit();
        }
        test_allocator.free(list);
    }
    try expect(3 == list.len);
    var count = countValidLength(list);
    try expect(2 == count);
    var index_count = countValidIndex(list);
    try expect(1 == index_count);
}
