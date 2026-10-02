:- module(mnn3_aioc_adapter, [select_workflow/2]).

select_workflow(Tasks, selection(deterministic_baseline, score(0, 0, 0))) :-
    is_list(Tasks).
