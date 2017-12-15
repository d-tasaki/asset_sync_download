module AssetSyncDownload
  class Storage
    extend Forwardable

    def_delegator :storage, :bucket
    def_delegator :storage, :config
    def_delegator :storage, :get_remote_files
    def_delegator :storage, :log
    def_delegator :storage, :path

    def storage
      @storage ||= AssetSync.storage
    end

    def get_asset_files_from_manifest
      if storage.respond_to?(:get_asset_files_from_manifest)
        return storage.get_asset_files_from_manifest
      end

      if self.config.manifest
        if ActionView::Base.respond_to?(:assets_manifest)
          log "Using: Rails 4.0 manifest access"
          manifest = Sprockets::Manifest.new(ActionView::Base.assets_manifest.environment, ActionView::Base.assets_manifest.dir)
          return manifest.assets.values.map { |f| File.join(self.config.assets_prefix, f) }
        elsif File.exist?(self.config.manifest_path)
          log "Using: Manifest #{self.config.manifest_path}"
          yml = YAML.load(IO.read(self.config.manifest_path))

          return yml.map do |original, compiled|
            # Upload font originals and compiled
            if original =~ /^.+(eot|svg|ttf|woff)$/
              [original, compiled]
            else
              compiled
            end
          end.flatten.map { |f| File.join(self.config.assets_prefix, f) }.uniq!
        else
          log "Warning: Manifest could not be found"
        end
      end
    end

    def download_manifest
      return unless defined?(Sprockets::ManifestUtils)

      files = get_remote_files
      manifest_key   = files.find { |f| File.basename(f) =~ Sprockets::ManifestUtils::MANIFEST_RE }
      manifest_key ||= files.find { |f| File.basename(f) =~ Sprockets::ManifestUtils::LEGACY_MANIFEST_RE }
      raise "Could not find any manifests. aborted." if manifest_key.nil?

      manifest = bucket.files.get(manifest_key)
      log "Downloaded: #{manifest_key} (#{manifest.content_length} Bytes)"

      manifest_path = File.join(path, manifest_key)
      local_dir = File.dirname(manifest_path)
      FileUtils.mkdir_p(local_dir) unless File.directory?(local_dir)
      File.open(manifest_path, "wb") { |f| f.write(manifest.body) }
    end

    def download_asset_files
      asset_paths = get_asset_files_from_manifest
      if asset_paths.nil?
        log "Using: Remote Directory Search"
        asset_paths = get_remote_files
      end

      asset_paths.each do |asset_path|
        local_path = File.join(path, asset_path)
        if File.exists?(local_path)
          log "Skipped: #{asset_path}"
          next
        end

        file = bucket.files.get(asset_path)
        log "Downloaded: #{asset_path} (#{file.content_length} Bytes)"
        local_dir = File.dirname(local_path)
        FileUtils.mkdir_p(local_dir) unless File.directory?(local_dir)
        File.open(local_path, "wb") { |f| f.write(file.body) }
      end
    end

    def download(target = :asset_files)
      log "AssetSync: Downloading #{target}."
      case target
      when :manifest
        download_manifest
      when :asset_files
        download_asset_files
      else
        raise "Unknown target specified: #{target}. It must be :manifest or :asset_files."
      end
      log "AssetSync: Done."
    end
  end
end
