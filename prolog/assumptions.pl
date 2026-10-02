:- module(mnn3_assumptions, [record_assumption/4, assumptions/1]).

:- dynamic assumption/4.

record_assumption(Id, Description, Reason, AffectedArtifacts) :-
    atom(Id),
    is_list(AffectedArtifacts),
    with_mutex(mnn3_assumptions,
               ( retractall(assumption(Id, _, _, _)),
                 assertz(assumption(Id, Description, Reason, AffectedArtifacts))
               )).

assumptions(Assumptions) :-
    findall(assumption(Id, Description, Reason, Affected),
            assumption(Id, Description, Reason, Affected),
            Assumptions).
