const std = @import("std");

const QueueError = error{
    QueueEmpty,
};

pub fn Queue(comptime T: type) type {
    return struct {
        len: usize,
        allocator: std.mem.Allocator,
        head: ?*Node(T),
        tail: ?*Node(T),

        pub fn Node(comptime _T: type) type {
            return struct {
                next: ?*Node(_T) = null,
                val: *_T = undefined,
            };
        }

        pub fn init(allocator: std.mem.Allocator) !*Queue(T) {
            const queue = try allocator.create(Queue(T));
            queue.* = Queue(T){
                .len = 0,
                .allocator = allocator,
                .head = null,
                .tail = null,
            };
            return queue;
        }

        pub fn deinit(self: *Queue(T)) void {
            var current = self.head;
            while (current != null) {
                const temp = current.?.next;
                self.allocator.destroy(current.?);
                current = temp;
            }
            self.allocator.destroy(self);
        }

        pub fn enqueue(self: *Queue(T), val: *T) !void {
            const node = try self.allocator.create(Node(T));
            node.* = Node(T){
                .next = null,
                .val = val,
            };
            self.len += 1;
            // If the head is null the tail should be null,
            // So we can set node to both, this is true for the first enque,
            if (self.tail == null) {
                self.head = node;
                self.tail = node;
            } else {
                self.tail.?.next = node;
                self.tail = node;
            }
        }

        pub fn dequeue(self: *Queue(T)) !*T {
            if (self.tail == null) {
                return QueueError.QueueEmpty;
            }

            const val = self.head.?.val;
            // End of queue
            if (self.head.?.next == null) {
                self.allocator.destroy(self.head.?);
                self.tail = null;
                self.head = null;
            } else {
                const head = self.head.?;
                self.head = self.head.?.next;
                self.allocator.destroy(head);
            }

            self.len -= 1;
            return val;
        }

        pub fn peek(self: *Queue(T)) !*T {
            if (self.head == null) {
                return QueueError.QueueEmpty;
            }

            return self.head.?.val;
        }
    };
}
