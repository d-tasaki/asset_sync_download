require "spec_helper"

RSpec.describe AssetSyncDownload do
  it "has a version number" do
    expect(AssetSyncDownload::VERSION).not_to be nil
  end
end
