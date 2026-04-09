## Multiline Prompt Plan

- Update the prompt window to size itself from the current command text instead of forcing a single-line height.
- Keep the prompt as a normal editable buffer so multiline typing, pasted commands, and standard buffer editing continue to work without a separate input mode.
- Add prompt height limits in config, with a minimum visible height of 5 lines for larger commands and a capped maximum so the floating window stays usable.
- Recompute prompt layout whenever the buffer changes and preserve cursor position while resizing.
- Make prompt helpers multiline-aware by splitting/joining buffer text consistently for `set_text()`, `get_text()`, history restore, and execution.
- Scope ghost text suggestions to single-line input only so multiline commands do not get misleading inline completions.
- Update history picker positioning to account for the taller prompt window.
- Document the new prompt sizing behavior and config knobs in `README.md`.
- Add regression coverage for multiline `set_text()`/`get_text()` behavior and prompt height calculation.
