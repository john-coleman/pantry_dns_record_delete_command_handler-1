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
        hostname     = message['hostname']
        domain       = message['domain']
        name_server  = get_name_server(@config['daemon']['name_server'], domain)
        @logger.info("Name Server located: #{name_server}")
        delete_record(name_server, domain, hostname)
        @logger.info('Delete dns record command completed successfully')
        @publisher.publish(message)
      end

      def delete_record(name_server, domain, hostname)
        runner = WinRMRunner.new
        @logger.info("WinRM Adding host: #{name_server}")
        runner.add_host(name_server, @config['ad']['username'], @config['ad']['password'])
        # http://technet.microsoft.com/en-us/library/cc772069.aspx#BKMK_15
        # syntax: dnscmd <NameServer>   /recorddelete <ZoneName> <NodeName> <RRType> <RRData> [/f]
        command = "dnscmd #{name_server} /recorddelete #{domain} #{hostname} A /f"
        @logger.info("WinRM exec: #{command}")
        runner.run_commands(command) do |_cmd, return_data|
          if /Command completed successfully/.match(return_data)
            @logger.info("WinRM returned: #{return_data}")
          else
            @logger.error(return_data)
            fail 'DNS Record Delete Failed'
          end
        end
      end

      def get_name_server(name_server, domain)
        if name_server.nil? || name_server.empty?
          resolver  = Resolv::DNS.new
          resolver.getresource(domain, Resolv::DNS::Resource::IN::A).address.to_s
        else
          name_server
        end
      end
    end
  end
end
