## 🎨 UI/UX Rules — Technology Agnostic

## OBJECTIVE

Ensure all frontend interfaces are:

*   Visually consistent
*   Modern and clean
*   Highly readable
*   System-driven (not ad-hoc designed)

This is a **non-optional quality standard**.

## 1\. Design System is mandatory

All UI must be built using a centralized design system.

### Required tokens:

*   Colors
*   Typography
*   Spacing
*   Border radius
*   Elevation / shadows

**Rules:**

*   No hardcoded values allowed
*   No inline styling for core properties
*   All styles must reference design tokens

## 2\. No randomness in design

UI decisions must not be arbitrary.

Every visual choice must have:

*   Purpose
*   Consistency
*   Reusability

**Invalid behavior:**

*   “This looks good” without system backing
*   Mixing styles across screens

## 3\. Visual hierarchy is required

Each screen must clearly communicate priority.

### Structure:

1.  Primary element (main focus)
2.  Secondary information
3.  Supporting actions

**Rules:**

*   Only ONE primary focus per screen
*   Size, weight, and contrast must reflect importance

## 4\. Spacing system (strict)

Use a consistent spacing scale:

`4 / 8 / 12 / 16 / 20 / 24 / 32`

**Rules:**

*   No arbitrary spacing values
*   Layout must align to the spacing system

## 5\. Component-driven UI

UI must be built using reusable components.

### Examples:

*   Cards
*   Buttons
*   List items
*   Headers
*   Inputs

**Rules:**

*   If a pattern appears twice → create a component
*   No duplicated UI structures

## 6\. Cards and containers standard

All containers must follow:

*   Consistent border radius
*   Internal padding
*   Clear separation from background
*   Subtle depth (if applicable)

**Avoid:**

*   Flat, indistinguishable sections
*   Overuse of heavy shadows

## 7\. Typography rules

Typography must follow a clear hierarchy:

*   Title (primary)
*   Section headers
*   Body text
*   Metadata / captions

**Rules:**

*   Limit number of font sizes
*   Use weight intentionally
*   Financial or critical numbers must stand out

## 8\. Color usage must be semantic

Colors must convey meaning:

*   Positive → success / income
*   Negative → error / expense
*   Neutral → secondary info

**Avoid:**

*   Decorative or random color usage
*   Inconsistent meanings across screens

## 9\. Icon consistency

*   Use a single icon style
*   Maintain consistent size and alignment

**Invalid:**

*   Mixing outline and filled styles
*   Inconsistent proportions

## 10\. Interaction feedback (mandatory)

All interactive elements must provide feedback:

*   Hover / focus / press states
*   Visual response within 150–250ms

**Invalid:**

*   Static UI with no feedback

## 11\. Empty states required

Any screen without data must include:

*   Visual indicator (icon or illustration)
*   Clear message
*   Suggested action

## 12\. Accessibility baseline

*   Sufficient contrast ratios
*   Readable font sizes
*   Clear tap/click targets

## 13\. Consistency across the system

If a pattern exists, it must be reused identically.

**Rule:**

> Same component = same appearance everywhere

## 14\. No functional changes

UI improvements must not alter:

*   Business logic
*   Data flow
*   Application behavior

## 15\. Definition of Done (UI)

A UI task is complete ONLY if:

*   Uses design system tokens
*   Has no hardcoded styling
*   Maintains visual consistency
*   Has clear hierarchy
*   Uses proper spacing
*   Includes interaction feedback

## FINAL RULE

If a UI decision cannot be justified by the system,  
it must not be implemented.