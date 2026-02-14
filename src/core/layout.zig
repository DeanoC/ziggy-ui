//! Layout engine for automatic widget positioning
const std = @import("std");
const Rect = @import("context.zig").Rect;
const Vec2 = @import("context.zig").Vec2;

/// Layout direction
pub const Direction = enum {
    horizontal,
    vertical,
};

/// Child alignment
pub const Alignment = enum {
    start,    // Top or left
    center,   // Centered
    end,      // Bottom or right
    stretch,  // Fill available space
};

/// Spacing between elements
pub const Spacing = struct {
    main: f32 = 0.0,      // Along the layout direction
    cross: f32 = 0.0,     // Perpendicular to layout direction
};

/// Layout constraints passed to children
pub const Constraints = struct {
    min_width: f32 = 0.0,
    max_width: f32 = std.math.inf(f32),
    min_height: f32 = 0.0,
    max_height: f32 = std.math.inf(f32),

    pub fn tight(size: Vec2) Constraints {
        return .{
            .min_width = size[0],
            .max_width = size[0],
            .min_height = size[1],
            .max_height = size[1],
        };
    }

    pub fn loose(size: Vec2) Constraints {
        return .{
            .min_width = 0.0,
            .max_width = size[0],
            .min_height = 0.0,
            .max_height = size[1],
        };
    }

    pub fn isTight(self: Constraints) bool {
        return self.min_width == self.max_width and 
               self.min_height == self.max_height;
    }

    pub fn constrain(self: Constraints, size: Vec2) Vec2 {
        return .{
            std.math.clamp(size[0], self.min_width, self.max_width),
            std.math.clamp(size[1], self.min_height, self.max_height),
        };
    }
};

/// Layout node - represents a widget in the layout tree
pub const LayoutNode = struct {
    id: u64,
    rect: Rect,
    children: std.ArrayList(u64), // IDs of child nodes
    
    // Layout properties
    flex: f32 = 0.0,              // Flex factor for proportional sizing
    margin: [4]f32 = .{ 0, 0, 0, 0 }, // left, top, right, bottom
    padding: [4]f32 = .{ 0, 0, 0, 0 },
    min_size: Vec2 = .{ 0, 0 },
    max_size: Vec2 = .{ std.math.inf(f32), std.math.inf(f32) },
    preferred_size: ?Vec2 = null,
    
    // Alignment
    align_self: ?Alignment = null, // Override parent's cross-axis alignment
    
    pub fn getContentRect(self: LayoutNode) Rect {
        return .{
            .min = .{ 
                self.rect.min[0] + self.padding[0], 
                self.rect.min[1] + self.padding[1] 
            },
            .max = .{ 
                self.rect.max[0] - self.padding[2], 
                self.rect.max[1] - self.padding[3] 
            },
        };
    }
};

/// Flex layout configuration
pub const FlexConfig = struct {
    direction: Direction = .horizontal,
    main_align: Alignment = .start,
    cross_align: Alignment = .stretch,
    wrap: bool = false,
    spacing: Spacing = .{},
};

