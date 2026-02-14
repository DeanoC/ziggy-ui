//! Dock drop zones for drag-and-drop
const std = @import("std");
const DockGraph = @import("dock_graph.zig");

/// Drop zone types
pub const DropZone = enum {
    center,    // Drop as tab in center
    left,      // Split left
    right,     // Split right  
    top,       // Split top
    bottom,    // Split bottom
};

/// Drop target info
pub const DropTarget = struct {
    node_id: DockGraph.DockNodeId,
    zone: DropZone,
    rect: struct { x: f32, y: f32, width: f32, height: f32 },
};

/// Drop preview state
pub const DropPreview = struct {
    active: bool = false,
    target_node: ?DockGraph.DockNodeId = null,
    zone: DropZone = .center,
    preview_rect: struct { x: f32, y: f32, width: f32, height: f32 } = .{},
};

/// Calculate drop zones for a node
pub fn calculateDropZones(
    node_rect: DockGraph.DockNode.Rect,
) [5]DropTarget {
    const center_size = @min(node_rect.width, node_rect.height) * 0.3;
    const edge_size = center_size * 0.5;
    
    const center_x = node_rect.x + node_rect.width * 0.5;
    const center_y = node_rect.y + node_rect.height * 0.5;
    
    return .{
        // Center
        .{
            .node_id = 0, // Caller sets this
            .zone = .center,
            .rect = .{
                .x = center_x - center_size * 0.5,
                .y = center_y - center_size * 0.5,
                .width = center_size,
                .height = center_size,
            },
        },
        // Left
        .{
            .node_id = 0,
            .zone = .left,
            .rect = .{
                .x = node_rect.x,
                .y = center_y - edge_size * 0.5,
                .width = edge_size,
                .height = edge_size,
            },
        },
        // Right
        .{
            .node_id = 0,
            .zone = .right,
            .rect = .{
                .x = node_rect.x + node_rect.width - edge_size,
                .y = center_y - edge_size * 0.5,
                .width = edge_size,
                .height = edge_size,
            },
        },
        // Top
        .{
            .node_id = 0,
            .zone = .top,
            .rect = .{
                .x = center_x - edge_size * 0.5,
                .y = node_rect.y,
                .width = edge_size,
                .height = edge_size,
            },
        },
        // Bottom
        .{
            .node_id = 0,
            .zone = .bottom,
            .rect = .{
                .x = center_x - edge_size * 0.5,
                .y = node_rect.y + node_rect.height - edge_size,
                .width = edge_size,
                .height = edge_size,
            },
        },
    };
}

/// Find drop target at position
pub fn findDropTarget(
    zones: []const DropTarget,
    pos: [2]f32,
) ?DropTarget {
    for (zones) |zone| {
        if (pos[0] >= zone.rect.x and 
            pos[0] <= zone.rect.x + zone.rect.width and
            pos[1] >= zone.rect.y and 
            pos[1] <= zone.rect.y + zone.rect.height) {
            return zone;
        }
    }
    return null;
}

/// Calculate preview rectangle for a drop
pub fn calculatePreviewRect(
    node_rect: DockGraph.DockNode.Rect,
    zone: DropZone,
) struct { x: f32, y: f32, width: f32, height: f32 } {
    const preview_ratio: f32 = 0.5;
    
    return switch (zone) {
        .center => .{
            .x = node_rect.x + node_rect.width * 0.25,
            .y = node_rect.y + node_rect.height * 0.25,
            .width = node_rect.width * 0.5,
            .height = node_rect.height * 0.5,
        },
        .left => .{
            .x = node_rect.x,
            .y = node_rect.y,
            .width = node_rect.width * preview_ratio,
            .height = node_rect.height,
        },
        .right => .{
            .x = node_rect.x + node_rect.width * (1.0 - preview_ratio),
            .y = node_rect.y,
            .width = node_rect.width * preview_ratio,
            .height = node_rect.height,
        },
        .top => .{
            .x = node_rect.x,
            .y = node_rect.y,
            .width = node_rect.width,
            .height = node_rect.height * preview_ratio,
        },
        .bottom => .{
            .x = node_rect.x,
            .y = node_rect.y + node_rect.height * (1.0 - preview_ratio),
            .width = node_rect.width,
            .height = node_rect.height * preview_ratio,
        },
    };
}
