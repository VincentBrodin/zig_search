const std = @import("std");
const Maze = @import("maze.zig");
const helper = @import("helper.zig");

const fs = std.fs;
const process = std.process;
const Alloc = std.heap.GeneralPurposeAllocator(.{});

const Stack = @import("stack.zig").Stack(u32);

const AppError = error{
    NoArgs,
};

pub fn main() !void {
    var gpa = Alloc{};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Get args "file [method] [input] [output]" output not needed
    var argIter = try process.ArgIterator.initWithAllocator(allocator);
    defer argIter.deinit();
    _ = argIter.skip();
    const method = argIter.next() orelse return AppError.NoArgs;
    const path = argIter.next() orelse return AppError.NoArgs;
    const out: ?([:0]const u8) = argIter.next();

    // Read file
    const fileContent = try helper.readFile(fs.cwd(), path, allocator);
    defer allocator.free(fileContent);

    // Solve the maze
    const start = try std.time.Instant.now();

    const maze = try Maze.getMaze(method, fileContent, allocator);
    defer maze.deinit();
    const solvedMaze = try maze.solve();

    const end = try std.time.Instant.now();
    const diff_ns = end.since(start);
    const diff_ms: f64 = @as(f64, @floatFromInt(diff_ns)) / 1_000_000.0;
    if (solvedMaze == null) {
        std.debug.print("Failed to solve maze in {} ms\n", .{diff_ms});
    } else {
        if (out == null) {
            for (solvedMaze.?) |row| {
                std.debug.print("{s}\n", .{row});
            }
        } else {
            try helper.writeFile(fs.cwd(), out.?, solvedMaze.?, allocator);
        }
        std.debug.print("Solved in: {d:.4} ms\n", .{diff_ms});
    }
}
