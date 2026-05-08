-module(iotserv_db).

-record(device, {
    id,
    name,
    address,
    temperature,
    metrics = []
}).

-export([
    open/1,
    close/0,
    add/1,
    delete/1,
    lookup/1,
    update/1
]).

-define(ETS, iotserv_ets).
-define(DETS, iotserv_dets).

open(ConfigFile) ->
    ensure_ets(),

    {ok, Bin} = file:read_file(ConfigFile),
    Config = jsx:decode(Bin, [return_maps]),

    DetsFile = binary_to_list(maps:get(<<"dets_file">>, Config)),

    dets:open_file(?DETS, [
        {file, DetsFile},
        {type, set},
        {keypos, #device.id}
    ]),

    restore(),
    {ok, DetsFile}.

close() ->
    dets:close(?DETS),
    ets:delete(?ETS),
    ok.

ensure_ets() ->
    ets:new(?ETS, [
        named_table,
        public,
        set,
        {keypos, #device.id}
    ]).

restore() ->
    Insert = fun(Device) ->
        ets:insert(?ETS, Device),
        continue
    end,
    dets:traverse(?DETS, Insert).

add(Device) ->
    Id = Device#device.id,

    case ets:lookup(?ETS, Id) of
        [] ->
            ets:insert(?ETS, Device),
            dets:insert(?DETS, Device),
            ok;
        _ ->
            {error, already_exists}
    end.

lookup(Id) ->
    case ets:lookup(?ETS, Id) of
        [Device] -> {ok, Device};
        [] -> {error, not_found}
    end.

update(Device) ->
    ets:insert(?ETS, Device),
    dets:insert(?DETS, Device),
    ok.

delete(Id) ->
    case ets:lookup(?ETS, Id) of
        [] ->
            {error, not_found};

        [_] ->
            ets:delete(?ETS, Id),
            dets:delete(?DETS, Id),
            ok
    end.