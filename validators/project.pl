:- module(mnn3_project_validator,
          [ validate_project_specs/2
          ]).

:- use_module('../prolog/artifact_specs', [validate_artifact_spec/1]).
:- use_module(library(lists), [member/2, memberchk/2, sort/2]).
:- use_module(library(apply), [include/3, maplist/2]).

validate_project_specs(Specs,
                       project_validation(Status, MissingDependencies,
                                         DuplicateIds)) :-
    is_list(Specs),
    maplist(validate_artifact_spec, Specs),
    findall(Id, member(artifact_spec(Id, _, _, _, _, _, _), Specs), Ids),
    sort(Ids, UniqueIds),
    findall(Id,
            (member(Id, Ids),
             count_id(Id, Ids, Count),
             Count > 1),
            DuplicateIds0),
    sort(DuplicateIds0, DuplicateIds),
    findall(Id-Dependency,
            (member(artifact_spec(Id, _, _, _, _, Dependencies, _), Specs),
             member(Dependency, Dependencies),
             \+ memberchk(Dependency, UniqueIds)),
            MissingDependencies),
    (MissingDependencies == [], DuplicateIds == [] ->
        Status = complete
    ;   Status = incomplete
    ).

count_id(Id, Ids, Count) :-
    include(==(Id), Ids, Matches),
    length(Matches, Count).
