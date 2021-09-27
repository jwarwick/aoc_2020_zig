const std = @import("std");
const io = std.io;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = &gpa.allocator;

    var c = try Cpu.load(allocator, "input.txt");
    defer c.deinit();

    const last_acc = try c.runUntilRepeat();
    const fix_acc = try c.fixOpcode();

    const stdout = io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{last_acc});
    try stdout.print("Part 2: {d}\n", .{fix_acc});
}

const Operation = enum { nop, acc, jmp };

const Instruction = struct {
    op: Operation,
    arg: i16,

    pub fn parse(str: []const u8) !Instruction {
        const s = str[0..3];
        const i = if (std.mem.eql(u8, s, "acc"))
            Operation.acc
        else if (std.mem.eql(u8, s, "jmp"))
            Operation.jmp
        else if (std.mem.eql(u8, s, "nop"))
            Operation.nop
        else
            unreachable;

        const a = try std.fmt.parseInt(i16, str[4..], 10);

        return Instruction{ .op = i, .arg = a };
    }
};

const CpuError = error{ InvalidInstruction, RepeatedInstruction };

const Cpu = struct {
    ip: u16 = 0,
    acc: i16 = 0,
    prog: []Instruction,
    flip_op: ?u16 = null,
    allocator: *Allocator,

    pub fn load(allocator: *Allocator, path: []const u8) !Cpu {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var list = std.ArrayList(Instruction).init(allocator);
        defer list.deinit();

        var buf_reader = io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [256]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            const inst = try Instruction.parse(line);
            try list.append(inst);
        }

        return Cpu{ .allocator = allocator, .prog = list.toOwnedSlice() };
    }

    pub fn deinit(self: *const Cpu) void {
        self.allocator.free(self.prog);
    }

    pub fn step(self: *Cpu) !bool {
        if (self.ip == self.prog.len) {
            return true;
        }

        if (self.ip > self.prog.len) {
            return CpuError.InvalidInstruction;
        }

        var op = self.prog[self.ip].op;
        if (self.flip_op) |flip_idx| {
            if (flip_idx == self.ip) {
                op = switch (op) {
                    Operation.nop => Operation.jmp,
                    Operation.jmp => Operation.nop,
                    Operation.acc => Operation.acc,
                };
            }
        }

        switch (op) {
            .nop => self.ip += 1,
            .acc => {
                self.acc += self.prog[self.ip].arg;
                self.ip += 1;
            },
            .jmp => {
                var new_ip: i16 = @intCast(i16, self.ip) + self.prog[self.ip].arg;
                self.ip = @intCast(u16, new_ip);
            },
        }

        return false;
    }

    pub fn run(self: *Cpu) !void {
        var done: bool = false;
        while (!done) {
            done = try self.step();
        }
    }

    pub fn runUntilRepeat(self: *Cpu) !i16 {
        var last_acc: i16 = 0;
        var map = std.AutoHashMap(u16, bool).init(self.allocator);
        defer map.deinit();

        var done: bool = false;
        while (!done) {
            if (map.contains(self.ip)) {
                return last_acc;
            }
            try map.put(self.ip, true);
            last_acc = self.acc;
            done = try self.step();
        }

        return last_acc;
    }

    pub fn fixOpcodeRun(self: *Cpu) !i16 {
        self.acc = 0;
        self.ip = 0;

        var last_acc: i16 = 0;
        var map = std.AutoHashMap(u16, bool).init(self.allocator);
        defer map.deinit();

        var done: bool = false;
        while (!done) {
            if (map.contains(self.ip)) {
                return CpuError.RepeatedInstruction;
            }
            try map.put(self.ip, true);
            last_acc = self.acc;
            done = try self.step();
        }

        return last_acc;
    }

    pub fn fixOpcode(self: *Cpu) !i16 {
        var i: u16 = 0;
        while (i < self.prog.len) : (i += 1) {
            if (Operation.acc == self.prog[i].op) continue;
            self.flip_op = i;
            return self.fixOpcodeRun() catch continue;
        }
        unreachable;
    }
};

test "basic behavior" {
    var n = try Cpu.load(test_allocator, "nop.txt");
    defer n.deinit();
    try n.run();
    try expect(0 == n.acc);

    var a = try Cpu.load(test_allocator, "acc.txt");
    defer a.deinit();
    try a.run();
    try expect(-3 == a.acc);

    var t = try Cpu.load(test_allocator, "test.txt");
    defer t.deinit();
    const last_acc = try t.runUntilRepeat();
    try expect(5 == last_acc);
}

test "op fix" {
    var t = try Cpu.load(test_allocator, "test.txt");
    defer t.deinit();
    const last_acc = try t.fixOpcode();
    try expect(8 == last_acc);
}
