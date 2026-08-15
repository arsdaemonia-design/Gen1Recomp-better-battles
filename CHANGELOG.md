# Changelog

All notable changes to the Better Battles mod will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-08-14

### Added
- **Type Badges**: Now display the real type icons (`assets/type_*.png`, the 15 Gen 1 types) instead of plain colored squares, pre-scaled and cached for crisp window-resolution rendering in both Classic 2D and Voxel 3D modes (color fallback if an image is missing).
- **Effective Markers**: Colored numeric multiplier (×0 / ×1 / ×2 / ×4 / ×.5 / ×.25) shown next to the marker (green super-effective, red not-very, grey no-effect).
- **Effective Markers**: Best Move Suggestion — a pulsing golden square highlights the move with the best expected damage (power × effectiveness).

### Changed
- **Effective Markers**: Markers, multiplier and suggestion are now drawn at window resolution via `render.hud` in Classic 2D mode, matching the crispness of the Voxel `shot.canvas` instead of tiny pixels on the 160×144 canvas.
- **Effective Markers**: Marker, multiplier and suggestion positions tweaked for better alignment (no longer touching the box edge or the text below).

### Fixed
- **Effective Markers**: Fixed crash when opening the FIGHT/PKM menu by replacing the non-existent `mod.content.types:getEffectiveness` with `TypeChart.effectiveness` (`src/battle/TypeChart.lua`).
- **Quick Item**: Fixed layering so the quick item menu is drawn above the battle menu in all modes (previously it could render behind it in Voxel).

## [1.0.0] - 2026-08-09

### Added
- **Better Status**: Floating status text and HP bar color gradients for status conditions (`PSN`, `BRN`, `PAR`, `FRZ`, `SLP`). Now features independent toggles for Text and Overlay!
- **Caught Indicator**: Pokeball icon in wild battles next to Pokemon names if caught in Pokedex.
- **Quick Item Menu**: Press Left Arrow in battle to quickly throw Pokeballs or use Potions.
- **Type Badges**: Johto-style colored squares next to level indicators in battle (supports 2D and Voxel 3D modes).
- **Effective Markers**: Move effectiveness indicators (Super Effective, Not Very Effective, No Effect) shown during move selection, featuring Voxel 3D support and Gold STAB highlight.
- **Party Advantage**: When opening the Pokemon Party Menu in battle, a bright green arrow (▲) appears dynamically next to Pokemon that have a super-effective move against the current enemy. Glows GOLD if the move has STAB!
- Options menu toggles for each feature under game Options.
