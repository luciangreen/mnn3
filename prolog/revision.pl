:- module(mnn3_revision, [record_revision/3, revisions/1]).

:- dynamic revision/3.

record_revision(Artifact, Version, Explanation) :-
    atom(Artifact),
    atom(Version),
    with_mutex(mnn3_revision,
               assertz(revision(Artifact, Version, Explanation))).

revisions(Revisions) :-
    findall(revision(Artifact, Version, Explanation),
            revision(Artifact, Version, Explanation),
            Revisions).
