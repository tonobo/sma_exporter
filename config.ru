require 'rack'
require "sma_exporter"
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

if ENV['SMA_ADDRESS']
	config = File.join(
		File.dirname(ENV.fetch('SMA_SBFPATH')),
		'SBFspot.cfg'
	)
	data = File.binread(config)
	data[/IP_Address=(.+)$/, 1] = ENV['SMA_ADDRESS']
	File.binwrite(config, data)
end

use Rack::Deflater, if: ->(_, _, _, body) { body.any? && body[0].length > 512 }
use SmaExporter::Rack
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

SmaExporter::Runner.register!

run ->(_) { 
  [200, { 'Content-Type' => 'text/html' }, ['OK'] ] 
}
