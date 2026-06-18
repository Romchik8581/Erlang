-module(sipcall_http).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2,
         handle_info/2, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    Port = application:get_env(sipcall, http_port, 8080),
    lager:info("sipcall_http: starting Cowboy on port ~p~n", [Port]),
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/api/call/:userid", sipcall_api_handler, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(
        sipcall_http_listener,
        [{port, Port}],
        #{env => #{dispatch => Dispatch}}
    ),
    lager:info("sipcall_http: Cowboy started on port ~p~n", [Port]),
    {ok, #{port => Port}}.

handle_call(_Req, _From, State) -> {reply, ok, State}.
handle_cast(_Msg, State)        -> {noreply, State}.
handle_info(_Info, State)       -> {noreply, State}.

terminate(_Reason, _State) ->
    cowboy:stop_listener(sipcall_http_listener),
    ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.
