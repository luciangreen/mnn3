:- begin_tests(mnn3_unit).

:- use_module('../prolog/goals').
:- use_module('../prolog/planner').
:- use_module('../prolog/task_graph').
:- use_module('../prolog/test_generator').
:- use_module('../prolog/verification').
:- use_module('../prolog/mnn3').

test(goal_is_structured_and_plannable) :-
    make_goal(g1, "Build an artifact", [], [source, tests], [artifact_only], Goal),
    create_plan(Goal, plan(Goal, Tasks, Dependencies, Outputs, Validation)),
    validate_task_graph(Tasks),
    Dependencies \= [],
    Outputs == [source, tests],
    Validation \= [].

test(task_cycles_are_rejected) :-
    \+ validate_task_graph([
        task(first, first, [second], pending),
        task(second, second, [first], pending)
    ]).

test(test_cases_cover_six_dimensions) :-
    requirement_test_cases(no_traversal, Cases),
    length(Cases, 6).

test(requirement_verification_reports_missing_files) :-
    verify_project_requirements([source, tests], [source],
                                verification(incomplete, [tests])).

test(security_invariants_keep_kernel_enabled) :-
    runtime_security_invariants(invariants(
        network_access(false), shell_access(false), computer_control(false),
        credential_access(false), arbitrary_process_execution(false),
        arbitrary_filesystem(false), third_party_side_effects(false),
        workspace_artifact_generation(true))).

:- end_tests(mnn3_unit).
