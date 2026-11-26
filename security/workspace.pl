:- module(mnn3_workspace,
          [ configure_workspace/1,
            workspace_root/1,
            read_artifact/2,
            create_artifact/3,
            create_artifact/4,
            validate_artifact_content/2
          ]).

:- use_module(path_validation, [safe_workspace_path/3, valid_relative_path/1]).
:- use_module(library(filesex), [directory_file_path/3]).
:- use_module(library(lists), [memberchk/2, sum_list/2]).
:- use_module(resource_limits).
:- use_module(capability, [request_capability/4]).
:- use_module(policy, [known_agent/1]).

:- dynamic configured_root/1.
:- dynamic artifact_record/3.
:- dynamic scanned_root/1.

configure_workspace(Directory) :-
    (   exists_directory(Directory),
        catch(absolute_file_name(Directory, Requested,
                                 [file_type(directory), access(read),
                                  solutions(first), file_errors(fail)]),
              _, fail),
        \+ workspace_symbolic_link(Requested),
        real_directory(Requested, Root),
        Root \== '/',
        \+ workspace_symbolic_link(Root)
    ->  with_mutex(mnn3_workspace, (retractall(configured_root(_)),
                                    assertz(configured_root(Root)),
                                    retractall(artifact_record(_, _, _)),
                                    retractall(scanned_root(_))))
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
    create_artifact(RelativePath, ArtifactType, Content, created).

%% create_artifact(+RelativePath, +ArtifactType, +Content, -Result)
%
% Result is created, or refused(Reason) with Reason one of capability_denied,
% unsupported_type, artifact_too_large, too_many_artifacts,
% project_too_large, unsafe_path or write_failed. Every limit is checked
% before any folder is made, so a refused write leaves the workspace as it
% was. Limits count the files already in the workspace, not only those
% written in this session.
create_artifact(RelativePath, ArtifactType, Content, Result) :-
    (   \+ request_capability(mnn3, create_artifact, workspace(RelativePath), allow)
    ->  Result = refused(capability_denied)
    ;   \+ valid_relative_path(RelativePath)
    ->  Result = refused(unsafe_path)
    ;   \+ (atom(ArtifactType), supported_artifact_type(ArtifactType))
    ->  Result = refused(unsupported_type)
    ;   \+ validate_artifact_content(ArtifactType, Content)
    ->  Result = refused(artifact_too_large)
    ;   normalize_text(Content, Text),
        string_length(Text, Characters),
        workspace_root(Root),
        with_mutex(mnn3_workspace,
                   guarded_write(Root, RelativePath, ArtifactType, Text,
                                 Characters, Result))
    ).

guarded_write(Root, RelativePath, ArtifactType, Text, Characters, Result) :-
    ensure_scanned(Root),
    (   \+ artifact_count_ok(RelativePath)
    ->  Result = refused(too_many_artifacts)
    ;   \+ project_size_ok(RelativePath, Characters)
    ->  Result = refused(project_too_large)
    ;   safe_workspace_path(Root, RelativePath, write(AbsolutePath))
    ->  (   write_artifact(AbsolutePath, RelativePath, ArtifactType, Text, Characters)
        ->  Result = created
        ;   Result = refused(write_failed)
        )
    ;   Result = refused(unsafe_path)
    ).

artifact_count_ok(RelativePath) :-
    max_artifacts(MaxArtifacts),
    findall(Path, artifact_record(Path, _, _), RecordedPaths0),
    sort([RelativePath|RecordedPaths0], RecordedPaths),
    length(RecordedPaths, ArtifactCount),
    ArtifactCount =< MaxArtifacts.

project_size_ok(RelativePath, Characters) :-
    max_project_characters(MaxProjectCharacters),
    findall(Size,
            (artifact_record(Path, _, Size), Path \== RelativePath),
            Sizes),
    sum_list(Sizes, PreviousCharacters),
    PreviousCharacters + Characters =< MaxProjectCharacters.

% Record the files already in the workspace once, so limits hold across
% restarts.
ensure_scanned(Root) :-
    scanned_root(Root), !.
ensure_scanned(Root) :-
    retractall(scanned_root(_)),
    scan_directory(Root, ''),
    assertz(scanned_root(Root)).

scan_directory(Directory, Prefix) :-
    catch(directory_files(Directory, Entries), _, Entries = []),
    forall(( member(Entry, Entries),
             Entry \== '.', Entry \== '..' ),
           scan_entry(Directory, Prefix, Entry)).

scan_entry(Directory, Prefix, Entry) :-
    directory_file_path(Directory, Entry, Path),
    ( Prefix == '' -> Relative = Entry ; atomic_list_concat([Prefix, '/', Entry], Relative) ),
    (   exists_directory(Path)
    ->  scan_directory(Path, Relative)
    ;   exists_file(Path),
        \+ artifact_record(Relative, _, _)
    ->  file_characters(Path, Characters),
        assertz(artifact_record(Relative, existing, Characters))
    ;   true
    ).

file_characters(Path, Characters) :-
    catch(setup_call_cleanup(open(Path, read, Stream, [encoding(utf8), type(text)]),
                             read_string(Stream, _, Content),
                             close(Stream)),
          _, Content = ""),
    string_length(Content, Characters).

validate_artifact_content(ArtifactType, Content) :-
    atom(ArtifactType),
    supported_artifact_type(ArtifactType),
    normalize_text(Content, Text),
    string_length(Text, Characters),
    max_artifact_characters(MaxCharacters),
    Characters =< MaxCharacters.

write_artifact(AbsolutePath, RelativePath, ArtifactType, Content, Characters) :-
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

real_directory(Path, Real) :-
    atom_string(Path, PathString),
    split_string(PathString, "/", "", Segments),
    real_components('/', Segments, Real).

real_components(Current, [], Current).
real_components(Current, [Segment|Rest], Final) :-
    (   Segment == ""
    ->  Next = Current
    ;   directory_file_path(Current, Segment, Candidate),
        (   catch(read_link(Candidate, _, Target), _, fail)
        ->  Next = Target
        ;   Next = Candidate
        )
    ),
    real_components(Next, Rest, Final).

workspace_symbolic_link(Path) :-
    catch(read_link(Path, _, _), _, fail).
