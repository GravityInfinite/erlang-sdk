-module(debug_consumer).
-author("GravityEngine").
-include("analytics.hrl").

%% API
-export([add/1,
  flush/0,
  close/0,
  init/0,
  init_with_config/1,
  init_with_config/2,
  flush_with_instance/1,
  close_with_instance/1
%%  add_with_instance/2
]).

%% ETS table names which debugConsumer used.
-define(TABLE, table_debug_consumer).

-define(SERVER_URL, server_url).
-define(CALLBACK, error_callback).

-type server_url() :: string().

-type error_callback() :: undefined | fun((Error :: term(), ClientId :: binary() | undefined) -> _).


%% @doc Init debug consumer
-spec init() -> _.
init() ->
  io:format("debug_consumer~n"),
  inets:start(),
  %% create ETS table.
  case ets:info(?TABLE) of
    undefined -> ets:new(?TABLE, [set, named_table, public]);
    _ -> ok
  end.


%% @doc Init debug consumer with config
-spec init_with_config(server_url()) -> _.
init_with_config(ServerUrl) ->
  init_with_config(ServerUrl, undefined).

%% @doc Init debug consumer with config and global error callback.
%% The callback is invoked as Callback(Error, ClientId) when report failed.
-spec init_with_config(server_url(), error_callback()) -> _.
init_with_config(ServerUrl, Callback) ->
  inets:start(),
  case ets:info(?TABLE) of
    undefined -> ets:new(?TABLE, [set, named_table, public]);
    _ -> ok
  end,
  ets:insert(?TABLE, {?SERVER_URL, ServerUrl}),
  ets:insert(?TABLE, {?CALLBACK, Callback}),
  #debug_consumer{server_url = ServerUrl, callback = Callback}.


-spec add(analytics:event()) -> _.
add(E) ->
  io:format("~n E ~n"),
  io:format(E),
  io:format("~n"),
%%  RequestBody = lists:concat(["data=", E]),
  RequestBody = E,
  ContentType = "application/json",
  HTTPOptions = [{timeout, 30000}],
  Options = [],
  [{_, Url}|_]  =  ets:lookup(?TABLE, ?SERVER_URL)  ,
  Callback = get_callback(),
  ClientId = extract_client_id(E),

  io:format(Url),
  io:format("~n"),

  case catch httpc:request(post, {Url, [], ContentType, RequestBody}, HTTPOptions, Options) of
    {ok, {{_Version, 200, _ReasonPhrase}, _Headers, Body}} ->
      case parse_result_code(Body) of
        0 ->
          io:format("200 add--->~n"),
          _ = lager:info("result add : ~ts~n", [unicode:characters_to_list(list_to_binary(Body))]),
          ok;
        Code ->
          ErrorMsg = list_to_binary(io_lib:format("Unexpected result code: ~p", [Code])),
          report_error(Callback, ErrorMsg, ClientId),
          _ = lager:error("result add error : ~ts~n", [unicode:characters_to_list(ErrorMsg)]),
          ok
      end;
    {ok, {{_Version, StatusCode, _ReasonPhrase}, _Headers, _Body}} ->
      ErrorMsg = list_to_binary(io_lib:format("Unexpected status code: ~p", [StatusCode])),
      report_error(Callback, ErrorMsg, ClientId),
      _ = lager:error("result add error : ~ts~n", [unicode:characters_to_list(ErrorMsg)]),
      ok;
    Error ->
      ErrorMsg = list_to_binary(io_lib:format("~p ---> add Error", [Error])),
      report_error(Callback, ErrorMsg, ClientId),
      _ = lager:error("result add error : ~ts~n", [unicode:characters_to_list(ErrorMsg)]),
      ok
  end.

%% @doc Get the global error callback from ETS
-spec get_callback() -> error_callback().
get_callback() ->
  case ets:lookup(?TABLE, ?CALLBACK) of
    [{_, Callback}] -> Callback;
    _ -> undefined
  end.

%% @doc Extract client_id from the event json
-spec extract_client_id(binary()) -> binary() | undefined.
extract_client_id(EventJson) ->
  try
    Map = jsone:decode(EventJson),
    maps:get(<<"client_id">>, Map, undefined)
  catch
    _:_ -> undefined
  end.

%% @doc Parse the result code from response body
-spec parse_result_code(binary()) -> integer().
parse_result_code(Body) ->
  try
    Map = jsone:decode(Body),
    maps:get(<<"code">>, Map, -1)
  catch
    _:_ -> -1
  end.

%% @doc Invoke the global error callback when report failed
-spec report_error(error_callback(), binary(), binary() | undefined) -> _.
report_error(undefined, _Error, _ClientId) ->
  ok;
report_error(Callback, Error, ClientId) when is_function(Callback, 2) ->
  try
    Callback(Error, ClientId)
  catch
    C:R ->
      lager:error("error callback failed: ~p:~p~n", [C, R])
  end;
report_error(_Callback, _Error, _ClientId) ->
  ok.

%% @doc (API_v2) Add event
%%-spec add_with_instance(analytics:debug_consumer(), analytics:event()) -> _.
%%add_with_instance(Consumer, E) ->
%%  RequestBody = lists:concat(["data=", E,  "&source=", "server" ]),
%%
%%
%%  ContentType = "application/json",
%%  HTTPOptions = [{timeout, 30000}],
%%  Options = [],
%%  Url = Consumer#debug_consumer.server_url ,
%%  Result = try
%%             {ok, {{_Version, code , _ReasonPhrase}, _Headers, Body}} =
%%               httpc:request(post, {Url, [], ContentType, RequestBody}, HTTPOptions, Options),
%%             Body,
%%             io:format("~p add_with_instance --->", [code])
%%           catch
%%             error:Error -> lager:error("~p lager Error", [Error])
%%           end,
%%  lager:info("result add_with_instance: ~ts~n", [unicode:characters_to_list(list_to_binary(Result))]).

%% @doc Flush data immediately. don't need invoke.
-spec flush() -> _.
flush() ->
  [].

%% @doc Close SDK
-spec close() -> _.
close() ->
  %% delete ETS table
  ets:delete(?TABLE).

%% @doc (API_v2) Flush data immediately. don't need invoke.
-spec flush_with_instance(analytics:debug_consumer()) -> _.
flush_with_instance(Consumer) ->
  Consumer,
  ok.

%% @doc (API_v2) Close SDK
-spec close_with_instance(analytics:debug_consumer()) -> _.
close_with_instance(Consumer) ->
  Consumer,
  ok.


