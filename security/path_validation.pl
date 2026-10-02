:- module(mnn3_path_validation, [safe_workspace_path/3]).

:- use_module(library(apply), [maplist/2, maplist/3]).
:- use_module(library(filesex), [directory_file_path/3]).
:- use_module(library(lists), [append/3, memberchk/2]).

safe_workspace_path(Root, RelativePath, Operation) :-
    canonical_root(Root, CanonicalRoot),
    relative_segments(RelativePath, Segments),
    \+ protected_segments(Segments),
    (   Operation = read(AbsolutePath)
    ->  resolve_existing(CanonicalRoot, Segments, AbsolutePath)
    ;   Operation = write(AbsolutePath)
    ->  resolve_write_target(CanonicalRoot, Segments, AbsolutePath)
    ;   fail
    ).

canonical_root(Root, CanonicalRoot) :-
    catch(absolute_file_name(Root, CanonicalRoot,
                             [file_type(directory), access(read),
                              solutions(first), file_errors(fail)]),
          _, fail),
    CanonicalRoot \== '/',
    \+ has_symlink_component(CanonicalRoot).

relative_segments(Path, Segments) :-
    (   atom(Path)
    ->  atom_string(Path, String)
    ;   string(Path)
    ->  String = Path
    ),
    string_length(String, Length),
    Length > 0,
    \+ sub_string(String, 0, 1, _, "/"),
    \+ sub_string(String, _, _, _, "\\"),
    \+ sub_string(String, _, _, _, "%"),
    \+ sub_string(String, _, _, _, ":"),
    split_string(String, "/", "", Parts),
    Parts \= [],
    maplist(valid_segment, Parts),
    maplist(atom_string, Segments, Parts).

valid_segment(Segment) :-
    Segment \= "",
    Segment \= ".",
    Segment \= "..",
    \+ sub_string(Segment, _, _, _, "~"),
    string_codes(Segment, Codes),
    \+ memberchk(0, Codes).

resolve_existing(Root, Segments, AbsolutePath) :-
    reject_symlink_components(Root, Segments),
    join_under_root(Root, Segments, Candidate),
    exists_file(Candidate),
    AbsolutePath = Candidate.

resolve_write_target(Root, Segments, AbsolutePath) :-
    append(Parents, [Filename], Segments),
    ensure_parent_directories(Root, Parents, Parent),
    directory_file_path(Parent, Filename, Candidate),
    (   exists_file(Candidate)
    ->  \+ symbolic_link(Candidate),
        Canonical = Candidate
    ;   \+ symbolic_link(Candidate),
        Canonical = Candidate
    ),
    AbsolutePath = Canonical.

ensure_parent_directories(Root, [], Root).
ensure_parent_directories(Root, [Segment|Rest], Parent) :-
    directory_file_path(Root, Segment, Candidate),
    (   exists_directory(Candidate)
    ->  \+ symbolic_link(Candidate),
        catch(absolute_file_name(Candidate, Canonical,
                                 [file_type(directory), access(read),
                                  solutions(first), file_errors(fail)]),
              _, fail),
        path_within(Root, Canonical)
    ;   \+ exists_file(Candidate),
        \+ symbolic_link(Candidate),
        catch(make_directory(Candidate), _, fail),
        catch(absolute_file_name(Candidate, Canonical,
                                 [file_type(directory), access(read),
                                  solutions(first), file_errors(fail)]),
              _, fail),
        path_within(Root, Canonical)
    ),
    ensure_parent_directories(Canonical, Rest, Parent).

reject_symlink_components(Root, Segments) :-
    reject_symlink_components(Root, Segments, _).

reject_symlink_components(Current, [], Current).
reject_symlink_components(Current, [Segment|Rest], Final) :-
    directory_file_path(Current, Segment, Candidate),
    \+ symbolic_link(Candidate),
    reject_symlink_components(Candidate, Rest, Final).

join_under_root(Root, Segments, Candidate) :-
    atomic_list_concat(Segments, '/', Relative),
    directory_file_path(Root, Relative, Candidate).

path_within(Root, Candidate) :-
    atom_concat(Root, '/', Prefix),
    (Candidate == Root ; sub_atom(Candidate, 0, _, _, Prefix)).

symbolic_link(Path) :-
    catch(read_link(Path, _, _), _, fail).

has_symlink_component(Path) :-
    atom_string(Path, PathString),
    split_string(PathString, "/", "", Segments),
    symlink_in_components('/', Segments).

symlink_in_components(_, []) :- fail.
symlink_in_components(Current, [Segment|Rest]) :-
    directory_file_path(Current, Segment, Candidate),
    (symbolic_link(Candidate) ; symlink_in_components(Candidate, Rest)).

protected_segments(Segments) :-
    memberchk(security, Segments) ;
    memberchk('.git', Segments).
