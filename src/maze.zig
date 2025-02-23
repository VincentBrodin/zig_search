const std = @import("std");
const Queue = @import("queue.zig").Queue(Maze.Node);

const MazeError = error{
    NoStart,
    NoGoal,
};

pub const Maze = struct {
    map: [][]Node = undefined,
    allocator: std.mem.Allocator,

    pub const Node = struct {
        isWall: bool,
        isStart: bool,
        isGoal: bool,
        x: u32,
        y: u32,

        visited: bool,
    };

    pub fn init(map_str: []u8, allocator: std.mem.Allocator) !*Maze {
        const maze = try allocator.create(Maze);
        maze.* = Maze{
            .allocator = allocator,
        };
        errdefer maze.deinit();

        var iter = std.mem.tokenize(u8, map_str, "\n");

        // Get the amount of rows
        var totalRows: usize = 0;
        while (iter.next()) |_| : (totalRows += 1) {}

        // Allocate
        maze.map = try allocator.alloc([]Node, totalRows);

        iter.reset();
        var currentRow: usize = 0;
        var hasStart = false;
        var hasGoal = false;
        while (iter.next()) |line| : (currentRow += 1) {
            const size = line.len - 1;
            maze.map[currentRow] = try allocator.alloc(Node, size);
            for (0..size) |i| {
                const c = line[i];
                const node = &maze.map[currentRow][i];
                node.* = Node{
                    // State
                    .isWall = c == '#',
                    .isStart = c == 's',
                    .isGoal = c == 'g',
                    .visited = false,

                    // Position
                    .x = @as(u32, @intCast(i)),
                    .y = @as(u32, @intCast(currentRow)),
                };

                if (node.isStart) {
                    hasStart = true;
                }
                if (node.isGoal) {
                    hasGoal = true;
                }
            }
        }
        if (!hasStart) {
            return MazeError.NoStart;
        }
        if (!hasGoal) {
            return MazeError.NoGoal;
        }
        return maze;
    }

    pub fn deinit(self: *Maze) void {
        for (self.map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.map);
        self.allocator.destroy(self);
    }

    pub fn findNeighbour(self: *Maze) []Node {
        return self.map[0];
    }

    pub fn print(self: *Maze) void {
        for (self.map) |row| {
            for (row) |node| {
                if (node.isWall) {
                    std.debug.print("#", .{});
                } else if (node.isStart) {
                    std.debug.print("s", .{});
                } else if (node.isGoal) {
                    std.debug.print("g", .{});
                } else {
                    std.debug.print(" ", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn solve(self: *Maze) bool {
        var startNode: Node = undefined;
        for (self.map) |row| {
            for (row) |node| {
                if (node.isStart) {
                    startNode = node;
                }
            }
        }

        _ = self.findNeighbour();
        return false;
    }
};
