-module(caller_store).
-behaviour(gen_server).

-export([start_link/0, put/2, get/1, all/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(TABLE, caller_store).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

put(UserId, Uri) ->
    gen_server:call(?MODULE, {put, UserId, Uri}).

get(UserId) ->
    case ets:lookup(?TABLE, UserId) of
        [{UserId, Uri}] -> {ok, Uri};
        []              -> {error, not_found}
    end.

all() ->
    ets:tab2list(?TABLE).

init([]) ->
    ets:new(?TABLE, [named_table, public, set]),
    {ok, #{}}.

handle_call({put, UserId, Uri}, _From, State) ->
    ets:insert(?TABLE, {UserId, Uri}),
    lager:info("caller_store: saved ~s~n", [UserId]),
    {reply, ok, State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State)  -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
