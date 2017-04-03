require 'kitchen/provisioner/base'
require 'fileutils'

module Kitchen
  module Provisioner
    # Salt Kitchen Provisioner
    class Salt < Base
      def install_command
        install_salt = '[[ $(which salt-call) ]] || wget --quiet -O - https://bootstrap.saltstack.com | sudo sh'
        install_chef = '[[ $(which chef-client) ]] || wget --quiet -O - https://www.getchef.com/chef/install.sh | sudo sh'
        [install_salt, install_chef].join("\n")
      end

      def create_sandbox
        super
        create_tree
        copy_states if config[:local_state_tree]
        copy_pillars if config[:local_pillar_roots]
        copy_config if config[:minion_config]
      end

      def init_command
        [
          "#{sudo('rm')} -rf #{config[:root_path]}",
          "mkdir -p #{config[:root_path]}"
        ].join(' && ')
      end

      def run_command
        info('Executing salt')
        [
          'sudo salt-call --local',
          '--retcode-passthrough',
          '--config-dir=/tmp/kitchen/etc/salt',
          '--file-root=/tmp/kitchen/srv/salt',
          '--pillar-root=/tmp/kitchen/srv/pillar',
          ("--state_output=#{config[:state_output]}" if config[:state_output]),
          'state.highstate'
        ].join(' ')
      end

      private

      def create_tree
        %w(etc/salt srv).each do |directory|
          target = File.join(sandbox_path, directory)
          FileUtils.mkdir_p(target)
        end
      end

      def copy_states
        src = File.expand_path(config[:local_state_tree])
        dst = File.join(sandbox_path, 'srv/salt')
        FileUtils.copy_entry(src, dst)
      end

      def copy_pillars
        src = File.expand_path(config[:local_pillar_roots])
        dst = File.join(sandbox_path, 'srv/pillar')
        FileUtils.copy_entry(src, dst)
      end

      def copy_config
        src = File.expand_path(config[:minion_config])
        dst = File.join(sandbox_path, 'etc/salt/minion')
        FileUtils.copy_entry(src, dst)
      end
    end
  end
end
