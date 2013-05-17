module Magiconfig; end

module Magiconf
  extend self

  # For each configuration key, define a method inside the module
  def setup!
    configuration = config

    configuration.keys.each do |key|
      nodule.define_singleton_method key do
        return configuration[key]
      end
    end

    nodule.define_singleton_method :method_missing do |m, *args, &block|
      nil
    end
  end

  # Have we already loaded the magiconf config?
  # @return [Boolean] true if we have been loaded, false otherwise
  def setup?
    namespace.constants.include?('Config') # Note: We cannot use const_defined?('Config')
                                           # here because that will recursively search up
                                           # Object and find RbConfig
  end

  # Get the namespace for the current application
  # @return [Module] the namespace of the Rails app
  def namespace
    @namespace ||= Rails.application.class.parent_name.constantize if defined?(Rails)
    @namespace ||= Magiconfig
  end

  def path
    @path ||= Rails.root.join('config/application.yml') if defined?(Rails)
    @path ||= Sinatra::Application.root.join('config/application.yml') if defined?(Sinatra)
  end

  private
  # Create a new Config module in the current namespace
  # @return [Module] the created module
  def nodule
    @nodule ||= namespace.const_set('Config', Module.new)
  end

  def yaml
    @yaml ||= File.exist?(path) ? File.read(path) : nil
  end
  
  def rawConfig
    @raw ||= yaml && YAML::load( ERB.new(yaml).result ) || {}
  end

  # The configuration yaml file
  # @return [Hash] the parsed yaml data
  def config
    @config ||= begin
      config = rawConfig
      # get env config and non-env/global config

      if defined?(Rails)
        env = Rails.env
      elsif defined?(Sinatra)
        env = "development" if Sinatra::Base.development?
        env = "production" if Sinatra::Base.production?
      else
        logger.warn "Magiconf: Rails and Sinatra are not defined, fallback to 'development' environment."
        env = "development"
      end

      config = config.select{|k,v| !v.is_a? Hash}.merge(config.fetch(env, {}))
      
      # extend the ENV variables with the config values
      config.each{|k,v| ENV[k] = v}
      
      config.symbolize_keys!
      config
    end
  end
end

require 'magiconf/railtie' if defined?(Rails)
