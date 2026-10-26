-record(debug_consumer, {
  server_url = ""
}).

-record(analytics, {
  consumer = #debug_consumer{},
  fun_add = fun() -> ok end,
  fun_flush = fun() -> ok end,
  fun_close = fun() -> ok end
}).