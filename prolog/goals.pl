:- module(mnn3_goals, [make_goal/6]).

:- use_module(library(apply), [maplist/2]).

make_goal(Id, Description, Inputs, Outputs, Constraints,
          goal(Id, Description, Inputs, Outputs, Constraints, pending)) :-
    atom(Id),
    Id \== '',
    text_value(Description),
    is_list(Inputs),
    is_list(Outputs),
    Outputs \= [],
    is_list(Constraints),
    maplist(atom, Outputs),
    maplist(atom, Constraints).

text_value(Text) :- string(Text), !.
text_value(Text) :- atom(Text), Text \== ''.
