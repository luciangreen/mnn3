:- module(mnn3_workspace,
          [ configure_workspace/1,
            workspace_root/1,
            read_artifact/2,
            create_artifact/3,
            validate_artifact_content/2
          ]).

:- use_module(path_validation, [safe_workspace_path/3]).
:- use_module(library(filesex), [directory_file_path/3]).
:- use_module(library(lists), [memberchk/2, sum_list/2]).
:- use_module(resource_limits).
:- use_module(capability, [request_capability/4]).
:- use_module(policy, [known_agent/1]).

:- dynamic configured_root/1.
:- dynamic artifact_record/3.

configure_workspace(Directory) :-
    (   exists_directory(Directory),
        catch(absolute_file_name(Directory, Root,
                                 [file_type(directory), access(read),
                                  solutions(first), file_errors(fail)]),
              _, fail),
        Root \== '/',
        \+ workspace_symbolic_link(Root),
        root_has_no_symlink_components(Root)
    ->  with_mutex(mnn3_workspace, (retractall(configured_root(_)),
                                    assertz(configured_root(Root)),
                                    retractall(artifact_record(_, _, _))))
    ;   fail
    ).

workspace_root(Root) :-
    (   configured_root(Root)
    ->  true
    ;   absolute_file_name('workspace', Root,
                           [file_type(directory), access(read),
                            solutions(first), file_errors(fail)])
    ).

read_artifact(RelativePath, Content) :-
    request_capability(mnn3, read_workspace, workspace(RelativePath), allow),
    workspace_root(Root),
    safe_workspace_path(Root, RelativePath, read(AbsolutePath)),
    max_project_characters(Maximum),
    ReadLimit is Maximum + 1,
    catch(setup_call_cleanup(
              open(AbsolutePath, read, Stream, [encoding(utf8), type(text)]),
              read_string(Stream, ReadLimit, Content),
              close(Stream)),
          _, fail),
    string_length(Content, Characters),
    Characters =< Maximum.

create_artifact(RelativePath, ArtifactType, Content) :-
    request_capability(mnn3, create_artifact, workspace(RelativePath), allow),
    validate_artifact_content(ArtifactType, Content),
    normalize_text(Content, Text),
    string_length(Text, Characters),
    workspace_root(Root),
    safe_workspace_path(Root, RelativePath, write(AbsolutePath)),
    with_mutex(mnn3_workspace,
               write_artifact(AbsolutePath, RelativePath, ArtifactType,
                              Text, Characters)).

validate_artifact_content(ArtifactType, Content) :-
    atom(ArtifactType),
    supported_artifact_type(ArtifactType),
    normalize_text(Content, Text),
    string_length(Text, Characters),
    max_artifact_characters(MaxCharacters),
    Characters =< MaxCharacters.

write_artifact(AbsolutePath, RelativePath, ArtifactType, Content, Characters) :-
    max_artifacts(MaxArtifacts),
    max_project_characters(MaxProjectCharacters),
    findall(Path, artifact_record(Path, _, _), RecordedPaths0),
    sort([RelativePath|RecordedPaths0], RecordedPaths),
    length(RecordedPaths, ArtifactCount),
    ArtifactCount =< MaxArtifacts,
    findall(Size,
            (artifact_record(Path, _, Size), Path \== RelativePath),
            Sizes),
    sum_list(Sizes, PreviousCharacters),
    PreviousCharacters + Characters =< MaxProjectCharacters,
    catch(setup_call_cleanup(
              open(AbsolutePath, write, Stream,
                   [encoding(utf8), type(text), lock(write),
                    if_exists(overwrite)]),
              format(Stream, '~s', [Content]),
              close(Stream)),
          _, fail),
    retractall(artifact_record(RelativePath, _, _)),
    assertz(artifact_record(RelativePath, ArtifactType, Characters)).

normalize_text(Content, Content) :- string(Content), !.
normalize_text(Content, Text) :- atom(Content), atom_string(Content, Text).

supported_artifact_type(Type) :-
    memberchk(Type, [source_code, tests, html, css, javascript, markdown,
                     plain_text, json, csv, xml, yaml, prolog_facts,
                     configuration, schema, report, specification,
                     documentation, repository_structure]).

root_has_no_symlink_components(Root) :-
    atom_string(Root, RootString),
    split_string(RootString, "/", "", Segments),
    root_components_are_real('/', Segments).

root_components_are_real(_, []).
root_components_are_real(Current, [Segment|Rest]) :-
    directory_file_path(Current, Segment, Candidate),
    \+ workspace_symbolic_link(Candidate),
    root_components_are_real(Candidate, Rest).

workspace_symbolic_link(Path) :-
    catch(read_link(Path, _, _), _, fail).
