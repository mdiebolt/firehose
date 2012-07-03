ENV['RACK_ENV'] ||= 'development'

require 'firehose/version'
require 'em-hiredis' # TODO Move this into a Redis module so that we can auto-load it. Lots of the CLI tools don't need this.
require 'firehose/logging'

if defined? ::Rails::Engine
  require 'firehose/rails'
elsif defined? ::Sprockets
  require "firehose/sprockets"
end

module Firehose
  autoload :Subscriber,   'firehose/subscriber'
  autoload :Publisher,    'firehose/publisher'
  autoload :Producer,     'firehose/producer' # TODO Move this into the Firehose::Client namespace.
  autoload :Default,      'firehose/default'
  autoload :Rack,         'firehose/rack'
  autoload :CLI,          'firehose/cli'
  autoload :Client,       'firehose/client'
  autoload :Server,       'firehose/server'
  autoload :Channel,      'firehose/channel'
  autoload :SwfPolicyRequest, 'firehose/swf_policy_request'
end