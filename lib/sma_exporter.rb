require "sma_exporter/version"
require 'prometheus/client'
require "sma_exporter/data"

module SmaExporter
  PROMETHEUS = Prometheus::Client.registry

  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      Runner.do!
      @app.call(env)
    end
  end

  module Runner

    PC = Prometheus::Client

    class CustomCounter < PC::Metric
      def type
        :counter
      end

      def set(value, labels: {})
        @store.set(labels: label_set_for(labels), val: value.to_f)
      end
    end

    DC_POW = PC::Gauge.new(:sma_dc_power_kw, docstring: "DC Power", labels: [:phase])
    DC_U = PC::Gauge.new(:sma_dc_voltage, docstring: "DC Voltage", labels: [:phase])
    DC_I = PC::Gauge.new(:sma_dc_current, docstring: "DC Current", labels: [:phase])

    AC_POW = PC::Gauge.new(:sma_ac_power_kw, docstring: "AC Power", labels: [:phase])
    AC_U = PC::Gauge.new(:sma_ac_voltage, docstring: "AC Voltage", labels: [:phase])
    AC_I = PC::Gauge.new(:sma_ac_current, docstring: "AC Current", labels: [:phase])

    YIELD_TODAY_TOTAL = CustomCounter.new(:sma_yield_today_total, docstring: "Yield today")
    YIELD_TOTAL = CustomCounter.new(:sma_yield_total, docstring: "Yield overall")

    OPERATING_HOURS = CustomCounter.new(:sma_operating_hours, docstring: "Power on hours")
    FEED_IN_TIME = CustomCounter.new(:sma_feed_in_hours, docstring: "Feed-in time")

    DEV_TEMP = PC::Gauge.new(:sma_device_temperature, docstring: "SMA device temperature")
    DEV_STATE = PC::Gauge.new(:sma_device_state, docstring: "SMA device state")
    DEV_SN = PC::Gauge.new(:sma_device_sn, docstring: "SMA device serialnumber")

    GRID_STATE = PC::Gauge.new(:sma_grid_state, docstring: "SMA grid state")
    GRID_FREQ = PC::Gauge.new(:sma_grid_freq, docstring: "SMA grid state")

    module_function

    def do!
      set_device!
      set_grid!
      set_ac!
      set_dc!
      set_operating_hours!
      set_yield!
    ensure
      flush!
    end

    def register!
      [
        DC_POW, DC_U, DC_I,
        AC_POW, AC_I, AC_U,
        DEV_TEMP, DEV_STATE, DEV_SN,
        GRID_STATE, GRID_FREQ,
        YIELD_TODAY_TOTAL, YIELD_TOTAL,
        OPERATING_HOURS, FEED_IN_TIME
      ].each do |x|
        PROMETHEUS.register x
      end
    end

    def set_device!
      x = data.device
      DEV_TEMP.set(x[:temp])
    end

    def set_grid!
      x = data.grid
      GRID_FREQ.set(x[:freq])
    end

    def set_dc!
      data.dc.each do |x|
        DC_POW.set(x[:power], labels: {phase: x[:id]})
        DC_U.set(x[:voltage], labels: {phase: x[:id]})
        DC_I.set(x[:current], labels: {phase: x[:id]})
      end
    end

    def set_ac!
      data.ac.each do |x|
        AC_POW.set(x[:power], labels: {phase: x[:id]})
        AC_U.set(x[:voltage], labels: {phase: x[:id]})
        AC_I.set(x[:current], labels: {phase: x[:id]})
      end
    end

    def set_yield!
      YIELD_TODAY_TOTAL.set(data.yield[:today])
      YIELD_TOTAL.set(data.yield[:total])
    end

    def set_operating_hours!
      # sbfspot is sometimes missing the operating time, only update if possible
      # to read them
      return if data.operating_hours[:power].zero?

      OPERATING_HOURS.set(data.operating_hours[:power])
      FEED_IN_TIME.set(data.operating_hours[:feed_in])
    end

    def flush!
      @data = nil
    end

    def data
      @data ||= Data.new(sbfpath: ENV.fetch('SMA_SBFPATH'))
    end

  end
end
