:- module(mnn3_decisions, [record_decision/5, decisions/1]).

:- dynamic decision/5.

record_decision(Id, Choice, Alternatives, Reason, Time) :-
    atom(Id),
    is_list(Alternatives),
    with_mutex(mnn3_decisions,
               ( retractall(decision(Id, _, _, _, _)),
                 assertz(decision(Id, Choice, Alternatives, Reason, Time))
               )).

decisions(Decisions) :-
    findall(decision(Id, Choice, Alternatives, Reason, Time),
            decision(Id, Choice, Alternatives, Reason, Time),
            Decisions).
