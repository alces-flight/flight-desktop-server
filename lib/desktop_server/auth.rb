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
module DesktopServer
  class Auth < Rack::Auth::Basic
    def call(env)
      request = Rack::Request.new(env)
      case request.path
      when '/', Regexp.new("^/assets/")
        @app.call(env)
      else
        super.tap do |r|
          if r[0] == 401
            r[2][0] = "Incorrect username or password."
            r[1]["Content-Length"] = r[2][0].length.to_s
          end
        end
      end

    end

    private
    def valid?(auth)
      user = auth.request.path.match(Regexp.new('^/([^/]*)'))[1]
      auth.credentials[0] == user &&
        @authenticator.call(user, auth.credentials[1])
    end
  end
end
