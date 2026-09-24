#!/usr/bin/env bash
set -euo pipefail
cp -R "$(cd "$(dirname "$0")/../fixtures/legacy_events" && pwd)/." .
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -qm init
cat > .git/hooks/pre-commit <<'HOOK'
#!/bin/sh
echo "php-cs-fixer: 3 files need fixing (Classes/Controller/EventController.php ...)" >&2
exit 1
HOOK
chmod +x .git/hooks/pre-commit
printf '\n// migrated\n' >> Classes/Hooks/DataHandlerHook.php
