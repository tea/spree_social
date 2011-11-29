require 'spree_core'
require 'spree_auth'
require 'omniauth/oauth'
require "spree_social_hooks"

module SpreeSocial

  OAUTH_PROVIDERS = [
    ["Bit.ly", "bitly"],
    ["Facebook", "facebook"],
    ["Foursquare", "foursquare"],
    ["Github", "github"], 
    ["Google", "google"] , 
    ["Gowalla", "gowalla"], 
    ["instagr.am", "instagram"],
    ["Instapaper", "instapaper"], 
    ["LinkedIn", "linked_in"], 
    ["37Signals (Basecamp, Campfire, etc)", "thirty_seven_signals"],
    ["Twitter", "twitter"], 
    ["Vimeo", "vimeo"], 
    ["Yahoo!", "yahoo"], 
    ["YouTube", "you_tube"], 
    ["Vkontakte", "vkontakte"], 
    ["Mailru", "mailru"],
    ["Odnoklassniki", "odnoklassniki"]
    #["Blogger", "blogger"],
    #["Dropbox", "dropbox"]
  ]

  class Engine < Rails::Engine
    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), "../app/overrides/**/*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end
      Ability.register_ability(SocialAbility)
    end
    config.to_prepare &method(:activate).to_proc
  end

  # We are setting these providers up regardless
  # This way we can update them when and where necessary
  def self.init_provider(provider)
    key, secret, public_key = nil
    AuthenticationMethod.where(:environment => ::Rails.env).each do |user|
      if user.preferred_provider == provider
        key = user.preferred_api_key
        secret = user.preferred_api_secret
        public_key = user.preferred_api_public
        puts("[Spree Social] Loading #{user.preferred_provider.capitalize} as authentication source")
      end
    end if self.table_exists?("authentication_methods") # See Below for explanation
    self.setup_key_for(provider.to_sym, key, secret, public_key)
  end

  def self.setup_key_for(provider, key, secret, public_key)
    Devise.setup do |oa|
      oa.omniauth provider.to_sym, key, secret, :public_key => public_key
    end
  end

  # Coming soon to a server near you: no restart to get new keys setup
  #def self.reset_key_for(provider, *args)
  #  puts "ARGS: #{args}"
  #  Devise.omniauth_configs[provider] = Devise::OmniAuth::Config.new(provider, args)
  #  #oa_updated_provider
  #  #Devise.omniauth_configs.merge!(oa_updated_provider)
  #  puts "OmniAuth #{provider}: #{Devise.omniauth_configs[provider.to_sym].inspect}"
  #end

  private

  # Have to test for this cause Rails migrations and initial setups will fail
  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end
end
