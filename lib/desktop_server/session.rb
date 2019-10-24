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
require_relative 'config'
require_relative 'errors'

require 'aw'
require 'base64'

module DesktopServer
  class Session
    PLACEHOLDER_IMAGE = Base64.strict_encode64(
      File.read(Config.placeholder_image)
    ).freeze

    class << self
      def launch(user)
        as_user(user) do
          desktop_cmd('start', Config.desktop_type)
        end
      end

      def terminate(user, uuid)
        as_user(user) do
          desktop_cmd('kill', uuid)
        end
      end

      def clean(user, uuid)
        as_user(user) do
          desktop_cmd('clean', uuid)
        end
      end

      def all(user)
        as_user(user) do
          sessons = [].tap do |a|
            desktop_cmd('list') do |lines|
              lines.each do |l|
                l.chomp!
                a << Session.new(*(l.split("\t")))
              end
            end
          end
        end
      end

      private
      def as_user(user)
        raise UserNotAvailable, "user not available: #{user}" if user == 'root'
        user_data = Etc.getpwnam(user)
        Aw.fork! do
          ENV['HOME'] = user_data.dir
          Process::Sys.setuid(user)
          Process.setsid
          yield
        rescue
          $!
        end.tap do |o|
          raise o if o.is_a?(Exception)
        end
      rescue ArgumentError
        raise UserNotFoundError, $!.message
      rescue Errno::EPERM
        raise UserNotAvailable, "user not available: #{user} (#{$!.message})"
      end

      def desktop_cmd(*cmd)
        with_unbundled_env do
          output = []
          IO.popen(
            [
              {
                "TERM" => "vt100"
              },
              '/opt/flight/bin/flight',
              'desktop',
              *cmd,
              :err=>[:child, :out]
            ]
          ) do |io|
            output.concat(io.readlines)
            yield(output) if block_given?
          end.tap do
            if $?.exitstatus != 0
              raise DesktopOperationError, output.join("\n")
            end
          end
        end
      end

      def with_unbundled_env(&block)
        home = ENV['HOME']
        block_with_home = lambda do
          ENV['HOME'] = home
          block.call
        end
        if Kernel.const_defined?(:OpenFlight) && OpenFlight.respond_to?(:with_unbundled_env)
          OpenFlight.with_unbundled_env(&block_with_home)
        else
          Bundler.with_unbundled_env(&block_with_home)
        end
      end
    end

    attr_reader :uuid, :type, :host, :ip, :display,
                :port, :websocket_port, :password, :state,
                :ctime, :mtime, :image

    def initialize(uuid, type, host, ip, display, port, websocket_port, password, state)
      @uuid = uuid
      @type = type
      @host = host
      @ip = ip
      @display = display
      @port = port
      @websocket_port = websocket_port
      @password = password
      @state = state
      if File.exists?(metadata_file)
        @ctime = File.stat(metadata_file).ctime
      end
      if File.exists?(log_file)
        @mtime = File.stat(log_file).mtime
      end
      if File.exists?(image_file)
        @image = Base64.strict_encode64(File.read(image_file))
      else
        @image = PLACEHOLDER_IMAGE
      end
    end

    def url
      @url ||= "#{Config.url_prefix}/#{ip}/#{websocket_port}"
    end

    def name
      @name ||= "#{type} desktop (#{uuid.split('-').first})"
    end

    private
    def metadata_file
      @metadata_file ||=
        File.join(
          session_dir,
          'metadata.yml'
        )
    end

    def log_file
      @log_file ||=
        File.join(
          session_dir,
          'session.log'
        )
    end

    def image_file
      @image_file ||=
        File.join(
          session_dir,
          'session.png'
        )
    end

    def session_dir
      @session_dir ||=
        File.join(
          ENV['HOME'],
          '.cache',
          'flight',
          'desktop',
          'sessions',
          uuid,
        )
    end
  end
end
