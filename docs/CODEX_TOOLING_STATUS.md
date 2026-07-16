# Codex Tooling Status

Generated: 2026-07-16T15:27:11

## Requested tooling

- Micrographic skill: MISSING
- Context7 MCP: CONFIGURED
- Ponytail plugin: INSTALLED
- Superpowers plugin: INSTALLED
- CodeGraph: NOT BUILT

## Required manual security step

Codex does not automatically trust plugin hooks.

1. Run `./scripts/start-codex-ready.sh`.
2. Open `/plugins` and verify Superpowers and Ponytail.
3. Open `/mcp` and verify Context7 and CodeGraph.
4. Open `/hooks`.
5. Review each command and trust only expected hooks from installed plugins.
6. Start a new Codex thread after trusting hooks.

## Environment

- Git version: `git version 2.43.0`
- Node version: `v22.23.1`
- npm version: `10.9.8`
- Codex version: `codex-cli 0.144.4`
- Flutter version: `missing`
- Dart version: `missing`
- Docker version: `Docker version 29.5.2, build 79eb04c`
- Java version: `openjdk version "21.0.11" 2026-04-21`

## Successful operations

- Git version
- Node version
- npm version
- Codex version
- Docker version
- Java version
- Installed Codex plugins before setup
- Codex plugin marketplaces before setup
- Codex MCP servers before setup
- Install Micrographic Codex skill
- Context7 MCP
- Refresh installed plugin state
- Ponytail plugin
- Discover available Codex plugins
- Superpowers plugin
- Clone CodeGraph
- Final Codex plugin list
- Final Codex MCP list
- Final Codex marketplace list

## Failed or skipped operations

- Flutter version
- Dart version
- Install CodeGraph dependencies

## Warnings

- Micrographic installer did not create .codex/skills/micrographic/SKILL.md.
- CodeGraph did not build successfully.
