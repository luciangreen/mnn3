:- begin_tests(mnn3_security).

:- use_module('../security/capability').
:- use_module('../security/path_validation').
:- use_module('../security/pure_tests').
:- use_module('../security/workspace').
:- use_module('../prolog/reviewer', [review_artifact/3]).
:- use_module(library(filesex), [directory_file_path/3, link_file/3]).
:- use_module(library(apply), [maplist/2]).
:- use_module(library(lists), [member/2]).
:- use_module(library(readutil), [read_file_to_string/3]).

test(allowed_capabilities_require_valid_resources) :-
    request_capability(mnn3, create_artifact, workspace('src/main.pl'), allow),
    request_capability(mnn3, read_project_memory, project(project1), allow),
    request_capability(mnn3, create_artifact, external_filesystem, deny).

test(unknown_agent_and_capability_fail_closed) :-
    request_capability(untrusted_agent, reason, project(project1), deny),
    request_capability(mnn3, arbitrary_capability, project(project1), deny),
    request_capability(mnn3, network, url('https://example.invalid'), deny),
    request_capability(mnn3, shell, command('echo no'), deny),
    request_capability(mnn3, human_controlled_export, project(project1),
                       requires_human_export).

test(all_external_action_capabilities_are_denied) :-
    forall(member(Capability,
                  [network, socket, shell, process_creation, browser_control,
                   keyboard_control, mouse_control, credentials, email,
                   remote_api, deployment, upload, arbitrary_filesystem]),
           request_capability(mnn3, Capability, unknown_resource, deny)).

test(delegation_only_reduces_capabilities) :-
    delegate_capabilities([reason, read_workspace],
                          [read_workspace], [read_workspace]),
    delegate_capabilities([reason], [network], []).

test(traversal_and_encoded_paths_are_rejected) :-
    \+ safe_workspace_path('/tmp/workspace', '../outside.txt', write(_)),
    \+ safe_workspace_path('/tmp/workspace', '/etc/passwd', read(_)),
    \+ safe_workspace_path('/tmp/workspace', '%2e%2e/outside', write(_)),
    \+ safe_workspace_path('/tmp/workspace', 'C:/outside', write(_)),
    \+ safe_workspace_path('/tmp/workspace', 'a\\..\\outside', write(_)),
    \+ safe_workspace_path('/tmp/workspace', 'a//outside', write(_)),
    \+ safe_workspace_path('/tmp/workspace', 'security/policy.pl', write(_)),
    \+ safe_workspace_path('/tmp/workspace', '.git/config', write(_)).

test(workspace_root_must_not_be_filesystem_root) :-
    \+ configure_workspace('/').

test(workspace_root_symlink_is_rejected,
     [setup(create_test_workspace(Root)), cleanup(remove_test_workspace(Root))]) :-
    tmp_file(mnn3_workspace_alias, Alias),
    link_file(Root, Alias, symbolic),
    \+ configure_workspace(Alias),
    catch(delete_file(Alias), _, true).

test(symlink_escape_is_rejected,
     [setup(create_test_workspace(Root)), cleanup(remove_test_workspace(Root))]) :-
    tmp_file(mnn3_external_workspace, Outside),
    make_directory(Outside),
    directory_file_path(Root, escape, Link),
    link_file(Outside, Link, symbolic),
    \+ safe_workspace_path(Root, 'escape/outside.txt', write(_)).

test(pure_interpreter_accepts_bounded_closed_expressions) :-
    run_internal_pure_test(
        all([assert_equal(5, add(integer(2), integer(3))),
             assert_true(less_than(integer(1), integer(2)))]),
        passed).

test(pure_interpreter_rejects_arbitrary_goals) :-
    run_internal_pure_test(call(system('echo unsafe')), unsupported_or_limit_exceeded).

test(pure_interpreter_limits_arithmetic) :-
    run_internal_pure_test(assert_equal(1, integer(1000000001)),
                           unsupported_or_limit_exceeded).

test(generated_code_is_flagged_not_executed) :-
    review_artifact(source_code, "shell('echo should-not-run')",
                    review(human_review_required, [shell_call])).

test(runtime_does_not_import_control_or_network_libraries) :-
    source_file_property(CapabilityFile, module(mnn3_capability)),
    source_file_property(WorkspaceFile, module(mnn3_workspace)),
    source_file_property(RuntimeFile, module(mnn3)),
    forall(member(File, [CapabilityFile, WorkspaceFile, RuntimeFile]),
           (read_file_to_string(File, Source, []),
            forall(member(Import,
                          ["library(process)", "library(socket)",
                           "library(http/http_open)", "library(pce)"]),
                   \+ sub_string(Source, _, _, _, Import)))).

test(static_scan_is_case_insensitive) :-
    review_artifact(source_code, "SHELL('blocked')",
                    review(human_review_required, [shell_call])).

test(workspace_write_and_read_are_confined,
     [setup(create_test_workspace(Root)), cleanup(remove_test_workspace(Root))]) :-
    configure_workspace(Root),
    create_artifact('src/notes.md', markdown, "safe artifact"),
    read_artifact('src/notes.md', "safe artifact"),
    \+ create_artifact('../outside.txt', plain_text, "blocked"),
    \+ read_artifact('../outside.txt', _).

test(workspace_rejects_unknown_types,
     [setup(create_test_workspace(Root)), cleanup(remove_test_workspace(Root))]) :-
    configure_workspace(Root),
    \+ create_artifact('bad.bin', executable, "not allowed").

test(workspace_rejects_generated_artifact_over_limit,
     [setup(create_test_workspace(Root)), cleanup(remove_test_workspace(Root))]) :-
    configure_workspace(Root),
    length(Codes, 131073),
    maplist(=(x), Codes),
    string_codes(Content, Codes),
    \+ create_artifact('too-large.txt', plain_text, Content).

create_test_workspace(Root) :-
    tmp_file(mnn3_test_workspace, Root),
    make_directory(Root),
    !.

remove_test_workspace(Root) :-
    catch(delete_directory_and_contents(Root), _, true).

:- end_tests(mnn3_security).
