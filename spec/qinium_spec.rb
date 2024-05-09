RSpec.describe Qinium do
  let(:config) { Qinium::Config.new(access_key: "masked-access-key") }
  let(:bucket) { :baklib }

  around(:each) do |example|
    VCR.use_cassette("access_key", &example)
  end

  context "Config" do
    it { expect(config.protocol).to eq :https }
    it { expect(config.uc_host).to eq "https://uc.qbox.me" }
    it { expect(config.up_host(bucket)).to eq "https://up-z2.qbox.me" }
    it { expect(config.public).to be_truthy }
  end

  context "HostManager" do
    subject(:manager) { Qinium::HostManager.new(config) }

    let(:hosts) { manager.hosts(bucket) }

    it { expect(hosts).to have_key "http" }
    it { expect(hosts).to have_key "https" }

    it { expect(manager.up_host(bucket)).to eq "https://up-z2.qbox.me" }
    it { expect(manager.up_hosts(bucket)).to eq ["https://up-z2.qbox.me", "https://upload-z2.qbox.me"] }
  end
end
