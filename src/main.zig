const std = @import("std");
const ReadFromCMD = @import("root.zig").ReadFromCMD;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var read_from_terminal = try ReadFromCMD.init(allocator, 40);
    defer read_from_terminal.deinit();

    try read_from_terminal.getInputFromCMD();
}
