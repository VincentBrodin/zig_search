const std = @import("std");
const Queue = @import("queue.zig").Queue(Maze.Node);

const MazeError = error{
    NoStart,
    NoGoal,
};

pub const Maze = struct {
    map: [][]Node = undefined,
    allocator: std.mem.Allocator,
    queue: *Queue,

    pub const Node = struct {
        isWall: bool,
        isStart: bool,
        isGoal: bool,
        x: u32,
        y: u32,

        cameFrom: ?*Node,

        visited: bool,

        pub fn print(self: *Node) void {
            std.debug.print("Node[{},{}] - |isWall: {}| |isStart: {}| |isGoal: {}|\n", .{ self.x, self.y, self.isWall, self.isStart, self.isGoal });
        }
    };

    pub fn init(map_str: []u8, allocator: std.mem.Allocator) !*Maze {
        const maze = try allocator.create(Maze);
        maze.* = Maze{
            .allocator = allocator,
            .queue = try Queue.init(allocator),
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
                    .cameFrom = null,

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
        self.queue.deinit();
        for (self.map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.map);
        self.allocator.destroy(self);
    }

    pub fn findNeighbour(self: *Maze, node: *Node) ![]*Node {
        const nodes = try self.allocator.alloc(*Node, 4);
        var i: usize = 0;

        if (self.nodeUp(node)) |n| {
            nodes[i] = n;
            i += 1;
        }
        if (self.nodeDown(node)) |n| {
            nodes[i] = n;
            i += 1;
        }
        if (self.nodeLeft(node)) |n| {
            nodes[i] = n;
            i += 1;
        }
        if (self.nodeRight(node)) |n| {
            nodes[i] = n;
            i += 1;
        }

        return nodes[0..i];
    }
    fn nodeUp(self: *Maze, node: *Node) ?*Node {
        const x = node.x;
        const y = node.y - 1;

        if ((y >= 0) and (y < self.map.len)) {
            return &self.map[y][x];
        }
        return null;
    }
    fn nodeDown(self: *Maze, node: *Node) ?*Node {
        const x = node.x;
        const y = node.y + 1;

        if ((y >= 0) and (y < self.map.len)) {
            return &self.map[y][x];
        }
        return null;
    }
    fn nodeLeft(self: *Maze, node: *Node) ?*Node {
        const x = node.x - 1;
        const y = node.y;

        if ((x >= 0) and (x < self.map[y].len)) {
            return &self.map[y][x];
        }
        return null;
    }
    fn nodeRight(self: *Maze, node: *Node) ?*Node {
        const x = node.x + 1;
        const y = node.y;

        if ((x >= 0) and (x < self.map[y].len)) {
            return &self.map[y][x];
        }
        return null;
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

    pub fn printPath(self: *Maze, from: *Node) !void {
        const map = try self.allocator.alloc([]u8, self.map.len);
        for (0..self.map.len) |i| {
            map[i] = try self.allocator.alloc(u8, self.map[i].len);
        }
        defer {
            for (map) |row| {
                self.allocator.free(row);
            }
            self.allocator.free(map);
        }

        // Setup base state
        for (map, 0..) |row, y| {
            for (row, 0..) |*c, x| {
                const node = &self.map[y][x];
                if (node.isWall) {
                    c.* = '#';
                } else if (node.isStart) {
                    c.* = 's';
                } else if (node.isGoal) {
                    c.* = 'g';
                } else {
                    c.* = ' ';
                }
            }
        }

        // Trace path
        var currentNode: ?*Node = from;
        while (currentNode != null and !currentNode.?.isStart) {
            map[currentNode.?.y][currentNode.?.x] = 'x';
            currentNode = currentNode.?.cameFrom;
        }

        // print
        for (map) |row| {
            std.debug.print("{s}\n", .{row});
        }
    }

    pub fn solve(self: *Maze) !bool {
        var startNode: *Node = undefined;
        for (self.map) |row| {
            for (row) |*node| {
                if (node.isStart) {
                    startNode = node;
                    startNode.visited = true;
                }
            }
        }

        // Start setup
        {
            const neighbours = try self.findNeighbour(startNode);
            startNode.print();
            std.debug.print("\n", .{});
            for (neighbours) |node| {
                if (!node.isWall and !node.visited) {
                    node.cameFrom = startNode;
                    node.visited = true;
                    try self.queue.enqueue(node);
                }
            }
            self.allocator.free(neighbours);
        }

        {
            var count: usize = 0;
            var currentNode: *Node = undefined;
            search: while (self.queue.len > 0) : (count += 1) {
                // Update the current node
                currentNode = try self.queue.dequeue();
                // Grab neighbours
                const neighbours = try self.findNeighbour(currentNode);
                defer self.allocator.free(neighbours);

                // Loop thorugh neighbours and add the valid ones to the queue
                for (neighbours) |node| {
                    if (!node.isWall and !node.visited) {
                        node.cameFrom = currentNode;
                        node.visited = true;
                        try self.queue.enqueue(node);
                        if (node.isGoal) {
                            std.debug.print("Found goal\n", .{});
                            break :search;
                        }
                    }
                }
            } else {
                std.debug.print("Could not solve\n", .{});
                return false;
            }
            std.debug.print("Solved in {} moves\n", .{count});

            try self.printPath(currentNode);
        }
        return true;
    }
};
