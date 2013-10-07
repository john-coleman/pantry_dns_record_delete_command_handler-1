require 'spec_helper'
require_relative '../../pantry_dns_record_delete_command_handler/pantry_dns_record_delete_command_handler'

describe Wonga::Daemon::PantryDnsRecordDeleteCommandHandler do
  let(:logger) { instance_double('Logger').as_null_object }
  let(:publisher) { instance_double('Publisher').as_null_object }
  subject { described_class.new(publisher, logger) }
  it_behaves_like 'handler'
  
  describe "#handle_message" do
    
  end
end

