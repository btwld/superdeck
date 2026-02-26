# SuperDeck AI - Automated Browser Testing Guide

Guide for testing the SuperDeck AI wizard workflow using Claude in Chrome MCP tools.

## Prerequisites

- Flutter app running on Chrome (`flutter run -d chrome`)
- Claude in Chrome extension installed and connected
- Dart MCP server connected

## Setup

### 1. Launch the App

```
mcp__dart__launch_app(root: "/path/to/columbus", device: "chrome")
```

### 2. Connect to Dart Tooling Daemon

```
mcp__dart__connect_dart_tooling_daemon(uri: "<dtd_uri_from_launch>")
```

### 3. Get the App URL

```
mcp__dart__get_app_logs(pid: <pid>, maxLines: 10)
```

Look for `app.webLaunchUrl` in the logs to find the correct `http://localhost:<port>` URL.

### 4. Initialize Browser Tab

Always create a **new tab** and navigate to the app URL. Never reuse tabs from previous sessions.

```
mcp__claude-in-chrome__tabs_create_mcp()
mcp__claude-in-chrome__navigate(url: "http://localhost:<port>", tabId: <tabId>)
```

Wait for the Flutter app to render:

```
mcp__claude-in-chrome__computer(action: "wait", duration: 3, tabId: <tabId>)
```

## Key Learnings: Flutter Web + Browser Automation

### Element Discovery Strategy

Use `read_page(filter: "interactive")` as the **primary discovery tool** — one call returns all interactive elements with their refs and dynamic text labels. This is more efficient than multiple `find` calls and handles AI-generated content that changes every run.

```
// One call gets ALL interactive elements with refs
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
```

Use `find` for **known constant text** like "Next step" — it's faster than `read_page` when you know exactly what you're looking for.

```
mcp__claude-in-chrome__find(query: "Next step", tabId: <tabId>)
```

### Ref Lifecycle in Flutter Web

Flutter re-renders the widget tree when selection state changes. This affects ref validity:

| Scenario | Refs survive? |
|----------|--------------|
| Click a **radio** option → other option refs | **No** — full re-render invalidates sibling refs |
| Click a **checkbox** option → other checkbox refs | **Yes** — only internal state changes |
| Click any option → **Next step** ref | **No** — always invalidated by re-render |
| Multiple checkbox clicks → checkbox refs | **Yes** — all survive from same `read_page` |

**Rule:** After clicking any wizard option, always do a fresh `find("Next step")` before clicking next. Never reuse the Next step ref from an earlier `read_page`.

### Accessibility Tree Patterns

`read_page(interactive)` returns elements with predictable patterns:

| Element type | Pattern in `read_page` output |
|-------------|-------------------------------|
| Radio option | `button "Option: <title>, <description>"` |
| Style option | `button "Style: <title>, <description>"` |
| Image style option | `button "Image style: <name>"` |
| Checkbox option | `group "<option text>"` |
| Next button | `button "Next step"` |
| Generate button | `button "Generate Slides"` |
| Suggestion chip | `button "\"<text>\""` |
| Slider | `slider` |
| Text input | `textbox "Chat message input"` |

Option text is **fully dynamic** (AI-generated) — pick from whatever `read_page` returns.

### Text Input in Flutter Web

Flutter web maintains its own text state separate from the DOM:

| Method | Works? | Notes |
|--------|--------|-------|
| `form_input` on semantic wrapper refs | No | Sets DOM value but Flutter's TextEditingController doesn't pick it up |
| `form_input` on internal textbox ref | Partial | Unreliable |
| `read_page` ref + `computer` click + type | **Yes** | Click the input ref, then type — simulates real keystrokes |

### Flutter Web Accessibility Tree Quirk

A single `SdTextField` generates **3 accessibility nodes**:
1. Semantic label node (e.g., `"Chat message input"`)
2. Hint + trailing text node (e.g., `"Type a message... Press Enter"`)
3. Internal unnamed textbox from RemixTextField

