# Mermaid Theme Test Slides

Test slides showcasing the new simple 4-color theme system across the 5 most popular diagram types.

---

## 1. Flowchart (Most Popular)

```mermaid
flowchart TB
    A[User Input] --> B{Valid?}
    B -->|Yes| C[Process Data]
    B -->|No| D[Show Error]
    C --> E[(Save to DB)]
    E --> F[Send Response]
    D --> G[Log Error]

    subgraph "Backend Processing"
        C
        E
    end
```

**Features tested:**
- Node backgrounds and borders
- Text color and readability
- Arrow/line colors
- Subgraph styling
- Decision nodes (diamond shapes)

---

## 2. Sequence Diagram (Second Most Popular)

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant API
    participant Database

    User->>Frontend: Login Request
    Frontend->>API: POST /auth/login
    API->>Database: Query User
    Database-->>API: User Data

    alt Credentials Valid
        API-->>Frontend: JWT Token
        Frontend-->>User: Success
    else Invalid Credentials
        API-->>Frontend: 401 Error
        Frontend-->>User: Login Failed
    end

    Note over User,Database: Authentication Flow
```

**Features tested:**
- Actor backgrounds and borders
- Signal/arrow colors
- Note styling
- Alt/else blocks
- Text readability on various backgrounds

---

## 3. Pie Chart (Third Most Popular)

```mermaid
pie title Project Time Distribution
    "Development" : 45
    "Testing" : 20
    "Code Review" : 15
    "Documentation" : 10
    "Meetings" : 10
```

**Features tested:**
- Automatic color generation for slices
- Text on colored backgrounds
- Title styling
- Mermaid's auto-derived pie1-12 colors

---

## 4. State Diagram (Fourth Most Popular)

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading : startRequest()
    Loading --> Success : requestComplete()
    Loading --> Error : requestFailed()

    Success --> Idle : reset()
    Error --> Idle : retry()

    Error --> [*] : abort()
    Success --> [*] : close()

    state Loading {
        [*] --> Fetching
        Fetching --> Processing
        Processing --> [*]
    }
```

**Features tested:**
- State node backgrounds
- Transition arrows
- Nested states (composite state)
- Start/end markers
- Transition labels

---

## 5. Gantt Chart (Fifth Most Popular)

```mermaid
gantt
    title SuperDeck Development Roadmap
    dateFormat YYYY-MM-DD

    section Phase 1
    Research & Planning    :done, p1, 2024-01-01, 2024-02-01
    Core Architecture      :done, p2, 2024-02-01, 2024-03-15

    section Phase 2
    Mermaid Integration    :active, p3, 2024-03-15, 2024-04-30
    Theme System          :active, p4, 2024-04-01, 2024-05-15

    section Phase 3
    Documentation         :p5, 2024-05-01, 2024-06-01
    Beta Testing          :p6, 2024-05-15, 2024-06-30

    section Launch
    Release v1.0          :crit, p7, 2024-06-30, 2024-07-15
```

**Features tested:**
- Task backgrounds (pending, active, done, critical)
- Grid colors
- Section headers
- Date axis styling
- Today line color (if applicable)

---

## Bonus: Class Diagram

```mermaid
classDiagram
    class MermaidTheme {
        +String background
        +String primary
        +String text
        +bool darkMode
        +toThemeVariables() Map
    }

    class MermaidGenerator {
        +MermaidTheme theme
        +generateAsset() Future~List~
    }

    class ColorUtils {
        +lighten() String
        +darken() String
        +contrastColor() String
    }

    MermaidGenerator --> MermaidTheme
    MermaidTheme --> ColorUtils
```

**Features tested:**
- Class boxes
- Method and property styling
- Relationship arrows
- Generic type notation

---

## Theme System Features

This presentation demonstrates:

✅ **Simple 4-color API** - Only background, primary, text, darkMode needed
✅ **Automatic derivation** - Secondary, tertiary, and all diagram-specific colors
✅ **Consistent styling** - All diagram types use the same color palette
✅ **High readability** - Proper contrast between text and backgrounds
✅ **Mermaid integration** - Leverages Mermaid's built-in color derivation

---

## How to Test Different Themes

```dart
// Dark theme (default)
MermaidGenerator(theme: MermaidTheme.dark);

// Light theme
MermaidGenerator(theme: MermaidTheme.light);

// Custom theme
MermaidGenerator(
  theme: MermaidTheme(
    background: '#1a1a2e',
    primary: '#00ff88',
    text: '#ffffff',
    darkMode: true,
  ),
);
```

---

## What's Next?

- Run `dart ../packages/cli/bin/main.dart build` to generate all diagrams
- Check `.superdeck/assets/mermaid_*.png` for visual results
- Verify colors are consistent and readable
- Test with different themes by modifying the generator configuration

---

## End

Simple. Powerful. Consistent.

The new 4-color theme system for SuperDeck Mermaid diagrams.
