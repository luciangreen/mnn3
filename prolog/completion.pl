:- module(mnn3_completion, [completion_report/2]).

:- use_module(projects, [project/1, project_trace/2]).

completion_report(ProjectId, Report) :-
    project(project(ProjectId, Goal, Tasks, Artifacts, Decisions, Questions, Status)),
    project_trace(ProjectId, Trace),
    format(string(Report),
           '# Completion report~n~n## Goal~n~w~n~n## Status~n~w~n~n## Planned tasks~n~w~n~n## Artifacts produced~n~w~n~n## Decisions~n~w~n~n## Open questions and unavailable integrations~n~w~n~n## Verification~nExternal execution was not performed. Static checks do not replace human review or operating-system sandboxing.~n~n## Project trace~n~w~n~n## Human next steps~nReview the generated artifacts, run appropriate tests in a separately controlled environment, and decide whether to export or deploy them.~n',
           [Goal, Status, Tasks, Artifacts, Decisions, Questions, Trace]).
