# Needed UI Changes

- Add a presentation mode that renders a full-scale version of the pattern with no symbols, no grid, and full opacity cell colors. Render this separately from the pattern view, it should not be scrollable or zoomable and will not be as concerned about optimization.
- Add renderer support for displaying full/half/other stitch types.
- Avoid using the extra buffer area around a backstitch slice if it is already selected, allowing the user to select the cell beneath it.
