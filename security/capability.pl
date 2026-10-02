:- module(mnn3_capability,
          [ allowed_capability/1,
            request_capability/4,
            delegate_capabilities/3
          ]).

:- use_module(policy, [allowed_capability/1, known_agent/1, human_export_action/1]).

request_capability(Agent, Capability, Resource, Decision) :-
    (   known_agent(Agent),
        atom(Capability),
        allowed_capability(Capability),
        resource_allowed(Capability, Resource)
    ->  Decision = allow
    ;   known_agent(Agent),
        human_export_action(Capability),
        valid_resource(Resource)
    ->  Decision = requires_human_export
    ;   Decision = deny
    ).

resource_allowed(read_workspace, workspace(_)).
resource_allowed(write_workspace, workspace(_)).
resource_allowed(create_artifact, workspace(_)).
resource_allowed(read_project_memory, project(_)).
resource_allowed(reason, project(_)).
resource_allowed(validate_artifact, artifact(_)).
resource_allowed(compare_artifacts, artifacts(_)).
resource_allowed(run_internal_pure_test, pure_test(_)).

valid_resource(workspace(Path)) :- safe_path_term(Path).
valid_resource(project(Id)) :- safe_identifier(Id).
valid_resource(artifact(Id)) :- safe_identifier(Id).
valid_resource(artifacts(Ids)) :- is_list(Ids), maplist(safe_identifier, Ids).
valid_resource(pure_test(Id)) :- safe_identifier(Id).

safe_path_term(Path) :- atom(Path), Path \== ''.
safe_identifier(Id) :- atom(Id), Id \== ''.

delegate_capabilities(ParentCapabilities, Requested, Delegated) :-
    (   is_list(ParentCapabilities),
        is_list(Requested),
        maplist(allowed_capability, ParentCapabilities),
        maplist(allowed_capability, Requested),
        subset(Requested, ParentCapabilities)
    ->  sort(Requested, Delegated)
    ;   Delegated = []
    ).
