require 'spec_helper'
require 'logger'
require_relative '../../pantry_dns_record_delete_command_handler/pantry_dns_record_delete_command_handler'

describe Wonga::Daemon::PantryDnsRecordDeleteCommandHandler do
  let(:logger) { instance_double('Logger').as_null_object }
  let(:publisher) { instance_double('Publisher').as_null_object }
  let(:config) { instance_double('Wonga::Daemon.load_config', 'daemon' => { 'name_server' => 'a_server' }).as_null_object }
  let(:win_rm_runner) { instance_double('Wonga::Daemon::WinRMRunner').as_null_object }
  let(:win_rm_cmd) { 'dnscmd good' }
  let(:win_rm_return_data) { 'Command completed successfully' }
  let(:message) do
    {
      'id'          => 1,
      'hostname'    => 'some-node',
      'domain'      => 'example.com',
      'instance_id' => 'i-c2c44977'
    }
  end
  subject { described_class.new(publisher, logger, config) }
  it_behaves_like 'handler'

  before(:each) do
    Wonga::Daemon::WinRMRunner.stub(:new).and_return(win_rm_runner)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  describe '#handle_message' do
    it 'should receive add host' do
      subject.handle_message(message)
      expect(win_rm_runner).to have_received(:add_host)
    end

    it 'should receive run commands' do
      subject.handle_message(message)
      expect(win_rm_runner).to have_received(:run_commands)
    end
  end

  describe '#delete_record' do
    before(:each) do
      allow(win_rm_runner).to receive(:run_commands).and_yield(win_rm_cmd, win_rm_return_data)
    end

    context 'when command is successful' do
      it 'does not raise error' do
        expect { subject.delete_record(config['daemon']['name_server'], message['domain'], message['hostname']) }.to_not raise_error
      end
    end

    context 'when command is unsuccessful' do
      let(:win_rm_cmd) { 'dnscmd bad' }
      let(:win_rm_return_data) { 'Command failed' }

      it 'raises error' do
        expect { subject.delete_record(config['daemon']['name_server'], message['domain'], message['hostname']) }.to raise_error
      end
    end
  end

  describe '#get_name_server' do
    before(:each) do
      Resolv::DNS.stub(:new).and_return(instance_double('Resolv::DNS').as_null_object)
    end

    it 'should return a name server from config file' do
      subject.get_name_server('a_server', 'aws.example.com').should == 'a_server'
    end
  end
end
