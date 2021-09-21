const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const contents = try file.reader().readAllAlloc(allocator, 409600);
    defer allocator.free(contents);

    var values = try parseInput(allocator, contents);
    defer allocator.free(values);

    const stdout = std.io.getStdOut().writer();

    const part1 = findTwo(&values);
    try stdout.print("Part 1: {d}\n", .{part1});

    const part2 = findThree(&values);
    try stdout.print("Part 2: {d}\n", .{part2});
}

fn parseInput(allocator: *std.mem.Allocator, str: []const u8) ![]const u64 {
    var nums = std.ArrayList(u64).init(allocator);
    defer nums.deinit();

    var iter = std.mem.split(u8, str, "\n");
    while (iter.next()) |str_value| {
        std.log.debug("line: {s}", .{str_value});
        const value = std.fmt.parseInt(u64, str_value, 10) catch |err|
            {
            std.log.debug("error: {}", .{err});
            continue;
        };
        try nums.append(value);
    }

    return nums.toOwnedSlice();
}

fn findTwo(values: *[]const u64) u64 {
    for (values.*) |v1, idx1| {
        for (values.*) |v2, idx2| {
            if (idx1 == idx2) continue;
            if (2020 == (v1 + v2)) {
                return (v1 * v2);
            }
        }
    }
    unreachable;
}

fn findThree(values: *[]const u64) u64 {
    for (values.*) |v1, idx1| {
        for (values.*) |v2, idx2| {
            if (idx1 == idx2) continue;
            for (values.*) |v3, idx3| {
                if (idx2 == idx3) continue;
                if (2020 == (v1 + v2 + v3)) {
                    return (v1 * v2 * v3);
                }
            }
        }
    }
    unreachable;
}

test "day1" {
    const test_input =
        \\1721
        \\979
        \\366
        \\299
        \\675
        \\1456
    ;

    var values = try parseInput(test_allocator, test_input);
    defer test_allocator.free(values);

    const test_values = [_]u64{ 1721, 979, 366, 299, 675, 1456 };
    try expect(std.mem.eql(u64, &test_values, values));

    try expect(514579 == findTwo(&values));
    try expect(241861950 == findThree(&values));
}
