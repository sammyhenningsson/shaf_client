require 'shaf_client/client'
require 'byebug'

module ShafClient
  def self.new(root, **headers)
    Client.new(root, headers).get_root
  end
end
