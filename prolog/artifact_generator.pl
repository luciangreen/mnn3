:- module(mnn3_artifact_generator,
          [ generate_artifact/6,
            generated_artifacts/1
          ]).

:- use_module('../security/workspace',
              [create_artifact/3, validate_artifact_content/2]).
:- use_module('../security/capability', [request_capability/4]).
:- use_module(reviewer, [review_artifact/3]).
:- use_module(provenance, [record_provenance/5]).
:- use_module(projects, [register_project_artifact/2]).

:- dynamic generated_artifact_record/6.

generate_artifact(ProjectId, RelativePath, Type, Purpose, Requirements, Content) :-
    request_capability(mnn3, validate_artifact, artifact(RelativePath), allow),
    validate_artifact_content(Type, Content),
    review_artifact(Type, Content, Review),
    create_artifact(RelativePath, Type, Content),
    record_provenance(RelativePath, Requirements, [], [], 1),
    validation_status(Review, ValidationStatus),
    Artifact = artifact(RelativePath, Type, Purpose, Requirements, Review,
                        ValidationStatus),
    with_mutex(mnn3_artifacts,
               ( retractall(generated_artifact_record(ProjectId, RelativePath,
                                                      _, _, _, _)),
                 assertz(generated_artifact_record(ProjectId, RelativePath,
                                                   Type, Purpose, Requirements,
                                                   Review))
               )),
    register_project_artifact(ProjectId, Artifact).

generated_artifacts(Artifacts) :-
    findall(artifact(ProjectId, Path, Type, Purpose, Requirements, Review),
            generated_artifact_record(ProjectId, Path, Type, Purpose, Requirements,
                                      Review),
            Artifacts).

validation_status(review(human_review_required, _), human_review_required) :- !.
validation_status(review(statically_checked, _), statically_checked) :- !.
validation_status(_, generated).
