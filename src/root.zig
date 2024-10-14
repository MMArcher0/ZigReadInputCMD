const std = @import("std");

pub const ReadFromCMD = struct {
    const Segment = struct {
        allocator: std.mem.Allocator,
        data: []u8,
        next: ?*Segment,

        fn init(allocator: std.mem.Allocator, data: []u8) !*Segment {
            const ptr = try allocator.create(Segment);
            ptr.allocator = allocator;
            ptr.data = data;
            ptr.next = null;
            return ptr;
        }

        fn deinit(self: *Segment) void {
            if (self.next) |ptr| ptr.deinit();
            self.allocator.destroy(self);
        }
    };

    const Self = @This();

    allocator: std.mem.Allocator,
    bufferSize: u16,
    segment_head: ?*Segment,

    pub fn init(allocator: std.mem.Allocator, bufferSize: u16) !Self {
        return .{ .allocator = allocator, .bufferSize = bufferSize, .segment_head = null };
    }

    pub fn getInputFromCMD(self: *Self) !void {
        var buffer = try self.allocator.alloc(u8, self.bufferSize);
        defer self.allocator.free(buffer);

        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();

        try stdout.print("Enter the command\n", .{});
        _ = try stdin.readUntilDelimiter(buffer, '\n');

        var last_seg_start: usize = 0;

        forinf: for (buffer, 0..) |v, i| {
            switch (v) {
                0...31 => {
                    try self.appendSegment(buffer[last_seg_start..i]);
                    break :forinf;
                },
                32 => {
                    if (last_seg_start == i) {
                        last_seg_start += 1;
                    } else {
                        try self.appendSegment(buffer[last_seg_start..i]);
                        last_seg_start = i + 1;
                    }
                },
                else => continue,
            }
        }
        try self.writeAllSegments();
    }

    fn appendSegment(self: *Self, data: []u8) !void {
        if (self.segment_head == null) {
            self.segment_head = try Segment.init(self.allocator, data);
        } else {
            var tail: *Segment = self.segment_head.?;
            while (tail.next) |ptr| tail = ptr;
            tail.next = try Segment.init(self.allocator, data);
        }
    }

    fn writeAllSegments(self: *Self) !void {
        if (self.segment_head == null) {
            @panic("No command segments found");
        } else {
            var tail: *Segment = self.segment_head.?;
            const stdout = std.io.getStdOut().writer();

            while (tail.next) |ptr| {
                try stdout.print("Comando {s} identificado \n", .{tail.data});
                tail = ptr;
            }

            try stdout.print("Comando {s} identificado \n", .{tail.data});
        }
    }

    pub fn deinit(self: *Self) void {
        if (self.segment_head != null) {
            const head = self.segment_head.?;
            head.deinit();
        }
    }
};
