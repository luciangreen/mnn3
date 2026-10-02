:- module(mnn3_policy, [allowed_capability/1, known_agent/1, human_export_action/1]).

allowed_capability(read_workspace).
allowed_capability(write_workspace).
allowed_capability(create_artifact).
allowed_capability(read_project_memory).
allowed_capability(reason).
allowed_capability(validate_artifact).
allowed_capability(compare_artifacts).
allowed_capability(run_internal_pure_test).

known_agent(mnn3).
known_agent(requirements_agent).
known_agent(architecture_agent).
known_agent(programmer_agent).
known_agent(tester_agent).
known_agent(reviewer_agent).
known_agent(documentation_agent).

human_export_action(human_controlled_export).
