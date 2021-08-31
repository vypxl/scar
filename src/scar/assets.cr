require "compress/zip"

# NOTE: Book: hint that music can be streamed from files
# TODO: Video (Playback)
# TODO: make extendable
# TODO: add Tilemaps as asset type

module Scar
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

    alias Asset = Text | Texture | Sound | Music | Font | Yaml | Json | Tilemap

    KNOWN_EXTENSIONS = /\.(txt|png|wav|ogg|ttf)$/

    @@dir_index : Hash(String, String) = Hash(String, String).new
    @@zip_index : Hash(String, String) = Hash(String, String).new

    @@cache : Hash(String, IO::Memory) = Hash(String, IO::Memory).new

    # Used to store references to currently loaded assets
    @@loaded : Hash(String, Asset) = Hash(String, Asset).new

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
    end

    # Unloads all loaded Assets.
    def unload_all
      @@sounds.each(&.finalize)
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

    # Fetches a loaded Text asset.
    def text(name) : Text
      self[name, Text]
    end

    # Fetches a loaded Texture asset.
    def texture(name) : Texture
      self[name, Texture]
    end

    # Fetches a loaded Music asset.
    def music(name) : Music
      self[name, Music]
    end

    # Fetches a loaded Font asset.
    def font(name) : Font
      self[name, Font]
    end

    # Fetches a loaded Yaml asset.
    def yaml(name) : Yaml
      self[name, Yaml]
    end

    # Fetches a loaded Json asset.
    def json(name) : Json
      self[name, Json]
    end

    # Fetches a loaded Tilemap asset.
    def tilemap(name) : Tilemap
      self[name, Tilemap]
    end

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
