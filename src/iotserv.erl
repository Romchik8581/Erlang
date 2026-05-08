-module(iotserv).
-behaviour(gen_server).

-record(device, {
    id,
    name,
    address,
    temperature,
    metrics = []
}).

-export([start_link/1, stop/0]).
-export([add/1, delete/1, change/2, lookup/1]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-record(state, {
    config_file
}).

start_link(ConfigFile) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, ConfigFile, []).

stop() ->
    gen_server:cast(?MODULE, stop).

add(Device) when is_record(Device, device) ->
    gen_server:call(?MODULE, {add, Device}).

delete(Id) ->
    gen_server:call(?MODULE, {delete, Id}).

change(Id, Updates) ->
    gen_server:call(?MODULE, {change, Id, Updates}).

lookup(Id) ->
    gen_server:call(?MODULE, {lookup, Id}).

init(ConfigFile) ->
    case iotserv_db:open(resolve_config_file(ConfigFile)) of
        {ok, _} ->
            {ok, #state{config_file = ConfigFile}};
        Error ->
            {stop, Error}
    end.

handle_call({add, Device}, _From, State) ->
    Reply = iotserv_db:add(Device),
    {reply, Reply, State};

handle_call({delete, Id}, _From, State) ->
    Reply = iotserv_db:delete(Id),
    {reply, Reply, State};

handle_call({lookup, Id}, _From, State) ->
    Reply = iotserv_db:lookup(Id),
    {reply, Reply, State};

handle_call({change, Id, Updates}, _From, State) ->
    Reply =
        case iotserv_db:lookup(Id) of
            {ok, Device} ->
                NewDevice = apply_updates(Device, Updates),
                iotserv_db:update(NewDevice);
            Error ->
                Error
        end,
    {reply, Reply, State};

handle_call(_, _, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast(stop, State) ->
    {stop, normal, State};

handle_cast(_, State) ->
    {noreply, State}.

handle_info(_, State) ->
    {noreply, State}.

terminate(_, _) ->
    iotserv_db:close(),
    ok.

code_change(_, State, _) ->
    {ok, State}.

apply_updates(Device, []) ->
    Device;

apply_updates(Device, [{name, Value} | T]) ->
    apply_updates(Device#device{name = Value}, T);

apply_updates(Device, [{address, Value} | T]) ->
    apply_updates(Device#device{address = Value}, T);

apply_updates(Device, [{temperature, Value} | T]) ->
    apply_updates(Device#device{temperature = Value}, T);

apply_updates(Device, [{metrics, Value} | T]) ->
    apply_updates(Device#device{metrics = Value}, T);

apply_updates(Device, [_ | T]) ->
    apply_updates(Device, T).

resolve_config_file(ConfigFile) ->
    filename:join(code:priv_dir(iotserv), ConfigFile).