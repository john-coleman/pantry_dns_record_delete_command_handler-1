require 'wonga/daemon/win_rm_runner'
require 'resolv'

module Wonga
  module Daemon
    class PantryDnsRecordDeleteCommandHandler
      def initialize(publisher, logger)
        @publisher = publisher
        @logger = logger
      end

      def handle_message(message)
        ec2_instance = AWSResource.new.find_server_by_id message["instance_id"]
        hostname = message["instance_name"]
        domain = message["domain"]
        ≈"FQDN is: #{hostname}.#{domain}")
        
        resolver = Resolv::DNS.new()
        name_server = resolver.getresource(domain, Resolv::DNS::Resource::IN::NS).name
        @logger.info("Name Server located: #{name_server}")
        
        runner = WinRMRunner.new
        @logger.info "WinRM Run command"
        puts name_server
        runner.add_host name_server
        
        # http://technet.microsoft.com/en-us/library/cc772069.aspx#BKMK_15
        # syntax: dnscmd <NameServer> /recorddelete <ZoneName> <NodeName> <RRType> <RRData> [/f]
        command = "dnscmd #{name_server} /recorddelete #{domain} #{hostname}.#{domain}. A /f"
        @logger.info(command)
        runner.run_commands(command)
        @publisher.publish(message)
      end
    end
  end
end
