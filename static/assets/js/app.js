/*
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
*/
function connectVNC(url, password) {
  // Creating a new RFB object will start a new connection
  rfb = new RFB(document.getElementById('screen'), url,
                { credentials: { password: password } });

  // When this function is called, the server requires
  // credentials to authenticate
  function credentialsAreRequired(e) {
    const password = prompt("Password Required:");
    if ( password != "" ) {
      rfb.sendCredentials({ password: password });
    }
  }

  // Add listeners to important events from the RFB module
  //rfb.addEventListener("connect",  connectedToServer);
  rfb.addEventListener("disconnect", reloadPage);
  rfb.addEventListener("credentialsrequired", credentialsAreRequired);
  //rfb.addEventListener("desktopname", updateDesktopName);

  // Set parameters that can be changed on an active connection
  rfb.viewOnly = false; //readQueryVariable('view_only', false);
  rfb.scaleViewport = false; //readQueryVariable('scale', false);

  return rfb;
}

function disconnectVNC(rfb) {
  rfb.disconnect();
  $('.desktop').addClass('d-none');
  $('.sessions').removeClass('d-none');
}

function reloadPage() {
  setTimeout(
    function() {
      window.location.reload();
    },
    2000
  );
}

$(document).ready(
  function() {
    $('[data-session]').on(
      'click',
      function(ev) {
        $('.sessions').addClass('d-none');
        $('.desktop').removeClass('d-none');
        var session = JSON.parse($(ev.currentTarget).attr('data-session'));
        $('#desktop-title').text(session.name);
        window.vnc_session = connectVNC(session.url, session.password);
      }
    )

    $('.disconnect').on(
      'click',
      function(ev) {
        disconnectVNC(window.vnc_session);
      }
    );

    $('#usernameForm').on(
      'submit',
      function(ev) {
        var form = $(this);
        var values = {};
        $.each(form.serializeArray(), function(i, field) {
          values[field.name] = field.value;
        });
        if ( values['username'] !== "" ) {
          window.location = "/" + values['username'];
        }
        ev.preventDefault();
      }
    );

    $('.btn-disableable').on(
      'click',
      function(ev) {
        var btn = $(ev.currentTarget);
        if ( btn.prop("disabled") == true ) {
          ev.preventDefault();
          return;
        }
        btn.prop("disabled", true);
        btn.addClass("disabled");
        var icon = btn.find('i');
        icon.attr("class", "");
        icon.addClass("spinner-border spinner-border-sm");
      }
    );
  }
);
