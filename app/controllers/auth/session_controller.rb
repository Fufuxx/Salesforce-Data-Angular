class Auth::SessionController < ApplicationController
	skip_before_filter :verify_authenticity_token

  def callback
    begin
      auth = request.env['omniauth.auth']
      extra = request.env['omniauth.params']['returnURL']

      #From SDO Tools
      user = User.find_or_create_by(:email => auth['extra']['email'], :uid => auth['uid'])
      user.uid = auth['uid']
      user.save

      #TODO Need OrgDetails
      o = Organization.find_or_create_by(:sfdc_id => auth['extra']['organization_id'], :user_id => user.id)
      o.user_id = user.id
      o.username = auth['extra']['username']
      o.name = auth['extra']['display_name']
      o.token = auth['credentials']['token']
      o.instanceurl = auth['extra']['instance_url']
      o.refreshtoken = auth['credentials']['refresh_token']
      o.metadataurl = auth['info']['urls']['metadata'].sub '{version}', '29.0'
      o.serviceurl = auth['info']['urls']['enterprise'].sub '{version}', '29.0'
      o.save

      #user = User.from_omniauth(env["omniauth.auth"])
      set_session_vars(user, auth)
      sign_in_and_redirect user

    rescue Exception => ex
      p "====== Exception ======"
      p ex
    end
  end

  def set_session_vars(user, auth)
    session[:user_id]               = user.id
    session['auth.token']           = auth['credentials']['token']
    session['auth.refresh_token']   = auth['credentials']['refresh_token']
    session['auth.instance_url']    = auth['extra']['instance_url']
    session['auth.picture']         = auth['extra']['photos']['picture']
    session['auth.user_id']         = auth['extra']['user_id']
    session['auth.username']        = auth['extra']['username']
    session['auth.display_name']    = auth['extra']['display_name']
    session['auth.organization_id'] = auth['extra']['organization_id']
    session['auth.metadata_url']    = auth['info']['urls']['metadata'].sub '{version}', ENV["API_VERSION"]
    session['auth.service_url']     = auth['info']['urls']['enterprise'].sub '{version}', ENV["API_VERSION"]
  end

end
