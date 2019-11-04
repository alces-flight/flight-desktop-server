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
require_relative 'auth'
require_relative 'config'
require_relative 'errors'
require_relative 'session'
require_relative 'version'

require 'rack/app'
require 'rack/app/front_end'
require 'json'
require 'cgi'
require 'rpam2'

module DesktopServer
  class App < Rack::App
    apply_extensions :front_end

    serve_files_from '/static'

    helpers do
      def h(v)
        CGI.escapeHTML(v)
      end

      def json_for(s)
        {
          url: s.url,
          name: s.name,
          password: s.password
        }.to_json
      end
    end

    layout '/views/layout.html.erb'

    use Auth, Config.realm do |username, password|
      Rpam2.auth("sshd", username, password)
    end

    error DesktopServer::RuntimeError do |ex|
      @ex = ex
      render '/views/error.html.erb'
    end

    get '/' do
      render '/views/index.html.erb'
    end

    namespace '/:user' do
      get '/' do
        @user = params['user']
        @sessions = Session.all(@user)
        render '/views/list.html.erb'
      end

      get '/launch' do
        @user = params['user']
        Session.launch(@user)
        response.status = 302
        response.headers['Location'] = "#{Config.path_prefix}/#{@user}"
      end

      get '/terminate/:uuid' do
        @user = params['user']
        Session.terminate(@user, params['uuid'])
        response.status = 302
        response.headers['Location'] = "#{Config.path_prefix}/#{@user}"
      end

      get '/clean/:uuid' do
        @user = params['user']
        Session.clean(@user, params['uuid'])
        response.status = 302
        response.headers['Location'] = "#{Config.path_prefix}/#{@user}"
      end
    end
  end
end
