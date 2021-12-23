local data = require "prometheus_data"
local var = ngx.var

data.metric_requests:inc(1, {var.server_name, var.status})
data.metric_latency:observe(tonumber(var.request_time), {var.server_name})