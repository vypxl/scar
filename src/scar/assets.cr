require "compress/zip"
require "./tiled_map.cr"

# TODO: Video (Playback)
# TODO: make extendable
# TODO: add more string constructors like in Components::Tilemap

# This module provides a convenient interface for loading different kinds of assets
# Usage:
# 1. `#use` a folder or zip file to index their contents
# 2. (optional) Use `#cache` (or `#cache_zipfile`) to preload assets into memory without instatiating the respective asset types
# 3. `#load` (or `#load_all`) the assets you want to use in your application
# 4. Use `#[]` or the more specific methods like `#text` to retrieve the loaded instances of your assets
#
# Loading the assets should be done in bulk at the start of the application or while a loading screen is shown,
# so that there are no mid-gameplay slowdowns
#
# ### Music and Sound
#
# Music and sound are somewhat special kinds of assets. It is recommended to use the `Music`
# and the `Sound` (coming soon) module to handle them. See the respective documentation for details.
#
# ### Hot reloading
#
# The `Assets` module supports hot reloading of certain asset types.
#
# The asset types that are reloaded automatically are: `Texture`, `Sound`, `Music`, `Font`
#
# `Components::Tilemap` components can also automatically reload their data if you use their `String` constructor (`Components::Tilemap#new(String)`)
#
# You can specify a block when retrieving assets, this block will get called
# when a change is detected. This works for all asset types.
#
# To enable hot-reloading, set `App#hotreload` to `true`.
# Hot-reloading only works if you are loading assets from plain files (not zipped) without caching them.
#
# ### Exampe usage:
# ```
# Scar::Assets.use "./assets"
# Scar::Assets.load "textures/player.png"
#
# tex = Scar::Assets.texture("textures/player.png") { |new_tex| puts "Player texture was modified" }
# playerSprite = Scar::Components::Sprite.new tex
# ```
module Scar::Assets
  extend self

  # :nodoc:
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
  # :nodoc:
  KNOWN_EXTENSIONS = /\.(txt|png|wav|ogg|ttf)$/

  {% for k, v in ASSET_TYPES %}
    alias {{ k.id }} = {{ v.id }}
  {% end %}

  {% begin %}
    # This Union contains all valid asset types.
    #
    # Instead of using the real class names, you can use the convenience aliases definend in `Assets`:
    {% for k, v in ASSET_TYPES %}
    # - {{ k.id }}: {{ v.id }}
    {% end %}
    #
    alias Asset = {{ ASSET_TYPES.keys.join(" | ").id }}
  {% end %}

  @@dir_index : Hash(String, String) = Hash(String, String).new
  @@zip_index : Hash(String, String) = Hash(String, String).new

  @@cache : Hash(String, IO::Memory) = Hash(String, IO::Memory).new

  {% for t in ASSET_TYPES.keys %}
    # Used to store references to currently loaded assets
    @@loaded_{{ t.id }} : Hash(String, {{ t.id }}) = Hash(String, {{ t.id }}).new

    private class HotreloadData{{ t.id }}
      property listeners : Array({{ t.id }}->)
      property timestamp : Time

      def initialize(@timestamp)
        @listeners = Array({{ t.id }}->).new
      end
    end

    # Used to store timestamps and listener functions for hot-reloading
    @@hotreload_{{ t.id }} : Hash(String, HotreloadData{{ t.id }}) = Hash(String, HotreloadData{{ t.id }}).new
  {% end %}

  # If you set this property, `Components::Text` components can be created without specifying a font. They will use this font as a default.
  #
  # Example usage:
  # ```
  # Assets.default_font = Assets.font "fonts/arial.ttf"
  # ```
  class_property default_font : Font? = nil

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

  # Indexes a folder or zip file containing assets
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

  # Loads an indexed assets' data into memory so it does not need to be loaded from the filesystem
  #
  # This method is for preloading; It **does not** load the asset, it only stores its raw data
  # in memory for it to be quickly accesible.
  def cache(name : String)
    raise "no asset named #{name} was indexed!" if !@@zip_index[name]? && !@@dir_index[name]?
    fname = @@zip_index[name]? ? @@zip_index[name] : @@dir_index[name]
    @@cache[name] = @@zip_index[name]? ? read_zip_entry_into_memory(name, fname) : read_into_memory(fname)
  end

  # Indexes a zip file and caches all its contents.
  #
  # You can use this to preload all assets in the file at once.
  def cache_zipfile(fname : String)
    use(fname)
    Compress::Zip::Reader.open(fname) do |reader|
      reader.each_entry do |entry|
        @@cache[entry.filename] = IO::Memory.new(entry.io.gets_to_end) if entry.file?
      end
    end
  end

  # Removes an assets' cache data
  def decache(name : String)
    @@cache.delete name
  end

  # The following method is only there for the docs generator, the actual implementation is in the macro below

  # Loads an Asset. See details
  #
  # You must provide the correct asset_type for this method to work (or you can use the guessing load function).
  #
  # Accepted types are all types of the `Asset` Union.
  # An asset must be loaded via this method before using it.
  # This method utilizes cached data if it is available.
  # Zip entries that are not cached are implicitly cached because Assets cannot be created directly from zip entries (this is not recommended, cache the zipfile first!).
  # Zip file entries take precedence over plain files.
  def load(name : String, asset_type)
    {% raise "Invalid asset type" %}
  end

  {% for t in ASSET_TYPES.keys %}
    # :nodoc:
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

  # Same as `#load`, but guesses the asset type based upon its file extension
  #
  # - ".txt" => Text
  # - ".png" => Texture
  # - ".wav" => Sound
  # - ".ogg" => Music
  # - ".ttf" => Font
  #
  # ".yml", ".yaml" and ".json" are not loaded because these extensions are ambigous.
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

  # Unloads (destroys) a loaded Asset
  #
  # Caution with assets like Textures or SoundBuffers, they could be referenced by Sprites or Sounds!
  def unload(name : String)
    {% for t in ASSET_TYPES.keys %}
      if @@loaded_{{ t.id }}.has_key? name
        unload_{{ t.id }} name
        return
      end
    {% end %}
  end

  # Unloads all loaded assets
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

  # The following methods are just there for the docs generator, the actual implementation is in the macro below

  # Fetches a loaded asset
  #
  # You have to specify the type of the asset type, or use the more specific functions.
  # Specify *on_reload* (type: `Proc(asset_type, Nil)`) to execute some code when the asset is modified on disk (see hot-reloading).
  #
  # Return type is *asset_type*.
  def [](name : String, asset_type, on_reload)
    {% raise "Invalid asset type" %}
  end

  # Fetches a loaded asset
  #
  # You have to specify the type of the asset type, or use the more specific functions.
  # Specify a block (type: `Proc(asset_type, Nil)`) to execute some code when the asset is modified on disk (see hot-reloading).
  #
  # Return type is *asset_type*.
  def [](name : String, asset_type, &block)
    {% raise "Invalid asset type" %}
  end

  # Same as `#[]`, but returns nil if *name* does not correspond to a loaded asset
  def []?(name : String, asset_type, on_reload)
    {% raise "Invalid asset type" %}
  end

  # :ditto:
  def []?(name : String, asset_type, &block)
    {% raise "Invalid asset type" %}
  end

  {% for t in ASSET_TYPES.keys %}
    # :nodoc:
    def []?(name : String, asset_type : {{ t.id }}.class, on_reload : ({{ t.id }}->) | Nil = nil) : {{ t.id }}?
      asset = @@loaded_{{ t.id }}[name]?
      return nil if asset.nil?
      @@hotreload_{{ t.id }}[name].listeners << on_reload unless on_reload.nil?

      asset
    end

    # :nodoc:
    def [](name : String, asset_type : {{ t.id }}.class, on_reload : ({{ t.id }}->) | Nil = nil) : {{ t.id }}
      asset = self[name, asset_type, on_reload]?
      Logger.fatal "No Asset named #{name} was loaded!" if asset.nil?
      asset
    end

    # :nodoc:
    def [](name : String, asset_type : {{ t.id }}.class, &block : ({{ t.id }}->)) : {{ t.id }}
      self[name, {{ t.id }}, block]
    end

    # :nodoc:
    def []?(name : String, asset_type : {{ t.id }}.class, &block : ({{ t.id }}->)) : {{ t.id }}?
      self[name, {{ t.id }}, block]?
    end

    # Same as `#[name, {{ t }}]`
    def {{ t.id.downcase }}(name) : {{ t.id }}
      self[name, {{ t.id }}]
    end

    # Same as `#[name, {{ t }}]?`
    def {{ t.id.downcase }}?(name) : {{ t.id }}?
      self[name, {{ t.id }}]?
    end

    # Same as `#[name, {{ t }}, block]`
    def {{ t.id.downcase }}(name, &block : {{ t.id }}->) : {{ t.id }}
      self[name, {{ t.id }}, block]
    end

    # Same as `#[name, {{ t }}, block]?`
    def {{ t.id.downcase }}?(name, &block : {{ t.id }}->) : {{ t.id }}?
      self[name, {{ t.id }}, block]?
    end
  {% end %}
end
