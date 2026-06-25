/// Example data for the RemixComponentPreview catalog item.
///
/// Separated from the main implementation to keep the schema and widget
/// code readable. Each entry is a closure returning a GenUI JSON string.
const remixComponentPreviewExamples = [_layoutSelectionExample];

String _layoutSelectionExample() => '''
      [
        {
          "id": "root",
          "component": {
            "RemixComponentPreview": {
              "question": "Which component layout do you prefer?",
              "description": "Pick the component composition that best fits your needs.",
              "theme": {"accent": "violet", "gray": "mauve", "brightness": "dark"},
              "componentOptions": [
                {
                  "id": "info_card",
                  "title": "Info Card",
                  "description": "A card with icon, heading, and action button.",
                  "rootNodeId": "card1",
                  "nodes": [
                    {"id": "card1", "type": "card", "children": ["col1"]},
                    {"id": "col1", "type": "column", "children": ["badge1", "text1", "text2", "btn1"]},
                    {"id": "badge1", "type": "badge", "label": "New", "color": "#6366F1"},
                    {"id": "text1", "type": "text", "label": "Getting Started"},
                    {"id": "text2", "type": "text", "label": "Learn the basics of our platform."},
                    {"id": "btn1", "type": "button", "label": "Learn More", "icon": "rocket"}
                  ]
                },
                {
                  "id": "settings_panel",
                  "title": "Settings Panel",
                  "description": "An accordion with toggleable settings.",
                  "rootNodeId": "acc1",
                  "nodes": [
                    {"id": "acc1", "type": "accordion", "children": ["s1", "s2", "s3"]},
                    {"id": "s1", "type": "column", "label": "Appearance", "children": ["sw1", "slider1"]},
                    {"id": "sw1", "type": "switchToggle", "label": "Dark mode", "selected": true},
                    {"id": "slider1", "type": "slider", "label": "Font size", "value": 0.5},
                    {"id": "s2", "type": "column", "label": "Notifications", "children": ["cb1", "cb2"]},
                    {"id": "cb1", "type": "checkbox", "label": "Email alerts", "selected": true},
                    {"id": "cb2", "type": "checkbox", "label": "Push notifications", "selected": false},
                    {"id": "s3", "type": "column", "label": "Privacy", "children": ["sw2"]},
                    {"id": "sw2", "type": "switchToggle", "label": "Share analytics", "selected": false}
                  ]
                },
                {
                  "id": "dashboard_tabs",
                  "title": "Dashboard Tabs",
                  "description": "Tabbed dashboard with stats and actions.",
                  "rootNodeId": "tabs1",
                  "nodes": [
                    {"id": "tabs1", "type": "tabs", "children": ["tab_overview", "tab_activity", "tab_settings"]},
                    {"id": "tab_overview", "type": "column", "label": "Overview", "icon": "home", "children": ["callout1", "row1"]},
                    {"id": "callout1", "type": "callout", "label": "Welcome back!", "description": "You have 3 new notifications.", "icon": "info"},
                    {"id": "row1", "type": "row", "children": ["progress1", "badge2"]},
                    {"id": "progress1", "type": "progress", "label": "Completion", "value": 0.72},
                    {"id": "badge2", "type": "badge", "label": "72%", "color": "#10B981"},
                    {"id": "tab_activity", "type": "column", "label": "Activity", "icon": "notifications", "children": ["text3", "divider1", "text4"]},
                    {"id": "text3", "type": "text", "label": "Latest updates will appear here."},
                    {"id": "divider1", "type": "divider"},
                    {"id": "text4", "type": "text", "label": "No recent activity."},
                    {"id": "tab_settings", "type": "column", "label": "Settings", "icon": "settings", "children": ["tf1", "btn2"]},
                    {"id": "tf1", "type": "textField", "label": "Display name"},
                    {"id": "btn2", "type": "button", "label": "Save Changes", "icon": "check"}
                  ]
                }
              ],
              "action": {"name": "submit_answer", "context": []}
            }
          }
        }
      ]
    ''';
