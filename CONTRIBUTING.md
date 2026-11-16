# Contributing

Thank you for helping Chronicles of Azeroth. This file sets the conventions of the
repository; [README.md](README.md) explains how to run the tests and publish a release.

## Language

Everything in the repository is written in English: code, comments, documentation, commit
messages, issues and pull requests. English is the language most contributors share, so it
keeps the project open to players and developers of every language.

Players see the addon in the language of their game client: every text shown in game goes
through the localization tables of `ChroniquesAzeroth/Locales/`, with an English and a French
entry, and stays out of this rule.

## Changes

- Run the offline tests before opening a pull request, with an English and a French client
  (see [README.md](README.md#development)). Continuous integration runs them again on every
  push and pull request.
- A change that alters what players see or keep is recorded in [CHANGELOG.md](CHANGELOG.md),
  in the section of the next version.
- Saved variables belong to the players: a change of their layout migrates the existing data
  instead of discarding it.
- The addon reads only the WoW client at runtime: no other addon, no network access, no
  heavy work at login. Data that cannot be read from the client is generated at build time
  by the scripts of `tools/` and shipped with the addon.

## License

Contributions are released under the GPL-3.0-or-later license of the project, see
[LICENSE](LICENSE).
