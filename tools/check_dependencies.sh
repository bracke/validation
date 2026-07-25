#!/bin/sh
# Dependency-boundary audit (VAL-INV-019/020, ADR-001).
#
# The Validation core (src/) must never depend on I/O, the system clock,
# randomness, sockets, or any ecosystem project. Fails if any core unit `with`s
# a forbidden package.

set -eu

cd "$(dirname "$0")/.."

# Ada packages that would violate the headless boundary.
FORBIDDEN='Ada\.Text_IO|Ada\.Wide_Text_IO|Ada\.Wide_Wide_Text_IO|Ada\.Direct_IO|Ada\.Sequential_IO|Ada\.Streams\.Stream_IO|Ada\.Directories|Ada\.Calendar\.Clock|Ada\.Numerics\.Float_Random|Ada\.Numerics\.Discrete_Random|GNAT\.Sockets|GNAT\.OS_Lib|AWS'

# Ecosystem projects the core must never consume.
ECOSYSTEM='Forms|Tables|Webframework|Database|Identity|Authorization|I18n|Humanize'

status=0

if grep -rnE "^[[:space:]]*(private[[:space:]]+)?with[[:space:]]+(${FORBIDDEN})" src/; then
  echo "FAIL: core withs a forbidden I/O/clock/random/socket unit"
  status=1
fi

if grep -rnE "^[[:space:]]*(private[[:space:]]+)?with[[:space:]]+(${ECOSYSTEM})[.;]" src/; then
  echo "FAIL: core withs an ecosystem project"
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "dependency boundary: clean ($(ls src/*.ads src/*.adb | wc -l | tr -d ' ') core units)"
fi

exit "$status"
