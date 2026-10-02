:- module(mnn3_planner, [create_plan/2]).

:- use_module(decomposition, [decompose_goal/2]).
:- use_module(task_graph, [validate_task_graph/1]).
:- use_module(library(lists), [member/2]).
:- use_module('../security/resource_limits', [max_task_depth/1]).

create_plan(Goal, plan(Goal, Tasks, Dependencies, Outputs, Validation)) :-
    decompose_goal(Goal, Tasks),
    length(Tasks, TaskCount),
    max_task_depth(MaxTasks),
    TaskCount =< MaxTasks,
    validate_task_graph(Tasks),
    findall(Id-Needs, member(task(Id, _, Needs, _), Tasks), Dependencies),
    Goal = goal(_, _, _, Outputs, _, _),
    Validation = [workspace_confinement, artifact_type_check,
                  static_review, requirement_traceability].
