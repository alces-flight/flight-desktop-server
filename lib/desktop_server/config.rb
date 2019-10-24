#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Desktop Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Desktop Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Desktop Server. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Desktop Server, please visit:
# https://github.com/alces-flight/flight-desktop-server
#==============================================================================
require 'tty-config'

module DesktopServer
  module Config
    class << self
      def data
        @data ||= TTY::Config.new.tap do |cfg|
          cfg.append_path(File.join(root, 'etc'))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def root
        @root ||= File.expand_path(File.join(__dir__, '..', '..'))
      end

      def desktop_type
        @desktop_type ||= data.fetch(
          :desktop_type,
          default: 'gnome'
        )
      end

      def realm
        @realm ||= data.fetch(
          :realm,
          default: 'Cluster login'
        )
      end

      def url_prefix
        @url_prefix ||= data.fetch(
          :url_prefix,
          default: 'ws://%HOST%/ws'
        )
      end

      def placeholder_image
        @placeholder_image ||= File.expand_path(
          data.fetch(
            :placeholder_image,
            default: 'etc/placeholder.jpg'
          ),
          root
        )
      end

      def path_prefix
        @path_prefix ||= data.fetch(
          :path_prefix,
          default: ''
        )
      end
    end
  end
end
