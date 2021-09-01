require "compress/zip"
require "./tiled_map.cr"

# NOTE: Book: hint that music can be streamed from files
# TODO: Video (Playback)
# TODO: make extendable
# TODO: add Tilemaps as asset type

module Scar
  # This module provides a convenient interface for loading different kinds of assets
  # Usage:
  # 1. `Assets#use` a folder or zip file to index their contents
  # (1.5 Use `Assets#cache` (or `#cache_zipfile`) to preload assets into memory without instatiating the respective asset types)
  # 2. `Assets#load` (or `#load_all`) the assets you want to use in you application
  # 3. Use `Assets#[]` to retrieve the loaded instances of your assets
  #
  # ## Hot reloading
  #
  # The Assets module supports hot reloading of certain asset types.
  # You can specify a block when retrieving assets, this block will get called
  # when a change is detected.
  # You can enable hot-reloading by setting App#hotreload to true.
  # Hot-reloading only works if you are loading assets from plain files (not zipped) without caching them.
  module Assets
    extend self

    class_property :default_font

    alias Text = String
    alias Texture = SF::Texture
    alias Sound = SF::SoundBuffer
    alias Music = SF::Music
    alias Font = SF::Font
    alias Yaml = YAML::Any
    alias Json = JSON::Any
    alias Tilemap = Scar::Tiled::Map

    ASSET_TYPES = ["String", "SF::Texture", "SF::SoundBuffer", "SF::Music", "SF::Font", "YAML::Any", "JSON::Any", "Scar::Tiled::Map"]
    alias Asset = Text | Texture | Sound | Music | Font | Yaml | Json | Tilemap

    KNOWN_EXTENSIONS = /\.(txt|png|wav|ogg|ttf)$/

    @@dir_index : Hash(String, String) = Hash(String, String).new
    @@zip_index : Hash(String, String) = Hash(String, String).new

    @@cache : Hash(String, IO::Memory) = Hash(String, IO::Memory).new

    # Used to store references to currently loaded assets
    @@loaded : Hash(String, Asset) = Hash(String, Asset).new

    @@hotreloadable : Set(String) = Set(String).new
    @@hotreloadfunctions : Hash(String, Array(Asset ->)) = Hash(String, Array(Asset ->)).new
    @@hotreloadtimes : Hash(String, Time) = Hash(String, Time).new

    # Define this to automatically choose the font when creating e.g. text components
    @@default_font : Font?

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
      Compress::Zip::File.open(zip_fname) do |zfile|
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
        Compress::Zip::File.open(file_or_folder_name) do |zfile|
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
    # for it to be accesible more quickly!
    def cache(name : String)
      raise "no asset named #{name} was indexed!" if !@@zip_index[name]? && !@@dir_index[name]?
      fname = @@zip_index[name]? ? @@zip_index[name] : @@dir_index[name]
      @@cache[name] = @@zip_index[name]? ? read_zip_entry_into_memory(name, fname) : read_into_memory(fname)
    end

    # Indexes a zip file and caches all contents of it. Use this to preload all assets in the file at once without reading each file on its own.
    def cache_zipfile(fname : String)
      use(fname)
      Compress::Zip::Reader.open(fname) do |reader|
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
    # Implicitly caches data from zip files because Assets cannot be created from zip entries (this is not recommended, cache the zipfile first!).
    # Loads from indexed zip file entries before indexed folders!
    def load(name : String, asset_type : T.class) forall T
      if @@hotreloadable.includes?(name)
        asset = @@loaded[name]
        if asset.is_a? Texture | Sound | Music | Font
          fname = @@dir_index[name]
          asset.load_from_file fname if asset.is_a? Texture | Sound | Font
          asset.open_from_file fname if asset.is_a? Music

          @@hotreloadfunctions[name].each(&.call(asset))
          return
        end
      end

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
                # Note to devs: yes, we need if/elsif here because case/when does not work somehow
                if asset_type == Text
                  String.new data
                elsif asset_type == Texture
                  SF::Texture.from_memory data
                elsif asset_type == Sound
                  SF::SoundBuffer.from_memory data
                elsif asset_type == Music
                  SF::Music.from_memory data
                elsif asset_type == Font
                  SF::Font.from_memory data
                elsif asset_type == Yaml
                  YAML.parse(String.new data)
                elsif asset_type == Json
                  JSON.parse(String.new data)
                elsif asset_type == Tilemap
                  Tilemap.from_json(String.new data)
                end
              else
                if asset_type == Text
                  File.read fname
                elsif asset_type == Texture
                  SF::Texture.from_file fname
                elsif asset_type == Sound
                  SF::SoundBuffer.from_file fname
                elsif asset_type == Music
                  SF::Music.from_file fname
                elsif asset_type == Font
                  SF::Font.from_file fname
                elsif asset_type == Yaml
                  YAML.parse(File.read fname)
                elsif asset_type == Json
                  JSON.parse(File.read fname)
                elsif asset_type == Tilemap
                  Tilemap.from_json(File.read fname)
                end
              end

      if asset.is_a? T && asset.is_a? Asset
        @@loaded[name] = asset
        if @@hotreloadable.includes?(name)
          @@hotreloadfunctions[name].each(&.call(asset))
        else
          @@hotreloadable.add(name)
          @@hotreloadfunctions[name] = [] of Asset ->
          @@hotreloadtimes[name] = File.info(fname).modification_time
        end
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
    # ".yml", ".yaml" and ".json" are not loaded because these extensions are ambigous
    def load(name : String)
      ex = /.+(\.[a-zA-Z]+)$/.match name
      if ex
        case ex[ex.size - 1]
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
        else
          raise "Unknown or ambigous file extension #{ex[ex.size - 1]}!"
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

    # Unloads (destroys) an loaded Asset. Caution with assets like Textures or SoundBuffers, they could be referenced by Sprites or Sounds!
    def unload(name : String)
      a = @@loaded[name]
      a.stop if a.responds_to?(:stop)
      a.finalize if a.responds_to?(:finalize)
      @@loaded.delete name
      @@hotreloadable.delete name
      @@hotreloadfunctions.delete name
    end

    # Unloads all loaded Assets.
    def unload_all
      @@sounds.each(&.finalize)
      @@loaded.keys.each { |k| unload k }
    end

    @@hotreload_timer = 0.0

    # :nodoc:
    def check_hotreload(dt = 1.0)
      @@hotreload_timer += dt
      return if @@hotreload_timer < 0.5
      @@hotreload_timer = 0

      @@hotreloadable.each do |name|
        new_time = File.info(@@dir_index[name]).modification_time
        if new_time != @@hotreloadtimes[name]
          @@hotreloadtimes[name] = new_time
          {% for t in ASSET_TYPES %}
          load(name, {{ t.id }}) if @@loaded[name].is_a? {{ t.id }}
          {% end %}
        end
      end
    end

    # Fetches an loaded asset. Use asset_type to specify the return type.
    # Specify on_reload to execute some code when the asset is modified on disk (see hot-reloading)
    def [](name : String, asset_type : T.class, on_reload : (Asset -> Nil) | Nil = nil) : T forall T
      asset = @@loaded[name]?
      Logger.fatal "No Asset named #{name} was loaded!" if asset == nil
      if asset.is_a? T && asset.is_a? Asset
        @@hotreloadfunctions[name] << on_reload unless on_reload.nil?
        asset
      else
        raise "Incompatible Asset Type #{T}!"
      end
    end

    {% for kind in [:Text, :Texture, :Music, :Font, :Yaml, :Json, :Tilemap] %}
      # Fetches a loaded {{kind}} asset.
      def {{kind.id.downcase}}(name) : {{kind.id}}
        self[name, {{kind.id}}]
      end

      # Fetches a loaded {{kind}} asset.
      # Add a block to execute some code when the asset is modified on disk (see hot-reloading)
      def {{kind.id.downcase}}(name, &block : Asset->Nil) : {{kind.id}}
        self[name, {{kind.id}}, block]
      end
    {% end %}

    # Keeps track of created SF::Sound instances so they can get unloaded properly.
    @@sounds : Array(SF::Sound) = Array(SF::Sound).new

    # Creates a SF::Sound from a loaded Sound asset.
    # This is necessary because SF::Sound has to get finalized explicitly.
    def sound(name) : SF::Sound
      buffer = self[name, Sound]
      s = SF::Sound.new(buffer)
      @@sounds << s
      s
    end
  end # End module Assets
end   # End module Scar
