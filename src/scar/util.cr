module Scar
  module Util
    extend self

    # :nodoc:
    USER_DIR = {% if flag?(:windows) %}ENV["appdata"]{% else %}"#{ENV["HOME"]}/.local/share"{% end %}
    @@dir : String = File.join(USER_DIR, "scar")

    # Sets the subdirectory to write files to
    #
    # The given path is appended to the user directory:
    # - On windows: `%appdata%\&lt;dir&gt;\`
    # - On linux: `~/.local/share/&lt;dir&gt;/`
    #
    # It is recommended to set your own subfolder via this method before writing to or reading from any files to avoid conficts.
    def dir=(dir : String)
      @@dir = File.join(USER_DIR, dir)
    end

    # Writes a `String` to given filename in the specified directory
    def write_file(name : String, content : String)
      Dir.mkdir_p(@@dir)
      fname = File.join(@@dir, name)
      File.touch(fname) if !File.exists?(fname)
      if File.writable?(fname)
        File.write(fname, content)
      else
        Logger.error "Could not write to file #{fname}"
      end
    end

    # Same as write_file but content is `Bytes`
    def write_file_bytes(name : String, content : Bytes)
      Dir.mkdir_p(@@dir)
      fname = File.join(@@dir, name)
      File.touch(fname) if !File.exists?(fname)
      if File.writable?(fname)
        File.write(fname, content)
      else
        Logger.error "Could not write to file #{fname}"
      end
    end

    # Reads filename in the specified directory as a `String`
    def read_file(name : String)
      fname = File.join(@@dir, name)
      File.read(fname)
    end

    # Same as read_file but reads it as `Bytes`
    def read_file_bytes(name : String)
      fname = File.join(@@dir, name)
      f = File.open(fname, mode = "r")
      buffer = Bytes.new(f.size)
      f.read(buffer)
      f.close
      buffer
    end
  end # End class Util
end   # End module Scar
