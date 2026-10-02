:- module(mnn3_mnn1_adapter,
          [ mnn1_status/1,
            select_algorithm/2
          ]).

mnn1_status(unavailable('No MNN1 implementation is present in this repository.')).

select_algorithm(_, unavailable(mnn1_not_configured)).
