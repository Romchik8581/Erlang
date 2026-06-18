-module(sipcall_sip).

-export([call/1]).
-export([sip_get_user_pass/4,
         sip_authorize/3,
         sip_route/5,
         sip_register/2,
         sip_invite/2,
         sip_publish/2]).

-include_lib("nkserver/include/nkserver_module.hrl").

call(Uri) ->
    lager:info("sipcall_sip: outbound INVITE to ~p~n", [Uri]),
    case nksip_uac:invite(sipcall_client, Uri, [auto_2xx_ack, {meta, []}]) of
        {ok, _Code, _Meta} -> ok;
        {error, Reason}    -> {error, Reason}
    end.

sip_get_user_pass(_User, _Realm, _Req, _Call) ->
    <<>>.

sip_authorize(AuthList, _Req, _Call) ->
    lager:info("sipcall_sip: sip_authorize ~p~n", [AuthList]),
    ok.

sip_route(_Scheme, <<>>, <<"localhost">>, _Req, _Call) ->
    process;
sip_route(_Scheme, _User, _Domain, Req, _Call) ->
    case nksip_request:is_local_ruri(Req) of
        true  -> process;
        false -> proxy
    end.

sip_register(Req, _Call) ->
    {ok, [{from_user, FromUser}]} = nksip_request:get_metas([from_user], Req),
    {ok, [{contacts, Contacts}]}  = nksip_request:get_metas([contacts], Req),
    lager:info("sipcall_sip: sip_register(From ~p)~n", [FromUser]),
    caller_store:put(binary_to_list(FromUser), Contacts),
    {reply, ok}.

sip_invite(Req, _Call) ->
    {ok, [{from_user, FromUser}]} = nksip_request:get_metas([from_user], Req),
    Contacts = nksip_sipmsg:get_meta(contacts, Req),
    lager:info("sipcall_sip: sip_invite(From ~p)~n", [FromUser]),
    caller_store:put(binary_to_list(FromUser), Contacts),
    {reply, {487, []}}.

sip_publish(_Req, _Call) ->
    lager:debug("sipcall_sip: sip_publish ignored~n"),
    {reply, ok}.
