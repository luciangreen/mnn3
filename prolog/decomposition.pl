:- module(mnn3_decomposition, [decompose_goal/2]).

decompose_goal(goal(_, Description, _, Outputs, _, _), Tasks) :-
    text_value(Description),
    is_list(Outputs),
    Tasks = [
        task(requirements, 'Interpret requirements', [], pending),
        task(architecture, 'Select an artifact structure', [requirements], pending),
        task(implementation, 'Generate the requested artifacts', [architecture], pending),
        task(tests, 'Generate and check applicable tests', [implementation], pending),
        task(documentation, 'Document artifacts and assumptions', [implementation], pending),
        task(verification, 'Verify completeness and traceability',
             [requirements, tests, documentation], pending)
    ].

text_value(Text) :- string(Text), !.
text_value(Text) :- atom(Text).
