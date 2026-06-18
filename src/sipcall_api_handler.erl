-module(sipcall_api_handler).

-export([init/2]).

init(Req0, State) ->
    Method = cowboy_req:method(Req0),
    Path   = cowboy_req:path(Req0),
    lager:info("sipcall_api_handler: ~s ~s~n", [Method, Path]),
    Req = dispatch(Method, Path, Req0),
    {ok, Req, State}.

dispatch(<<"GET">>, <<"/api/call/", _/binary>>, Req0) ->
    UserId    = binary_to_list(cowboy_req:binding(userid, Req0)),
    case caller_store:get(UserId) of
        {ok, Uri} ->
            lager:info("sipcall_api_handler: calling ~s~n", [UserId]),
            case sipcall_sip:call(Uri) of
                ok ->
                    json_reply(200, #{<<"status">>  => <<"ok">>,
                                     <<"message">> => <<"Call initiated">>,
                                     <<"userid">>  => list_to_binary(UserId)}, Req0);
                {error, Reason} ->
                    Err = list_to_binary(io_lib:format("~p", [Reason])),
                    json_reply(500, #{<<"status">>  => <<"error">>,
                                     <<"message">> => Err,
                                     <<"userid">>  => list_to_binary(UserId)}, Req0)
            end;
        {error, not_found} ->
            json_reply(404, #{<<"status">>  => <<"error">>,
                              <<"message">> => <<"User not found. Has this user called us?">>,
                              <<"userid">>  => list_to_binary(UserId)}, Req0)
    end;

dispatch(_Method, _Path, Req) ->
    json_reply(404, #{<<"error">> => <<"not found">>}, Req).

json_reply(Code, Body, Req) ->
    cowboy_req:reply(
        Code,
        #{<<"content-type">> => <<"application/json">>},
        jsx:encode(Body),
        Req
    ).
