-module(debug_consumer).
-author("GravityEngine").
-include("analytics.hrl").

%% API
-export([add/1,
  flush/0,
  close/0,
  init/0,
  init_with_config/1,
  flush_with_instance/1,
  close_with_instance/1
%%  add_with_instance/2
]).

%% ETS table names which debugConsumer used.
-define(TABLE, table_debug_consumer).

-define(SERVER_URL, server_url).

-type server_url() :: string().


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
  inets:start(),
  case ets:info(?TABLE) of
    undefined -> ets:new(?TABLE, [set, named_table, public]);
    _ -> ok
  end,
  ets:insert(?TABLE, {?SERVER_URL, ServerUrl}),
  #debug_consumer{server_url = ServerUrl}.


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

  io:format(Url),
  io:format("~n"),

  Result = try
           {ok, {{_Version, code , _ReasonPhrase}, _Headers, Body}} =
             httpc:request(post, {Url, [], ContentType, RequestBody}, HTTPOptions, Options),
           Body,
           io:format("~p add--->", [code])
         catch
           error:Error ->io:format("~p ---> add Error ", [Error])
         end,
  _ =lager:info("result add : ~ts~n", [unicode:characters_to_list(list_to_binary(Result))]).

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


