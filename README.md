[![Build Status](https://travis-ci.org/richardszalay/spare-keys.svg?branch=master)](https://travis-ci.org/richardszalay/spare-keys)

Ruby Gem for temporarily modifying the Mac OS Keychain configuration. Useful for shared environments or processes with transient Keychain requirements.

This utility was created specifically for use with Fastlane's match / resign utilities. The process requires a keychain, but since match uses a git repository as the "source of truth" there's no need for the keychain to exist after the re-signing.


## API

```ruby
class SpareKeys
    # Temporarily adds the specified keychain to the top of the search list, reverting it after the block is invoked.
    def self.use_keychain(keychain_path, clear_list = false, type = nil, domain = nil)
    end
    
    # Creates a secure temporary keychain and adds it to the top of the 
    # search list, reverting the list and deleting the keychain after the block is invoked.
    def self.temp_keychain(clear_list = false, type = nil, domain = nil)
    end
end
```

## Usage

```ruby
SpareKeys.temp_keychain do |temp_keychain_path, temp_keychain_password|
  # The keychain list starts with +temp_keychain_path+
end

# Everything is back to normal now

SpareKeys.temp_keychain true do |temp_keychain_path, temp_keychain_password|
  # The keychain list is empty, apart from +temp_keychain_path+
end

# Everything is back to normal now

SpareKeys.temp_keychain true, "default" do |temp_keychain_path, temp_keychain_password|
  # The keychain list is empty, apart from +temp_keychain_path+
  # The default keychain has been set to temp_keychain_path
end

# Everything is back to normal now
```

## `clear_list` usage

When `clear_list` is set to `true`, the supplied keychain will be configured as the only keychain in the list, 
preventing the possibility of fallback to another (locked) keychain.

However, if your server can have multiple builds running concurrently `clear_list` will remove temp keychains 
added by other builds, causing them to fail. If this is an issue for you, set `clear_list` to `false`.
