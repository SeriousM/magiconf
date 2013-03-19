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

  private
  # Get the namespace for the current application
  # @return [Module] the namespace of the Rails app
  def namespace
    @namespace ||= Rails.application.class.parent_name.constantize
  end

  # Create a new Config module in the current namespace
  # @return [Module] the created module
  def nodule
    @nodule ||= namespace.const_set('Config', Module.new)
  end

  # The configuration yaml file
  # @return [Hash] the parsed yaml data
  def config
    @config ||= begin
      config = YAML::load( ERB.new( File.read('config/application.yml') ).result )
      # get env config and non-env/global config
      config = config.select{|k,v| !v.is_a? Hash}.merge(config.fetch(Rails.env, {}))
      
      # extend the ENV variables with the config values
      config.each{|k,v| ENV[k] = v}
      
      config.symbolize_keys!
      config
    end
  end
end

require 'magiconf/railtie' if defined?(Rails)
