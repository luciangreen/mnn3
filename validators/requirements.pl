:- module(mnn3_requirements_validator,
          [ validate_requirement_traceability/4
          ]).

:- use_module(library(lists), [member/2, sort/2]).
:- use_module(library(apply), [maplist/2]).

validate_requirement_traceability(Requirements, Implementations, Tests,
                                  traceability(Status, MissingImplementations,
                                               MissingTests)) :-
    is_list(Requirements),
    is_list(Implementations),
    is_list(Tests),
    maplist(valid_requirement, Requirements),
    maplist(valid_implementation, Implementations),
    maplist(valid_test, Tests),
    sort(Requirements, UniqueRequirements),
    findall(Requirement,
            (member(Requirement, UniqueRequirements),
             \+ member(implements(_, requirement(Requirement)), Implementations)),
            MissingImplementations),
    findall(Requirement,
            (member(Requirement, UniqueRequirements),
             \+ member(tests(_, requirement(Requirement)), Tests)),
            MissingTests),
    (MissingImplementations == [], MissingTests == [] ->
        Status = complete
    ;   Status = incomplete
    ).

valid_requirement(Requirement) :-
    atom(Requirement).

valid_implementation(implements(File, requirement(Requirement))) :-
    text_value(File),
    atom(Requirement).

valid_test(tests(File, requirement(Requirement))) :-
    text_value(File),
    atom(Requirement).

text_value(Text) :-
    atom(Text),
    Text \== '',
    !.
text_value(Text) :-
    string(Text),
    Text \== "".
