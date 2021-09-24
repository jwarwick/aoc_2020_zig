const std = @import("std");
const expect = std.testing.expect;
const io = std.io;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = &gpa.allocator;

    var list = try readSeats(allocator, "input.txt");
    defer allocator.free(list);

    std.sort.sort(u16, list, {}, comptime std.sort.asc(u16));
    const largest = std.mem.max(u16, list);
    var last: u16 = list[0];
    var gap: u16 = 0;

    for (list[1..]) |item| {
        if (item != last + 1) {
            gap = item - 1;
            break;
        }
        last = item;
    }

    const stdout = io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{largest});
    try stdout.print("Part 2: {d}\n", .{gap});
}

fn readSeats(allocator: *Allocator, path: []const u8) ![]u16 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var list = ArrayList(u16).init(allocator);
    defer list.deinit();

    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [64]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try list.append(seatNumber(line));
    }

    return list.toOwnedSlice();
}

pub fn seatNumber(str: []const u8) u16 {
    const row = partition(str[0..7], 0, 127);
    const col = partition(str[7..], 0, 7);
    return (row * 8) + col;
}

fn partition(str: []const u8, min: u16, max: u16) u16 {
    if (max == min) {
        return min;
    }

    const offset: f16 = (@intToFloat(f16, max - min)) / 2;
    switch (str[0]) {
        'F', 'L' => {
            return partition(str[1..], min, min + @floatToInt(u16, @floor(offset)));
        },
        'B', 'R' => {
            return partition(str[1..], min + @floatToInt(u16, @ceil(offset)), max);
        },
        else => unreachable,
    }
    unreachable;
}

test "part1" {
    try expect(357 == seatNumber("FBFBBFFRLR"));
    try expect(567 == seatNumber("BFFFBBFRRR"));
    try expect(119 == seatNumber("FFFBBBFRRR"));
    try expect(820 == seatNumber("BBFFBBFRLL"));
}
