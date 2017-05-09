class WelcomeController < ApplicationController
  def index
    p "Welcome Index"
    if current_user.nil?
      p "Current User not set"
      redirect_to '/auth/salesforce', :id => 'sign_in' and return
    end

    @organization = Organization.where(:sfdc_id => session['auth.organization_id']).first if session['auth.organization_id']
    @current_user = current_user

    p @organization
    p @current_user

  end
end