This is normal Flutter web behavior — it doesn't mean there are multiple inputs.

## Wizard Flow Test Script

### Optimized Pattern Per Step Type

**Radio step (4 calls):**
```
read_page(interactive)        → discover dynamic options + pick one
click(option_ref)             → select (invalidates sibling refs)
find("Next step") → click    → advance (need fresh ref)
wait + screenshot             → verify next step loaded
```

**Checkbox step (N+3 calls, N = selections):**
```
read_page(interactive)        → discover all checkbox refs (they survive clicks)
click(cb1_ref)                → check first
click(cb2_ref)                → check second (ref still valid)
click(cbN_ref)                → check Nth (ref still valid)
find("Next step") → click    → advance (need fresh ref)
wait + screenshot             → verify next step loaded
```

**Slider step (3 calls):**
```
read_page(interactive)        → see slider (accept default or adjust)
find("Next step") → click    → advance
wait + screenshot             → verify
```

---

### Step 1: Submit Topic

Suggestion chips auto-submit when tapped. Use `read_page` to discover them.

```
// Discover all interactive elements
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Look for: button "\"Startup pitch deck\"" [ref_X]

// Click suggestion chip (auto-submits the topic)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<chip_ref>", tabId: <tabId>)

// Wait for AI response + verify
mcp__claude-in-chrome__computer(action: "wait", duration: 6, tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

**Alternative** — type a custom topic:

```
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Find: textbox "Chat message input" [ref_X]
mcp__claude-in-chrome__computer(action: "left_click", ref: "<input_ref>", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "type", text: "Startup pitch deck", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "key", text: "Enter", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "wait", duration: 6, tabId: <tabId>)
```

**Expected:** Left panel shows target audience question with radio cards. Right panel shows conversation.

### Step 2: Target Audience (Radio)

```
// Discover options (text is dynamic, AI-generated)
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Look for: button "Option: <title>, <description>" [ref_X]
// → Pick the first option ref (or any)

// Select option (invalidates sibling option refs + Next step ref)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<option_ref>", tabId: <tabId>)

