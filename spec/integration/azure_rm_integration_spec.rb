require "spec_helper"
require "fog/azurerm"

def bucket(name)
  options = {
    :provider => 'AzureRM',
    :azure_storage_account_name => ENV['AZURE_STORAGE_ACCOUNT_NAME'],
    :azure_storage_access_key => ENV['AZURE_STORAGE_ACCESS_KEY']
  }
  options.merge!({ :environment => ENV['FOG_REGION'] }) if ENV.has_key?('FOG_REGION')

  connection = Fog::Storage.new(options)
  connection.directories.get(ENV['FOG_DIRECTORY'], :prefix => name)
end

def execute(command, app)
  app_path = File.expand_path("../../dummy_#{app}", __FILE__)
  Dir.chdir app_path
  `#{command}`
end

describe "AssetSyncDownload" do
  before(:each) do
    @prefix = SecureRandom.hex(6)
  end
  
  after(:each) do
    @directory = bucket(@prefix)
    @directory.files.each do |f|
      f.destroy
    end
  end

  it "assets:sync:download:manifest" do
    expect do
      execute "rake ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_MANIFEST=true ASSET_SYNC_INCLUDE_MANIFEST=true assets:precompile", :app1
      execute "rake ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_MANIFEST=true assets:sync:download:manifest", :app2
    end.not_to raise_error

    manifests  = Dir.glob(File.expand_path("../../dummy_app2/public/#{@prefix}/**/.*.json", __FILE__))
    manifests += Dir.glob(File.expand_path("../../dummy_app2/public/#{@prefix}/**/*.json",  __FILE__))
    expect(manifests.compact.uniq.size).to eq(1)

    assets = Dir.glob(File.expand_path("../../dummy_app2/public/#{@prefix}/**/*", __FILE__))
    assets.reject! { |f| f =~ /manifest.*\.json$/ }
    expect(assets.size).to eq(0)
  end

  it "assets:sync:download:asset_files" do
    expect do
      execute "rake ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_INCLUDE_MANIFEST=true assets:precompile", :app1
      execute "rake ASSET_SYNC_PREFIX=#{@prefix} assets:sync:download:asset_files", :app2
    end.not_to raise_error

    assets = Dir.glob(File.expand_path("../../dummy_app1/public/#{@prefix}/**/*", __FILE__))
    expect(assets.size).to be > 0

    assets.each do |f|
      expect(File.exists?(f.sub("dummy_app1", "dummy_app2"))).to eq(true)
    end
  end

end
