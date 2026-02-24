# Mermaid Official Theme Definitions

This directory contains the official theme definitions from [mermaid-js/mermaid](https://github.com/mermaid-js/mermaid) repository (develop branch).

## Files

- **theme-default.js** (432 lines) - Default purple/lavender theme
- **theme-dark.js** (395 lines) - Dark theme (dark content on light background)
- **theme-forest.js** (398 lines) - Forest/green nature theme
- **theme-neutral.js** (404 lines) - Neutral B&W theme for printing
- **theme-base.js** (399 lines) - Base customizable theme

## Key Color Values

### Default Theme
```javascript
background: '#f4f4f4'
primaryColor: '#ECECFF'
secondaryColor: '#ffffde'
mainBkg: '#ECECFF'
lineColor: '#333333'
border1: '#9370DB'
border2: '#aaaa33'
textColor: '#333'
```

### Dark Theme
```javascript
background: '#333'
primaryColor: '#1f2020'
secondaryColor: lighten(primaryColor, 16)
mainBkg: '#1f2020'
textColor: '#ccc'
border1: '#ccc'
border2: rgba(255, 255, 255, 0.25)
titleColor: '#F9FFFE'
```

### Forest Theme
```javascript
background: 'white'
primaryColor: '#cde498'
secondaryColor: '#cdffb2'
mainBkg: '#cde498'
lineColor: 'green'
border1: '#13540c'
border2: '#6eaa49'
tertiaryColor: lighten('#cde498', 10)
```

### Neutral Theme
```javascript
background: '#f4f4f4'
primaryColor: '#eee'
secondaryColor: '#006100'
tertiaryColor: '#fff'
mainBkg: '#eee'
lineColor: '#707070'
border1: '#cccccc'
border2: '#888888'
```

### Base Theme
```javascript
background: '#f4f4f4'
primaryColor: '#fff4dd'
secondaryColor: adjust(primaryColor, { h: -120 })
tertiaryColor: adjust(primaryColor, { h: 120, s: -15, l: -10 })
// Base is designed to be fully customizable via themeVariables
```

## Patterns Observed

### Color Derivation
All themes use helper functions from `khroma` library:
- `lighten(color, amount)` - Lighten a color
- `darken(color, amount)` - Darken a color
- `adjust(color, { h, s, l })` - Adjust hue, saturation, lightness
- `invert(color)` - Invert a color
- `rgba(r, g, b, a)` - Create RGBA color
- `isDark(color)` - Check if color is dark
- `mkBorder(color, darkMode)` - Create border color

### Variable Types
Each theme defines ~100+ variables for different diagram types:
- **Flowchart**: nodeBkg, nodeBorder, clusterBkg, defaultLinkColor
- **Sequence**: actorBorder, actorBkg, signalColor, labelBoxBkgColor
- **Class**: classText, attributeBackgroundColorOdd, attributeBackgroundColorEven
- **State**: labelColor, altBackground, errorBkgColor, errorTextColor
- **ER Diagram**: attributeBackgroundColorOdd, attributeBackgroundColorEven
- **Gantt**: sectionBkgColor, taskBkgColor, todayLineColor
- **Git**: git0-7, gitInv0-7, gitBranchLabel0-9
- **Pie**: pie1-12, pieTitleTextSize, pieTitleTextColor
- **Requirement**: requirementBackground, requirementBorderColor
- **Timeline**: cScale0-11, cScaleInv0-11

### Our Implementation vs Mermaid's Approach

**Mermaid's Approach:**
- Hard-coded base colors
- Use khroma functions for derivation
- Many variables set to 'calculated' (computed later)
- ~400 lines per theme

**Our Approach:**
- ColorUtils.dart for Dart-side calculations
- All variables explicitly calculated upfront
- No 'calculated' placeholders
- More predictable and testable

## Usage Notes

These files are for reference only. We use our own theme implementation in `mermaid_theme.dart` which:
1. Provides better control over color calculations
2. Ensures consistency across diagram types
3. Optimizes for our specific dark/light slide backgrounds
4. Implements fallback logic for problematic diagrams (timeline)

## Source

Downloaded from: https://github.com/mermaid-js/mermaid/tree/develop/packages/mermaid/src/themes
Date: October 20, 2025
Mermaid Version: v11.x (develop branch)
