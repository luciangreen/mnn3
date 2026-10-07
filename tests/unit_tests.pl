:- begin_tests(mnn3_unit).

:- use_module('../prolog/goals').
:- use_module('../prolog/planner').
:- use_module('../prolog/task_graph').
:- use_module('../prolog/test_generator').
:- use_module('../prolog/verification').
:- use_module('../prolog/mnn3').
:- use_module('../prolog/workflow_library').
:- use_module('../prolog/workflow_aioc').
:- use_module('../prolog/reviewer', [review_artifact/3]).
:- use_module('../prolog/verification', [verify_project_requirements/3]).
:- use_module(library(lists), [memberchk/2]).

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

test(requirement_traceability_requires_implementation_and_tests) :-
    mnn3:verify_requirement_traceability(
        [no_overlap, deterministic],
        [implements('scheduler.pl', requirement(no_overlap))],
        [tests('scheduler_tests.pl', requirement(no_overlap))],
        traceability(incomplete, [deterministic], [deterministic])).

test(project_spec_dependencies_must_resolve) :-
    mnn3:validate_project_specs(
        [artifact_spec(model, source_code, "Data model", [], [data_model], [],
                       [static_review]),
         artifact_spec(service, source_code, "Service", [], [service], [model],
                       [static_review])],
        project_validation(complete, [], [])),
    mnn3:validate_project_specs(
        [artifact_spec(service, source_code, "Service", [], [service], [model],
                       [static_review])],
        project_validation(incomplete, [service-model], [])).

test(project_spec_duplicate_identifiers_are_reported) :-
    mnn3:validate_project_specs(
        [artifact_spec(module, source_code, "First", [], [], [], []),
         artifact_spec(module, tests, "Second", [], [], [], [])],
        project_validation(incomplete, [], [module])).

test(requirement_is_complete_when_implemented_and_tested) :-
    mnn3:verify_requirement_traceability(
        [implemented], [implements(source, requirement(implemented))],
        [tests(test_file, requirement(implemented))],
        traceability(complete, [], [])).

test(security_invariants_keep_kernel_enabled) :-
    runtime_security_invariants(invariants(
        network_access(false), shell_access(false), computer_control(false),
        credential_access(false), arbitrary_process_execution(false),
        arbitrary_filesystem(false), third_party_side_effects(false),
        workspace_artifact_generation(true))).

test(all_ablations_keep_security_kernel) :-
    forall(workflow_variant(_, Features), memberchk(security_kernel, Features)).

test(unknown_workflow_is_rejected_by_optimiser) :-
    compare_workflows(not_an_ablation, 'MNN3-0', rejected(not_an_ablation)).

test(networking_artifact_requires_human_review) :-
    review_artifact(javascript, "fetch('https://example.invalid')",
                    review(human_review_required, [browser_network])).

:- end_tests(mnn3_unit).
