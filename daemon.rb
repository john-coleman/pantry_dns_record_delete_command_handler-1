#!/usr/bin/env ruby
require 'rubygems'
require 'wonga/daemon'
require_relative 'pantry_dns_record_delete_command_handler/pantry_dns_record_delete_command_handler'

config_name = File.join(File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__), "config", "daemon.yml")
Wonga::Daemon.load_config(File.expand_path(config_name))
Wonga::Daemon.run(Wonga::Daemon::PantryDnsRecordDeleteCommandHandler.new(Wonga::Daemon.publisher,Wonga::Daemon.logger))
