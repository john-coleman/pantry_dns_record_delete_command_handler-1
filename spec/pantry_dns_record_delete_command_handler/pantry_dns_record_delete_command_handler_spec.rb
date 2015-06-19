require 'spec_helper'
require 'logger'
require 'wonga/daemon/publisher'
require 'wonga/daemon/win_rm_runner'
require_relative '../../pantry_dns_record_delete_command_handler/pantry_dns_record_delete_command_handler'

RSpec.describe Wonga::Daemon::PantryDnsRecordDeleteCommandHandler do
  let(:logger) { instance_double(Logger).as_null_object }
  let(:publisher) { instance_double(Wonga::Daemon::Publisher).as_null_object }
  let(:config) { { 'daemon' => { 'name_server' => 'a_server' }, 'ad' => {} } }
  let(:win_rm_runner) { instance_double(Wonga::Daemon::WinRMRunner).as_null_object }
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
    allow(Wonga::Daemon::WinRMRunner).to receive(:new).and_return(win_rm_runner)
    allow(win_rm_runner).to receive(:run_commands).and_yield(win_rm_cmd, win_rm_return_data)
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

    include_examples 'send message'
  end

  describe '#delete_record' do
    context 'when command is successful' do
      it 'does not raise error' do
        expect { subject.delete_record(config['daemon']['name_server'], message['domain'], message['hostname']) }.to_not raise_error
      end
    end

    context 'when command is unsuccessful' do
      let(:win_rm_return_data) { 'Command failed' }

      it 'raises error' do
        expect { subject.delete_record(config['daemon']['name_server'], message['domain'], message['hostname']) }.to raise_error RuntimeError
      end
    end
  end

  describe '#get_name_server' do
    before(:each) do
      allow(Resolv::DNS).to receive(:new).and_return(instance_double('Resolv::DNS').as_null_object)
    end

    it 'returns a name server from config file' do
      expect(subject.get_name_server('a_server', 'aws.example.com')).to eq 'a_server'
    end
  end
end
