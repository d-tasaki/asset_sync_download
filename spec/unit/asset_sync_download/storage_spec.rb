require 'spec_helper'

describe AssetSyncDownload::Storage do
  include_context "mock Rails without_yml"

  describe '#download_manifest' do
    before(:each) do
      @remote_files = ["assets/javascript1.js", "assets/.sprockets-manifest-d7e39800c56569d1b7364078de1b7069.json"]
      allow(storage).to receive_messages(:get_remote_files => @remote_files, :path => "tmp", :bucket => double('bucket.files'))
      allow(storage.bucket).to receive(:files).and_return(double('bucket.files'))
      allow(storage.bucket.files).to receive(:get).and_return(double('buecket.files.get'))
      allow(storage.bucket.files.get).to receive_messages(:content_lendth => 12345, :body => manifest_json)
    end

    let(:storage) do
      AssetSync.storage
    end

    let(:manifest_json) do
      { :files => {
          "javascript1-63390acca29373bd01af81294376cb8602ff12cddd97c33b0e9c08ee5b65b828.js" => {
            :logical_path => "javascript1.js",
            :mtime => "2017-12-13T14:15:16+09:00",
            :size  => 12345,
            :digest => "63390acca29373bd01af81294376cb8602ff12cddd97c33b0e9c08ee5b65b828",
            :itegrity => "sha256-PazZKzv67B2AYqfogcI3g7H+tkIwm2SajDvBPlcmGIc=",
          }
        },
        :assets => {
          "javascript1.js" => "javascript1-63390acca29373bd01af81294376cb8602ff12cddd97c33b0e9c08ee5b65b828.js"
        }
      }.to_json
    end

    it 'should download the manifest file' do
      expect do
        AssetSyncDownload.storage.download_manifest
      end.not_to raise_error
    end
  end

end
