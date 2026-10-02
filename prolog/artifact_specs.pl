:- module(mnn3_artifact_specs,
          [ artifact_spec/7,
            validate_artifact_spec/1
          ]).

artifact_spec(Id, Type, Purpose, Inputs, Requirements, Dependencies, Validation) :-
    atom(Id),
    memberchk(Type, [source_code, tests, html, css, javascript, markdown,
                     plain_text, json, csv, xml, yaml, prolog_facts,
                     configuration, schema, report, specification,
                     documentation, repository_structure]),
    text_value(Purpose),
    is_list(Inputs),
    is_list(Requirements),
    is_list(Dependencies),
    is_list(Validation).

validate_artifact_spec(Spec) :-
    Spec = artifact_spec(Id, Type, Purpose, Inputs, Requirements, Dependencies,
                         Validation),
    artifact_spec(Id, Type, Purpose, Inputs, Requirements, Dependencies,
                  Validation).

text_value(Text) :- string(Text), !.
text_value(Text) :- atom(Text), Text \== ''.
