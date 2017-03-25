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
        {
          state_tree_source => state_tree_destination,
          pillar_roots_source => pillar_roots_destination,
          minion_config_source => minion_config_destination
        }.each { |src, dest| cp(src, dest) }
      end

      private

      def cp(src, dest)
        tree = dest
        tree = File.dirname(dest) if File.file?(src)
        FileUtils.mkdir_p(tree)
        FileUtils.copy_entry(src, dest, remove_destination: true)
      end

      def state_tree_destination
        File.join(sandbox_path, '/srv/salt')
      end

      def state_tree_source
        File.expand_path(config.fetch(:local_state_tree))
      end

      def pillar_roots_destination
        File.join(sandbox_path, '/srv/pillar')
      end

      def pillar_roots_source
        File.expand_path(config.fetch(:local_pillar_roots))
      end

      def minion_config_source
        File.expand_path(config.fetch(:minion_config))
      end

      def minion_config_destination
        File.join(sandbox_path, '/etc/salt/minion')
      end
    end
  end
end
