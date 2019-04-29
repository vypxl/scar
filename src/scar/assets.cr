require "zip"

# NOTE: Book: hint that music can be streamed from files
# TODO: Video (Playback)

module Scar
  module Assets
    extend self

    alias Text = String
    alias Texture = SF::Texture
    alias Sound = SF::Sound
    alias Music = SF::Music
    alias Font = SF::Font
    alias Yaml = YAML::Any
    alias Json = JSON::Any

    alias Asset = Text | Texture | Sound | Music | Font | Yaml | Json

    KNOWN_EXTENSIONS = /\.(txt|png|wav|ogg|ttf|yml|yaml|json)$/

    @@dir_index : Hash(String, String) = Hash(String, String).new
    @@zip_index : Hash(String, String) = Hash(String, String).new

    @@cache : Hash(String, IO::Memory) = Hash(String, IO::Memory).new

    # Used to store references to currently loaded assets
    @@loaded : Hash(String, Asset) = Hash(String, Asset).new

    # Indexes a folder recursively
    private def index_folder_recursive(path : String, base_path : String)
      Dir.cd path do
        Dir.entries(path).each do |entry|
          # exclude '.' and '..'
          unless /^(\.{1,2})$/ =~ entry
            exp = File.expand_path entry
            if File.directory?(exp)
              new_base_path = base_path == "" ? entry : "#{base_path}/#{entry}"
              index_folder_recursive(exp, new_base_path)
            else
              prefix = base_path == "" ? "" : "#{base_path}/"
              @@dir_index[prefix + entry] = exp
            end
          end
        end
      end
    end

    # Loads a file into a IO::Memory
    private def read_into_memory(fname : String)
      IO::Memory.new(File.read(fname))
    end

    # Loads a zip entry into a IO::Memory
    private def read_zip_entry_into_memory(entry_name : String, zip_fname : String)
      data = IO::Memory.new("")
      Zip::File.open(zip_fname) do |zfile|
        zfile[entry_name].open do |entry_data|
          data = IO::Memory.new(entry_data.gets_to_end)
        end
      end
      data
    end

    # Indexes a folder or zip file containing assets.
    def use(file_or_folder_name : String)
      if File.directory? file_or_folder_name
        index_folder_recursive(File.expand_path(file_or_folder_name), "")
      elsif File.exists? file_or_folder_name
        zip_file_path = File.expand_path file_or_folder_name
        Zip::File.open(file_or_folder_name) do |zfile|
          zfile.entries.each do |entry|
            fname = entry.filename
            @@zip_index[fname] = zip_file_path unless entry.dir?
          end
        end
      else
        Logger.error "Could not use resource location #{file_or_folder_name}!"
      end
    end

    # Loads an indexed assets data into memory so it is not loaded from the filesystem.
    # Only use this for preloading as it DOES NOT LOAD THE ASSET, it only stores the raw data
    # for it to be quicker accesible!
    def cache(name : String)
      raise "no asset named #{name} was indexed!" if !@@zip_index[name]? && !@@dir_index[name]?
      fname = @@zip_index[name]? ? @@zip_index[name] : @@dir_index[name]
      @@cache[name] = @@zip_index[name]? ? read_zip_entry_into_memory(name, fname) : read_into_memory(fname)
    end

    # Indexes a zip file and caches all contents of it. Use this to preload all assets in the file at once without reading each file on its own.
    def cache_zipfile(fname : String)
      use(fname)
      Zip::Reader.open(fname) do |reader|
        reader.each_entry do |entry|
          @@cache[entry.filename] = IO::Memory.new(entry.io.gets_to_end) if entry.file?
        end
      end
    end

    # Removes an assets data from the cache
    def decache(name : String)
      @@cache.delete name
    end

    # Loads an Asset. See details.
    # You must provide the correct Asset Type for it to work (Or use the guessing load function).
    # Accepted types are all in Alias Asset.
    # Must be called before using the Asset.
    # Uses cached data if available.
    # Implicitly caches data from zip files because Assets cannot be created from zip entries (this is not recommended).
    # Loads from indexed zip file entries before indexed folders!
    def load(name : String, asset_type : T.class) forall T
      raise "no asset named #{name} was indexed!" if !@@zip_index[name]? && !@@dir_index[name]?
      fname = @@zip_index[name]? ? @@zip_index[name] : @@dir_index[name]

      # Raise if not cached but in zip file
      if @@cache[name]? == nil && fname == @@zip_index[name]?
        raise "Cannot load single Asset '#{name}' from zip file #{fname}! You have to cache it first or use Assets#cache_zipfile."
      end

      mem = @@cache[name]?
      asset = if mem
                mem.rewind
                data = mem.to_slice
                if asset_type == Text
                  String.new data
                elsif asset_type == Texture
                  SF::Texture.from_memory data
                elsif asset_type == Sound
                  SF::Sound.new SF::SoundBuffer.from_memory data
                elsif asset_type == Music
                  SF::Music.from_memory data
                elsif asset_type == Font
                  SF::Font.from_memory data
                elsif asset_type == Yaml
                  YAML.parse(String.new data)
                elsif asset_type == Json
                  JSON.parse(String.new data)
                end
              else
                if asset_type == Text
                  File.read fname
                elsif asset_type == Texture
                  SF::Texture.from_file fname
                elsif asset_type == Sound
                  SF::Sound.new SF::SoundBuffer.from_file fname
                elsif asset_type == Music
                  SF::Music.from_file fname
                elsif asset_type == Font
                  SF::Font.from_file fname
                elsif asset_type == Yaml
                  YAML.parse(File.read fname)
                elsif asset_type == Json
                  JSON.parse(File.read fname)
                end
              end

      if asset.is_a? T && asset.is_a? Asset
        @@loaded[name] = asset
      else
        raise "Incompatible Asset Type #{T}!"
      end
    end

    # Same as load but guesses the type based upon file extension.
    # ".txt" => Text
    # ".png" => Texture
    # ".wav" => Sound
    # ".ogg" => Music
    # ".ttf" => Font
    # ".yml", ".yaml" => Yaml
    # ".json" => JSON
    def load(name : String)
      ex = /.+(\.[a-zA-Z]+)$/.match name
      if ex
        ed = case ex[ex.size - 1]
             when ".txt"
               load(name, Text)
             when ".png"
               load(name, Texture)
             when ".wav"
               load(name, Sound)
             when ".ogg"
               load(name, Music)
             when ".ttf"
               load(name, Font)
             when ".yml"
               load(name, Yaml)
             when ".yaml"
               load(name, Yaml)
             when ".json"
               load(name, Json)
             else
               raise "Unknown file extension #{ex[ex.size - 1]}!"
             end
      else
        Logger.fatal "No file extension to guess upon in #{name}!"
      end
    end

    # Loads all indexed assets in directories and all cached assets from zip files; both only if they have a known file extension
    def load_all
      @@dir_index.keys.each do |asset_name|
        load(asset_name) if asset_name =~ KNOWN_EXTENSIONS
      end

      @@zip_index.keys.each do |asset_name|
        load(asset_name) if @@cache[asset_name]? && asset_name =~ KNOWN_EXTENSIONS
      end
    end

    # Unloads (destroys) an loaded Asset.
    def unload(name : String)
      a = @@loaded[name]
      if a.is_a? Sound
        buffer = a.buffer
        buffer.finalize if buffer
      end
      a.finalize if a.responds_to?(:finalize)
      @@loaded.delete name
    end

    # Unloads all loaded Assets.
    def unload_all
      @@loaded.keys.each { |k| unload k }
    end

    # Fetches an loaded asset. Use asset_type to specify the return type.
    def [](name : String, asset_type : T.class) : T forall T
      asset = @@loaded[name]?
      Logger.fatal "No Asset named #{name} was loaded!" if asset == nil
      if asset.is_a? T && asset.is_a? Asset
        asset
      else
        raise "Incompatible Asset Type #{T}!"
      end
    end

    # Same as [] but guesses the Asset type based upon file extension.
    def [](name : String)
      ex = /.+(\.[a-zA-Z]+)$/.match name
      if ex
        ed = case ex[ex.size - 1]
             when ".txt"
               self[name, Text]
             when ".png"
               self[name, Texture]
             when ".wav"
               self[name, Sound]
             when ".ogg"
               self[name, Music]
             when ".ttf"
               self[name, Font]
             else
               raise "Unknown file extension #{ex[ex.size - 1]}!"
             end
      else
        raise "No file extension to guess upon in #{name}!"
      end
    end
  end # End module Assets
end   # End module Scar
