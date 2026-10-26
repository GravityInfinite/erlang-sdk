-module(analytics).
-include("analytics.hrl").

%% API
-export([
  init/1,
  track/3,
  user_set/2,
  user_unset/2,
  user_set_once/2,
  user_append/2,
  user_unique_append/2,
  user_add/2,
  user_del/1,
  close/0,
  flush/0,
  init_with_consumer/1,
  track_instance/4,

  user_set_instance/3,
  user_unset_instance/3,
  user_set_once_instance/3,
  user_append_instance/3,
  user_unique_append_instance/3,
  user_add_instance/3,
  user_del_instance/2,
  flush_instance/1,
  close_instance/1
]).

-export_type([operation/0, event/0, consumer_type/0]).

-define(TABLE, table).
-define(OPERATION, "operation").

-define(TRACK, "track").

-define(USER_SET, "user_set").
-define(USER_UNSET, "user_unset").
-define(USER_SET_ONCE, "user_setOnce").
-define(USER_ADD, "user_add").
-define(USER_APPEND, "user_append").
-define(USER_UNIQUE_APPEND, "user_uniq_append").
-define(USER_DEL, "user_del").

-define(SDK_VERSION, "1.0.0").
-define(LIB_NAME, "Erlang").


-define(FUNC_ADD, add).
-define(FUNC_FLUSH, flush).
-define(FUNC_CLOSE, close).
-define(CONSUMER_TYPE_DEBUG, consumer_debug).
-type consumer_type() :: consumer_debug.


-type operation() :: #{ ?FUNC_ADD => fun()
                      , ?FUNC_FLUSH => fun()
                      , ?FUNC_CLOSE => fun()
                      }.

-type analytics() :: #analytics{}.

-type client_id() :: string().

-type event_name() :: string().

-type properties() :: map().

-type event_type() :: string().


-type event() :: #{ eventName => event_name()
                  , clientId => client_id()
                  , type => event_type()
                  , properties => properties()
                  }.

%% ... existing code ...

%% @doc Init SDK
-spec init(consumer_type()) -> _.
init(Type) ->
  io:format("init-analytics: ~p~n", [Type]),

  Operation = case Type of
                ?CONSUMER_TYPE_DEBUG -> #{
                  ?FUNC_ADD => fun debug_consumer:add/1,
                  ?FUNC_FLUSH => fun debug_consumer:flush/0,
                  ?FUNC_CLOSE => fun debug_consumer:close/0
                };
                _ -> #{}
              end,
  case ets:info(?TABLE) of
    undefined -> ets:new(?TABLE, [set, named_table, public]);
    _ -> ok
  end,
  ets:insert(?TABLE, {?OPERATION, Operation}).

%% ... existing code ...

%% @doc Ordinary event
-spec track(client_id(), event_name(), properties()) -> _.
track(ClientId, EventName, Properties) ->
  internal_track(ClientId, ?TRACK, EventName, Properties).

-spec user_set(client_id(), properties()) -> _.
user_set(ClientId, Properties) ->
  internal_user(ClientId, ?USER_SET, Properties).

-spec user_unset(client_id(), properties()) -> _.
user_unset(ClientId, Properties) ->
  internal_user(ClientId, ?USER_UNSET, Properties).

-spec user_set_once(client_id(), properties()) -> _.
user_set_once(ClientId, Properties) ->
  internal_user(ClientId, ?USER_SET_ONCE, Properties).

-spec user_add(client_id(), properties()) -> _.
user_add(ClientId, Properties) ->
  internal_user(ClientId, ?USER_ADD, Properties).

-spec user_append(client_id(), properties()) -> _.
user_append(ClientId, Properties) ->
  internal_user(ClientId, ?USER_APPEND, Properties).

-spec user_unique_append(client_id(), properties()) -> _.
user_unique_append(ClientId, Properties) ->
  internal_user(ClientId, ?USER_UNIQUE_APPEND, Properties).

