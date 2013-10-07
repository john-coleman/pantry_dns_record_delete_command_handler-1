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
        puts domain
        machine_address = ec2_instance.private_ip_address
        puts machine_address
        #@logger.info "Finding SOA"
        resolver = Resolv::DNS.new()
        name_server = resolver.getresource(domain, Resolv::DNS::Resource::IN::NS).name
        puts name_server
        @logger.info "Name Server located: #{name_server}"
        runner = WinRMRunner.new
        @logger.info "WinRM Run command"
        puts name_server
        runner.add_host name_server
        # http://technet.microsoft.com/en-us/library/cc772069.aspx#BKMK_15
        # syntax: dnscmd /recorddelete <ZoneName> <NodeName> <RRType> <RRData>[/f]
        # example: dnscmd /recorddelete test.contoso.com test MX 10 mailserver.test.contoso.com
        command = "dnscmd #{??} /recorddelete #{domain} #{hostname} A #{hostname}.#{domain}"
        @logger.info command
        dns_record_hash = command
        @logger.info "WinRM Run command retuned with"
        @logger.debug dns_record_hash.inspect
        @publisher.publish(message)
      end
    end
  end
end
