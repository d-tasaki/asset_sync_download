# AssetSyncDownload

Downloads asset files to Rails applications from a cloud storage, such as AWS S3 and AzureBlob, synchronized with AssetSync gem.

It enables you to distribute a manifest file and asset files to load-balanced redundant servers without commiting these files to your repository.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'asset_sync'
gem 'asset_sync_download'
```

AssetSyncDownload depends on AssetSync gem deeply.

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install asset_sync_download

## Usage

AssetSyncDownload supposes deployment operations as belows:

1. Run `assets:precompile` rake task on your local PC. You should configure AssetSync to upload a manifest file not only asset files.
2. Deploy rails application to servers. Do not start or restart them.
3. Run `assets:sync:download` rake task on the servers. It will download the manifest file and asset files.
4. Restart the rails applications.

### Rake Tasks

* `rake assets:sync:download:manifest` downloads manifest file.
* `rake assets:sync:download:asset_files` downloads all asset files on a cloud storage.
    * If you configure AssetSync as `config.manifest = true`, you get only asset files mentioned in the manifest file.

## Configuration

### AssetSyncDownload

AssetSync has no configurations, but it requires well-configured AssetSync such as `config.fog_provider`, `config.aws_access_key_id` and `config.aws_secret_access_key`.

### AssetSync

Configure **config/environments/production.rb** to use AWS S3 as below. (please refer to documents of AssetSync gem for more information.)

```ruby
if defined?(AssetSync)
  AssetSync.configure do |config|
    config.fog_provider = 'AWS'
    config.aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
    config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

    config.manifest = true
  end
end
```

`config.manifest` is an option which enables to use the manifest file to get the list of local files to upload. **AssetSyncDownload** also refers to the option to get the list of remote files to download.

To enable uploading a manifest file to a cloud storage, you should configure **AssetSync** with **config/initializers/asset_sync.rb** as below:

```ruby
if defined?(AssetSync)
  AssetSync.configure do |config|
    ...
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
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/devchick/asset_sync_download.


## Credits

Inspired by:

 - [AssetSync gem](https://github.com/AssetSync/asset_sync)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

