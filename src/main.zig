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
    const out: ?([:0]const u8) = argIter.next();

    // Read file
    const fileContent = try helper.readFile(fs.cwd(), path, alloc);
    defer alloc.free(fileContent);

    // Solve the maze
    const start = try std.time.Instant.now();

    const maze = try Maze.init(fileContent, alloc);
    defer maze.deinit();
    const solvedMaze = try maze.solve();

    const end = try std.time.Instant.now();
    const diff_ns = end.since(start);
    const diff_ms = diff_ns / 1_000_000;
    if (solvedMaze == null) {
        std.debug.print("Failed to solve maze in {} ms\n", .{diff_ms});
    } else {
        if (out == null) {
            for (solvedMaze.?) |row| {
                std.debug.print("{s}\n", .{row});
            }
        } else {
            try helper.writeFile(fs.cwd(), out.?, solvedMaze.?, alloc);
        }
        std.debug.print("Solved in: {} ms\n", .{diff_ms});
    }
}
