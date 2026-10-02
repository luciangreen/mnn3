:- module(mnn3_verification,
          [ verification_status/3,
            verify_project_requirements/3
          ]).

:- use_module(library(lists), [subtract/3]).

verification_status(generated, generated, []).
verification_status(statically_checked, statically_checked, []).
verification_status(internally_tested, internally_tested, []).
verification_status(human_review_required, human_review_required, []).
verification_status(externally_tested, externally_tested, []).
verification_status(accepted, accepted, []).

verify_project_requirements(RequiredPaths, ProducedPaths,
                            verification(Status, Missing)) :-
    is_list(RequiredPaths),
    is_list(ProducedPaths),
    subtract(RequiredPaths, ProducedPaths, Missing),
    (Missing == [] -> Status = complete ; Status = incomplete).
