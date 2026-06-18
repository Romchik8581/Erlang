-module(sipcall_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).
-export([dump/0, print_tree/3]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    lager:info("sipcall_sup: init~n"),

    CallerStoreSpec = #{
        id       => caller_store,
        start    => {caller_store, start_link, []},
        restart  => permanent,
        shutdown => 5000,
        type     => worker,
        modules  => [caller_store]
    },

    SipServerSpec = nksip:get_sup_spec(sipcall_sip, #{
        sip_local_host => "127.0.0.1",
        plugins        => [nksip_registrar],
        sip_listen     => "sip:0.0.0.0:5060;transport=udp"
    }),

    SipClientSpec = nksip:get_sup_spec(sipcall_client, #{
        sip_local_host => "127.0.0.1",
        sip_listen     => "sip:127.0.0.1:5075;transport=udp"
    }),

    HttpSpec = #{
        id       => sipcall_http,
        start    => {sipcall_http, start_link, []},
        restart  => permanent,
        shutdown => 5000,
        type     => worker,
        modules  => [sipcall_http]
    },

    ChildSpecs = [CallerStoreSpec, SipServerSpec, SipClientSpec, HttpSpec],
    io:format("sipcall_sup: ChildSpecs ~p~n", [ChildSpecs]),

    SupFlags = #{
        strategy  => one_for_one,
        intensity => 10,
        period    => 60
    },

    {ok, {SupFlags, ChildSpecs}}.

dump() ->
    io:format("++++ Supervisor tree: sipcall_sup ~p~n", [whereis(sipcall_sup)]),
    print_tree(whereis(sipcall_sup), sipcall_sup, 0).

print_tree(Proc, ProcId, Level) ->
    RegName = erlang:process_info(Proc, registered_name),
    case catch supervisor:which_children(Proc) of
        {'EXIT', _} ->
            indent(Level),
            io:format("+-- ~p ~p <worker> ~p~n", [Proc, ProcId, RegName]);
        Children when is_list(Children) ->
            indent(Level),
            io:format("+-- ~p ~p <supervisor> ~p~n", [Proc, ProcId, RegName]),
            lists:foreach(
                fun({Id, Child, Type, Modules}) ->
                    print_child(Id, Child, Type, Modules, Level + 1)
                end, Children)
    end.

print_child(Id, Child, supervisor, _Modules, Level) ->
    print_tree(Child, Id, Level);
print_child(Id, Child, worker, Modules, Level) ->
    indent(Level),
    RegName = erlang:process_info(Child, registered_name),
    io:format("+-- ~p ~p (worker, modules: ~p) ~p~n",
              [Child, Id, Modules, RegName]).

indent(Level) ->
    lists:foreach(fun(_) -> io:format("|    ") end, lists:seq(1, Level)).
