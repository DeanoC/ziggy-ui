const std = @import("std");
const contracts = @import("ziggy-ui-panels");

const has_settings_tree = @hasDecl(contracts, "settings_tree");

pub const SettingsTreeNode = if (has_settings_tree)
    contracts.settings_tree.SettingsTreeNode
else
    struct {
        id: []const u8,
        label: []const u8,
        expanded: bool = true,
        children: []const SettingsTreeNode = &.{},
    };

pub const SettingsTreeModel = if (has_settings_tree)
    contracts.settings_tree.SettingsTreeModel
else
    struct {
        root_nodes: []const SettingsTreeNode = &.{},
        selected_id: ?[]const u8 = null,
    };

pub const SettingsTreeAction = if (has_settings_tree)
    contracts.settings_tree.SettingsTreeAction
else
    union(enum) {
        none,
    };

pub fn hasNode(model: SettingsTreeModel, node_id: []const u8) bool {
    if (has_settings_tree) return contracts.settings_tree.hasNode(model, node_id);
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
