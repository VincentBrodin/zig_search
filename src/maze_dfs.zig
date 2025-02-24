const std = @import("std");
const Stack = @import("stack.zig").Stack(MazeDfs.Node);

const MazeError = error{
    NoStart,
    NoGoal,
};

pub const MazeDfs = struct {
    map: [][]Node = undefined,
    solved: [][]u8 = undefined,
    allocator: std.mem.Allocator,
    stack: *Stack,

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

    pub fn init(map_str: []u8, allocator: std.mem.Allocator) !*MazeDfs {
        const maze = try allocator.create(MazeDfs);
        maze.* = MazeDfs{
            .allocator = allocator,
            .stack = try Stack.init(allocator),
        };
        errdefer maze.deinit();

        var iter = std.mem.tokenize(u8, map_str, "\n");

        // Get the amount of rows
        var totalRows: usize = 0;
        while (iter.next()) |_| : (totalRows += 1) {}

        // Allocate
        maze.map = try allocator.alloc([]Node, totalRows);
        maze.solved = try allocator.alloc([]u8, totalRows);

        iter.reset();
        var currentRow: usize = 0;
        var hasStart = false;
        var hasGoal = false;
        while (iter.next()) |line| : (currentRow += 1) {
            const size = line.len - 1;

            maze.map[currentRow] = try allocator.alloc(Node, size);
            maze.solved[currentRow] = try allocator.alloc(u8, size);

            for (0..size) |i| {
                const c = line[i];
                maze.solved[currentRow][i] = c;
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

    pub fn deinit(self: *MazeDfs) void {
        self.stack.deinit();

        for (self.map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.map);

        for (self.solved) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.solved);

        self.allocator.destroy(self);
    }

    const Neighbours = std.meta.Tuple(&.{ []*Node, usize });
    fn findNeighbour(self: *MazeDfs, node: *Node) !Neighbours {
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

        return .{ nodes, i };
    }
    fn nodeUp(self: *MazeDfs, node: *Node) ?*Node {
        if (node.y == 0) return null;
        const x = node.x;
        const y = node.y - 1;

        if ((y >= 0) and (y < self.map.len)) {
            return &self.map[y][x];
        }
        return null;
    }
    fn nodeDown(self: *MazeDfs, node: *Node) ?*Node {
        const x = node.x;
        const y = node.y + 1;

        if ((y >= 0) and (y < self.map.len)) {
            return &self.map[y][x];
        }
        return null;
    }
    fn nodeLeft(self: *MazeDfs, node: *Node) ?*Node {
        if (node.x == 0) return null;
        const x = node.x - 1;
        const y = node.y;

        if ((x >= 0) and (x < self.map[y].len)) {
            return &self.map[y][x];
        }
        return null;
    }
    fn nodeRight(self: *MazeDfs, node: *Node) ?*Node {
        const x = node.x + 1;
        const y = node.y;

        if ((x >= 0) and (x < self.map[y].len)) {
            return &self.map[y][x];
        }
        return null;
    }
    pub fn print(self: *MazeDfs) void {
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

    fn tracePath(self: *MazeDfs, from: *Node) [][]u8 {
        var currentNode: ?*Node = from;
        while (currentNode != null and !currentNode.?.isStart) {
            self.solved[currentNode.?.y][currentNode.?.x] = '.';
            currentNode = currentNode.?.cameFrom;
        }

        return self.solved;
    }

    pub fn solve(self: *MazeDfs) !?[][]u8 {
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
            for (0..neighbours[1]) |i| {
                const node: *Node = neighbours[0][i];
                if (!node.isWall and !node.visited) {
                    node.cameFrom = startNode;
                    node.visited = true;
                    try self.stack.enqueue(node);
                }
            }
            self.allocator.free(neighbours[0]);
        }

        var count: usize = 0;
        var currentNode: *Node = startNode;
        search: while (self.stack.len != 0) : (count += 1) {
            currentNode = try self.stack.dequeue();
            // Grab neighbours
            const neighbours = try self.findNeighbour(currentNode);
            defer self.allocator.free(neighbours[0]);
            // Loop thorugh neighbours and add the valid ones to the queue
            for (0..neighbours[1]) |i| {
                const node: *Node = neighbours[0][i];
                // Node is not valid to search
                if (node.isWall or node.visited or node.isStart) {
                    continue;
                }
                node.visited = true;
                node.cameFrom = currentNode;
                if (node.isGoal) {
                    break :search;
                }
                try self.stack.enqueue(node);
            }
        } else {
            // Could not solve
            return null;
        }

        // Trace the path
        return self.tracePath(currentNode);
    }
};
