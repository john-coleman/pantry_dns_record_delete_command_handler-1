require 'spec_helper'
require_relative '../../pantry_dns_record_delete_command_handler/pantry_dns_record_delete_command_handler'

describe Wonga::Daemon::PantryDnsRecordDeleteCommandHandler do
  let(:logger) { instance_double('Logger').as_null_object }
  let(:publisher) { instance_double('Publisher').as_null_object }
  let(:config) { instance_double('Wonga::Daemon.load_config', {'daemon' => {'name_server' => 'a_server'}}).as_null_object }
  let(:win_rm_runner) { instance_double('Wonga::Daemon::WinRMRunner').as_null_object }
  let(:message) { 
    {
      "id"          => 1,
      "hostname"    => 'some-node',
      "domain"      => 'example.com',
      "instance_id" => 'i-c2c44977'
    }  
  }
  subject { described_class.new(publisher, logger, config) }
  it_behaves_like 'handler'
  
  describe "#handle_message" do
    before(:each) do
      Wonga::Daemon::WinRMRunner.stub(:new).and_return(win_rm_runner)
    end
    
    it "should receive add host" do
      subject.handle_message(message)
      expect(win_rm_runner).to have_received(:add_host)
    end
    
    it "should receive run commands" do
      subject.handle_message(message)
      expect(win_rm_runner).to have_received(:run_commands)
    end
  end
  
  describe "get_name_server" do
    it "should return a name server from config file" do
      resolver = Resolv::DNS.stub(:new).and_return(instance_double('Resolv::DNS').as_null_object)
      subject.get_name_server('a_server', 'aws.example.com').should == 'a_server'
    end
  end
end
