-module(code_lock_t).

-include_lib("eunit/include/eunit.hrl").

setup() ->
    catch code_lock:stop(),
    {ok, _Pid} = code_lock:start_link([1, 2], 0),
    ok.

cleanup(_) ->
    catch code_lock:stop(),
    ok.
open_and_change_code_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     fun() ->
         ?assertEqual(ok, code_lock:button(1)),
         ?assertEqual(ok, code_lock:button(2)),
         ?assertEqual(ok, code_lock:set_code([3, 4])),
         ?assertEqual(ok, code_lock:button(0)),
         ?assertEqual(ok, code_lock:button(3)),
         ?assertEqual(ok, code_lock:button(4))

     end}.

suspend_after_three_wrong_codes_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     fun() ->
         ?assertEqual(ok, code_lock:button(9)),
         ?assertEqual(error, code_lock:button(9)),
         ?assertEqual(ok, code_lock:button(8)),
         ?assertEqual(error, code_lock:button(8)),
         ?assertEqual(ok, code_lock:button(7)),
         ?assertEqual(error, code_lock:button(7)),
         ?assertEqual(error, code_lock:button(1))

     end}.