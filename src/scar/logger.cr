module Scar
  # A Logging Helper.
  #
  # Every method in this module outputs the given message to stdout while appending the prefix of `[&lt;method name&gt;]`
  #
  # `Logger#fatal` indicates a fatal error, therefore it raises.
  class Logger
    def self.info(msg)
      puts "[info]  #{msg}"
    end

    def self.warn(msg)
      puts "[warn]  #{msg}"
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
