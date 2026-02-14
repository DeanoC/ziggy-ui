//! Window management and docking system
const std = @import("std");
const Rect = @import("../core/context.zig").Rect;
const Vec2 = @import("../core/context.zig").Vec2;

/// Unique identifier for panels
pub const PanelId = u64;

/// Unique identifier for dock nodes
pub const NodeId = u32;

/// Docking axis for split nodes
pub const Axis = enum {
    vertical,
    horizontal,
};

/// Drop location for dock operations
pub const DropLocation = enum {
    left,
    right,
    top,
    bottom,
    center,
};

/// Split node - divides space between two children
pub const SplitNode = struct {
    axis: Axis,
    ratio: f32, // 0.0 to 1.0, position of split
    first: NodeId,
    second: NodeId,
};

/// Tabs node - contains stacked panels with tabs
pub const TabsNode = struct {
    active: usize = 0,
    tabs: std.ArrayList(PanelId),

    pub fn deinit(self: *TabsNode, allocator: std.mem.Allocator) void {
        self.tabs.deinit(allocator);
    }

    pub fn contains(self: TabsNode, panel_id: PanelId) bool {
        for (self.tabs.items) |id| {
            if (id == panel_id) return true;
        }
        return false;
    }

    pub fn indexOf(self: TabsNode, panel_id: PanelId) ?usize {
        for (self.tabs.items, 0..) |id, i| {
            if (id == panel_id) return i;
        }
        return null;
    }

    pub fn remove(self: *TabsNode, allocator: std.mem.Allocator, panel_id: PanelId) bool {
        const idx = self.indexOf(panel_id) orelse return false;
        _ = self.tabs.orderedRemove(allocator, idx);
        if (self.active >= self.tabs.items.len and self.tabs.items.len > 0) {
            self.active = self.tabs.items.len - 1;
        }
        return true;
    }
};

/// Dock node - either a split or tabs container
pub const DockNode = union(enum) {
    split: SplitNode,
    tabs: TabsNode,

    pub fn deinit(self: *DockNode, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .split => {},
            .tabs => |*tabs| tabs.deinit(allocator),
        }
    }

    pub fn containsPanel(self: DockNode, panel_id: PanelId) bool {
        switch (self) {
            .split => return false,
            .tabs => |tabs| return tabs.contains(panel_id),
        }
    }
};

/// Serializable split node snapshot
pub const SplitSnapshot = struct {
    axis: Axis,
    ratio: f32,
    first: NodeId,
    second: NodeId,
};

/// Serializable tabs node snapshot
pub const TabsSnapshot = struct {
    active: usize = 0,
    tabs: ?[]PanelId = null,

    pub fn deinit(self: *TabsSnapshot, allocator: std.mem.Allocator) void {
        if (self.tabs) |tabs| allocator.free(tabs);
        self.* = undefined;
    }
};

/// Serializable node snapshot
pub const NodeSnapshot = struct {
    id: NodeId,
    split: ?SplitSnapshot = null,
    tabs: ?TabsSnapshot = null,

    pub fn deinit(self: *NodeSnapshot, allocator: std.mem.Allocator) void {
        if (self.tabs) |*tabs| {
            tabs.deinit(allocator);
        }
        self.* = undefined;
    }
};

/// Serializable dock graph snapshot
pub const DockSnapshot = struct {
    layout_version: u32 = 2,
    root: ?NodeId = null,
    nodes: ?[]NodeSnapshot = null,

    pub fn deinit(self: *DockSnapshot, allocator: std.mem.Allocator) void {
        if (self.nodes) |nodes| {
            for (nodes) |*n| n.deinit(allocator);
            allocator.free(nodes);
        }
        self.* = undefined;
    }
};

/// Layout group - result of layout computation
pub const LayoutGroup = struct {
    node_id: NodeId,
    rect: Rect,
};

/// Splitter handle for resizing
pub const Splitter = struct {
    node_id: NodeId,
    axis: Axis,
    handle_rect: Rect,
    container_rect: Rect,
};

