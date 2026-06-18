-module(sipcall_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    lager:info("sipcall_app: starting~n"),
    {ok, Pid} = sipcall_sup:start_link(),
    sipcall_sup:dump(),
    {ok, Pid}.

stop(_State) ->
    lager:info("sipcall_app: stopping~n"),
    ok.