// Next step needs fresh ref after selection
mcp__claude-in-chrome__find(query: "Next step", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<next_ref>", tabId: <tabId>)

// Wait + verify
mcp__claude-in-chrome__computer(action: "wait", duration: 6, tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

**Expected:** Approach/narrative style question with radio cards.

### Step 3: Approach (Radio)

Same pattern as Step 2:

```
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
mcp__claude-in-chrome__computer(action: "left_click", ref: "<option_ref>", tabId: <tabId>)
mcp__claude-in-chrome__find(query: "Next step", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<next_ref>", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "wait", duration: 6, tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

**Expected:** Topics checkbox step.

### Step 4: Topics (Checkbox)

Checkbox refs survive between clicks — select all from one `read_page`.

```
// Discover all checkbox options
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Look for: group "<option text>" [ref_X]
// → Pick 3 group refs

// Click all checkboxes (refs survive between clicks)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<cb1_ref>", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<cb2_ref>", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<cb3_ref>", tabId: <tabId>)

// Next step needs fresh ref
mcp__claude-in-chrome__find(query: "Next step", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<next_ref>", tabId: <tabId>)

// Wait + verify
mcp__claude-in-chrome__computer(action: "wait", duration: 6, tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

**Expected:** Slider step (slide count).

### Step 5: Slide Count (Slider)

> **Known issue:** The Remix slider may crash if Gemini returns a value outside min/max range.

Accept the default value and advance:

```
// Next step (slider default is fine)
mcp__claude-in-chrome__find(query: "Next step", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<next_ref>", tabId: <tabId>)

// Wait + verify
mcp__claude-in-chrome__computer(action: "wait", duration: 6, tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

**Expected:** Style selection step (radio cards or style/image_style input).

### Step 6a: Style Selection (Radio)

```
// Discover style options
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Look for: button "Style: <title>, <description>" [ref_X]

mcp__claude-in-chrome__computer(action: "left_click", ref: "<style_option_ref>", tabId: <tabId>)
mcp__claude-in-chrome__find(query: "Next step", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<next_ref>", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "wait", duration: 6, tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

**Expected:** Image style selection step.

### Step 6b: Image Style (Radio)

```
// Discover image style options
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Look for: button "Image style: <name>" [ref_X]

mcp__claude-in-chrome__computer(action: "left_click", ref: "<image_style_ref>", tabId: <tabId>)
mcp__claude-in-chrome__find(query: "Next step", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<next_ref>", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "wait", duration: 6, tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

**Expected:** Summary card with all selections.

### Step 7: Summary Card

```
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Look for generate/confirm button
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
mcp__claude-in-chrome__find(query: "Generate", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<generate_ref>", tabId: <tabId>)
```

**Expected:** Navigation to `/presentation/creating`.

### Step 8: Generation

The app navigates to the creating route and generates the presentation.

```
mcp__claude-in-chrome__computer(action: "wait", duration: 10, tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

## Chat Panel Toggle Test

Verify only one input exists regardless of panel state:

```
// With chat panel shown (default)
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Should show textbox elements (3 nodes = 1 input)

// Find and click the toggle button
mcp__claude-in-chrome__find(query: "Hide chat panel", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<ref_id>", tabId: <tabId>)

// With chat panel hidden
mcp__claude-in-chrome__read_page(tabId: <tabId>, filter: "interactive")
// → Should still show same 3 textbox nodes (1 input, repositioned)

// Toggle back
mcp__claude-in-chrome__find(query: "Show chat panel", tabId: <tabId>)
mcp__claude-in-chrome__computer(action: "left_click", ref: "<ref_id>", tabId: <tabId>)
```

## Hot Reload After Code Changes

```
// After editing Dart files
mcp__dart__hot_restart()

// Or hot reload (preserves state)
mcp__dart__hot_reload()

// Then re-verify
mcp__claude-in-chrome__computer(action: "screenshot", tabId: <tabId>)
```

## Debugging

### Check Runtime Errors

```
mcp__dart__get_runtime_errors()
```

### Check Console Logs

```
mcp__claude-in-chrome__read_console_messages(tabId: <tabId>, pattern: "error|Error")
```

### Check App Logs

```
mcp__dart__get_app_logs(pid: <pid>, maxLines: 50)
```

### Analyze Code

```
mcp__dart__analyze_files(roots: [{"root": "file:///path/to/columbus", "paths": ["lib/chat/view/chat_screen.dart"]}])
```

## Element Discovery Reference

Use `read_page(filter: "interactive")` as primary discovery. Use `find` for known constant text.

| Element | Discovery method | Pattern / Query |
|---------|-----------------|-----------------|
| Suggestion chips | `read_page` | `button "\"Startup pitch deck\""` |
| Radio options | `read_page` | `button "Option: <dynamic title>, <description>"` |
| Style options | `read_page` | `button "Style: <title>, <description>"` |
| Image style options | `read_page` | `button "Image style: <name>"` |
| Checkbox options | `read_page` | `group "<dynamic option text>"` |
| Slider | `read_page` | `slider` |
| Generate button | `read_page` or `find` | `button "Generate Slides"` |
| Next button | `find` | `"Next step"` (always this exact text) |
| Chat input | `read_page` | `textbox "Chat message input"` |
| Chat toggle | `find` | `"Hide chat panel"` / `"Show chat panel"` |
| Restart | `find` | `"Restart conversation"` |
| Regenerate | `find` | `"Regenerate presentation"` |
| View presentation | `find` | `"View presentation"` |

> **Tip:** Always take a screenshot after waiting to verify the expected state. If elements are missing, the AI response may still be loading — increase wait time or retry.
