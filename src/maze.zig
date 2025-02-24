const std = @import("std");
const MazeBfs = @import("maze_bfs.zig").MazeBfs;
const MazeDfs = @import("maze_dfs.zig").MazeDfs;

pub const Maze = union(enum) {
    bfs: *MazeBfs,
    dfs: *MazeDfs,

    pub fn deinit(self: Maze) void {
        switch (self) {
            .bfs => self.bfs.deinit(),
            .dfs => self.dfs.deinit(),
        }
    }

    pub fn print(self: Maze) !void {
        return switch (self) {
            .bfs => self.bfs.print(),
            .dfs => self.dfs.print(),
        };
    }

    pub fn solve(self: Maze) !?[][]u8 {
        return switch (self) {
            .bfs => self.bfs.solve(),
            .dfs => self.dfs.solve(),
        };
    }
};

pub fn getMaze(method: []const u8, map_str: []u8, allocator: std.mem.Allocator) !Maze {
    if (std.mem.eql(u8, method, "bfs")) {
        return Maze{ .bfs = try MazeBfs.init(map_str, allocator) };
    } else if (std.mem.eql(u8, method, "dfs")) {
        return Maze{ .dfs = try MazeDfs.init(map_str, allocator) };
    } else {
        return error.UnknownMethod;
    }
}
