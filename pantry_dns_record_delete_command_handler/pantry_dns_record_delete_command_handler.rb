require 'wonga/daemon/win_rm_runner'
require 'resolv'

module Wonga
  module Daemon
    class PantryDnsRecordDeleteCommandHandler
      def initialize(publisher, logger, config)
        @publisher = publisher
        @logger = logger
        @config = config
      end

      def handle_message(message)
        #hostname = message["instance_name"]
        #domain = message["domain"]
        fqdn = message["node"].split(".")
        hostname = fqdn[0]
        domain = fqdn.slice(1, fqdn.length)

        @logger.info("FQDN is: #{fqdn}")
        name_server = get_name_server(@config['daemon']['name_server'], domain)
        @logger.info("Name Server located: #{name_server}")
        runner = WinRMRunner.new
        @logger.info("WinRM Run command")
        @logger.info("Adding #{name_server} name server")
        runner.add_host(name_server)
        
        # http://technet.microsoft.com/en-us/library/cc772069.aspx#BKMK_15
        # syntax: dnscmd <NameServer> /recorddelete <ZoneName> <NodeName> <RRType> <RRData> [/f]
        command = "dnscmd #{name_server} /recorddelete #{domain} #{hostname}.#{domain}. A /f"
        @logger.info(command)
        result = runner.run_commands(command)
        @logger.info(result.inspect)
        @publisher.publish(message)
      end
      
      def get_name_server(name_server, domain)
        unless name_server && name_server.empty?
          resolver = Resolv::DNS.new
          resource = resolver.getresource(domain, Resolv::DNS::Resource::IN::NS)
          server_name = resource.name
        end
        
        name_server
      end
    end
  end
end
