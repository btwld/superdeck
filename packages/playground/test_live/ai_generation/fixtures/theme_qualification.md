---
title: Evidence Becomes Momentum
style: hero
---

@section

@block { align: bottomLeft }

# Evidence Becomes Momentum

@section

@block { align: topLeft }

A ten-slide renderer check for hierarchy, rhythm, and component legibility.

---
title: The Decision Gap
style: content
---

@section { spacing: 40 }

@block { flex: 3 }

## Teams collect more signals than ever

Research, support, and product telemetry arrive continuously, but decisions
still wait for a quarterly synthesis cycle.

@block { flex: 2 }

### What breaks

- Context fragments
- Trade-offs stay implicit
- Follow-through becomes hard to trace

---
title: One Number Changes the Conversation
style: data
---

@block { align: centerLeft }

# 31%

## of shipped features reach their adoption target

The operating problem is not output. It is the distance between evidence and
the next funded decision.

---
title: From Reporting to Operating
style: section
---

@block { align: centerLeft }

# From reporting to operating

Make evidence part of the weekly decision loop.

---
title: A Shared Decision Loop
style: content
---

@section { spacing: 32 }

@block

### Capture

Bring customer, market, and product signals into one reviewable stream.

@block

### Connect

Link every claim to the evidence, owner, and decision it informs.

@block

### Commit

Turn the strongest signal into a bounded experiment with a clear review date.

---
title: Choose the Operating Model
style: data
---

@block

## Three ways to organize the work

| Model | Decision speed | Evidence trail | Best use |
| --- | --- | --- | --- |
| Quarterly review | Slow | Fragmented | Stable portfolios |
| Team dashboards | Medium | Local | Functional optimization |
| Shared loop | Fast | Connected | Cross-team bets |

---
title: The Standard for Trust
style: quote
---

@block { align: centerLeft }

> A recommendation earns trust when the audience can see what changed, why it
> matters, and what happens next.

**Decision design principle**

---
title: Put the Handoff in the Room
style: visual
---

@section { spacing: 48 }

@block { flex: 3 }

## Continue with the working prototype

The call to action remains useful at full slide size and as a thumbnail. The QR
surface also verifies element padding, clipping, and contrast.

@qrcode {
  text: "https://superdeck-dev.web.app"
  size: 280
  flex: 2
  align: center
}

---
title: A Renderer-Owned Component
style: content
---

@section { spacing: 40 }

@block { flex: 3 }

## Keep contracts small and explicit

```dart
final theme = catalog.resolve(id: id, version: version);
store.applyGeneratedStyle(theme.toGeneratedDeckStyle());
```

@block { flex: 2 }

### Verification

Use the [same recipe](https://superdeck-dev.web.app) for editor previews,
fullscreen slides, captures, and replay.

---
title: Decide, Learn, Repeat
style: closing
---

@block { align: centerLeft }

# Decide, learn, repeat

Adopt one shared evidence loop for the next 90 days, review it weekly, and fund
the next decision from what the team learns.
