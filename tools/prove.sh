#!/bin/sh
# GNATprove on the SPARK_Mode units (§74). Foundational bounded algorithms are
# proved free of run-time errors; callback-heavy polymorphic execution is out of
# scope for proof by design.

set -eu
cd "$(dirname "$0")/.."

alr exec -- gnatprove -P validation.gpr --mode=all --level=1 \
  -u validation-identifier_syntax.adb "$@"

echo "proof: identifier_syntax clean"
