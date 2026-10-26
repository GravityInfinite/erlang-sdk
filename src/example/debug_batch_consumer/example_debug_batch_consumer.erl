
-module(example_debug_batch_consumer).
-author("GravityEngine").

%% API
-export([test_v1/0]).


  %%  example_debug_batch_consumer:test_v1().

test_v1() ->
  io:format("SRART~n"),
  ServerUrl =  "https://backend.gravity-engine.com/event_center/api/v1/event/collect/?access_token=x5emsWAxqnlwqpDH1j4bbicR8igmhruT",

  %% init consumer
  debug_consumer:init_with_config(ServerUrl),

  %% init SDK with Consumer
  analytics:init(consumer_debug),

  %% ordinary event
  analytics:track("_test_client_id_0", "$AppStart", #{name => "Charlie"}),

  %% nested Properties event
  analytics:track("_test_client_id_0", "$AppStart", #{name => "Charlie"}),

  %% include time
  analytics:track("_test_client_id_0", "$AppStart", #{name => "Charlie"}),

  %% user Properties
  analytics:user_set("_test_client_id_0", #{name => "Charlie"}),

  analytics:user_add("_test_client_id_0", #{name => "Charlie"}),
  analytics:user_unset("_test_client_id_0", [name]),
  analytics:user_set_once("_test_client_id_0", #{name => "Charlie"}),
  analytics:user_append("_test_client_id_0", #{name => "Charlie"}),
  analytics:user_unique_append("_test_client_id_0", #{name => "Charlie"}),
  analytics:user_del("_test_client_id_0"),
  analytics:flush(),
  io:format("END~n"),
  ok.