/// Layout engine - computes widget positions
pub const LayoutEngine = struct {
    allocator: std.mem.Allocator,
    nodes: std.AutoHashMap(u64, LayoutNode),
    root_id: ?u64 = null,
    next_id: u64 = 1,

    pub fn init(allocator: std.mem.Allocator) LayoutEngine {
        return .{
            .allocator = allocator,
            .nodes = std.AutoHashMap(u64, LayoutNode).init(allocator),
        };
    }

    pub fn deinit(self: *LayoutEngine) void {
        var it = self.nodes.valueIterator();
        while (it.next()) |node| {
            node.children.deinit(self.allocator);
        }
        self.nodes.deinit();
    }

    pub fn createNode(self: *LayoutEngine, parent_id: ?u64) !u64 {
        const id = self.next_id;
        self.next_id += 1;

        var node = LayoutNode{
            .id = id,
            .rect = .{ .min = .{ 0, 0 }, .max = .{ 0, 0 } },
            .children = .empty,
        };

        try self.nodes.put(id, node);

        if (parent_id) |pid| {
            if (self.nodes.getPtr(pid)) |parent| {
                try parent.children.append(self.allocator, id);
            }
        } else {
            self.root_id = id;
        }

        return id;
    }

    pub fn removeNode(self: *LayoutEngine, id: u64) void {
        if (self.nodes.fetchRemove(id)) |kv| {
            kv.value.children.deinit(self.allocator);
        }
    }

    pub fn getNode(self: *LayoutEngine, id: u64) ?*LayoutNode {
        return self.nodes.getPtr(id);
    }

    pub fn setNodeRect(self: *LayoutEngine, id: u64, rect: Rect) void {
        if (self.nodes.getPtr(id)) |node| {
            node.rect = rect;
        }
    }

    /// Compute flex layout for a container
    pub fn computeFlexLayout(
        self: *LayoutEngine,
        container_id: u64,
        available_size: Vec2,
        config: FlexConfig,
    ) !void {
        const container = self.nodes.getPtr(container_id) orelse return;
        const child_ids = container.children.items;
        
        if (child_ids.len == 0) return;

        // First pass: measure non-flex children
        var total_flex: f32 = 0.0;
        var used_main: f32 = 0.0;
        var max_cross: f32 = 0.0;

        for (child_ids) |child_id| {
            const child = self.nodes.getPtr(child_id) orelse continue;
            
            if (child.flex > 0.0) {
                total_flex += child.flex;
            } else {
                const child_size = child.preferred_size orelse child.min_size;
                const margin_main = switch (config.direction) {
                    .horizontal => child.margin[0] + child.margin[2],
                    .vertical => child.margin[1] + child.margin[3],
                };
                const margin_cross = switch (config.direction) {
                    .horizontal => child.margin[1] + child.margin[3],
                    .vertical => child.margin[0] + child.margin[2],
                };
                
                used_main += switch (config.direction) {
                    .horizontal => child_size[0] + margin_main,
                    .vertical => child_size[1] + margin_main,
                };
                max_cross = @max(max_cross, switch (config.direction) {
                    .horizontal => child_size[1] + margin_cross,
                    .vertical => child_size[0] + margin_cross,
                });
            }
        }

        // Add spacing between children
        const total_spacing = config.spacing.main * @as(f32, @floatFromInt(child_ids.len -| 1));
        used_main += total_spacing;

        // Second pass: compute flex sizes and positions
        const available_main = switch (config.direction) {
            .horizontal => available_size[0] - container.padding[0] - container.padding[2],
            .vertical => available_size[1] - container.padding[1] - container.padding[3],
        };
        const available_cross = switch (config.direction) {
            .horizontal => available_size[1] - container.padding[1] - container.padding[3],
            .vertical => available_size[0] - container.padding[0] - container.padding[2],
        };

        const remaining = @max(0.0, available_main - used_main);
        const flex_unit = if (total_flex > 0.0) remaining / total_flex else 0.0;

        // Compute starting position based on main alignment
        var pos_main: f32 = switch (config.main_align) {
            .start => 0.0,
            .center => remaining / 2.0,
            .end => remaining,
            .stretch => 0.0,
        };
        pos_main += switch (config.direction) {
            .horizontal => container.padding[0],
            .vertical => container.padding[1],
        };

        // Position children
        for (child_ids) |child_id| {
            const child = self.nodes.getPtr(child_id) orelse continue;
            
            // Calculate size
            var child_size: Vec2 = undefined;
            if (child.flex > 0.0) {
                const flex_size = child.flex * flex_unit;
                child_size = switch (config.direction) {
                    .horizontal => .{ flex_size, available_cross },
                    .vertical => .{ available_cross, flex_size },
                };
            } else {
                child_size = child.preferred_size orelse child.min_size;
            }

            // Apply cross-axis alignment
            const margin_cross_start = switch (config.direction) {
                .horizontal => child.margin[1],
                .vertical => child.margin[0],
            };
            const margin_cross_end = switch (config.direction) {
                .horizontal => child.margin[3],
                .vertical => child.margin[2],
            };
            const margin_main_start = switch (config.direction) {
                .horizontal => child.margin[0],
                .vertical => child.margin[1],
            };

            const cross_align = child.align_self orelse config.cross_align;
            const content_cross = available_cross - margin_cross_start - margin_cross_end;
            
            var pos_cross: f32 = switch (cross_align) {
                .start => margin_cross_start,
                .center => (available_cross - child_size[@intFromBool(config.direction == .vertical)]) / 2.0,
                .end => available_cross - child_size[@intFromBool(config.direction == .vertical)] - margin_cross_end,
                .stretch => margin_cross_start,
            };
            pos_cross += switch (config.direction) {
                .horizontal => container.padding[1],
                .vertical => container.padding[0],
            };

            // Set child rect
            const final_size: Vec2 = switch (cross_align) {
                .stretch => .{
                    if (config.direction == .horizontal) child_size[0] else content_cross,
                    if (config.direction == .vertical) child_size[1] else content_cross,
                },
                else => child_size,
            };

            child.rect = switch (config.direction) {
                .horizontal => Rect.fromMinSize(
                    .{ container.rect.min[0] + pos_main + margin_main_start, container.rect.min[1] + pos_cross },
                    final_size,
                ),
                .vertical => Rect.fromMinSize(
                    .{ container.rect.min[0] + pos_cross, container.rect.min[1] + pos_main + margin_main_start },
                    final_size,
                ),
            };

            // Advance position
            pos_main += switch (config.direction) {
                .horizontal => final_size[0] + margin_main_start + child.margin[2],
                .vertical => final_size[1] + margin_main_start + child.margin[3],
            };
            pos_main += config.spacing.main;
        }
    }

    /// Simple stack layout (children fill available space)
    pub fn computeStackLayout(self: *LayoutEngine, container_id: u64, available_size: Vec2) !void {
        const container = self.nodes.getPtr(container_id) orelse return;
        
        const content_rect = Rect.fromMinSize(
            .{ 
                container.rect.min[0] + container.padding[0], 
                container.rect.min[1] + container.padding[1] 
            },
            .{ 
                available_size[0] - container.padding[0] - container.padding[2], 
                available_size[1] - container.padding[1] - container.padding[3] 
            },
        );

        for (container.children.items) |child_id| {
            const child = self.nodes.getPtr(child_id) orelse continue;
            child.rect = content_rect;
        }
    }
};
