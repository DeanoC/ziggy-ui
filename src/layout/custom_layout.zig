//! Custom layout helpers
const std = @import("std");

/// Custom layout state for panel arrangements
pub const CustomLayoutState = struct {
    left_ratio: f32 = 0.42,
    min_left_width: f32 = 360.0,
    min_right_width: f32 = 320.0,
    is_resizing: bool = false,
    resize_start_x: f32 = 0,
    resize_start_ratio: f32 = 0.42,
};

/// Calculate three-pane layout
pub fn calculateThreePaneLayout(
    width: f32,
    height: f32,
    left_ratio: f32,
    min_left_width: f32,
    min_right_width: f32,
) struct {
    left: struct { x: f32, y: f32, width: f32, height: f32 },
    center: struct { x: f32, y: f32, width: f32, height: f32 },
    right: struct { x: f32, y: f32, width: f32, height: f32 },
    show_left: bool,
    show_right: bool,
} {
    const splitter_width = 4.0;
    
    // Determine visibility based on minimum widths
    const show_left = width * left_ratio >= min_left_width;
    const show_right = width * (1.0 - left_ratio) >= min_right_width + min_left_width;
    
    var left_width: f32 = 0;
    var right_width: f32 = 0;
    var center_x: f32 = 0;
    var center_width = width;
    
    if (show_left) {
        left_width = width * left_ratio - splitter_width * 0.5;
        center_x = left_width + splitter_width;
        center_width -= left_width + splitter_width;
    }
    
    if (show_right) {
        right_width = min_right_width;
        center_width -= right_width + splitter_width;
    }
    
    return .{
        .left = .{ .x = 0, .y = 0, .width = left_width, .height = height },
        .center = .{ .x = center_x, .y = 0, .width = center_width, .height = height },
        .right = .{ 
            .x = width - right_width, 
            .y = 0, 
            .width = right_width, 
            .height = height 
        },
        .show_left = show_left,
        .show_right = show_right,
    };
}

/// Calculate splitter handle rectangle
pub fn getSplitterHandleRect(
    left_rect: struct { x: f32, y: f32, width: f32, height: f32 },
) struct { x: f32, y: f32, width: f32, height: f32 } {
    return .{
        .x = left_rect.x + left_rect.width,
        .y = left_rect.y,
        .width = 4.0,
        .height = left_rect.height,
    };
}

/// Simple vertical stack layout
pub fn calculateVerticalStack(
    items: []const struct { height: f32, padding: f32 },
    container_width: f32,
    start_y: f32,
) std.ArrayList(struct { x: f32, y: f32, width: f32, height: f32 }) {
    var result = std.ArrayList(struct { x: f32, y: f32, width: f32, height: f32 }).init(std.heap.page_allocator);
    
    var current_y = start_y;
    for (items) |item| {
        result.append(.{
            .x = 0,
            .y = current_y,
            .width = container_width,
            .height = item.height,
        }) catch break;
        current_y += item.height + item.padding;
    }
    
    return result;
}

/// Calculate grid layout
pub fn calculateGridLayout(
    item_count: usize,
    container_width: f32,
    _container_height: f32,
    item_width: f32,
    item_height: f32,
    gap: f32,
) struct {
    cols: usize,
    rows: usize,
    item_rects: []struct { x: f32, y: f32, width: f32, height: f32 },
} {
    _ = _container_height;
    const available_width = container_width - gap;
    const cols = @max(1, @as(usize, @intFromFloat(@floor(available_width / (item_width + gap)))));
    const rows = (item_count + cols - 1) / cols;
    
    var rects = std.ArrayList(struct { x: f32, y: f32, width: f32, height: f32 }).init(std.heap.page_allocator);
    
    var i: usize = 0;
    while (i < item_count) : (i += 1) {
        const col = i % cols;
        const row = i / cols;
        
        const x = gap + @as(f32, @floatFromInt(col)) * (item_width + gap);
        const y = gap + @as(f32, @floatFromInt(row)) * (item_height + gap);
        
        rects.append(.{
            .x = x,
            .y = y,
            .width = item_width,
            .height = item_height,
        }) catch break;
    }
    
    return .{
        .cols = cols,
        .rows = rows,
        .item_rects = rects.toOwnedSlice() catch &.{},
    };
}
