

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

        keychain_path = expand_keychain_path(keychain_path)

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
                
                unless clear_list
                    # Grab the keychain list as it looks right now in case
                    # another process has changed it
                    current_list = `security list-keychains #{domain_flag}`
                    current_list_as_array = current_list.scan(/"[^"]*"/).map { |item| item.gsub(/^"|"$/, "")}
                    # Remove the supplied keychain
                    original_list = (current_list_as_array.reject { |item| item == keychain_path }).join(" ")
                end
                
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
        temp_keychain = temporary_keychain_name('spare-keys')

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

    def self.expand_keychain_path(path)

        if (File.basename(path) == path)
            default_keychain_path = File.expand_path("~/Library/Keychains")

            path = File.join(default_keychain_path, path)
        else
            path = File.expand_path(path)
        end

        return path
    end

    def self.temporary_keychain_name(prefix)
        t = Time.now.strftime("%Y%m%d")
        extension = keychain_extension()
        "#{prefix}-#{t}-#{$$}-#{rand(0x100000000).to_s(36)}#{extension}"
    end

end