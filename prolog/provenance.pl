:- module(mnn3_provenance,
          [ record_provenance/5,
            artifact_provenance/1
          ]).

:- dynamic provenance/5.

record_provenance(File, Requirements, Algorithms, SourceArtifacts, Revision) :-
    atom(File),
    is_list(Requirements),
    is_list(Algorithms),
    is_list(SourceArtifacts),
    with_mutex(mnn3_provenance,
               ( retractall(provenance(File, _, _, _, _)),
                 assertz(provenance(File, Requirements, Algorithms,
                                    SourceArtifacts, Revision))
               )).

artifact_provenance(Records) :-
    findall(artifact_provenance(File, Requirements, Algorithms, Sources, Revision),
            provenance(File, Requirements, Algorithms, Sources, Revision),
            Records).
