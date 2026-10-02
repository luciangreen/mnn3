:- module(mnn3_task_graph, [validate_task_graph/1, topological_order/2]).

:- use_module(library(lists),
              [ member/2,
                subset/2,
                select/3,
                delete/3,
                reverse/2,
                same_length/2
              ]).
:- use_module(library(apply), [maplist/2]).

validate_task_graph(Tasks) :-
    is_list(Tasks),
    findall(Id, member(task(Id, _, _, _), Tasks), Ids),
    sort(Ids, UniqueIds),
    same_length(Ids, UniqueIds),
    forall(member(task(_, _, Dependencies, _), Tasks),
           (is_list(Dependencies), maplist(member_of(Ids), Dependencies))),
    forall(member(task(Id, _, Dependencies, _), Tasks),
           \+ memberchk(Id, Dependencies)),
    topological_order(Tasks, _),
    !.

member_of(Ids, Id) :- memberchk(Id, Ids).

topological_order(Tasks, Order) :-
    validate_graph_edges(Tasks),
    findall(Id, member(task(Id, _, _, _), Tasks), Ids),
    once(topological_loop(Tasks, Ids, [], Order)).

validate_graph_edges(Tasks) :-
    is_list(Tasks),
    findall(Id, member(task(Id, _, _, _), Tasks), Ids),
    sort(Ids, UniqueIds),
    same_length(Ids, UniqueIds),
    forall(member(task(_, _, Dependencies, _), Tasks),
           (is_list(Dependencies), maplist(member_of(Ids), Dependencies))).

topological_loop([], [], Accumulator, Order) :- reverse(Accumulator, Order).
topological_loop(Tasks, Remaining, Accumulator, Order) :-
    select_ready(Remaining, Tasks, Accumulator, Ready),
    Ready \== [],
    remove_task(Ready, Tasks, RestTasks),
    delete(Remaining, Ready, RestRemaining),
    topological_loop(RestTasks, RestRemaining, [Ready|Accumulator], Order).

select_ready([Id|_], Tasks, Done, Id) :-
    memberchk(task(Id, _, Dependencies, _), Tasks),
    subset(Dependencies, Done),
    !.
select_ready([_|Rest], Tasks, Done, Ready) :-
    select_ready(Rest, Tasks, Done, Ready).

remove_task(Id, Tasks, Rest) :-
    select(task(Id, _, _, _), Tasks, Rest).
