local data = require "prometheus_data"
local var = ngx.var
local metric_connections = data.metric_connections
local prometheus = data.prometheus

metric_connections:set(var.connections_reading, {"reading"})
metric_connections:set(var.connections_waiting, {"waiting"})
metric_connections:set(var.connections_writing, {"writing"})
prometheus:collect()