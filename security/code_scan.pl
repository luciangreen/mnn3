:- module(mnn3_code_scan, [scan_generated_code/3]).

:- use_module('../validators/prolog', [static_scan/3]).
:- use_module(library(lists), [append/3]).

scan_generated_code(prolog, Content, Result) :-
    !,
    static_scan(Content, Status, Findings),
    Result = scan(Status, Findings).
scan_generated_code(javascript, Content, Result) :-
    !,
    static_scan(Content, PrologStatus, PrologFindings),
    to_lower_string(Content, Lower),
    findall(Pattern, javascript_pattern(Lower, Pattern), WebFindings),
    append(PrologFindings, WebFindings, Findings0),
    sort(Findings0, Findings),
    (PrologStatus == clear, WebFindings == [] ->
        Status = clear
    ;   Status = human_review_required
    ),
    Result = scan(Status, Findings).
scan_generated_code(generic_code, Content, Result) :-
    !,
    static_scan(Content, PrologStatus, PrologFindings),
    to_lower_string(Content, Lower),
    findall(Pattern, generic_pattern(Lower, Pattern), OtherFindings),
    append(PrologFindings, OtherFindings, Findings0),
    sort(Findings0, Findings),
    (PrologStatus == clear, OtherFindings == [] ->
        Status = clear
    ;   Status = human_review_required
    ),
    Result = scan(Status, Findings).
scan_generated_code(_, _, scan(not_applicable, [])).

javascript_pattern(Text, browser_network) :-
    contains(Text, "fetch(") ;
    contains(Text, "xmlhttprequest") ;
    contains(Text, "websocket(").
javascript_pattern(Text, browser_control) :-
    contains(Text, "navigator.clipboard") ;
    contains(Text, "window.open(").

generic_pattern(Text, process_or_network_client) :-
    contains(Text, "subprocess.") ;
    contains(Text, "os.system(") ;
    contains(Text, "requests.") ;
    contains(Text, "urllib.request").
generic_pattern(Text, credential_literal) :-
    contains(Text, "api_key = '") ;
    contains(Text, "api_key = \"") ;
    contains(Text, "password = '") ;
    contains(Text, "password = \"") ;
    contains(Text, "token = '") ;
    contains(Text, "token = \"").

contains(Text, Substring) :- sub_string(Text, _, _, _, Substring).
to_lower_string(Content, Lower) :-
    (string(Content) -> Text = Content ; atom_string(Content, Text)),
    string_lower(Text, Lower).
