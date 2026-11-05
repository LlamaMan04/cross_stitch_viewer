# Needed UI Changes

## Pattern render section

The entire render engine needs to be reworked to only render the current visible area. In addition, the following changes need to be made from the existing status:

- Update color pallette. Prefer a more grayscale app theme with option to adjust colors in settings page. The pattern itself may render thread colors as desired.
- Cap the size of the lines between grid squares. You should always be able to see the cells no matter the size of the screen or zoom level.
- Adjust the screen layout so that all headings/captions/settings are in a small upper bar or a collapsible side bar. The rest of the viewport should belong to the pattern renderer, it is the main feature.
- Provide options to render each cell as color or no color as well as symbol or no symbol. Default to render with symbol and no color. Add a local config option to change the transparency of the rendered color.
- Change the grid color to solid black. Add an option to change this between a few preset values in the collapsible sidebar.
- The grid must render a sub-grid 10 cells by 10 cells inside the main grid as slightly thicker lines than the standard grid lines, but still thinner than the outside lines.
- Add a toggleable ruler on the top and left sides (configurable) that displays tick marks for each grid line, as well as numbers displaying the coordinates of the sub-grid (every 10 stitches).
- Allow source regions to be toggled on and off from being rendered in the grid. By default do not render them.
- Add a configuration option to select whether or not completed cells are highlighted as part of cells highlighted by selected symbol.
