:- begin_tests(mnn3_integration).

:- use_module('../prolog/mnn3').
:- use_module('../prolog/projects').
:- use_module('../prolog/artifact_generator').

test(project_plan_records_trace_and_safe_generation,
     [setup(create_integration_workspace(Root)),
      cleanup(remove_integration_workspace(Root))]) :-
    configure_workspace(Root),
    plan_project(integration_project, "Create a sample artifact", [report],
                 plan(_, Tasks, _, _, _), Trace),
    Tasks \= [],
    sub_string(Trace, _, _, _, "artifact-only"),
    create_project_artifact(integration_project, 'reports/result.md', markdown,
                            'Test report', [report_requirement], "# Result"),
    read_artifact('reports/result.md', "# Result"),
    generated_artifacts([artifact(integration_project, 'reports/result.md',
                                  markdown, 'Test report', [report_requirement],
                                  review(static_checks_limited, []))]),
    create_completion_report(integration_project, Completion),
    sub_string(Completion, _, _, _, "No generated test program was executed"),
    sub_string(Completion, _, _, _, "MNN2 interpretation"),
    create_manifest(integration_project, Manifest),
    sub_string(Manifest, _, _, _, "manifest(version(1)"),
    read_artifact('manifest.pl', SavedManifest),
    SavedManifest == Manifest.

create_integration_workspace(Root) :-
    tmp_file(mnn3_integration_workspace, Root),
    make_directory(Root),
    !.

remove_integration_workspace(Root) :-
    catch(delete_directory_and_contents(Root), _, true).

:- end_tests(mnn3_integration).
