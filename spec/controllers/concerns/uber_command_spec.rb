require "uber_command"

describe UberCommand do
  let(:command) { UberCommand.new("", 1, "") }

  describe "#run" do
    it "parses commands" do
      expect(command).to receive(:estimate).with("160 spear street to 150 spear street")
      command.run("estimate 160 Spear Street to 150 Spear Street")
    end

    it "reports unparseable commands" do
      expect(command.run("")).to eq(UNKNOWN_COMMAND_ERROR)
    end

    it "reports invalid commands" do
      expect(command.run("demand free rides")).to eq(UNKNOWN_COMMAND_ERROR)
    end
  end
end
