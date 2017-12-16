require "spec_helper"
require "fog/azurerm"
require "systemu"

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

def execute(app, command, options = {}, &block)
  app_path = File.expand_path("../../dummy_#{app}", __FILE__)
  Dir.chdir app_path
  systemu(command, options, &block)
end

def find_manifest_files(app, prefix)
  manifests  = Dir.glob(File.expand_path("../../dummy_#{app}/public/#{prefix}/**/.*.json", __FILE__))
  manifests += Dir.glob(File.expand_path("../../dummy_#{app}/public/#{prefix}/**/*.json",  __FILE__))
end

def find_public_files(app, prefix)
  files  = Dir.glob(File.expand_path("../../dummy_#{app}/public/#{@prefix}/**/*",  __FILE__))
  files += Dir.glob(File.expand_path("../../dummy_#{app}/public/#{@prefix}/**/.*", __FILE__))
  files.reject! { |f| File.directory?(f) }
  files
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

  let(:expects_for_upload) do
    # should be override
    # { :exited => true or false
    #   :status => an Integer
    #   :out    => an String or Regexp
    #   :err    => an String or Regexp
    # }
    { :status => 0,
      :err    => "",
    }
  end

  let(:expects_for_download) do
    # should be override
    { :status => 0,
      :err    => "",
    }
  end

  let(:execute_upload) do
    @uploaded_status,   @uploaded_out,   @uploaded_err   = execute(:app1, "rake #{env_for_upload} assets:precompile")
  end

  let(:execute_download) do
    @downloaded_status, @downloaded_out, @downloaded_err = execute(:app2, "rake #{env_for_upload} #{rake_task_name_for_download}")
  end

  let(:shared_examples_for_upload) do
    status, out, err = @uploaded_status, @uploaded_out, @uploaded_err

    expects = expects_for_upload || {}
    expect(status.exited?).to    eq(expects[:exited]) if expects.has_key?(:exited)
    expect(status.exitstatus).to eq(expects[:status]) if expects.has_key?(:status)
    expect(out).to match(expects[:out]) if expects.has_key?(:out)
    expect(err).to match(expects[:err]) if expects.has_key?(:err)
  end

  let(:shared_examples_for_download) do
    status, out, err = @downloaded_status, @downloaded_out, @downloaded_err

    expects = expects_for_download || {}
    expect(status.exited?).to    eq(expects[:exited]) if expects.has_key?(:exited)
    expect(status.exitstatus).to eq(expects[:status]) if expects.has_key?(:status)
    expect(out).to match(expects[:out]) if expects.has_key?(:out)
    expect(err).to match(expects[:err]) if expects.has_key?(:err)
  end

  describe "assets:sync:download:manifest" do
    let(:rake_task_name_for_download) do
      "assets:sync:download:manifest"
    end

    context "with uploaded manifest file" do
      let(:env_for_upload) do
        # envronment variables to upload a manifest file
        "ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_INCLUDE_MANIFEST=true"
      end

      let(:env_for_download) do
        "ASSET_SYNC_PREFIX=#{@prefix}"
      end

      let(:expects_for_download) do
        { :exited => true }
      end

      it "downloads the manifest file only" do
        execute_upload
        execute_download
        shared_examples_for_download

        manifests = find_manifest_files(:app2, @prefix)
        expect(manifests.compact.uniq.size).to eq(1)

        assets = find_public_files(:app2, @prefix)
        assets.reject! { |f| f =~ /manifest.*\.json$/ }
        expect(assets.size).to eq(0)
      end
    end

    context "without uploaded manifest file" do
      let(:env_for_upload) do
        # envronment variables not to upload a manifest file
        "ASSET_SYNC_PREFIX=#{@prefix} ASSET_SYNC_INCLUDE_MANIFEST=false"
      end

      let(:env_for_download) do
        "ASSET_SYNC_PREFIX=#{@prefix}"
      end

      let(:expects_for_download) do
        { :status => 1,
          :err => /Could not find any manifests\. aborted\./,
        }
      end

      it "could not download any manifest files" do
        execute_upload
        execute_download
        shared_examples_for_download

        manifests = find_manifest_files(:app2, @prefix)
        expect(manifests.compact.uniq.size).to eq(0)

        assets = find_public_files(:app2, @prefix)
        assets.reject! { |f| f =~ /manifest.*\.json$/ }
        expect(assets.size).to eq(0)
      end
    end
  end

  describe "assets:sync:download:asset_files" do
    let(:rake_task_name_for_download) do
      "assets:sync:download:asset_files"
    end

    describe "without manifest file, with uploaded an extra file" do
      let(:env_for_upload) do
        # environment variables not to upload a manifest file
        "ASSET_SYNC_PREFIX=#{@prefix}"
      end

      let(:env_for_download) do
        "ASSET_SYNC_PREFIX=#{@prefix}"
      end

      it "downloads the assets files and also the extra file" do
        # prepare an extra file
        execute :app1, "mkdir -p public/#{@prefix}"
        execute :app1, "echo 'extra file' > public/#{@prefix}/extra.js"

        execute_upload
        execute_download
        shared_examples_for_download

        assets = find_public_files(:app1, @prefix)
        expect(assets.size).to eq(4) # ie. manifest, application.js, application.js.gz, extra.js

        # there is no manifest files
        manifests = find_manifest_files(:app2, @prefix)
        expect(manifests.compact.uniq.size).to eq(0)

        # there are files except a manifest file
        assets.each do |f|
          if f =~ /manifest.*\.json$/
            expect(File.exists?(f.sub("dummy_app1", "dummy_app2"))).to eq(false)
          else
            expect(File.exists?(f.sub("dummy_app1", "dummy_app2"))).to eq(true)
          end
        end
      end
    end
  end

end
