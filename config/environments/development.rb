# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false


memcache_options = {
  :c_threshold => 10_000,
  :compression => true,
  :debug => true,
  :namespace => 'BioPortal',
  :readonly => false,
  :urlencode => false,
  :check_size => false
}

require 'memcache'
CACHE = MemCache.new memcache_options
CACHE.servers = 'localhost:11211'

FALLBACK_CACHE = {}

ActionController::Base.session_options[:cache] = CACHE
# end memcache setup

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked # We're in smart spawning mode, se we need to reset connections to stuff when forked
      CACHE.reset # reset memcache connection
    else # We're in conservative spawning mode. We don't need to do anything.
    end
  end
end

# Include the BioPortal-specific configuration options
require 'config/bioportal_config.rb'

# Spawn pre-caching
# require "Spawn"
# config.to_prepare do
#   Spawn::spawn do
#     sleep 30
#     puts "after initialize!"
#   end
# end
