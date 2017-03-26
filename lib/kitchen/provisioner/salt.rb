require 'kitchen/provisioner/base'
require 'fileutils'

module Kitchen
  module Provisioner
    # Salt Kitchen Provisioner
    class Salt < Base
      def install_command
        '[[ $(which salt-call) ]] || wget --quiet -O - https://bootstrap.saltstack.com | sudo sh'
      end

      def create_sandbox
        super
        pave
        copy_state_tree
        copy_pillar_roots if config[:local_pillar_roots]
        copy_minion_config if config[:minion_config]
      end

      def run_command
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

      def pave
        ['/srv/salt', '/srv/pillar', '/etc/salt'].each do |p|
          target = File.join(sandbox_path, p)
          FileUtils.rm_rf target
        end
      end

      def copy_state_tree
        src = File.expand_path(config[:local_state_tree])
        dest = File.join(sandbox_path, '/srv/salt')
        FileUtils.mkdir_p(dest)
        FileUtils.cp_r("#{src}/.", dest)
      end

      def copy_pillar_roots
        src = File.expand_path(config[:local_pillar_roots])
        dest = File.join(sandbox_path, '/srv/pillar')
        FileUtils.mkdir_p(dest)
        FileUtils.cp_r("#{src}/.", dest)
      end

      def copy_minion_config
        src = File.expand_path(config[:minion_config])
        FileUtils.mkdir_p(File.join(sandbox_path, 'etc/salt'))
        FileUtils.cp(src, File.join(sandbox_path, '/etc/salt/minion'))
      end
    end
  end
end
