require 'spare_keys'

describe SpareKeys, '#use_keychain' do

  before(:context) do
    require 'tempfile'
    @example_keychain = SpareKeys.temporary_keychain_name('spare-keys-spec')
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

  context "when clear_list is false" do
    before do
      @list_before_block = capture_keychain_list
      @list_in_block = nil
      
      SpareKeys.use_keychain @example_keychain, false do
        `security list-keychains -s otherprocess.keychain #{capture_keychain_list}`

        @list_in_block = capture_keychain_list
      end
      
      @list_after_block = capture_keychain_list
    end

    it "should remove added keychain after block" do
      expect(@list_after_block).not_to include(@example_keychain)
    end

    it "should not remove any keychains added during block" do
      expect(@list_after_block).to include("otherprocess.keychain")
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

  def timeout_of_keychain(path)
    `security show-keychain-info #{path} 2>&1 | awk '{ print $NF }' | tr -d ' \t\r\n'`
  end

  context "when block is supplied" do

    before do
      @list_before_block = capture_keychain_list
      SpareKeys.temp_keychain true do |tmp|
        @list_in_block = capture_keychain_list
        @temp_keychain = tmp
        @timeout_keychain = timeout_of_keychain(tmp)
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

    it "should unlock the keychain indefinitely" do
      expect(@timeout_keychain).to eql("no-timeout")
    end

  end

end
