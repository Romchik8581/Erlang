FROM erlang:21

WORKDIR /app

COPY rebar.config rebar.lock ./

RUN rm -f _build

RUN rebar3 deps

COPY . .

RUN rebar3 compile

RUN chmod -R 777 priv

EXPOSE 5060/udp
EXPOSE 5060/tcp
EXPOSE 8080/tcp

CMD ["rebar3", "shell", "--apps", "sipcall"]
