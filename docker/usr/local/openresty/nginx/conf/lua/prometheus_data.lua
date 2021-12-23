local prometheus = require("prometheus").init("prometheus_metrics")
local metric_requests = prometheus:counter(
    "nginx_http_requests_total", "Number of HTTP requests", {"host", "status"})
local metric_latency = prometheus:histogram(
    "nginx_http_request_duration_seconds", "HTTP request latency", {"host"})
local metric_connections = prometheus:gauge(
    "nginx_http_connections", "Number of HTTP connections", {"state"})

local _M = {
    prometheus = prometheus,
    metric_requests = metric_requests,
    metric_latency = metric_latency,
    metric_connections = metric_connections
}

return _M