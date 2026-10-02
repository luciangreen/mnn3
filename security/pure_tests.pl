:- module(mnn3_pure_tests, [run_internal_pure_test/2]).

:- use_module(capability, [request_capability/4]).
:- use_module(resource_limits, [max_task_depth/1]).

run_internal_pure_test(Test, Result) :-
    request_capability(mnn3, run_internal_pure_test, pure_test(internal), allow),
    max_task_depth(MaxDepth),
    (   evaluate(Test, 0, MaxDepth, Result)
    ->  true
    ;   Result = unsupported_or_limit_exceeded
    ).

evaluate(assert_equal(Expected, Expression), Depth, Limit, Result) :-
    integer(Expected),
    next_depth(Depth, Limit, Next),
    evaluate_expression(Expression, Next, Limit, Actual),
    (Actual =:= Expected -> Result = passed ; Result = failed(expected(Expected), got(Actual))).
evaluate(assert_true(Expression), Depth, Limit, Result) :-
    evaluate_boolean(Expression, Depth, Limit, Truth),
    (Truth == true -> Result = passed ; Result = failed(assertion_false)).
evaluate(all(Tests), Depth, Limit, Result) :-
    is_list(Tests),
    length(Tests, Count),
    Count =< 1000,
    next_depth(Depth, Limit, Next),
    evaluate_all(Tests, Next, Limit, Result).

evaluate_all([], _, _, passed).
evaluate_all([Test|Rest], Depth, Limit, Result) :-
    evaluate(Test, Depth, Limit, First),
    (   First == passed
    ->  evaluate_all(Rest, Depth, Limit, Result)
    ;   Result = failed(test(First))
    ).

evaluate_boolean(true, _, _, true).
evaluate_boolean(false, _, _, false).
evaluate_boolean(equal(A, B), Depth, Limit, Truth) :-
    evaluate_expression(A, Depth, Limit, Left),
    evaluate_expression(B, Depth, Limit, Right),
    (Left =:= Right -> Truth = true ; Truth = false).
evaluate_boolean(less_than(A, B), Depth, Limit, Truth) :-
    evaluate_expression(A, Depth, Limit, Left),
    evaluate_expression(B, Depth, Limit, Right),
    (Left < Right -> Truth = true ; Truth = false).

evaluate_expression(integer(Value), _, _, Value) :-
    integer(Value),
    abs(Value) =< 1000000000.
evaluate_expression(add(Left, Right), Depth, Limit, Value) :-
    evaluate_binary(+, Left, Right, Depth, Limit, Value).
evaluate_expression(subtract(Left, Right), Depth, Limit, Value) :-
    evaluate_binary(-, Left, Right, Depth, Limit, Value).
evaluate_expression(multiply(Left, Right), Depth, Limit, Value) :-
    evaluate_binary(*, Left, Right, Depth, Limit, Value).
evaluate_expression(integer_divide(Left, Right), Depth, Limit, Value) :-
    evaluate_expression(Left, Depth, Limit, A),
    evaluate_expression(Right, Depth, Limit, B),
    B =\= 0,
    Value is A // B,
    bounded(Value).

evaluate_binary(Operator, Left, Right, Depth, Limit, Value) :-
    next_depth(Depth, Limit, Next),
    evaluate_expression(Left, Next, Limit, A),
    evaluate_expression(Right, Next, Limit, B),
    arithmetic_result(Operator, A, B, Value),
    bounded(Value).

arithmetic_result(+, A, B, Value) :- Value is A + B.
arithmetic_result(-, A, B, Value) :- Value is A - B.
arithmetic_result(*, A, B, Value) :- Value is A * B.

bounded(Value) :- integer(Value), abs(Value) =< 1000000000.
next_depth(Depth, Limit, Next) :-
    Depth < Limit,
    Next is Depth + 1.
