require 'spare_keys'

describe SpareKeys, '#use_keychain' do

  before(:context) do
    require 'tempfile'
    @example_keychain = Dir::Tmpname.make_tmpname(['spare-keys-spec-', '.keychain'], nil)
    `security create-keychain -p "" #{@example_keychain}`
  end

  after(:context) do
    `security delete-keychain #{@example_keychain}`
  end

  def capture_keychain(type)
    `security #{type}-keychain | xargs`
  end

  def capture_keychain_list
    `security list-keychains | xargs`
  end

  context "when block is supplied" do
    before do
      @default_before_block = capture_keychain("default")
      @list_before_block = capture_keychain_list
      @list_in_block = nil

      SpareKeys.use_keychain @example_keychain do
        @default_in_block = capture_keychain("default")
        @list_in_block = capture_keychain_list
      end
      @list_after_block = capture_keychain_list
    end

    it "should not change the default keychain" do
      expect(@list_in_block).to include(@example_keychain)
    end

    it "should add the keychain to the list for the duration of the block" do
      expect(@list_in_block).to include(@example_keychain)
    end

    it "should revert the keychain list after the block" do
      expect(@list_after_block).not_to include(@example_keychain)
    end
  end

  context "when block throws an error" do
    before do
      @list_before_block = capture_keychain_list
      @list_in_block = nil

      begin
        SpareKeys.use_keychain @example_keychain do
          raise "Awesome"
        end
      rescue
      end
      @list_after_block = capture_keychain_list
    end

    it "should still revert the keychain list after the block" do
      expect(@list_after_block).not_to include(@example_keychain)
    end
  end

  context "when clear_list is true" do
    before do
      @list_before_block = capture_keychain_list
      @list_in_block = nil

      SpareKeys.use_keychain @example_keychain, true do
        @list_in_block = capture_keychain_list
      end
      @list_after_block = capture_keychain_list
    end

    it "should remove other keychain entries for the duration of the block" do
        expect(@list_in_block).not_to include("login.keychain")
    end

    it "should revert the keychain list after the block" do
      expect(@list_after_block).to eql(@list_before_block)
    end
  end

  context "when type is specified" do
    before do
      @default_before_block = capture_keychain("default")
      SpareKeys.use_keychain @example_keychain, false, "default" do
        @default_in_block = capture_keychain("default")
      end
      @default_after_block = capture_keychain("default")
    end

    it "should change the keychain for the duration of the block" do
        expect(@default_in_block).to include(@example_keychain)
        expect(@default_in_block).not_to eql(@default_before_block)
    end

    it "should revert the keychain after the block" do
      expect(@default_after_block).to eql(@default_before_block)
    end
  end

  context "when type is not supplied" do
    before do
      @default_before_block = capture_keychain("default")
      SpareKeys.use_keychain @example_keychain do
        @default_in_block = capture_keychain("default")
      end
    end

    it "should not change the default keychain" do
      expect(@default_in_block).to eql(@default_before_block)
    end
  end
end

describe SpareKeys, '#temp_keychain' do

  def capture_keychain_list
    `security list-keychains | xargs`
  end

  context "when block is supplied" do

    before do
      @list_before_block = capture_keychain_list
      SpareKeys.temp_keychain true do |tmp|
        @list_in_block = capture_keychain_list
        @temp_keychain = tmp
      end
      @list_after_block = capture_keychain_list
    end 

    it "supplies the keychain path to the block" do
      expect(@temp_keychain).not_to be_empty
      expect(@list_in_block).to include(@temp_keychain)
    end

    it "should revert the keychain list after the block" do
      expect(@list_after_block).to eql(@list_before_block)
    end

  end

end