/// Result of layout computation
pub const LayoutResult = struct {
    groups: [32]LayoutGroup = undefined,
    len: usize = 0,

    pub fn append(self: *LayoutResult, g: LayoutGroup) void {
        if (self.len >= self.groups.len) return;
        self.groups[self.len] = g;
        self.len += 1;
    }

    pub fn slice(self: *const LayoutResult) []const LayoutGroup {
        return self.groups[0..self.len];
    }
};

/// Result of splitter computation
pub const SplitterResult = struct {
    splitters: [32]Splitter = undefined,
    len: usize = 0,

    pub fn append(self: *SplitterResult, s: Splitter) void {
        if (self.len >= self.splitters.len) return;
        self.splitters[self.len] = s;
        self.len += 1;
    }

    pub fn slice(self: *const SplitterResult) []const Splitter {
        return self.splitters[0..self.len];
    }
};

/// Panel location within the dock graph
pub const PanelLocation = struct {
    node_id: NodeId,
    tab_index: usize,
};

/// Dock graph - manages the tree of dock nodes
pub const DockGraph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(?DockNode),
    root: ?NodeId = null,
    next_node_id: NodeId = 1,

    pub fn init(allocator: std.mem.Allocator) DockGraph {
        return .{
            .allocator = allocator,
            .nodes = .empty,
        };
    }

    pub fn deinit(self: *DockGraph) void {
        for (self.nodes.items) |*node_opt| {
            if (node_opt.*) |*node| node.deinit(self.allocator);
        }
        self.nodes.deinit(self.allocator);
        self.* = undefined;
    }

    pub fn clear(self: *DockGraph) void {
        for (self.nodes.items) |*node_opt| {
            if (node_opt.*) |*node| node.deinit(self.allocator);
            node_opt.* = null;
        }
        self.nodes.clearRetainingCapacity();
        self.root = null;
    }

    /// Clone from another dock graph
    pub fn cloneFrom(self: *DockGraph, src: *const DockGraph) !void {
        self.clear();
        try self.nodes.ensureTotalCapacity(self.allocator, src.nodes.items.len);
        for (src.nodes.items) |node_opt| {
            if (node_opt) |node| {
                switch (node) {
                    .split => |s| try self.nodes.append(self.allocator, .{ .split = s }),
                    .tabs => |tabs| {
                        var new_tabs = std.ArrayList(PanelId).empty;
                        try new_tabs.ensureTotalCapacity(self.allocator, tabs.tabs.items.len);
                        try new_tabs.appendSlice(self.allocator, tabs.tabs.items);
                        try self.nodes.append(self.allocator, .{ .tabs = .{ .active = tabs.active, .tabs = new_tabs } });
                    },
                }
            } else {
                try self.nodes.append(self.allocator, null);
            }
        }
        self.root = src.root;
    }

    /// Create a tabs node
    pub fn addTabsNode(self: *DockGraph, panel_ids: []const PanelId, active_index: usize) !NodeId {
        const id = self.next_node_id;
        self.next_node_id += 1;

        const idx: usize = @intCast(id);
        if (idx >= self.nodes.items.len) {
            try self.nodes.resize(self.allocator, idx + 1);
        }

        var tabs = std.ArrayList(PanelId).empty;
        try tabs.ensureTotalCapacity(self.allocator, panel_ids.len);
        try tabs.appendSlice(self.allocator, panel_ids);

        self.nodes.items[idx] = .{ .tabs = .{ .active = active_index, .tabs = tabs } };
        return id;
    }

    /// Create a split node
    pub fn addSplitNode(self: *DockGraph, axis: Axis, ratio: f32, first: NodeId, second: NodeId) !NodeId {
        const id = self.next_node_id;
        self.next_node_id += 1;

        const idx: usize = @intCast(id);
        if (idx >= self.nodes.items.len) {
            try self.nodes.resize(self.allocator, idx + 1);
        }

        self.nodes.items[idx] = .{ .split = .{
            .axis = axis,
            .ratio = std.math.clamp(ratio, 0.1, 0.9),
            .first = first,
            .second = second,
        } };
        return id;
    }

    /// Get a node by ID
    pub fn getNode(self: *DockGraph, id: NodeId) ?*DockNode {
        const idx: usize = @intCast(id);
        if (idx >= self.nodes.items.len) return null;
        return &self.nodes.items[idx].?;
    }

    /// Remove a panel from the graph
    pub fn removePanel(self: *DockGraph, panel_id: PanelId) bool {
        var found = false;
        for (self.nodes.items) |*node_opt| {
            if (node_opt.*) |*node| {
                switch (node.*) {
                    .tabs => |*tabs| {
                        if (tabs.remove(self.allocator, panel_id)) {
                            found = true;
                        }
                    },
                    .split => {},
                }
            }
        }
        return found;
    }

    /// Find which node contains a panel
    pub fn findPanel(self: *const DockGraph, panel_id: PanelId) ?PanelLocation {
        for (self.nodes.items, 0..) |node_opt, idx| {
            if (node_opt) |node| {
                switch (node) {
                    .tabs => |tabs| {
                        if (tabs.indexOf(panel_id)) |tab_idx| {
                            return .{ .node_id = @intCast(idx), .tab_index = tab_idx };
                        }
                    },
                    .split => {},
                }
            }
        }
        return null;
    }

    /// Compute layout rectangles for all tab groups
    pub fn computeLayout(self: *const DockGraph, available: Rect) LayoutResult {
        var result = LayoutResult{};
        if (self.root) |root_id| {
            self.computeLayoutRecursive(root_id, available, &result);
        }
        return result;
    }

    fn computeLayoutRecursive(self: *const DockGraph, node_id: NodeId, rect: Rect, result: *LayoutResult) void {
        const node = self.nodes.items[@intCast(node_id)] orelse return;

        switch (node) {
            .split => |split| {
                const ratio = split.ratio;
                if (split.axis == .vertical) {
                    const split_x = rect.min[0] + (rect.max[0] - rect.min[0]) * ratio;
                    const first_rect = Rect{
                        .min = rect.min,
                        .max = .{ split_x, rect.max[1] },
                    };
                    const second_rect = Rect{
                        .min = .{ split_x, rect.min[1] },
                        .max = rect.max,
                    };
                    self.computeLayoutRecursive(split.first, first_rect, result);
                    self.computeLayoutRecursive(split.second, second_rect, result);
                } else {
                    const split_y = rect.min[1] + (rect.max[1] - rect.min[1]) * ratio;
                    const first_rect = Rect{
                        .min = rect.min,
                        .max = .{ rect.max[0], split_y },
                    };
                    const second_rect = Rect{
                        .min = .{ rect.min[0], split_y },
                        .max = rect.max,
                    };
                    self.computeLayoutRecursive(split.first, first_rect, result);
                    self.computeLayoutRecursive(split.second, second_rect, result);
                }
            },
            .tabs => {
                result.append(.{ .node_id = node_id, .rect = rect });
            },
        }
    }

    /// Compute splitter handles for interactive resizing
    pub fn computeSplitters(self: *const DockGraph, available: Rect) SplitterResult {
        var result = SplitterResult{};
        if (self.root) |root_id| {
            self.computeSplittersRecursive(root_id, available, &result);
        }
        return result;
    }

    fn computeSplittersRecursive(self: *const DockGraph, node_id: NodeId, rect: Rect, result: *SplitterResult) void {
        const node = self.nodes.items[@intCast(node_id)] orelse return;

        switch (node) {
            .split => |split| {
                const ratio = split.ratio;
                const handle_thickness: f32 = 6.0;

                if (split.axis == .vertical) {
                    const split_x = rect.min[0] + (rect.max[0] - rect.min[0]) * ratio;
                    const handle_rect = Rect{
                        .min = .{ split_x - handle_thickness / 2.0, rect.min[1] },
                        .max = .{ split_x + handle_thickness / 2.0, rect.max[1] },
                    };
                    result.append(.{
                        .node_id = node_id,
                        .axis = .vertical,
                        .handle_rect = handle_rect,
                        .container_rect = rect,
                    });

                    const first_rect = Rect{
                        .min = rect.min,
                        .max = .{ split_x, rect.max[1] },
                    };
                    const second_rect = Rect{
                        .min = .{ split_x, rect.min[1] },
                        .max = rect.max,
                    };
                    self.computeSplittersRecursive(split.first, first_rect, result);
                    self.computeSplittersRecursive(split.second, second_rect, result);
                } else {
                    const split_y = rect.min[1] + (rect.max[1] - rect.min[1]) * ratio;
                    const handle_rect = Rect{
                        .min = .{ rect.min[0], split_y - handle_thickness / 2.0 },
                        .max = .{ rect.max[0], split_y + handle_thickness / 2.0 },
                    };
                    result.append(.{
                        .node_id = node_id,
                        .axis = .horizontal,
                        .handle_rect = handle_rect,
                        .container_rect = rect,
                    });

                    const first_rect = Rect{
                        .min = rect.min,
                        .max = .{ rect.max[0], split_y },
                    };
                    const second_rect = Rect{
                        .min = .{ rect.min[0], split_y },
                        .max = rect.max,
                    };
                    self.computeSplittersRecursive(split.first, first_rect, result);
                    self.computeSplittersRecursive(split.second, second_rect, result);
                }
            },
            .tabs => {},
        }
    }

    /// Update split ratio from drag position
    pub fn updateSplitRatio(self: *DockGraph, node_id: NodeId, container_rect: Rect, drag_pos: Vec2) void {
        const node = self.nodes.items[@intCast(node_id)] orelse return;

        switch (node) {
            .split => |*split| {
                const new_ratio = if (split.axis == .vertical)
                    std.math.clamp((drag_pos[0] - container_rect.min[0]) / (container_rect.max[0] - container_rect.min[0]), 0.1, 0.9)
                else
                    std.math.clamp((drag_pos[1] - container_rect.min[1]) / (container_rect.max[1] - container_rect.min[1]), 0.1, 0.9);
                split.ratio = new_ratio;
            },
            .tabs => {},
        }
    }

    /// Move a panel to a drop location
    pub fn movePanel(self: *DockGraph, panel_id: PanelId, target_node_id: NodeId, location: DropLocation) !void {
        // Remove from current location
        _ = self.removePanel(panel_id);

        // Add to new location
        const target_node = self.getNode(target_node_id) orelse return;

        switch (target_node.*) {
            .tabs => |*tabs| {
                if (location == .center) {
                    try tabs.tabs.append(self.allocator, panel_id);
                } else {
                    // Split the node
                    const axis: Axis = if (location == .left or location == .right) .vertical else .horizontal;
                    const ratio: f32 = if (location == .left or location == .top) 0.5 else 0.5;

                    var old_tabs = std.ArrayList(PanelId).empty;
                    try old_tabs.ensureTotalCapacity(self.allocator, tabs.tabs.items.len);
                    try old_tabs.appendSlice(self.allocator, tabs.tabs.items);
                    const old_node_id = try self.addTabsNode(old_tabs.items, tabs.active);
                    old_tabs.deinit(self.allocator);

                    const new_node_id = try self.addTabsNode(&[_]PanelId{panel_id}, 0);

                    const first = if (location == .left or location == .top) new_node_id else old_node_id;
                    const second = if (location == .left or location == .top) old_node_id else new_node_id;

                    const new_split_id = try self.addSplitNode(axis, ratio, first, second);

                    // Replace target node with split
                    target_node.* = self.nodes.items[@intCast(new_split_id)].?;
                    self.nodes.items[@intCast(new_split_id)] = null;
                }
            },
            .split => {},
        }
    }

    /// Serialize to snapshot
    pub fn toSnapshot(self: *const DockGraph, allocator: std.mem.Allocator) !DockSnapshot {
        var snap = DockSnapshot{ .layout_version = 2, .root = self.root, .nodes = null };
        errdefer snap.deinit(allocator);

        if (self.root == null) return snap;

        // Collect all node IDs via BFS
        var seen = std.AutoHashMap(NodeId, void).init(allocator);
        defer seen.deinit();

        var stack = std.ArrayList(NodeId).empty;
        defer stack.deinit(allocator);

        try stack.append(allocator, self.root.?);
        while (stack.pop()) |nid| {
            if (seen.contains(nid)) continue;
            try seen.put(nid, {});

            const node = self.nodes.items[@intCast(nid)] orelse continue;
            switch (node) {
                .split => |s| {
                    try stack.append(allocator, s.first);
                    try stack.append(allocator, s.second);
                },
                .tabs => {},
            }
        }

        // Create snapshots
        var nodes = try allocator.alloc(NodeSnapshot, seen.count());
        errdefer allocator.free(nodes);

        var i: usize = 0;
        var it = seen.keyIterator();
        while (it.next()) |key_ptr| : (i += 1) {
            const nid = key_ptr.*;
            const node = self.nodes.items[@intCast(nid)] orelse continue;

            var ns = NodeSnapshot{ .id = nid };
            switch (node) {
                .split => |s| {
                    ns.split = .{ .axis = s.axis, .ratio = s.ratio, .first = s.first, .second = s.second };
                },
                .tabs => |t| {
                    const list = try allocator.alloc(PanelId, t.tabs.items.len);
                    @memcpy(list, t.tabs.items);
                    ns.tabs = .{ .active = t.active, .tabs = list };
                },
            }
            nodes[i] = ns;
        }

        snap.nodes = nodes;
        return snap;
    }

    /// Deserialize from snapshot
    pub fn fromSnapshot(allocator: std.mem.Allocator, snap: DockSnapshot) !DockGraph {
        var g = DockGraph.init(allocator);
        errdefer g.deinit();

        g.root = snap.root;

        const nodes = snap.nodes orelse return g;

        // Find max ID
        var max_id: NodeId = 0;
        for (nodes) |n| {
            if (n.id > max_id) max_id = n.id;
        }

        // Resize nodes array
        const cap: usize = @as(usize, @intCast(max_id)) + 1;
        try g.nodes.resize(allocator, cap);
        for (g.nodes.items) |*slot| slot.* = null;

        // Populate nodes
        for (nodes) |n| {
            const idx: usize = @intCast(n.id);
            if (n.tabs) |tabs_snap| {
                var tabs = std.ArrayList(PanelId).empty;
                const src_tabs = tabs_snap.tabs orelse &[_]PanelId{};
                try tabs.ensureTotalCapacity(allocator, src_tabs.len);
                try tabs.appendSlice(allocator, src_tabs);
                g.nodes.items[idx] = .{ .tabs = .{ .active = tabs_snap.active, .tabs = tabs } };
            } else if (n.split) |split| {
                g.nodes.items[idx] = .{ .split = .{
                    .axis = split.axis,
                    .ratio = split.ratio,
                    .first = split.first,
                    .second = split.second,
                } };
            }
        }

        g.next_node_id = max_id + 1;
        return g;
    }
};

/// Panel - represents a dockable content panel
pub const Panel = struct {
    id: PanelId,
    title: []const u8,
    userdata: ?*anyopaque = null,

    // Callbacks
    draw_callback: ?*const fn (panel: *Panel, rect: Rect, ctx: ?*anyopaque) void = null,
    draw_ctx: ?*anyopaque = null,

    pub fn init(allocator: std.mem.Allocator, id: PanelId, title: []const u8) !Panel {
        const title_copy = try allocator.dupe(u8, title);
        return .{
            .id = id,
            .title = title_copy,
        };
    }

    pub fn deinit(self: *Panel, allocator: std.mem.Allocator) void {
        allocator.free(self.title);
    }

    pub fn draw(self: *Panel, rect: Rect) void {
        if (self.draw_callback) |cb| {
            cb(self, rect, self.draw_ctx);
        }
    }
};
