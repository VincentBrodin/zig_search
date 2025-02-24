const std = @import("std");
const fs = std.fs;

pub fn readFile(dir: fs.Dir, path: [:0]const u8, alloccator: std.mem.Allocator) ![]u8 {
    const file = try dir.openFile(path, .{});
    defer file.close();
    const stat = try file.stat();
    return file.readToEndAlloc(alloccator, stat.size);
}

pub fn writeFile(dir: fs.Dir, path: [:0]const u8, content: [][]u8, allocator: std.mem.Allocator) !void {
    var count: usize = 0;
    for (content) |line| {
        count += line.len + 1;
    }
    const str = try allocator.alloc(u8, count);
    defer allocator.free(str);

    var i: usize = 0;
    for (content) |line| {
        for (line) |c| {
            str[i] = c;
            i += 1;
        }
        str[i] = '\n';
        i += 1;
    }

    const file = try dir.createFile(path, .{});
    defer file.close();
    try file.writeAll(str);
}
