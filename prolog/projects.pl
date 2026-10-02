:- module(mnn3_projects,
          [ start_project/3,
            project/1,
            add_project_event/2,
            project_trace/2,
            register_project_artifact/2,
            project_artifacts/2
          ]).

:- dynamic project_state/7.
:- dynamic project_event/3.

:- use_module(library(lists), [append/3, member/2]).

start_project(Id, Goal, Tasks) :-
    atom(Id),
    is_list(Tasks),
    with_mutex(mnn3_projects,
               ( retractall(project_state(Id, _, _, _, _, _, _)),
                 retractall(project_event(Id, _, _)),
                 assertz(project_state(Id, Goal, Tasks, [], [], [], active))
               )),
    add_project_event(Id, 'The project goal and initial plan were recorded.').

project(project(Id, Goal, Tasks, Artifacts, Decisions, OpenQuestions, Status)) :-
    project_state(Id, Goal, Tasks, Artifacts, Decisions, OpenQuestions, Status).

add_project_event(Id, Description) :-
    text_value(Description),
    get_time(Timestamp),
    with_mutex(mnn3_projects,
               assertz(project_event(Id, Timestamp, Description))).

project_trace(Id, Trace) :-
    findall(Timestamp-Description, project_event(Id, Timestamp, Description), Events0),
    keysort(Events0, Events),
    findall(Line,
            ( member(_-Description, Events),
              format(string(Line), '~w', [Description])
            ),
            Lines),
    atomics_to_string(Lines, "\n", Trace).

register_project_artifact(Id, Artifact) :-
    with_mutex(mnn3_projects,
               ( retract(project_state(Id, Goal, Tasks, Artifacts, Decisions,
                                       Questions, Status)),
                 append(Artifacts, [Artifact], UpdatedArtifacts),
                 assertz(project_state(Id, Goal, Tasks, UpdatedArtifacts,
                                       Decisions, Questions, Status))
               )),
    add_project_event(Id, 'An artifact was generated and added to the project trace.').

project_artifacts(Id, Artifacts) :-
    project_state(Id, _, _, Artifacts, _, _, _).

text_value(Text) :- string(Text), !.
text_value(Text) :- atom(Text), Text \== ''.
