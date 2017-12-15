class Rails::Railtie::Configuration
  def asset_sync_download
    AssetSyncDownload.config
  end
end
