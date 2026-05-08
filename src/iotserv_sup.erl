-module(iotserv_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    ConfigFile = case application:get_env(iotserv, config_file) of
        {ok, Value} -> Value;
        undefined -> "iotserv_config.json"
    end,

    Child = {iotserv,
             {iotserv, start_link, [ConfigFile]},
             permanent,
             5000,
             worker,
             [iotserv]},

    {ok, {{one_for_one, 5, 10}, [Child]}}.
