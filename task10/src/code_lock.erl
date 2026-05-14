-module(code_lock).
-behaviour(gen_statem).

-export([start_link/2, stop/0]).
-export([button/1, set_lock_button/1, set_code/1]).
-export([init/1, callback_mode/0, terminate/3]).
-export([handle_event/4]).

start_link(Code, LockButton) ->
    gen_statem:start_link(
        {local, code_lock},
        ?MODULE,
        {Code, LockButton},
        []
    ).

stop() ->
    gen_statem:stop(code_lock).

button(Button) ->
    gen_statem:call(code_lock, {button, Button}).

set_lock_button(LockButton) ->
    gen_statem:call(code_lock, {set_lock_button, LockButton}).

set_code(Code) ->
    gen_statem:call(code_lock, {set_code, Code}).

init({Code, LockButton}) ->
    process_flag(trap_exit, true),

    Data = #{
        code => Code,
        length => length(Code),
        buttons => [],
        fail_count => 0,
        lock_button => LockButton
    },

    {ok, locked, Data}.

callback_mode() ->
    [handle_event_function, state_enter].

handle_event(enter, _OldState, locked, Data) ->
    do_lock(),
    {keep_state, Data#{buttons := []}};

handle_event(enter, _OldState, open, Data) ->
    do_unlock(),
    {keep_state,
     Data#{buttons := [], fail_count := 0},
     [{state_timeout, 10000, unlock_timeout}]};

handle_event(enter, _OldState, suspended, Data) ->
    do_suspend(),
    {keep_state,
     Data#{buttons := []},
     [{state_timeout, 10000, suspend_timeout}]};

handle_event(state_timeout, unlock_timeout, open, Data) ->
    {next_state, locked, Data#{buttons := []}};

handle_event(state_timeout, suspend_timeout, suspended, Data) ->
    {next_state, locked, Data#{buttons := [], fail_count := 0}};

handle_event({call, From}, {button, Button}, locked, Data) ->
    handle_locked_button(From, Button, Data);

handle_event({call, From}, {button, Button}, open, Data) ->
    handle_open_button(From, Button, Data);

handle_event({call, From}, {button, _Button}, suspended, _Data) ->
    {keep_state_and_data, [{reply, From, error}]};

handle_event({call, From}, {set_code, NewCode}, open, Data)
  when is_list(NewCode) ->

    NewData = Data#{
        code := NewCode,
        length := length(NewCode),
        buttons := []
    },

    {keep_state, NewData, [{reply, From, ok}]};

handle_event({call, From}, {set_code, _BadCode}, open, _Data) ->
    {keep_state_and_data, [{reply, From, error}]};

handle_event({call, From}, {set_code, _}, _State, _Data) ->
    {keep_state_and_data, [{reply, From, error}]};

handle_event({call, From}, {set_lock_button, NewLockButton}, _State, Data) ->
    OldLockButton = maps:get(lock_button, Data),
    NewData = Data#{lock_button := NewLockButton},
    {keep_state, NewData, [{reply, From, OldLockButton}]};

handle_event(_, _, _, _) ->
    keep_state_and_data.

handle_locked_button(From, Button, Data) ->
    Code = maps:get(code, Data),
    Length = maps:get(length, Data),
    Buttons0 = maps:get(buttons, Data),
    Fail0 = maps:get(fail_count, Data),

    Buttons1 = Buttons0 ++ [Button],
    NewData0 = Data#{buttons := Buttons1},

    case length(Buttons1) of
        N when N < Length ->
            {keep_state,
             NewData0,
             [{reply, From, ok}]};

        _ ->
            case Buttons1 =:= Code of
                true ->
                    {next_state,
                     open,
                     NewData0#{buttons := [], fail_count := 0},
                     [{reply, From, ok}]};

                false ->
                    Fail1 = Fail0 + 1,

                    NewData1 = NewData0#{
                        buttons := [],
                        fail_count := Fail1
                    },

                    case Fail1 >= 3 of
                        true ->
                            {next_state,
                             suspended,
                             NewData1,
                             [{reply, From, error}]};

                        false ->
                            {keep_state,NewData1,
                             [{reply, From, error}]}
                    end
            end
    end.

handle_open_button(From, Button, Data) ->
    LockButton = maps:get(lock_button, Data),

    case Button of
        LockButton ->
            {next_state,
             locked,
             Data#{buttons := [], fail_count := 0},
             [{reply, From, ok}]};

        _ ->
            {keep_state_and_data,
             [{reply, From, ok}]}
    end.

do_lock() ->
    io:format("Locked~n", []).

do_unlock() ->
    io:format("Open~n", []).

do_suspend() ->
    io:format("Suspended~n", []).

terminate(_Reason, State, _Data) ->
    State =/= locked andalso do_lock(),
    ok.