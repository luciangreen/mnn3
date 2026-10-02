:- module(mnn3_path_validation, [safe_workspace_path/3]).

safe_workspace_path(Root, RelativePath, Operation) :-
    canonical_root(Root, CanonicalRoot),
    relative_segments(RelativePath, Segments),
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
          _, fail).

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
    \+ string_codes(Segment, Codes), memberchk(0, Codes).

resolve_existing(Root, Segments, AbsolutePath) :-
    join_under_root(Root, Segments, Candidate),
    catch(absolute_file_name(Candidate, Canonical,
                             [access(read), solutions(first), file_errors(fail)]),
          _, fail),
    path_within(Root, Canonical),
    exists_file(Canonical),
    AbsolutePath = Canonical.

resolve_write_target(Root, Segments, AbsolutePath) :-
    append(Parents, [Filename], Segments),
    ensure_parent_directories(Root, Parents, Parent),
    directory_file_path(Parent, Filename, Candidate),
    (   exists_file(Candidate)
    ->  catch(absolute_file_name(Candidate, Canonical,
                                 [access(none), solutions(first),
                                  file_errors(fail)]),
              _, fail),
        path_within(Root, Canonical)
    ;   Canonical = Candidate
    ),
    AbsolutePath = Canonical.

ensure_parent_directories(Root, [], Root).
ensure_parent_directories(Root, [Segment|Rest], Parent) :-
    directory_file_path(Root, Segment, Candidate),
    (   exists_directory(Candidate)
    ->  catch(absolute_file_name(Candidate, Canonical,
                                 [file_type(directory), access(read),
                                  solutions(first), file_errors(fail)]),
              _, fail),
        path_within(Root, Canonical)
    ;   \+ exists_file(Candidate),
        catch(make_directory(Candidate), _, fail),
        catch(absolute_file_name(Candidate, Canonical,
                                 [file_type(directory), access(read),
                                  solutions(first), file_errors(fail)]),
              _, fail),
        path_within(Root, Canonical)
    ),
    ensure_parent_directories(Canonical, Rest, Parent).

join_under_root(Root, Segments, Candidate) :-
    atomic_list_concat(Segments, '/', Relative),
    directory_file_path(Root, Relative, Candidate).

path_within(Root, Candidate) :-
    atom_concat(Root, '/', Prefix),
    (Candidate == Root ; sub_atom(Candidate, 0, _, _, Prefix)).
