require "sma_exporter/version"
require 'prometheus/client'
require "sma_exporter/data"

module SmaExporter
  PROMETHEUS = Prometheus::Client.registry

  class Rack
    def initialize(app)
      p "moo"
      @app = app
    end

    def call(env)
      Runner.do!
      @app.call(env)
    end
  end
 
  module Runner

    PC = Prometheus::Client

    DC_POW = PC::Gauge.new(:sma_dc_power_kw, "DC Power")
    DC_U = PC::Gauge.new(:sma_dc_voltage, "DC Voltage")
    DC_I = PC::Gauge.new(:sma_dc_current, "DC Current")
    
    AC_POW = PC::Gauge.new(:sma_ac_power_kw, "AC Power")
    AC_U = PC::Gauge.new(:sma_ac_voltage, "AC Voltage")
    AC_I = PC::Gauge.new(:sma_ac_current, "AC Current")

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
    ensure
      flush!
    end

    def register!
      [
        DC_POW, DC_U, DC_I, 
        AC_POW, AC_I, AC_U, 
        DEV_TEMP, DEV_STATE, DEV_SN, 
        GRID_STATE, GRID_FREQ
      ].each do |x|
        PROMETHEUS.register x
      end
    end

    def set_device!
      x = data.device
      DEV_TEMP.set({},x[:temp])
      DEV_STATE.set({},x[:state])
      DEV_SN.set({},x[:sn])
    end
    
    def set_grid!
      x = data.grid
      GRID_FREQ.set({},x[:freq])
      GRID_STATE.set({},x[:state])
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

    def flush!
      @data = nil
    end

    def data
      @data ||= Data.new(sbfpath: ENV.fetch('SMA_SBFPATH'))
    end

  end
end
