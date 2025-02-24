const std = @import("std");

const StackError = error{
    StackEmpty,
};

pub fn Stack(comptime T: type) type {
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

        pub fn init(allocator: std.mem.Allocator) !*Stack(T) {
            const queue = try allocator.create(Stack(T));
            queue.* = Stack(T){
                .len = 0,
                .allocator = allocator,
                .head = null,
                .tail = null,
            };
            return queue;
        }

        pub fn deinit(self: *Stack(T)) void {
            var current = self.head;
            while (current != null) {
                const temp = current.?.next;
                self.allocator.destroy(current.?);
                current = temp;
            }
            self.allocator.destroy(self);
        }

        pub fn enqueue(self: *Stack(T), val: *T) !void {
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
                node.next = self.head;
                self.head = node;
            }
        }

        pub fn dequeue(self: *Stack(T)) !*T {
            if (self.head == null) {
                return StackError.StackEmpty;
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

        pub fn peek(self: *Stack(T)) !*T {
            if (self.head == null) {
                return StackError.StackEmpty;
            }

            return self.head.?.val;
        }
    };
}
