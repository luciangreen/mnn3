:- module(mnn3_code_scan, [scan_generated_code/3]).

:- use_module('../validators/prolog', [static_scan/3]).

scan_generated_code(prolog, Content, Result) :-
    !,
    static_scan(Content, Status, Findings),
    Result = scan(Status, Findings).
scan_generated_code(_, _, scan(not_applicable, [])).
