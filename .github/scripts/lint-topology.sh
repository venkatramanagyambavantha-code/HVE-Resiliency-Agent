#!/usr/bin/env bash
# Static checks for the deployment topology contract.
# Run from the repository root: bash .github/scripts/lint-topology.sh
set -uo pipefail

CONTRACT=".github/instructions/hve-resiliency-topology.instructions.md"
LOCK_PROMPT=".github/prompts/hve-resiliency-topology-0-lock.prompt.md"
FAIL=0

say()  { printf '%s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; FAIL=1; }
pass() { printf '  ok    %s\n' "$*"; }

# Files the rules deliberately exempt: the contract defines the vocabulary,
# and the lock prompt documents its own region defaults.
exempt() {
  case "$1" in
    "$CONTRACT"|"$LOCK_PROMPT") return 0 ;;
    *) return 1 ;;
  esac
}

say "== 1. contract and lock prompt exist =="
[ -f "$CONTRACT" ]    && pass "contract present"    || fail "missing $CONTRACT"
[ -f "$LOCK_PROMPT" ] && pass "lock prompt present" || fail "missing $LOCK_PROMPT"

say ""
say "== 2. no hardcoded region literals =="
hits=0
while IFS= read -r f; do
  exempt "$f" && continue
  if grep -qiE 'west us|westus|east us|eastus' "$f"; then
    fail "region literal in $f"; hits=$((hits+1))
  fi
done < <(find .github -name '*.md')
[ "$hits" -eq 0 ] && pass "no region literals outside the contract and lock prompt"

say ""
say "== 3. no hardcoded research paths =="
if grep -rq '\.copilot-tracking/research/' .github --include='*.md'; then
  grep -rln '\.copilot-tracking/research/' .github --include='*.md' | while read -r f; do fail "hardcoded research path in $f"; done
  FAIL=1
else
  pass "all research paths use <researchRoot>"
fi

say ""
say "== 4. topology is declared, never discovered =="
# A prompt must not select topology from a dependency or database inventory.
if grep -rlniE '(select|choose|determine|derive) .{0,40}(kafka )?topology .{0,40}(from|based on) .{0,30}(database|dependency|inventory|cosmos|sql)' \
     .github --include='*.md' | grep -q .; then
  grep -rlniE '(select|choose|determine|derive) .{0,40}topology .{0,40}(from|based on) .{0,30}(database|dependency|inventory|cosmos|sql)' \
     .github --include='*.md' | while read -r f; do fail "topology inferred from evidence in $f"; done
  FAIL=1
else
  pass "no prompt derives deployment topology from discovered evidence"
fi

say ""
say "== 5. no operator prompt for topology =="
# Match only AFFIRMATIVE gates; "Never ask the operator ..." is the desired state.
if grep -rniE '(^|[^a-z])(ask|prompt) the (operator|user) (which|what) [^.]{0,40}topology' .github --include='*.md' \
     | grep -viE 'never |do not |don.t |no longer ' | grep -q .; then
  grep -rlniE '(^|[^a-z])(ask|prompt) the (operator|user) (which|what) [^.]{0,40}topology' .github --include='*.md' \
     | while read -r f; do grep -qiE 'never ask|do not ask' "$f" || fail "operator topology gate in $f"; done
  pass "affirmative gates checked"
else
  pass "no interactive topology gate remains"
fi

say ""
say "== 6. write model is not called 'topology' =="
if grep -rqE '(Topology verdict|Topology classification):' .github --include='*.md'; then
  # legacy labels may be referenced only as deprecated aliases
  bad=0
  while IFS= read -r f; do
    if ! grep -qi 'deprecat\|legacy' "$f"; then fail "write model labelled as topology in $f"; bad=1; fi
  done < <(grep -rlE '(Topology verdict|Topology classification):' .github --include='*.md')
  [ "$bad" -eq 0 ] && pass "legacy labels appear only as deprecated aliases"
  [ "$bad" -eq 1 ] && FAIL=1
else
  pass "no conflatable write-model labels"
fi

say ""
say "== 7. delta prompts carry the required clauses =="
# Research prompts continue and record; consolidation prompts stop Blocked.
# Both are correct implementations of Mismatch Handling, so check per class.
missing=0
while IFS= read -r f; do
  grep -q 'hve-resiliency-topology.instructions.md' "$f" || { fail "no contract link: $f"; missing=1; }
  case "$f" in
    *consolidate*)
      grep -qi 'artifact topology mismatch' "$f" \
        || { fail "consolidation prompt lacks the block-on-mismatch rule: $f"; missing=1; } ;;
    *)
      grep -qi 'never switch' "$f" \
        || { fail "research prompt lacks the never-switch clause: $f"; missing=1; } ;;
  esac
done < <(grep -rl '^## Topology Deltas' .github/prompts)
[ "$missing" -eq 0 ] && pass "all delta prompts link the contract and carry the correct mismatch rule for their class"

say ""
say "== 8. planner layer is topology-parameterized =="
# Match only an affirmative default, not a statement that there is none.
if grep -rniE 'targetDeployment[^.]{0,80}[Dd]efault[^.]{0,40}Active/Active' .github/prompts/planner/ \
     | grep -viE 'no default|never|not default' | grep -q .; then
  fail "planner still defaults targetDeployment to Active/Active"
else
  pass "targetDeployment no longer defaults to Active/Active"
fi

say ""
if [ "$FAIL" -eq 0 ]; then say "RESULT: PASS"; else say "RESULT: FAIL"; fi
exit "$FAIL"
