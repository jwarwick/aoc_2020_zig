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
    var map = try Map.init(allocator, "input.txt");
    defer map.deinit();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{map.countTrees(3, 1)});
    try stdout.print("Part 2: {d}\n", .{map.multTrees()});
}

const Map = struct {
    width: u32,
    height: u32,
    data: []bool,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator, path: []const u8) !Map {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var list = ArrayList(bool).init(allocator);
        defer list.deinit();

        var height: u32 = 0;
        var width: u64 = 0;

        var buf_reader = io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (0 == width) {
                width = line.len;
            }

            for (line) |t| {
                try list.append('#' == t);
            }

            height += 1;
        }

        return Map{ .width = @intCast(u32, width), .height = height, .data = list.toOwnedSlice(), .allocator = allocator };
    }

    pub fn deinit(self: *const Map) void {
        self.allocator.free(self.data);
    }

    pub fn at(self: *const Map, x: u32, y: u32) ?bool {
        const offset = (y * self.width) + (x % self.width);
        if (offset >= self.data.len) {
            return null;
        } else {
            return self.data[offset];
        }
    }

    pub fn countTrees(self: *const Map, right: u32, down: u32) u32 {
        var x: u32 = 0;
        var y: u32 = 0;
        var count: u32 = 0;

        while (self.at(x, y)) |t| {
            if (t) {
                count += 1;
            }
            x = x + right;
            y = y + down;
        }

        return count;
    }

    pub fn multTrees(self: *const Map) u32 {
        const r1 = self.countTrees(1, 1);
        const r2 = self.countTrees(3, 1);
        const r3 = self.countTrees(5, 1);
        const r4 = self.countTrees(7, 1);
        const r5 = self.countTrees(1, 2);
        return r1 * r2 * r3 * r4 * r5;
    }
};

test "part1" {
    var map = try Map.init(test_allocator, "test.txt");
    defer map.deinit();

    try expect(map.height == 11);
    try expect(map.width == 11);

    try expect(false == map.at(0, 0));
    try expect(true == map.at(0, 1));
    try expect(false == map.at(1, 0));
    try expect(true == map.at(10, 10));
    try expect(false == map.at(3, 1));

    var trees = map.countTrees(3, 1);
    try expect(trees == 7);

    var mult = map.multTrees();
    try expect(mult == 336);
}
