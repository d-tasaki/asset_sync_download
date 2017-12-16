if defined?(AssetSync)
  AssetSync.configure do |config|

    case ENV['FOG_PROVIDER']
    when 'AWS'
      config.fog_provider = 'AWS'
      config.aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
      config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    when 'Google'
      config.fog_provider = 'Google'
      config.google_storage_access_key_id     = ENV['GOOGLE_STORAGE_ACCESS_KEY_ID']
      config.google_storage_secret_access_key = ENV['GOOGLE_STORAGE_SECRET_ACCESS_KEY']
    when 'Rackspace'
      config.fog_provider = 'Rackspace'
      config.rackspace_username = ENV['RACKSPACE_USERNAME']
      config.rackspace_api_key  = ENV['RACKSPACE_API_KEY']
    when 'AzureRM'
      config.fog_provider = 'AzureRM'
      config.azure_storage_account_name = ENV['AZURE_STORAGE_ACCOUNT_NAME']
      config.azure_storage_access_key   = ENV['AZURE_STORAGE_ACCESS_KEY']
    end

    config.fog_directory = ENV['FOG_DIRECTORY']
    config.fog_region    = ENV['FOG_REGION']

    if ENV['ASSET_SYNC_INCLUDE_MANIFEST'] == "true"
      if config.respond_to?(:include_manifest)
        config.include_manifest = true
      else
        config.add_local_file_paths do
          if ActionView::Base.respond_to?(:assets_manifest)
            manifest = Sprockets::Manifest.new(ActionView::Base.assets_manifest.environment, ActionView::Base.assets_manifest.dir)
            manifest_path = manifest.filename
          else
            manifest_path = self.config.manifest_path
          end
          [manifest_path.sub(/^#{config.public_path}\//, "")] # full path to relative path
        end
      end
    end
  end
end
