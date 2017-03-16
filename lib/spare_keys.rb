
# Temporarily reconfigures the active keychain
class SpareKeys

    # Temporarily adds the specified keychain to the top of the search list, reverting it after the block is invoked.
    #
    # If no block is supplied, reverting the state becomes the responsibility of the caller.
    # Params:
    # +keychain_path+:: path to keychain to switch to
    # +clear_list+:: when true, the search list will be initially cleared to prevent fallback to a different keychain
    # +type+:: if specified, replaces default/login keychain ("default", "login", nil)
    # +domain+:: if specified, performs keychain operations using the specified domain
    def self.use_keychain(keychain_path, clear_list = false, type = nil, domain = nil)
        domain_flag = "-d #{domain}" if domain

        original_list = `security list-keychains #{domain_flag} | xargs`
        original_keychain = `security #{type}-keychain #{domain_flag} | xargs` if type 

        `security #{type}-keychain #{domain_flag} -s #{keychain_path}` if type

        list_tail = original_list unless clear_list
        `security list-keychains #{domain_flag} -s #{keychain_path} #{list_tail}`

        if block_given?
            begin
                yield if block_given?
            ensure
                original_keychain = `security #{type}-keychain #{domain_flag} -s #{original_keychain}` if type
                `security list-keychains #{domain_flag} -s #{original_list}`
            end
        end
    end

    # Creates a secure temporary keychain and adds it to the top of the 
    # search list, reverting the list and deleting the keychain after the block is invoked.
    #
    # If no block is supplied, reverting the state becomes the responsibility of the caller.
    # Params:
    # +clear_list+:: when true, the search list will be initially cleared to prevent fallback to a different keychain
    # +type+:: if specified, replaces default/login keychain ("default", "login", nil)
    # +domain+:: if specified, performs keychain operations using the specified domain
    def self.temp_keychain(clear_list = false, type = nil, domain = nil) # :yields: keychain_path
        require 'tempfile'
        require 'securerandom'

        password = SecureRandom.hex

        extension = keychain_extension()
        temp_keychain = Dir::Tmpname.make_tmpname(['spare-keys-', extension], nil)

        `security create-keychain -p "#{password}" #{temp_keychain}`
        `security set-keychain-settings #{temp_keychain}`
        `security unlock-keychain -p "#{password}" #{temp_keychain}`

        if block_given?
            begin
                use_keychain(temp_keychain, clear_list, type) {
                    yield temp_keychain, password
                }
            ensure
                `security delete-keychain #{temp_keychain}`
            end
        else
            use_keychain(temp_keychain, clear_list, type)
        end
    end

private

    def self.keychain_extension()
        return is_sierra() ? '.keychain-db' : '.keychain' 
    end

    def self.is_sierra()
 
        osVersion = `sysctl -n kern.osrelease`
    
        majorOsVersion = Integer(osVersion.split('.')[0])
    
        return majorOsVersion >= 16 # Sierra
    
    end

end