module Scar
  # A Logging Helper
  # All methods put messages prefixed with `[<method name>] `
  class Logger
    def self.info(msg)
      puts "[info] #{msg}"
    end

    def self.warn(msg)
      puts "[warn] #{msg}"
    end

    def self.debug(msg)
      puts "[debug] #{msg}"
    end

    def self.error(msg)
      puts "[error] #{msg}"
    end

    def self.fatal(msg)
      raise "[fatal] #{msg}"
    end
  end
end
