:- module(mnn3_reviewer, [review_artifact/3]).

:- use_module('../security/code_scan', [scan_generated_code/3]).

review_artifact(Type, Content, review(Status, Findings)) :-
    (   code_type(Type, CodeType)
    ->  scan_generated_code(CodeType, Content, scan(ScanStatus, Findings)),
        review_status(ScanStatus, Status)
    ;   Status = static_checks_limited,
        Findings = []
    ).

code_type(source_code, prolog).
code_type(tests, prolog).
code_type(prolog_facts, prolog).

review_status(clear, statically_checked).
review_status(human_review_required, human_review_required).
review_status(not_applicable, static_checks_limited).

