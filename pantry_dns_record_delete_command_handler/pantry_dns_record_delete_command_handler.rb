require 'wonga/daemon/win_rm_runner'
require 'resolv'

module Wonga
  module Daemon
    class PantryDnsRecordDeleteCommandHandler
      def initialize(publisher, logger, config)
        @publisher   = publisher
        @logger      = logger
        @config      = config
      end

      def handle_message(message)
        fqdn         = message["node"].split(".") 
        hostname     = fqdn[0]
        domain       = fqdn.slice(1, fqdn.length).join(".")        
        name_server  = get_name_server(@config['daemon']['name_server'], domain)
        @logger.info("Name Server located: #{name_server}")
        delete_record(name_server, domain, hostname)
        @logger.info("Complete. Publishing to topic")
        @publisher.publish(message)      
      end

      def delete_record(name_server, domain, hostname) 
        runner      = WinRMRunner.new        
        @logger.info("WinRM Adding host: #{name_server}")
        runner.add_host(name_server, @config['ad']['username'], @config['ad']['password'])
        # http://technet.microsoft.com/en-us/library/cc772069.aspx#BKMK_15
        # syntax: dnscmd <NameServer>   /recorddelete <ZoneName> <NodeName> <RRType> <RRData> [/f]
        command     = "dnscmd #{name_server} /recorddelete #{domain} #{hostname}.#{domain} A /f"
        @logger.info("WinRM exec: #{command}")
        result      = runner.run_commands(command)
        @logger.info("WinRM returned: #{result.inspect}")
      end
      
      def get_name_server(name_server, domain)
        if name_server.nil? || name_server.empty?
          resolver  = Resolv::DNS.new
          resolver.getresource(
            domain, 
            Resolv::DNS::Resource::IN::NS
          ).name
        else
          name_server
        end
      end
    end
  end
end
