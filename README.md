# MNN3

MNN3 is a deterministic SWI-Prolog prototype for planning artifact projects and
writing reviewed text artifacts into a configured workspace. It is an
artifact-producing layer, not an agent for operating a computer or contacting
third-party systems.

## Requirements

- SWI-Prolog 9.x

Run the security tests first, followed by the full test suite:

```sh
swipl -q -s tests/run_tests.pl -g "run_tests(mnn3_security)" -t halt
swipl -q -s tests/run_tests.pl -g run_tests -t halt
```

## Try it

Start the Prolog console with the MNN3 API loaded:

```sh
swipl -q -s prolog/mnn3.pl
```

Configure a workspace directory that already exists, then create a structured
plan. Plans and generated files are data; MNN3 does not execute them.

```prolog
?- mnn3:configure_workspace('/path/to/your/workspace').
?- mnn3:plan_project(demo, "Prepare a sample report", [report, documentation],
                      Plan, Trace).
```

Generated text can be saved with `create_project_artifact/6`:

```prolog
?- mnn3:create_project_artifact(
       demo, 'reports/summary.md', markdown, 'Summary report',
       [report_requirement], "# Summary\n\nHuman review required.\n").
?- mnn3:create_completion_report(demo, Completion).
?- mnn3:create_manifest(demo, Manifest).
?- mnn3:run_internal_pure_test(
       assert_equal(5, add(integer(2), integer(3))), Result).
```

Paths are workspace-relative. Parent directories are created only under the
workspace. The API rejects absolute paths, traversal, encoded separators,
symlink escapes, unsupported artifact types, and artifacts over configured
limits. Use only a dedicated workspace; do not point it at a filesystem root,
home directory, or a directory containing sensitive files.

## What is implemented

- Default-deny capability reference monitor and restricted logical-subagent
  capability delegation.
- Workspace-relative artifact read/write and size/count limits.
- Deterministic goal decomposition, dependency-checked task ordering, project
  trace, assumptions, decisions, revisions, provenance, and completion report.
- Requirement-to-implementation/test traceability checks and artifact-spec
  dependency validation; completion reports distinguish missing mappings.
- Static Prolog capability warnings, a deliberately small arithmetic/boolean
  pure-test interpreter, requirement test-case scaffolding, workflow variants,
  and a fail-closed baseline for optional integrations.
- A Prolog-term artifact manifest and completion report; generated workspace
  files are ignored by Git by default.
- Security, unit, and end-to-end regression tests.

Generated Prolog that appears to use shell, process, socket, HTTP, pipe, or
foreign-library capabilities is marked for human review. This scanner is a
heuristic: it is not a proof that arbitrary generated code is safe. MNN3 never
loads or executes generated artifacts.

## Integration status and trust boundary

MNN1, MNN2, S2A, and learned AIOC implementations are not included in this
repository. Their adapters report that they are unavailable; MNN3 does not
pretend to provide language-model interpretation or algorithm discovery.
Goals therefore enter through the structured Prolog API. Workflow selection
is a deterministic baseline, not learned optimization.

The modules avoid importing shell, process, network-client, browser-control, or
credential APIs, and do not accept generated Prolog as executable input.
However, SWI-Prolog itself is a general-purpose runtime: module-level code
cannot remove operating-system capabilities from the Prolog process or protect
against a malicious operator with direct access to its console. A production
deployment must additionally run MNN3 under a separately configured
OS-enforced sandbox with network disabled, a dedicated workspace mount, and
resource limits. This repository does not claim that the Prolog API alone is
an OS sandbox or that it eliminates filesystem time-of-check/time-of-use and
hard-link risks.

No artifact is deployed, published, uploaded, committed remotely, or otherwise
sent outside the workspace. A human must review and separately handle any
external use.
