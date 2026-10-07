:- module(mnn3_completion, [completion_report/2]).

:- use_module(projects, [project/1, project_trace/2]).
:- use_module(assumptions, [assumptions/1]).
:- use_module(verification, [verify_requirement_traceability/4]).
:- use_module(library(lists), [member/2]).

completion_report(ProjectId, Report) :-
    project(project(ProjectId, Goal, _Tasks, Artifacts, Decisions, Questions, Status)),
    project_trace(ProjectId, Trace),
    assumptions(AssumptionRecords),
    findall(Requirement,
            (member(artifact(_, _, _, Requirements, _, _), Artifacts),
             member(Requirement, Requirements)),
            Requirements0),
    sort(Requirements0, RequirementsCovered),
    findall(Path,
            member(artifact(Path, tests, _, _, _, _), Artifacts),
            GeneratedTests),
    findall(Path-Findings,
            member(artifact(Path, _, _, _, review(human_review_required, Findings), _),
                   Artifacts),
            SensitiveArtifacts),
    findall(implements(Path, requirement(Requirement)),
            (member(artifact(Path, Type, _, Requirements, _, _), Artifacts),
             Type \== tests,
             member(Requirement, Requirements)),
            Implementations),
    findall(tests(Path, requirement(Requirement)),
            (member(artifact(Path, tests, _, Requirements, _, _), Artifacts),
             member(Requirement, Requirements)),
            Tests),
    verify_requirement_traceability(RequirementsCovered, Implementations, Tests,
                                    Traceability),
    format(string(Report),
           '# Completion report~n~n## Requested goal~n~w~n~n## Status~n~w~n~n## Artifacts produced~n~w~n~n## Requirements covered~n~w~n~n## Requirement traceability~n~w~n~n## Algorithms incorporated~nNo MNN1 algorithms were recorded; the MNN1 adapter is unavailable in this repository.~n~n## Tests generated~n~w~n~n## Internal verification~nNo generated test program was executed. Only the restricted pure-test expression interface can be evaluated internally.~n~n## Tests requiring external execution~nTests that require arbitrary program, operating-system, or network behavior remain human-controlled artifacts.~n~n## Assumptions~n~w~n~n## Decisions~n~w~n~n## Unresolved issues and unavailable integrations~n~w~nMNN2 interpretation, S2A algorithm discovery, and learned AIOC are not configured.~n~n## Security-sensitive generated functionality~n~w~n~n## Project trace~n~w~n~n## Human next steps~nReview the artifacts and this heuristic scan, resolve missing requirement mappings, run appropriate tests in a separately controlled environment, and decide whether to export or deploy them. MNN3 itself does not export or deploy artifacts.~n',
           [Goal, Status, Artifacts, RequirementsCovered, Traceability,
            GeneratedTests, AssumptionRecords, Decisions, Questions,
            SensitiveArtifacts, Trace]).
