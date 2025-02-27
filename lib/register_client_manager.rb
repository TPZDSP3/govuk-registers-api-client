require 'register_client'
require 'in_memory_data_store'

module RegistersClient
    VERSION = '2.0.0'
    class RegisterClientManager
      def initialize(config_options = {})
        @config_options = defaults.merge(config_options)
        @register_clients = {}
      end
  
      def get_register(register, phase, options = {})
        environment_url = get_environment_url_from_phase(phase)
        get_register_from_environment(register, environment_url, options)
      end

      def get_register_from_environment(register, environment_url, options = {})
        key = register + ':' + environment_url.to_s

        if !@register_clients.key?(key)
          data_store = options.has_key?(:data_store) ? options[:data_store] : RegistersClient::InMemoryDataStore.new(@config_options)
          register_url = get_register_url(register, environment_url)

          @register_clients[key] = create_register_client(register_url, data_store, @config_options.fetch(:page_size))
        end
  
        @register_clients[key]
      end
  
      private
  
      def defaults
        {
            api_key: nil,
            page_size: 100
        }
      end

      def create_register_client(register_url, data_store, page_size)
        register_options = {
            api_key: @config_options[:api_key]
        }

        RegistersClient::RegisterClient.new(register_url, data_store, page_size, register_options)
      end

      def get_register_url(register, environment_url)
        URI.parse(environment_url.to_s.sub('register', register))
      end

      def get_environment_url_from_phase(phase)
        case phase
        when 'beta'
          URI.parse('https://register.dsp-dev.agrimetrics.co.uk')
        when 'discovery'
          URI.parse('http://register.192.168.1.99.nip.io:8080')
        when 'alpha', 'test'
          URI.parse("https://register.dev-tpz-apps.tpzdsp3.com")
        else
          raise ArgumentError "Invalid phase '#{phase}'. Must be one of 'beta', 'alpha', 'discovery', 'test'."
        end
      end
    end
  end