-spec user_del(client_id()) -> _.
user_del(ClientId) ->
  internal_user(ClientId, ?USER_DEL, #{}).

%% @doc Flush data
-spec flush() -> _.
flush() ->
  Flush = find_function(?FUNC_FLUSH),
  if
    is_function(Flush) -> Flush();
    true -> []
  end.

%% @doc Close SDK
-spec close() -> _.
close() ->
  Close = find_function(?FUNC_CLOSE),
  if
    is_function(Close) -> Close();
    true -> []
  end,
  ets:delete(?TABLE).

%% V2 API. support multiple instance.

%% @doc (API_v2) Init SDK. Return analytics record
-spec init_with_consumer(#{}) -> _.
init_with_consumer(Consumer) ->
      if
        is_record(Consumer, debug_consumer) ->
          io:format("GravityEngine init debug consumer.~n"),
          #analytics{consumer = Consumer, fun_add = fun debug_consumer:add_with_instance/2, fun_flush = fun debug_consumer:flush_with_instance/1, fun_close = fun debug_consumer:close_with_instance/1};
        true -> throw("GravityEngine Consumer error. ~n")
      end.

%% @doc (API_v2) Ordinary event
-spec track_instance(analytics(), client_id(), event_name(), properties()) -> _.
track_instance(Instance, ClientId, EventName, Properties) ->
  internal_track_instance(Instance, ClientId, ?TRACK, EventName,  Properties).


%% @doc (API_v2) Set user Properties. would overwrite existing names
-spec user_set_instance(analytics(), client_id(), properties()) -> _.
user_set_instance(Instance, ClientId, Properties) ->
  internal_user_instance(Instance, ClientId, ?USER_SET, Properties).

%% @doc (API_v2) Clear the user Properties of users
-spec user_unset_instance(analytics(), client_id(), erlang:list()) -> _.
user_unset_instance(Instance, ClientId, PropertiesList) ->
  NewList = lists:map(fun(E) -> {E, 0} end, PropertiesList),
  Properties = maps:from_list(NewList),
  internal_user_instance(Instance, ClientId, ?USER_UNSET, Properties).

%% @doc (API_v2) If such property had been set before, this message would be neglected.
-spec user_set_once_instance(analytics(), client_id(), properties()) -> _.
user_set_once_instance(Instance, ClientId, Properties) ->
  internal_user_instance(Instance, ClientId, ?USER_SET_ONCE, Properties).

%% @doc (API_v2) To accumulate operations against the property
-spec user_add_instance(analytics(), client_id(), properties()) -> _.
user_add_instance(Instance, ClientId, Properties) ->
  internal_user_instance(Instance, ClientId, ?USER_ADD, Properties).

%% @doc (API_v2) To add user Properties of array type
-spec user_append_instance(analytics(), client_id(), properties()) -> _.
user_append_instance(Instance, ClientId, Properties) ->
  internal_user_instance(Instance, ClientId, ?USER_APPEND, Properties).

%% @doc (API_v2) Add user Properties of array type. delete duplicated user property
-spec user_unique_append_instance(analytics(), client_id(), properties()) -> _.
user_unique_append_instance(Instance, ClientId, Properties) ->
  internal_user_instance(Instance, ClientId, ?USER_UNIQUE_APPEND, Properties).

%% @doc (API_v2) Delete a user
-spec user_del_instance(analytics(), client_id()) -> _.
user_del_instance(Instance, ClientId) ->
  internal_user_instance(Instance, ClientId, ?USER_DEL, #{}).

%% @doc (API_v2) Flush data
-spec flush_instance(analytics()) -> _.
flush_instance(SDK) ->
  Flush = SDK#analytics.fun_flush,
  Flush(SDK#analytics.consumer).

%% @doc (API_v2) Close SDK
-spec close_instance(analytics()) -> _.
close_instance(SDK) ->
  Close = SDK#analytics.fun_close,
  Close(SDK#analytics.consumer).

%% Private methods

%% Process event
-spec internal_track(client_id(), event_type(), event_name(),  properties()) -> _.
internal_track(ClientId, EventType, EventName, Properties) ->
  %% set preset Properties
  NewProperties = Properties,
  %% generate event
  JsonEvent = generate_event(ClientId, EventType, EventName,  NewProperties),
  %% invoke Add function
  Add = find_function(?FUNC_ADD),
  if
    is_function(Add) -> Add(JsonEvent);
    true -> []
  end.

%% Process event
-spec internal_track_instance(analytics(), client_id(), event_type(), event_name(),  properties()) -> _.
internal_track_instance(Instance, ClientId, EventType, EventName,  Properties) ->
  %% set preset Properties
  NewProperties =Properties,
  %% generate event
  JsonEvent = generate_event(ClientId, EventType, EventName,  NewProperties),
  %% invoke Add function
  Add = Instance#analytics.fun_add,
  if
    is_function(Add) -> Add(Instance#analytics.consumer, JsonEvent);
    true -> []
  end.

%% Process user Properties
-spec internal_user(client_id(), event_type(), properties()) -> _.
internal_user(ClientId, EventType, Properties) ->
  %% Properties don't be null unless EventType is equal USER_DEL

  JsonEvent = generate_event(ClientId, EventType, "profile", Properties),
  %% invoke Add function
  Add = find_function(?FUNC_ADD),
  if
    is_function(Add) -> Add(JsonEvent);
    true -> []
  end.

%% Process user Properties
-spec internal_user_instance(analytics(), client_id(), event_type(), properties()) -> _.
internal_user_instance(Instance, ClientId, EventType, Properties) ->
  %% Properties don't be null unless EventType is equal USER_DEL
  if
    EventType /= ?USER_DEL, map_size(Properties) == 0 -> throw("gravity engine data error: Properties not be nil");
    true -> []
  end,
  JsonEvent = generate_event(ClientId, EventType, "",  Properties),
  %% invoke Add function
  Add = Instance#analytics.fun_add,
  if
    is_function(Add) -> Add(Instance#analytics.consumer, JsonEvent);
    true -> []
  end.

%% Generate event
-spec generate_event(client_id(), event_type(), event_name(),  properties()) -> _.
generate_event(ClientId, EventType, EventName,  Properties) ->

{Megasecs, Secs, Microsecs} = os:timestamp(),
Time = (Megasecs * 1000000 + Secs) * 1000 + Microsecs div 1000,

%%PropertiesItem =  #{
%%   "properties" => Properties
%%},
  Event0 = #{
%%  "client_id"=> ClientId,
  "type"=>  EventName,
  "time" => Time,
  "event" => EventType,
  "properties"=>Properties
},
Event = #{
  "client_id"=> ClientId,
%%  "type"=> EventType,
%%  "time" => Time,
%%  "event" => EventName,
  "event_list"=> [Event0]
},


  NewEvent = convert_string2binary(Event),
  JsonEvent=jsone:encode(NewEvent),
%%  JsonEvent = binary_to_list(jsone:encode(NewEvent, [{float_format, [{decimals, 11}, compact]}])),
  JsonEvent.

%% Convert string to binary
-spec convert_list2binary([]) -> binary().
convert_list2binary(Value) ->
  if
    is_list(Value) ->
      %% is normal string or not
      case io_lib:printable_list(Value) of
        false ->
          %% not normal string (include unicode, and list)
          case io_lib:printable_unicode_list(Value) of
            false ->
              %% normal list
              lists:map(fun(E) ->
                if
                  is_list(E) -> convert_list2binary(E);
                  is_map(E) -> convert_string2binary(E);
                  true -> E
                end
                        end, Value);
            true ->
              %% is unicode
              unicode:characters_to_binary(Value)
          end;
        true ->
          %% string which not include unicode
          list_to_binary(Value)
      end;
    is_map(Value) ->
      convert_string2binary(Value);
    true -> Value
  end.

%% Convert string to binary
-spec convert_string2binary(#{}) -> #{}.
convert_string2binary(Map) ->
  maps:fold(fun(Key, Value, AccIn) ->
    NewValue = if
                 is_list(Value) -> convert_list2binary(Value);
                 is_map(Value) -> convert_string2binary(Value);
                 true ->
                   Value
               end,
    AccIn#{convert_list2binary(Key) => NewValue}
            end, #{}, Map).


%% find truth function in strategy
-spec find_function(string()) -> fun().
find_function(Name) ->
  try
    [{_, E}|_] = ets:lookup(?TABLE, ?OPERATION),
    {_, Func} = maps:find(Name, E),
    Func
  catch
    error:_ ->
      io:format("gravity engine data error: not match function ~p.~n", [Name]),
      fun(_) -> ok end
  end.


