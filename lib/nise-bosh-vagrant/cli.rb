require 'trollop'

require 'nise-bosh-vagrant/runner'
require 'nise-bosh-vagrant/version'

module NiseBOSHVagrant
	class CLI

		def self.start
			opts = Trollop::options do
				  version NiseBOSHVagrant::VERSION
  banner <<-EOS
Based on nise-bosh from NTT Labs and Vagrant from HashiCorp

Requires Vagrant >= 1.2

Usage:
       nise-bosh-vagrant [options] <BOSH Release>

Options:
EOS

				opt :manifest, "Path to manifest file", :type => :string
				opt :nise, "Path to nise-bosh if you don't wish to pull HEAD of master from GitHub", :type => :string
				opt :install, "Run install script after preparing the VM"
				opt :start, "Start all jobs after installing them (implies --install)"
				opt :memory, "Amount of memory to allocate to the VM in MB", :type => :integer, :default => 512
				opt :preinstall, "Preinstall hook script", :type => :string
				opt :postinstall, "Postinstall hook script", :type => :string
				opt :address, "IP address for the VM", :type => :string
				opt :bridge, "Use bridged network interface"
			end

			Trollop::die :manifest, "must provide a manifest file" if opts[:manifest].nil?
			Trollop::die :manifest, "must exist" unless File.exist?(opts[:manifest])
			Trollop::die :preinstall, "must exist" unless opts[:preinstall].nil? || File.exist?(opts[:preinstall])
			Trollop::die :postinstall, "must exist" unless opts[:postinstall].nil? || File.exist?(opts[:postinstall])
			Trollop::die :address, "must exist" if opts[:bridge] && opts[:address].nil?

			opts[:release] = ARGV[0]

			if opts[:start]
				opts[:install] = true
			end
			if ! opts[:bridge]
				opts[:address] ||= "192.168.10.10"
			end


			# Generate, start and prepare a fresh VM
			runner = NiseBOSHVagrant::Runner.new(opts)
			runner.generate_vagrantfile
			runner.copy_manifest
			runner.copy_hook_scripts
			runner.generate_install_script
			puts "---> Starting Vagrant VM"
			runner.start_vm
			puts "---> Preparing Vagrant VM"
			runner.prepare_vm

			# If instructed, install the release
			if opts[:install]
				if opts[:preinstall]
					puts "---> Running preinstall script"
					runner.run_preinstall_release
				end
				puts "---> Installing release"
				runner.install_release
				if opts[:postinstall]
					puts "---> Running postinstall script"
					runner.run_postinstall_release
				end
			end

			# If instructed, start the release
			if opts[:start]
				puts "---> Starting release"
				runner.start_release
			end
		end

	end
end
