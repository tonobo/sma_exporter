require 'rack'
require "sma_exporter"
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

use Rack::Deflater, if: ->(_, _, _, body) { body.any? && body[0].length > 512 }
use SmaExporter::Rack
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

SmaExporter::Runner.register!

run ->(_) { 
  [200, { 'Content-Type' => 'text/html' }, ['OK'] ] 
}
