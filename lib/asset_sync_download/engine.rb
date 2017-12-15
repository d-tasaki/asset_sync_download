module AssetSyncDownload
  class Engine < Rails::Engine

    engine_name "asset_sync_download"

    initializer "asset_sync_download config", :group => :all do |app|
    end

  end
end
