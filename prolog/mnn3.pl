:- module(mnn3,
          [ plan_project/5,
            create_project_artifact/6,
            create_completion_report/2,
            create_manifest/2,
            configure_workspace/1,
            read_artifact/2,
            request_capability/4,
            run_internal_pure_test/2,
            runtime_security_invariants/1,
            verify_requirement_traceability/4,
            validate_project_specs/2,
            mnn1_status/1,
            mnn2_status/1
          ]).

:- use_module(goals, [make_goal/6]).
:- use_module(planner, [create_plan/2]).
:- use_module(projects,
              [start_project/3, project_artifacts/2, add_project_event/2]).
:- use_module(artifact_generator, [generate_artifact/6]).
:- use_module(completion, [completion_report/2]).
:- use_module('../security/workspace',
              [configure_workspace/1, read_artifact/2]).
:- use_module('../security/capability',
              [request_capability/4]).
:- use_module('../security/pure_tests',
              [run_internal_pure_test/2]).
:- use_module('../security/policy', [allowed_capability/1]).
:- use_module('../adapters/mnn1_adapter', [mnn1_status/1]).
:- use_module('../adapters/mnn2_adapter', [mnn2_status/1]).
:- use_module(task_graph, [topological_order/2]).
:- use_module(verification, []).
:- use_module('../validators/project', []).
:- use_module(reviewer, [review_artifact/3]).
:- use_module(library(lists), [member/2]).

plan_project(ProjectId, Description, Outputs, Plan, Trace) :-
    make_goal(ProjectId, Description, [], Outputs, [artifact_only], Goal),
    create_plan(Goal, Plan),
    Plan = plan(_, Tasks, _, _, _),
    start_project(ProjectId, Goal, Tasks),
    add_project_event(ProjectId,
                      'Requirements are accepted as structured input; natural-language interpretation is not configured.'),
    add_project_event(ProjectId,
                      'MNN1/MNN2 adapters are unavailable; no external service was contacted.'),
    topological_order(Tasks, OrderedTasks),
    format(string(Trace),
           'Created a deterministic artifact-only plan with tasks: ~w. The security kernel remains active.',
           [OrderedTasks]).

verify_requirement_traceability(Requirements, Implementations, Tests, Result) :-
    mnn3_verification:verify_requirement_traceability(
        Requirements, Implementations, Tests, Result).

validate_project_specs(Specs, Result) :-
    mnn3_project_validator:validate_project_specs(Specs, Result).

create_project_artifact(ProjectId, Path, Type, Purpose, Requirements, Content) :-
    generate_artifact(ProjectId, Path, Type, Purpose, Requirements, Content).

create_completion_report(ProjectId, Report) :-
    completion_report(ProjectId, Report),
    create_project_artifact(ProjectId, 'COMPLETION.md', markdown,
                            'Human-readable project completion summary',
                            [project_completion, human_review_boundary], Report).

create_manifest(ProjectId, Manifest) :-
    project_artifacts(ProjectId, Artifacts),
    findall(record(Path, Type, Purpose, Requirements, Review, Status, []),
            member(artifact(Path, Type, Purpose, Requirements, Review, Status),
                   Artifacts),
            Records),
    with_output_to(string(Manifest),
                   write_term(current_output, manifest(version(2), Records),
                              [quoted(true), numbervars(true), fullstop(true), nl(true)])),
    create_project_artifact(ProjectId, 'manifest.pl', prolog_facts,
                            'Machine-readable artifact manifest',
                            [artifact_manifest], Manifest).

runtime_security_invariants(invariants(
    network_access(false),
    shell_access(false),
    computer_control(false),
    credential_access(false),
    arbitrary_process_execution(false),
    arbitrary_filesystem(false),
    third_party_side_effects(false),
    workspace_artifact_generation(true)
)).
