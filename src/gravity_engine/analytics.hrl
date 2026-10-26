-record(debug_consumer, {
  server_url = "",
  callback = undefined  %% global error callback, invoked when report failed: fun(Error, ClientId)
}).

-record(analytics, {
  consumer = #debug_consumer{},
  fun_add = fun() -> ok end,
  fun_flush = fun() -> ok end,
  fun_close = fun() -> ok end
}).