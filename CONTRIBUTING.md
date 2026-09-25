# Contributing

- Keep the reference cards factual and short. Link a TYPO3 changelog entry
  (`Breaking-#NNNNN`, `Deprecation-#NNNNN`) whenever a card states a removal.
  If you're not sure, write "verify" rather than guess.
- Every card with a greppable pattern gets a matching row in `data/rules-*.tsv`.
- Scripts must work with the bash 3.2 that ships with macOS and with GNU/BSD
  userlands (no `mapfile`, no `grep -P`, no `sed -i` without a suffix).
- Run `npm test` (self-test and Markdown lint) before opening a pull request.
- Commit messages follow the TYPO3 style: `[FEATURE]`, `[BUGFIX]`, `[TASK]`, `[DOCS]`.
