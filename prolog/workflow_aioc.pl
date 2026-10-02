:- module(mnn3_workflow_aioc,
          [ compare_workflows/3,
            workflow_score/3
          ]).

:- use_module(workflow_library).

compare_workflows(First, Second, Comparison) :-
    workflow_score(First, FirstScore, FirstHardConstraints),
    workflow_score(Second, SecondScore, SecondHardConstraints),
    (   FirstHardConstraints \= satisfied
    ->  Comparison = rejected(First)
    ;   SecondHardConstraints \= satisfied
    ->  Comparison = rejected(Second)
    ;   FirstScore >= SecondScore
    ->  Comparison = preferred(First)
    ;   Comparison = preferred(Second)
    ).

workflow_score(Workflow, Score, satisfied) :-
    atom(Workflow),
    (   mnn3_workflow_library:workflow(Workflow, Features)
    ;   mnn3_workflow_library:workflow_variant(Workflow, Features)
    ),
    !,
    length(Features, Score).
workflow_score(_, 0, unknown).
