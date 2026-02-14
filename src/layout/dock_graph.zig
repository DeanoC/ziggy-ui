//! Dock graph layout system
const std = @import("std");

/// Dock node identifier
pub const DockNodeId = u32;

/// Dock split direction
pub const SplitDirection = enum {
    horizontal,
    vertical,
};

/// Dock node types
pub const DockNodeType = enum {
    leaf,      // Contains a panel
    split,     // Splits space between children
    tab_stack, // Stacked tabs
};

/// Dock node
pub const DockNode = struct {
    id: DockNodeId,
    parent_id: ?DockNodeId = null,
    node_type: DockNodeType = .leaf,
    
    // For split nodes
    split_direction: SplitDirection = .horizontal,
    split_ratio: f32 = 0.5,
    first_child: ?DockNodeId = null,
    second_child: ?DockNodeId = null,
    
    // For leaf/tab nodes
    panel_ids: std.ArrayList(DockNodeId) = undefined,
    active_tab: usize = 0,
    
    // Layout
    rect: Rect = .{},
    
    pub const Rect = struct {
        x: f32 = 0,
        y: f32 = 0,
        width: f32 = 0,
        height: f32 = 0,
        
        pub fn contains(self: Rect, point: [2]f32) bool {
            return point[0] >= self.x and point[0] <= self.x + self.width and
                   point[1] >= self.y and point[1] <= self.y + self.height;
        }
        
        pub fn center(self: Rect) [2]f32 {
            return .{ self.x + self.width * 0.5, self.y + self.height * 0.5 };
        }
    };
};

/// Dock graph manages the layout tree
pub const DockGraph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(DockNode),
    root_id: ?DockNodeId = null,
    next_id: DockNodeId = 1,

    pub fn init(allocator: std.mem.Allocator) DockGraph {
        return .{
            .allocator = allocator,
            .nodes = std.ArrayList(DockNode).init(allocator),
        };
    }

    pub fn deinit(self: *DockGraph) void {
        for (self.nodes.items) |*node| {
            if (node.node_type == .leaf or node.node_type == .tab_stack) {
                node.panel_ids.deinit();
            }
        }
        self.nodes.deinit();
    }

    /// Create a new node
    pub fn createNode(self: *DockGraph) !DockNodeId {
        const id = self.next_id;
        self.next_id += 1;
        
        try self.nodes.append(.{
            .id = id,
            .panel_ids = std.ArrayList(DockNodeId).init(self.allocator),
        });
        
        if (self.root_id == null) {
            self.root_id = id;
        }
        
        return id;
    }

    /// Split a node
    pub fn splitNode(
        self: *DockGraph,
        node_id: DockNodeId,
        direction: SplitDirection,
        ratio: f32,
    ) !struct { first: DockNodeId, second: DockNodeId } {
        const node = self.getNodeMut(node_id) orelse return error.NodeNotFound;
        
        const first = try self.createNode();
        const second = try self.createNode();
        
        node.node_type = .split;
        node.split_direction = direction;
        node.split_ratio = std.math.clamp(ratio, 0.1, 0.9);
        node.first_child = first;
        node.second_child = second;
        
        // Set parent references
        if (self.getNodeMut(first)) |n| n.parent_id = node_id;
        if (self.getNodeMut(second)) |n| n.parent_id = node_id;
        
        return .{ .first = first, .second = second };
    }

    /// Get node by ID
    pub fn getNode(self: *const DockGraph, id: DockNodeId) ?*const DockNode {
        for (self.nodes.items) |*node| {
            if (node.id == id) return node;
        }
        return null;
    }

    /// Get mutable node by ID
    pub fn getNodeMut(self: *DockGraph, id: DockNodeId) ?*DockNode {
        for (self.nodes.items) |*node| {
            if (node.id == id) return node;
        }
        return null;
    }

    /// Calculate layout for all nodes
    pub fn calculateLayout(self: *DockGraph, root_rect: DockNode.Rect) void {
        if (self.root_id) |root| {
            self.layoutNode(root, root_rect);
        }
    }

    fn layoutNode(self: *DockGraph, node_id: DockNodeId, rect: DockNode.Rect) void {
        const node = self.getNodeMut(node_id) orelse return;
        node.rect = rect;
        
        if (node.node_type == .split) {
            const first = node.first_child orelse return;
            const second = node.second_child orelse return;
            
            var first_rect = rect;
            var second_rect = rect;
            
            if (node.split_direction == .horizontal) {
                const split_x = rect.x + rect.width * node.split_ratio;
                first_rect.width = split_x - rect.x;
                second_rect.x = split_x;
                second_rect.width = rect.x + rect.width - split_x;
            } else {
                const split_y = rect.y + rect.height * node.split_ratio;
                first_rect.height = split_y - rect.y;
                second_rect.y = split_y;
                second_rect.height = rect.y + rect.height - split_y;
            }
            
            self.layoutNode(first, first_rect);
            self.layoutNode(second, second_rect);
        }
    }

    /// Find leaf node at position
    pub fn findNodeAt(self: *const DockGraph, pos: [2]f32) ?DockNodeId {
        return self.findNodeAtRecursive(self.root_id, pos);
    }

    fn findNodeAtRecursive(self: *const DockGraph, node_id: ?DockNodeId, pos: [2]f32) ?DockNodeId {
        const id = node_id orelse return null;
        const node = self.getNode(id) orelse return null;
        
        if (!node.rect.contains(pos)) return null;
        
        if (node.node_type == .leaf) {
            return id;
        }
        
        if (node.node_type == .split) {
            if (self.findNodeAtRecursive(node.first_child, pos)) |found| return found;
            if (self.findNodeAtRecursive(node.second_child, pos)) |found| return found;
        }
        
        return id;
    }
};
