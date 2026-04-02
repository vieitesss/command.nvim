This is a Neovim plugin for running shell commands inside Neovim, with history, context expansion, validation warnings, terminal recovery, and quickfix integration.

Release workflow:
- Use Semantic Versioning tags in the form `vX.Y.Z`.
- Keep new release notes in `CHANGELOG.md` under `## [Unreleased]` until the release is cut.
- Treat the documented `require('command')` functions, `:Command*` commands, `<Plug>(Command*)` mappings, documented config keys, documented `command.actions.*` modules, and history compatibility as the public API.
- Patch: bug fixes, docs, tests, and internal refactors with no user-facing breakage.
- Minor: backwards-compatible features.
- Before `1.0.0`, breaking changes bump the minor version. After `1.0.0`, they bump the major version.
- When asked to create a release, work from `main`, review changes since the last tag, update `CHANGELOG.md`, create an annotated tag, and push the tag. If there is no prior tag, use `v0.1.0` unless the user asks for a different first version.
- If the user asks for a GitHub release, use `gh release create` and use the matching `CHANGELOG.md` section as the release notes.
- Do not create a release tag or GitHub release unless the user explicitly asks.

There is no automated release pipeline in this repo right now.
