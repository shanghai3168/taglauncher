# Important Design Notes

This document records important product/design implementation ideas that should be easy to recover later.

## View 2: Colorless Container

The colorless container view groups apps by tag into independent frosted-material cards.

Layout logic:

- Use a masonry/waterfall layout.
- Calculate how many columns fit in the available overlay width.
- Estimate each tag card's height from its app count, current icon size, and card width.
- Place each next tag group into the currently shortest column.
- Each card uses a transparent background over `.ultraThinMaterial`, with only a subtle border by default.
- When the user hovers or clicks a tag/card, the corresponding card is filled with that tag's color at low opacity, creating a temporary focus state.
- Tag navigation hover/click scrolls to the matching card and also activates the same color fill.

Design intent:

- Keep the whole view visually light and non-color-dominant.
- Use color only as an interaction/focus signal.
- Let groups with different app counts occupy natural heights, so dense groups do not force empty space in neighboring groups.

## View 4: Colorless Grid

The colorless grid view also groups apps by tag into frosted-material cards, but aligns cards into row-based grid tracks instead of waterfall columns.

Layout logic:

- Choose a preferred number of grid tracks per row based on available width:
  - 3 tracks on wide screens
  - 2 tracks on medium screens
  - 1 track on narrow screens
- For each row, test span patterns:
  - 3-track row: `1+1+1`, `1+2`, `2+1`, or `3`
  - 2-track row: `1+1` or `2`
  - 1-track row: `1`
- Pick the lowest-cost pattern by estimating how many icon rows each card needs.
- Cards in the same row share the same fixed icon-row height, so their bottoms align.
- Inside each card, apps are manually split into rows and empty cells are filled with clear placeholders to preserve grid alignment.
- Like colorless container view, the card is transparent over `.ultraThinMaterial` by default and only receives low-opacity tag color on hover/click focus.

Design intent:

- Preserve the clarity of grouped cards while making rows visually orderly.
- Avoid the uneven bottom edges of masonry when the user wants a stricter grid feeling.
- Keep the "colorless by default, colored only on focus" interaction model consistent with View 2.

## View 3: Colored Container

The colored container view uses the same masonry/waterfall layout as View 2, but each tag card is always tinted with its tag color.

Interaction logic:

- The card background is always filled with the tag color at low opacity over `.ultraThinMaterial`.
- Hovering a card raises visual emphasis with shadow and a slight scale-up.
- Unlike the colorless container view, clicking the card does not toggle a persistent fill state because the card is already colored.
- Tag navigation hover/click still scrolls to the matching card, but the key visual distinction comes from the card's permanent tag color.
- App drag/drop behavior remains the same: dropping an app onto a card moves or copies it into that tag group.

Design intent:

- Make tag grouping immediately visible without requiring hover.
- Use color as a persistent category marker.
- Keep the masonry layout's compactness while making group identity stronger than View 2.

## View 5: Colored Grid

The colored grid view uses the same row-aligned grid layout as View 4, but each tag card is always tinted with its tag color.

Interaction logic:

- Cards are arranged with the View 4 grid-row algorithm: adaptive track count, span pattern selection, and equal fixed icon-row height per row.
- Each card background is always filled with the tag color at low opacity over `.ultraThinMaterial`.
- Hovering a card adds shadow and a slight scale-up to show focus.
- Clicking does not toggle a fill state because the colored background is permanent.
- Empty cells are still inserted inside each card to keep icon rows aligned.
- App drag/drop behavior remains the same as other container views.

Design intent:

- Combine the stronger category recognition of colored cards with the orderly rhythm of the grid layout.
- Make dense app libraries easier to scan by preserving row alignment.
- Use hover only for focus emphasis, not for revealing color.
