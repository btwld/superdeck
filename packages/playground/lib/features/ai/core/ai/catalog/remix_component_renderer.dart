import 'package:flutter/material.dart';

import 'package:remix/remix.dart';

import '../../debug_logger.dart';
import '../../ui/ui.dart';
import '../../utils/color_utils.dart';

import 'remix_component_preview.dart';

// ─────────────────────────────────── TREE RENDERER ───────────────────────────────────

/// Renders a component tree from a nodeMap starting at rootNodeId.
///
/// This widget recursively resolves node IDs from the map and renders
/// the corresponding Remix/Sd components.
class ComponentTreeRenderer extends StatelessWidget {
  const ComponentTreeRenderer({
    super.key,
    required this.nodeMap,
    required this.rootNodeId,
  });

  final Map<String, UiNodeType> nodeMap;
  final String rootNodeId;

  @override
  Widget build(BuildContext context) {
    return _renderNode(context, rootNodeId, depth: 0);
  }

  Widget _renderNode(BuildContext context, String nodeId, {int depth = 0}) {
    // Guard against infinite recursion
    if (depth > 10) {
      debugLog.log('ComponentTreeRenderer', 'Max depth exceeded at $nodeId');
      return const SizedBox.shrink();
    }

    final node = nodeMap[nodeId];
    if (node == null) {
      debugLog.log('ComponentTreeRenderer', 'Node not found: $nodeId');
      return const SizedBox.shrink();
    }

    return _buildForType(context, node, depth: depth);
  }

  List<Widget> _resolveChildren(
    BuildContext context,
    UiNodeType node, {
    required int depth,
  }) {
    final childIds = node.children;
    if (childIds == null || childIds.isEmpty) return [];
    return childIds
        .map((id) => _renderNode(context, id, depth: depth + 1))
        .toList();
  }

  Widget _buildForType(BuildContext context, UiNodeType node, {int depth = 0}) {
    switch (node.type) {
      // Layout
      case UiComponentType.row:
        return _buildRow(context, node, depth: depth);
      case UiComponentType.column:
        return _buildColumn(context, node, depth: depth);

      // Display
      case UiComponentType.text:
        return _buildText(node);
      case UiComponentType.card:
        return _buildCard(context, node, depth: depth);
      case UiComponentType.badge:
        return _buildBadge(node);
      case UiComponentType.callout:
        return _buildCallout(node);
      case UiComponentType.divider:
        return const SdDivider();
      case UiComponentType.progress:
        return _buildProgress(node);
      case UiComponentType.spinner:
        return const SdSpinner();
      case UiComponentType.avatar:
        return _buildAvatar(context, node);

      // Interactive
      case UiComponentType.button:
        return _buildButton(node);
      case UiComponentType.iconButton:
        return _buildIconButton(node);
      case UiComponentType.checkbox:
        return _buildCheckbox(node);
      case UiComponentType.switchToggle:
        return _buildSwitch(node);
      case UiComponentType.radio:
        return _buildRadio(node);
      case UiComponentType.slider:
        return _buildSlider(node);
      case UiComponentType.textField:
        return _buildTextField(node);

      // Composite
      case UiComponentType.accordion:
        return _buildAccordion(context, node, depth: depth);
      case UiComponentType.tabs:
        return _buildTabs(context, node, depth: depth);
    }
  }

  // ─────────────────────────────────── LAYOUT ───────────────────────────────────

  Widget _buildRow(
    BuildContext context,
    UiNodeType node, {
    required int depth,
  }) => _buildFlex(context, node, depth: depth, direction: Axis.horizontal);

  Widget _buildColumn(
    BuildContext context,
    UiNodeType node, {
    required int depth,
  }) => _buildFlex(context, node, depth: depth, direction: Axis.vertical);

  Widget _buildFlex(
    BuildContext context,
    UiNodeType node, {
    required int depth,
    required Axis direction,
  }) {
    final children = _resolveChildren(context, node, depth: depth);
    if (children.isEmpty) return const SizedBox.shrink();

    var style = FlexBoxStyler().spacing(8);
    if (direction == Axis.vertical) {
      style = style.column().crossAxisAlignment(CrossAxisAlignment.start);
    } else {
      style = style.crossAxisAlignment(CrossAxisAlignment.center);
    }

    return style(children: children);
  }

  // ─────────────────────────────────── DISPLAY ───────────────────────────────────

  Widget _buildText(UiNodeType node) {
    return SdBody(node.label ?? '');
  }

