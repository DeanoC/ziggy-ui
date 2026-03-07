const std = @import("std");
// Compatibility shim for legacy settings-tree consumers.
pub const SettingsTreeNode = struct {
    id: []const u8,
    label: []const u8,
    expanded: bool = true,
    children: []const SettingsTreeNode = &.{},
};

pub const SettingsTreeModel = struct {
    root_nodes: []const SettingsTreeNode = &.{},
    selected_id: ?[]const u8 = null,
};

pub const SettingsTreeAction = union(enum) {
    none,
};

pub fn hasNode(model: SettingsTreeModel, node_id: []const u8) bool {
    return hasNodeFallback(model, node_id);
}

fn hasNodeFallback(model: SettingsTreeModel, node_id: []const u8) bool {
    for (model.root_nodes) |node| {
        if (nodeMatchesFallback(node, node_id)) return true;
    }
    return false;
}

fn nodeMatchesFallback(node: SettingsTreeNode, node_id: []const u8) bool {
    if (std.mem.eql(u8, node.id, node_id)) return true;
    for (node.children) |child| {
        if (nodeMatchesFallback(child, node_id)) return true;
    }
    return false;
}
