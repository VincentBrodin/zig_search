const std = @import("std");
const fs = std.fs;

const Node = struct {
    cameFrom: ?*Node = null,
    cost: u32 = 0,
    i: u32 = 0,
    j: u32 = 0,
    isWall: bool = false,
    isStart: bool = false,
    isGoal: bool = false,
};

const Queue = struct {
    const QueueError = error{
        NoHead,
    };

    head: ?*QueueNode = null,
    tail: ?*QueueNode = null,
    allocator: *std.mem.Allocator,
    size: usize = 0,

    const QueueNode = struct {
        next: ?*QueueNode = null,
        val: *Node,
    };

    pub fn deinit(self: *Queue) void {
        while (self.head != null) {
            const temp = self.head.?;
            self.head = self.head.?.next;
            self.allocator.destroy(temp);
        }
        self.size = 0;
    }

    pub fn Enqueue(self: *Queue, val: *Node) !void {
        const temp = try self.allocator.create(QueueNode);
        temp.val = val;
        if (self.head == null) {
            self.head = temp;
            self.tail = temp;
        } else {
            self.tail.?.next = temp;
            self.tail = temp;
        }
        self.size += 1;
    }

    pub fn Dequeue(self: *Queue) !*Node {
        if (self.head == null) {
            return QueueError.NoHead;
        }
        const temp = self.head;
        self.head = self.head.?.next;
        self.size -= 1;
        if (temp == null) {
            return QueueError.NoHead;
        }
        const val = temp.?.*.val;
        self.allocator.destroy(temp.?);
        return val;
    }
};

const Alloc = std.heap.GeneralPurposeAllocator(.{});

pub fn old_main() !void {
    const cwd = fs.cwd();
    const folderPath = "maps";
    // try to make directory and ignore error if already exists
    cwd.makeDir(folderPath) catch |err| {
        switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        }
    };

    const maps = try cwd.openDir(folderPath, .{});

    // Open file
    const filePath = "map.txt";
    const file = try maps.openFile(filePath, .{});
    defer file.close();

    // Get the size of the file
    const stat = try file.stat();
    const fileSize = stat.size;

    // Create gpa
    var gpa = Alloc{};
    defer _ = gpa.deinit();
    const allocater = gpa.allocator();

    // Read file
    const content = try file.readToEndAlloc(allocater, fileSize);
    defer allocater.free(content);

    // Create map
    var lines = std.mem.tokenizeAny(u8, content, "\n");
    var cols: usize = 0;
    while (lines.next()) |_| : (cols += 1) {}
    lines.reset();
    var map = try allocater.alloc([]Node, cols);
    defer {
        for (map) |col| {
            allocater.free(col);
        }
        allocater.free(map);
    }

    // Fill map
    var i: u32 = 0;
    while (lines.next()) |line| : (i += 1) {
        const size = line.len - 1;
        map[i] = try allocater.alloc(Node, size);
        for (line, 0..) |c, j| {
            if (j == size) {
                break;
            }
            map[i][j] = switch (c) {
                '#' => Node{
                    .isWall = true,
                },
                's' => Node{
                    .isStart = true,
                },
                'g' => Node{
                    .isGoal = true,
                },
                else => Node{},
            };
            map[i][j].i = @intCast(i);
            map[i][j].j = @intCast(j);
        }
    }

    // Ready to work :)
    const solved = try solveMap(&map);
    std.debug.print("Is solved {}", .{solved});
}

fn solveMap(map: *[][]Node) !bool {
    std.debug.print("Trying to solve map\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocater = gpa.allocator();
    var queue = Queue{ .allocator = &allocater };
    defer queue.deinit();

    var startI: usize = 0;
    var startJ: usize = 0;
    findStart: for (map.*, 0..) |row, i| {
        for (row, 0..) |node, j| {
            if (node.isStart) {
                startI = i;
                startJ = j;
                break :findStart;
            }
        }
    } else {
        return false;
    }

    {
        const currentNode = &(map.*[startI][startJ]);
        const up = getUp(map, currentNode);
        if (up != null) {
            try queue.Enqueue(up.?);
        }
        const down = getDown(map, currentNode);
        if (down != null) {
            try queue.Enqueue(down.?);
        }
        const left = getLeft(map, currentNode);
        if (left != null) {
            try queue.Enqueue(left.?);
        }
        const right = getRight(map, currentNode);
        if (right != null) {
            try queue.Enqueue(right.?);
        }
    }

    if (queue.size == 0) {
        return false;
    }
    var steps: u32 = 0;
    while (queue.size != 0) : (steps += 1) {
        const currentNode = try queue.Dequeue();
        const up = getUp(map, currentNode);
        if (up != null) {
            if (up.?.isGoal) {
                break;
            }
            try queue.Enqueue(up.?);
        }
        const down = getDown(map, currentNode);
        if (down != null) {
            if (down.?.isGoal) {
                break;
            }
            try queue.Enqueue(down.?);
        }
        const left = getLeft(map, currentNode);
        if (left != null) {
            if (left.?.isGoal) {
                break;
            }
            try queue.Enqueue(left.?);
        }
        const right = getRight(map, currentNode);
        if (right != null) {
            if (right.?.isGoal) {
                break;
            }
            try queue.Enqueue(right.?);
        }
    } else {
        return false;
    }

    std.debug.print("Steps to solve: {}", .{steps});

    return true;
}

fn getUp(map: *[][]Node, node: *Node) ?*Node {
    const newRow: u32 = @subWithOverflow(node.i, 1)[0];
    const col = node.j;
    if (newRow < map.*.len and col < map.*[newRow].len) {
        return &(map.*[newRow][col]);
    } else {
        return null;
    }
}

fn getDown(map: *[][]Node, node: *Node) ?*Node {
    const newRow: u32 = @addWithOverflow(node.i, 1)[0];
    const col = node.j;
    if (newRow < map.*.len and col < map.*[newRow].len) {
        return &(map.*[newRow][col]);
    } else {
        return null;
    }
}

fn getLeft(map: *[][]Node, node: *Node) ?*Node {
    const i = node.i;
    const j: u32 = @subWithOverflow(node.j, 1)[0];
    if ((j >= 0) and (j < map.len)) {
        return &(map.*[i][j]);
    } else {
        return null;
    }
}

fn getRight(map: *[][]Node, node: *Node) ?*Node {
    const i = node.i;
    const j: u32 = @addWithOverflow(node.j, 1)[0];
    if ((j >= 0) and (j < map.len)) {
        return &(map.*[i][j]);
    } else {
        return null;
    }
}

fn printMap(map: *[][]Node) void {
    for (map) |row| {
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
