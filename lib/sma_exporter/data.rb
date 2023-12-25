require 'shellwords'

module SmaExporter
  class Data

    include Shellwords

    attr_reader :sbfpath

    def initialize(sbfpath:)
      @sbfpath = sbfpath
    end

    def device
      {
        state: value(output[/Device Status\s*:\s*(\S+)/,1].to_s.downcase),
        sn: value(output[/Device Name\s*:\s*SN:\s*(\S+)/,1]),
        temp: output[/Device Temperature:[^\d]+(\d+\.\d+)/,1].to_f
      }
    end

    def grid
      {
        freq: output[/Grid Freq.[^\d]+(\d+\.\d+)/,1].to_f,
        state: value(output[/GridRelay Status\s*:\s*(\S+)/,1].to_s.downcase)
      }
    end

    def yield
      {
        today: output[/EToday: (\d+(?:\.\d+)?)kWh/,1].to_f,
        total: output[/ETotal: (\d+(?:\.\d+)?)kWh/,1].to_f,
      }
    end

    def operating_hours
      {
        power: output[/Operation Time: (\d+(?:\.\d+)?)h/,1].to_f,
        feed_in: output[/Feed-In Time  : (\d+(?:\.\d+)?)h/,1].to_f
      }
    end

    def ac
      output.scan(
        /Phase\s(\d+)
        \sPac[^\d]+(\d+\.\d+)
        [^\d]+(\d+\.\d+)
        [^\d]+(\d+\.\d+)/x
      ).map do |x|
        { id: x[0].to_i, power: x[1].to_f,
          voltage: x[2].to_f, current: x[3].to_f }
      end
    end

    def dc
      output.scan(
        /String\s(\d+)
        \sPdc[^\d]+(\d+\.\d+)
        [^\d]+(\d+\.\d+)
        [^\d]+(\d+\.\d+)/x
      ).map do |x|
        { id: x[0].to_i, power: x[1].to_f,
          voltage: x[2].to_f, current: x[3].to_f }
      end
    end

    def output
      installer = ""
      if ENV["SMA_INSTALLER"]
        installer = "-installer -password:#{shellescape ENV['SMA_INSTALLER']}"
      end
      @output ||= `#{shellescape(sbfpath)} -nosql -nocsv -loadlive -sp0 -finq -v #{installer}`.force_encoding("UTF-8")
    end

    def value(v)
      v.to_s.empty? ? "unkown" : v
    end

  end
end
