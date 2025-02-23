const std = @import("std");
const Maze = @import("maze.zig").Maze;
const helper = @import("helper.zig");

const fs = std.fs;
const process = std.process;
const Alloc = std.heap.GeneralPurposeAllocator(.{});

const AppError = error{
    NoArgs,
};

pub fn main() !void {
    var gpa = Alloc{};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // Get args
    var argIter = try process.ArgIterator.initWithAllocator(alloc);
    defer argIter.deinit();
    _ = argIter.skip();
    const path = argIter.next() orelse return AppError.NoArgs;

    // Read file
    const fileContent = try helper.readFile(fs.cwd(), path, alloc);
    defer alloc.free(fileContent);

    const maze = try Maze.init(fileContent, alloc);
    defer maze.deinit();
    maze.print();
    _ = try maze.solve();
}
