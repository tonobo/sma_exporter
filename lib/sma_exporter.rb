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

      def set(labels, value)
        @values[label_set_for(labels)] = value.to_f
      end
    end

    DC_POW = PC::Gauge.new(:sma_dc_power_kw, "DC Power")
    DC_U = PC::Gauge.new(:sma_dc_voltage, "DC Voltage")
    DC_I = PC::Gauge.new(:sma_dc_current, "DC Current")

    AC_POW = PC::Gauge.new(:sma_ac_power_kw, "AC Power")
    AC_U = PC::Gauge.new(:sma_ac_voltage, "AC Voltage")
    AC_I = PC::Gauge.new(:sma_ac_current, "AC Current")

    YIELD_TODAY_TOTAL = CustomCounter.new(:sma_yield_today_total, "Yield today")
    YIELD_TOTAL = CustomCounter.new(:sma_yield_total, "Yield overall")

    OPERATING_HOURS = CustomCounter.new(:sma_operating_hours, "Power on hours")
    FEED_IN_TIME = CustomCounter.new(:sma_feed_in_hours, "Feed-in time")

    DEV_TEMP = PC::Gauge.new(:sma_device_temperature, "SMA device temperature")
    DEV_STATE = PC::Gauge.new(:sma_device_state, "SMA device state")
    DEV_SN = PC::Gauge.new(:sma_device_sn, "SMA device serialnumber")

    GRID_STATE = PC::Gauge.new(:sma_grid_state, "SMA grid state")
    GRID_FREQ = PC::Gauge.new(:sma_grid_freq, "SMA grid state")

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
      DEV_TEMP.set({},x[:temp])
    end

    def set_grid!
      x = data.grid
      GRID_FREQ.set({},x[:freq])
    end

    def set_dc!
      data.dc.each do |x|
        DC_POW.set({phase: x[:id]}, x[:power])
        DC_U.set({phase: x[:id]}, x[:voltage])
        DC_I.set({phase: x[:id]}, x[:current])
      end
    end

    def set_ac!
      data.ac.each do |x|
        AC_POW.set({phase: x[:id]}, x[:power])
        AC_U.set({phase: x[:id]}, x[:voltage])
        AC_I.set({phase: x[:id]}, x[:current])
      end
    end

    def set_yield!
      YIELD_TODAY_TOTAL.set({}, data.yield[:today])
      YIELD_TOTAL.set({}, data.yield[:total])
    end

    def set_operating_hours!
      # sbfspot is sometimes missing the operating time, only update if possible
      # to read them
      return if data.operating_hours[:power].zero?

      OPERATING_HOURS.set({}, data.operating_hours[:power])
      FEED_IN_TIME.set({}, data.operating_hours[:feed_in])
    end

    def flush!
      @data = nil
    end

    def data
      @data ||= Data.new(sbfpath: ENV.fetch('SMA_SBFPATH'))
    end

  end
end
