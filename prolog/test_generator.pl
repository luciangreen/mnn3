:- module(mnn3_test_generator, [requirement_test_cases/2]).

requirement_test_cases(Requirement,
                       [test_case(Requirement, normal),
                        test_case(Requirement, boundary),
                        test_case(Requirement, negative),
                        test_case(Requirement, counterexample),
                        test_case(Requirement, interaction),
                        test_case(Requirement, regression)]) :-
    atom(Requirement).
