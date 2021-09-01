require "compress/zip"
require "./tiled_map.cr"

# NOTE: Book: hint that music can be streamed from files
# TODO: Video (Playback)
# TODO: make extendable

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
  # The asset types that are reloaded automatically are: Texture, Sound, Music, Font
  # Tilemap components can also automatically reload their data if you use their String constructor
  # You can specify a block when retrieving assets, this block will get called
  # when a change is detected. This works for all asset types.
  # You can enable hot-reloading by setting App#hotreload to true.
  # Hot-reloading only works if you are loading assets from plain files (not zipped) without caching them.
  module Assets
    extend self

    class_property :default_font

    ASSET_TYPES = {
      "Text":    "String",
      "Texture": "SF::Texture",
      "Sound":   "SF::SoundBuffer",
      "Music":   "SF::Music",
      "Font":    "SF::Font",
      "Yaml":    "YAML::Any",
      "Json":    "JSON::Any",
      "Tilemap": "Scar::Tiled::Map",
    }
    KNOWN_EXTENSIONS = /\.(txt|png|wav|ogg|ttf)$/

    {% for k, v in ASSET_TYPES %}
      alias {{ k.id }} = {{ v.id }}
    {% end %}

    {% begin %}
      alias Asset = {{ ASSET_TYPES.keys.join(" | ").id }}
    {% end %}

    @@dir_index : Hash(String, String) = Hash(String, String).new
    @@zip_index : Hash(String, String) = Hash(String, String).new

    @@cache : Hash(String, IO::Memory) = Hash(String, IO::Memory).new

    {% for t in ASSET_TYPES.keys %}
      # Used to store references to currently loaded assets
      @@loaded_{{ t.id }} : Hash(String, {{ t.id }}) = Hash(String, {{ t.id }}).new

      class HotreloadData{{ t.id }}
        property listeners : Array({{ t.id }}->)
        property timestamp : Time

        def initialize(@timestamp)
          @listeners = Array({{ t.id }}->).new
        end
      end

      # Used to store timestamps and listener functions for hot-reloading
      @@hotreload_{{ t.id }} : Hash(String, HotreloadData{{ t.id }}) = Hash(String, HotreloadData{{ t.id }}).new
    {% end %}

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

    {% for t in ASSET_TYPES.keys %}
      # Loads an Asset. See details.
      # You must provide the correct Asset Type for it to work (Or use the guessing load function).
      # Accepted types are all that are listed in Assets::ASSET_TYPES.
      # Must be called before using the Asset.
      # Uses cached data if available.
      # Implicitly caches data from zip files because Assets cannot be created from zip entries (this is not recommended, cache the zipfile first!).
      # Loads from indexed zip file entries before indexed folders!
      def load(name : String, asset_type : {{ t.id }}.class)
        {% if ["Texture", "Sound", "Music", "Font"].map(&.id).includes? t %}
          if @@hotreload_{{ t.id }}.has_key?(name)
            asset = @@loaded_{{ t.id }}[name]
            fname = @@dir_index[name]
            {% if t == "Music" %}
              asset.open_from_file fname
            {% else %}
              asset.load_from_file fname
            {% end %}

            @@hotreload_{{ t.id }}[name].listeners.each(&.call(asset))
            return
          end
        {% end %}

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
                  {% if t == "Text" %}
                    String.new data
                  {% elsif t == "Texture" %}
                    SF::Texture.from_memory data
                  {% elsif t == "Sound" %}
                    SF::SoundBuffer.from_memory data
                  {% elsif t == "Music" %}
                    SF::Music.from_memory data
                  {% elsif t == "Font" %}
                    SF::Font.from_memory data
                  {% elsif t == "Yaml" %}
                    YAML.parse(String.new data)
                  {% elsif t == "Json" %}
                    JSON.parse(String.new data)
                  {% elsif t == "Tilemap" %}
                    Tilemap.from_json(String.new data)
                  {% end %}
                else
                  {% if t == "Text" %}
                    File.read fname
                  {% elsif t == "Texture" %}
                    SF::Texture.from_file fname
                  {% elsif t == "Sound" %}
                    SF::SoundBuffer.from_file fname
                  {% elsif t == "Music" %}
                    SF::Music.from_file fname
                  {% elsif t == "Font" %}
                    SF::Font.from_file fname
                  {% elsif t == "Yaml" %}
                    YAML.parse(File.read fname)
                  {% elsif t == "Json" %}
                    JSON.parse(File.read fname)
                  {% elsif t == "Tilemap" %}
                    Tilemap.from_json(File.read fname)
                  {% end %}
                end

        @@loaded_{{ t.id }}[name] = asset
        if @@hotreload_{{ t.id }}.has_key?(name)
          @@hotreload_{{ t.id }}[name].listeners.each(&.call(asset))
        else
          @@hotreload_{{ t.id }}[name] = HotreloadData{{ t.id }}.new(File.info(fname).modification_time)
        end
      end

    {% end %}

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

    {% for t in ASSET_TYPES.keys %}
      private def unload_{{ t.id }}(name)
        asset = @@loaded_{{ t.id }}[name]
        asset.stop if asset.responds_to?(:stop)
        asset.finalize if asset.responds_to?(:finalize)
        @@loaded_{{ t.id }}.delete name
        @@hotreload_{{ t.id }}.delete name
      end
    {% end %}

    # Unloads (destroys) an loaded Asset. Caution with assets like Textures or SoundBuffers, they could be referenced by Sprites or Sounds!
    def unload(name : String)
      {% for t in ASSET_TYPES.keys %}
        if @@loaded_{{ t.id }}.has_key? name
          unload_{{ t.id }} name
          return
        end
      {% end %}
    end

    # Unloads all loaded Assets.
    def unload_all
      {% for t in ASSET_TYPES.keys %}
        @@loaded_{{ t.id }}.keys.each { |k| unload_{{ t.id }} k }
      {% end %}
    end

    @@hotreload_timer = 0.0

    # :nodoc:
    def check_hotreload(dt = 1.0)
      @@hotreload_timer += dt
      return if @@hotreload_timer < 0.5
      @@hotreload_timer = 0

      {% for t in ASSET_TYPES.keys %}
        @@hotreload_{{ t.id }}.each do |name, data|
          new_time = File.info(@@dir_index[name]).modification_time
          if new_time != data.timestamp
            data.timestamp = new_time
            load(name, {{ t.id }})
          end
        end
      {% end %}
    end

    {% for t in ASSET_TYPES.keys %}
      # Fetches an loaded asset.
      # You have to specify the type of the asset type,
      # or use the more specific functions.
      # Specify on_reload to execute some code when the asset is modified on disk (see hot-reloading)
      def []?(name : String, asset_type : {{ t.id }}.class, on_reload : ({{ t.id }}->) | Nil = nil) : {{ t.id }}?
        asset = @@loaded_{{ t.id }}[name]?
        return nil if asset.nil?
        @@hotreload_{{ t.id }}[name].listeners << on_reload unless on_reload.nil?

        asset
      end

      # :ditto:
      def [](name : String, asset_type : {{ t.id }}.class, on_reload : ({{ t.id }}->) | Nil = nil) : {{ t.id }}
        asset = self[name, asset_type, on_reload]?
        Logger.fatal "No Asset named #{name} was loaded!" if asset.nil?
        asset
      end

      # Same as #[], but with a block argument
      def [](name : String, asset_type : {{ t.id }}.class, &block : ({{ t.id }}->)) : {{ t.id }}
        self[name, {{ t.id }}, block]
      end

      # :ditto:
      def []?(name : String, asset_type : {{ t.id }}.class, &block : ({{ t.id }}->)) : {{ t.id }}?
        self[name, {{ t.id }}, block]?
      end

      # Fetches a loaded {{ t }} asset.
      def {{ t.id.downcase }}(name) : {{ t.id }}
        self[name, {{ t.id }}]
      end

      # :ditto
      def {{ t.id.downcase }}?(name) : {{ t.id }}?
        self[name, {{ t.id }}]?
      end

      # Fetches a loaded {{ t }} asset.
      # Add a block to execute some code when the asset is modified on disk (see hot-reloading)
      def {{ t.id.downcase }}(name, &block : {{ t.id }}->) : {{ t.id }}
        self[name, {{ t.id }}, block]
      end

      # :ditto
      def {{ t.id.downcase }}?(name, &block : {{ t.id }}->) : {{ t.id }}?
        self[name, {{ t.id }}, block]?
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
