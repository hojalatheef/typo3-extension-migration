#!/usr/bin/env bash
set -euo pipefail
cp -R "$(cd "$(dirname "$0")/../fixtures/legacy_events" && pwd)/." .
sed -i.bak -e 's/\^11\.5/^13.4/g' -e 's/"\^7\.4 || \^8\.0"/"^8.2"/' composer.json
sed -i.bak -e "s/11\.5\.0-11\.5\.99/13.4.0-13.4.99/" -e "s/7\.4\.0-8\.1\.99/8.2.0-8.4.99/" ext_emconf.php
rm -f ./*.bak
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -qm init
