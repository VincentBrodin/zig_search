const std = @import("std");
const fs = std.fs;

pub fn readFile(dir: fs.Dir, path: [:0]const u8, alloc: std.mem.Allocator) ![]u8 {
    const file = try dir.openFile(path, .{});
    defer file.close();
    const stat = try file.stat();
    return file.readToEndAlloc(alloc, stat.size);
}