  Widget _buildCard(
    BuildContext context,
    UiNodeType node, {
    required int depth,
  }) {
    final children = _resolveChildren(context, node, depth: depth);
    final content = children.length == 1
        ? children.first
        : FlexBoxStyler().column().spacing(8)(children: children);

    return SdPanel(child: content);
  }

  Widget _buildBadge(UiNodeType node) {
    final badgeColor = node.color != null ? hexToColor(node.color!) : null;
    final style = FortalBadgeStyles.surface();
    return SdBadge(
      label: node.label ?? 'Badge',
      style: badgeColor != null
          ? style
                .backgroundColor(badgeColor)
                .label(TextStyler().color(FortalTokens.gray12()))
          : style,
    );
  }

  Widget _buildCallout(UiNodeType node) {
    return SdCallout(
      text: node.label,
      icon: node.icon?.iconData,
      child: node.description != null ? SdCaption(node.description!) : null,
    );
  }

  Widget _buildProgress(UiNodeType node) {
    final value = (node.value ?? 0.5).clamp(0.0, 1.0).toDouble();
    final label = node.label;

    final row = FlexBoxStyler()
        .spacing(8)
        .crossAxisAlignment(CrossAxisAlignment.center);

    return row(
      children: [
        if (label != null) SdCaption(label),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, UiNodeType node) {
    final color = node.color != null ? hexToColor(node.color!) : null;
    final fallback = node.label ?? '?';

    return CircleAvatar(
      backgroundColor: color ?? FortalTokens.accent5.resolve(context),
      radius: 20,
      child: Text(
        fallback.isNotEmpty ? fallback[0].toUpperCase() : '?',
        style: TextStyle(
          color: FortalTokens.gray12.resolve(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─────────────────────────────────── INTERACTIVE ───────────────────────────────────

  Widget _buildButton(UiNodeType node) {
    return SdButton(
      label: node.label ?? 'Button',
      onPressed: () {},
      icon: node.icon?.iconData,
    );
  }

  Widget _buildIconButton(UiNodeType node) {
    return SdIconButton(
      icon: node.icon?.iconData ?? Icons.more_horiz,
      onPressed: () {},
    );
  }

  Widget _buildCheckbox(UiNodeType node) {
    final row = FlexBoxStyler()
        .spacing(8)
        .crossAxisAlignment(CrossAxisAlignment.center);

    return row(
      children: [
        SdCheckbox(selected: node.selected ?? false),
        if (node.label != null) SdBody(node.label!),
      ],
    );
  }

  Widget _buildSwitch(UiNodeType node) {
    final row = FlexBoxStyler()
        .spacing(8)
        .crossAxisAlignment(CrossAxisAlignment.center);

    return row(
      children: [
        SdSwitch(selected: node.selected ?? false, onChanged: (_) {}),
        if (node.label != null) SdBody(node.label!),
      ],
    );
  }

  Widget _buildRadio(UiNodeType node) {
    final isSelected = node.selected ?? false;
    final row = FlexBoxStyler()
        .spacing(8)
        .crossAxisAlignment(CrossAxisAlignment.center);

    return SdRadioGroup<bool>(
      groupValue: isSelected,
      onChanged: (_) {},
      child: row(
        children: [
          // Keep a stable option value so selected=false renders unselected.
          SdRadio<bool>(value: true),
          if (node.label != null) SdBody(node.label!),
        ],
      ),
    );
  }

  Widget _buildSlider(UiNodeType node) {
    final value = (node.value ?? 0.5).clamp(0.0, 1.0).toDouble();

    final col = FlexBoxStyler()
        .column()
        .spacing(4)
        .crossAxisAlignment(CrossAxisAlignment.start);

    return col(
      children: [
        if (node.label != null) SdCaption(node.label!),
        SdSlider(value: value, onChanged: (_) {}),
      ],
    );
  }

  Widget _buildTextField(UiNodeType node) {
    return SdTextField(hintText: node.label ?? 'Enter text...');
  }

  // ─────────────────────────────────── COMPOSITE ───────────────────────────────────

  Widget _buildAccordion(
    BuildContext context,
    UiNodeType node, {
    required int depth,
  }) {
    final childIds = node.children ?? [];
    if (childIds.isEmpty) return const SizedBox.shrink();

    final items = <Widget>[];
    for (final childId in childIds) {
      final childNode = nodeMap[childId];
      if (childNode == null) continue;

      final title = childNode.label ?? childId;
      final contentChildren = _resolveChildren(
        context,
        childNode,
        depth: depth + 1,
      );

      final contentCol = FlexBoxStyler()
          .column()
          .spacing(8)
          .crossAxisAlignment(CrossAxisAlignment.start);

      items.add(
        _AccordionSection(
          title: title,
          icon: childNode.icon?.iconData,
          child: contentCol(children: contentChildren),
        ),
      );
    }

    final col = FlexBoxStyler()
        .column()
        .spacing(0)
        .crossAxisAlignment(CrossAxisAlignment.stretch);

    return SdPanel(
      style: BoxStyler().paddingAll(0),
      child: col(children: items),
    );
  }

  Widget _buildTabs(
    BuildContext context,
    UiNodeType node, {
    required int depth,
  }) {
    final childIds = node.children ?? [];
    if (childIds.isEmpty) return const SizedBox.shrink();

    // Collect tab data from child nodes
    final tabEntries = <_TabEntry>[];
    for (final childId in childIds) {
      final childNode = nodeMap[childId];
      if (childNode == null) continue;
      tabEntries.add(
        _TabEntry(
          id: childId,
          label: childNode.label ?? childId,
          icon: childNode.icon?.iconData,
          node: childNode,
        ),
      );
    }

    if (tabEntries.isEmpty) return const SizedBox.shrink();

    return _TabsPreview(entries: tabEntries, nodeMap: nodeMap, depth: depth);
  }
}

// ─────────────────────────────────── ACCORDION SECTION ───────────────────────────────────

class _AccordionSection extends StatefulWidget {
  const _AccordionSection({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final Widget child;

  @override
  State<_AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<_AccordionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final headerStyle = FlexBoxStyler()
        .spacing(8)
        .crossAxisAlignment(CrossAxisAlignment.center)
        .paddingAll(12);

    return FlexBoxStyler().column().crossAxisAlignment(
      CrossAxisAlignment.stretch,
    )(
      children: [
        Pressable(
          onPress: () => setState(() => _expanded = !_expanded),
          child: headerStyle(
            children: [
              if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: 16,
                  color: FortalTokens.gray11.resolve(context),
                ),
              Expanded(
                child: SdBody(
                  widget.title,
                  style: TextStyler().fontWeight(FontWeight.w500),
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: FortalTokens.gray10.resolve(context),
              ),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: widget.child,
          ),
      ],
    );
  }
}

// ─────────────────────────────────── TABS PREVIEW ───────────────────────────────────

class _TabEntry {
  const _TabEntry({
    required this.id,
    required this.label,
    required this.node,
    this.icon,
  });

  final String id;
  final String label;
  final IconData? icon;
  final UiNodeType node;
}

class _TabsPreview extends StatefulWidget {
  const _TabsPreview({
    required this.entries,
    required this.nodeMap,
    required this.depth,
  });

  final List<_TabEntry> entries;
  final Map<String, UiNodeType> nodeMap;
  final int depth;

  @override
  State<_TabsPreview> createState() => _TabsPreviewState();
}

class _TabsPreviewState extends State<_TabsPreview> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final col = FlexBoxStyler()
        .column()
        .spacing(0)
        .crossAxisAlignment(CrossAxisAlignment.stretch);

    // Tab bar
    final tabBar = FlexBoxStyler()
        .spacing(0)
        .crossAxisAlignment(CrossAxisAlignment.end);

    final tabButtons = widget.entries.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      final isActive = index == _selectedTab;

      final tabStyle = BoxStyler()
          .paddingX(12)
          .paddingY(8)
          .borderBottom(
            color: isActive ? FortalTokens.accent11() : Colors.transparent,
            width: 2,
          );

      return Pressable(
        onPress: () => setState(() => _selectedTab = index),
        child: tabStyle(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if (tab.icon != null)
                Icon(
                  tab.icon,
                  size: 14,
                  color: isActive
                      ? FortalTokens.accent11.resolve(context)
                      : FortalTokens.gray10.resolve(context),
                ),
              SdCaption(
                tab.label,
                style: TextStyler().color(
                  isActive ? FortalTokens.accent12() : FortalTokens.gray10(),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Tab content - render from the active tab's node ID
    final activeEntry = widget.entries[_selectedTab];
    final renderer = ComponentTreeRenderer(
      nodeMap: widget.nodeMap,
      rootNodeId: activeEntry.id,
    );

    return SdPanel(
      style: BoxStyler().paddingAll(0),
      child: col(
        children: [
          tabBar(children: tabButtons),
          const SdDivider(),
          Padding(padding: const EdgeInsets.all(12), child: renderer),
        ],
      ),
    );
  }
}
