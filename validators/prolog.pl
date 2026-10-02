:- module(mnn3_prolog_validator, [static_scan/3]).

static_scan(Content, Status, Findings) :-
    to_string(Content, Text),
    findall(Pattern, detected_pattern(Text, Pattern), Findings0),
    sort(Findings0, Findings),
    (Findings == [] -> Status = clear ; Status = human_review_required).

detected_pattern(Text, shell_call) :- contains(Text, "shell(").
detected_pattern(Text, process_creation) :- contains(Text, "process_create(").
detected_pattern(Text, socket_access) :- contains(Text, "socket(").
detected_pattern(Text, http_client) :- contains(Text, "http_open(").
detected_pattern(Text, pipe_open) :- contains(Text, "open(pipe(").
detected_pattern(Text, foreign_loading) :-
    contains(Text, "load_foreign_library(") ;
    contains(Text, "use_foreign_library(").
detected_pattern(Text, sensitive_module_import) :-
    contains(Text, "library(process)") ;
    contains(Text, "library(socket)") ;
    contains(Text, "library(http/http_open)").

contains(Text, Substring) :- sub_string(Text, _, _, _, Substring).

to_string(Text, Text) :- string(Text), !.
to_string(Text, String) :- atom(Text), atom_string(Text, String).
