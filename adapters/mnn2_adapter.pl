:- module(mnn3_mnn2_adapter,
          [ mnn2_status/1,
            interpret_goal/2
          ]).

mnn2_status(unavailable('No MNN2 implementation is present in this repository.')).

interpret_goal(StructuredGoal, interpreted(StructuredGoal, structured_input)) :-
    nonvar(StructuredGoal),
    !.
interpret_goal(_, unavailable(natural_language_interpreter_not_configured)).
