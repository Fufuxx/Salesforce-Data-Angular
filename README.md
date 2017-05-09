###### Where we left off

This is the 3rd of a series of tutorials on getting started with Angular and Ruby on Rails. Here are the 2 first tutorials if you missed it ! :)
1. First Part: [Get Started with rails 5 & Angular](https://q-labs.herokuapp.com/2016/10/28/get-started-angular2-rails5/)
2. Second part: [Plugging Angular to Rails ActionCable - WebSockets](https://q-labs.herokuapp.com/2017/04/10/angular-and-actioncable-observable-pattern-and-websocket/)

If you want to jump straight away to this one, here is the [github repo of the last part](https://github.com/Fufuxx/ActionCable-Angular) so you can just start from here.

###### What we are going to do

Basically we are going to set up salesforce authentication on the Angular app so by the end of this tutorial, you'll be able to access and modify data of your salesforce Instance from your angular app.

If you didn't read it yet, I would advise looking into the great [User Authentication](https://q-labs.herokuapp.com/2017/01/30/user-authentication-in-sdo-tools-for-dummies/) article wrote by **Arunima Dasgupta**, as we are basically going to implement the most part of it.

###### Set up the needed libraries

So we are going to need 3 libraries:
1. Devise
2. Omniauth
3. Omniauth Salesforce

So let's go ahead and make sure we have those in our gemfile.

```
gem 'omniauth'
gem 'omniauth-salesforce'
gem 'devise'
gem 'restforce'
```

I have added the library 'restforce' as we will be using it to access nd modify Salesforce data once authenticated.
[More infos on Restforce](https://github.com/ejholmes/restforce)

run ```bundle install``` from your terminal window in your app directory.

###### Set Up Connected app

We are going to need a Client Id and Client Secret in order to auth to salesforce. To do so, we need to first create a connected app.

In your Org go to Setup -> Create and Apps. Scroll down to connected app and create a new connected app.
Call it the name you want. I chose Salesforce auth.

Tick the enable OAuth Settings and enter ```http://localhost:3000/auth/salesforce/callback``` as callback url.
Finally give full access and save.

![](https://sdotools-q-labs.s3.amazonaws.com/2017/May/Screen_Shot_2017_05_09_at_11_45_47_AM-1494326773533.png)

You now should have access to client_id and client_secret.
Let's set them up as env variable in our project.

Go to your app directory and create a new file called .env (if you don't have one already).
Like so (of course replace ```CLIENT_ID``` and ```CLIENT_SECRET`` values with the one from your connected app):
![](https://sdotools-q-labs.s3.amazonaws.com/2017/May/Screen_Shot_2017_05_09_at_10_48_44_AM-1494323348095.png)

This will set them up as Environment variable for our project.

###### Set Up Devise

Remember the devise library we set up at the start ? It's time to set it up properly.
It will easily set up a user sign in process for us.

Go to your terminal, to the root of the application an run: ```rails generate devise:install```

In you app, go to config/environments/development.rb and add this line at the end:
```
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

That's it, don't worry about the other instructions on the screen, we won't need it here.

In the terminal again run:
```
rails generate devise User
```

1. In the app, go to db/migrate and open the file inside. We need change this line:```add_index :users, :email, unique: true ```
into this: ```add_index :users, :email ```

And add this one: ``` t.string :uid ```

> We do this because the same email user can exist in different org (SDO) so unicity is not only on email.

2. In app/models/user.rb remove ```:validatable```

> Validatable would make use of encypted password for login. In our case, we are going to use Omniauth to login through salesforce so no need for this.

We need a model for Organization as well.
In the terminal again run:
```
rails generate migration AddOrganization
```
In db/migrate you should see the new file and inside set this up:
```
class AddOrganization < ActiveRecord::Migration[5.0]
  def change
    create_table :organizations do |t|
      t.string :sfdc_id
      t.integer :user_id
      t.string :name
      t.string :username

      t.string :orgname
      t.string :orgtype
      t.datetime :orgexpiry

      t.binary :logo

      t.string :token
      t.string :instanceurl
      t.string :metadataurl
      t.string :serviceurl
      t.string :refreshtoken

      t.string :division

      t.datetime :last_sign_in_date
      t.datetime :org_created_date

      t.integer :exp_notice_level
      t.integer :whitelist_id
      t.integer :organization_type_id

      t.timestamps
    end
  end
end
```
Ok our model is now ready. Go to your terminal window and run ```rails db:migrate```

Last things.
-> Create a organization.rb file under /app/models containing:
```
class Organization < ApplicationRecord
    belongs_to :user
end
```
-> In user.rb add on ``` has_many :organizations ``` below devise

###### Setting up Omniauth

In config/initializers, add a file called ```salesforce.rb``` that contains:
```
module OmniAuth
  module Strategies
    class Salesforce
      def raw_info
        access_token.options[:mode] = :query
        access_token.options[:param_name] = :oauth_token
        u = URI.parse(access_token['id'])
        u.host = URI.parse(access_token['instance_url']).host
        @raw_info ||= access_token.post(u.to_s).parsed
      end
    end

  end
end
```

And another one called ```omniauth.rb``` containing:
```
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :salesforce, ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
end
```

Let's set up the callback URI route and handler.
In config/route.rb add on this:
```
namespace :auth do
    match "/salesforce/callback", :to => "session#callback", :via => [:get, :post]
end
```
And create the corresponding controller. In app/controller create a new folder auth and inside a ```session_controller.rb``` controller.

Fill the session_controller.rb with this:
```
class Auth::SessionController < ApplicationController
	skip_before_filter :verify_authenticity_token

  def callback
    begin
      auth = request.env['omniauth.auth']
      extra = request.env['omniauth.params']['returnURL']

      user = User.find_or_create_by(:email => auth['extra']['email'], :uid => auth['uid'])
      user.uid = auth['uid']
      user.save

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

```
Here is what is happening

On callback from Salesforce Authentication, we use the logged-in user and org info to set session variables and 'sign_in' the user (setting a current_user devise variable) that we create if no email + uid match found.

This, added up to the Organization insert allows us to keep those info in our database for future use. And in a session to be able to get those info in our welcome controller.

In app/controller/welcome_controller.rb :
```
class WelcomeController < ApplicationController
  def index
    p "Welcome Index"
    if current_user.nil?
      p "Current User not set"
      redirect_to '/auth/salesforce', :id => 'sign_in' and return
    end

    p session
    p current_user  
  end
end  
```
When reaching the index, we look into current_user devise variable. If nil (not signed_in) we redirect to omniauth salesforce login that will handle the Authorization and Authentication process and redirect us to our callback above that will then sign in the user and set the sesssion and database records.

>Wow ! that is a lot of information to process

I know ! It's actually not so complicated and overwhelming, it's just that it's using several libraries to handle this all Salesforce Authentication process.

***Let's test all this***

In your terminal, go to your root directory and run ```foreman start -p 3000```.
Then go to your browser and ```localhost:3000```

You should be following the salesforce authentication process and get to your app welcome index page.

If you look into your terminal, you should see session and current_user information.

> Congratulations ! You have now an access token to use Salesforce api in your org :)

###### Passing Org and User infos to Angular

Change welcome_controller.rb as follow:
```
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
```
Refresh your browser (localhost:3000). You should now see your organization and user infos in the terminal window.

Now go to your /app/view/welcome/index.html.erb
Inside ```<script>``` and before ```var package = ...```
Set a context variable as follow:
```
var context = {
      user: JSON.parse('<%= raw @current_user.id %>'),
      organization: JSON.parse('<%= raw @organization.id %>'),
      instanceUrl: '<%= @organization.instanceurl %>'
    };
```
Now go to /public/app/app.component.ts and add this:
```
import {Component} from '@angular/core'

declare let ActionCable:any
declare let context:any
```
Then inside the constructor:
```
console.log(context);
```
Go to your browser, localhost:3000 and inspect the page.
You should now see the context object print in the console containing your context (user id and organization id).

![](https://sdotools-q-labs.s3.amazonaws.com/2017/May/Screen_Shot_2017_05_09_at_12_50_42_PM-1494330676701.png)

> Now that you have the context, you can use it by sending it in the request you make to Rails. Rails will then be able to retrieve the corresponding db record and get the token to use Restforce library to play with your instance data.

###### Restforce Example - Getting a list of Account

Ok let's modify our doStuff method in /public/app/app.component.ts to add context to data sent to backend:
```
doStuff: function(data){    
    data.context = context;
    console.log('Doing stuff', data);
    this.perform('doStuff', data);
}
```
Now go to your backend /app/channels/my_channel.rb and set the doStuff action as follow:
```
def doStuff(data)
 p "Doing stuff"
 p data["context"]


 ActionCable.server.broadcast "MyStream",
      { :method => 'doStuff', :status => 'success',
        :data => { :message => 'Stuff done !' } }
end
```
If you reload your localhost:3000, you will see the context being printed in the terminal.

Now let's use it to set up Restforce and query our Accounts.
Change the method again as follow:
```
def doStuff(data)
    p "Doing stuff"
    begin
    o =  Organization.find(data["context"]["organization"])
    p o

    sClient = Restforce.new :oauth_token => o.token,
        :refresh_token => o.refreshtoken,
        :instance_url => o.instanceurl,
        :api_version => ENV['API_VERSION'], :client_id => ENV['CLIENT_ID'], :client_secret => ENV['CLIENT_SECRET']

    accounts = sClient.query("Select Id, Name from Account Limit 10")

    rescue Exception => e
      ActionCable.server.broadcast "MyStream",
        { :method => 'doStuff', :status => 'error', :data => { :message => e.message } }
    end
    ActionCable.server.broadcast "MyStream",
      { :method => 'doStuff', :status => 'success', :data => { :accounts => accounts } }
  end
```
Re-run you localhost and click the doStuff button, you should now see something like that in your console:
![](https://sdotools-q-labs.s3.amazonaws.com/2017/May/Screen_Shot_2017_05_09_at_1_06_55_PM-1494331634414.png)

###### Display the Account list on the page using Angular

So now that we have the data, we need to display it.
Let's start by changing the app.component.ts as follow
```
import {Component} from '@angular/core'

declare let ActionCable:any
declare let context:any

@Component({
  selector: 'app',
  templateUrl: '/app/app.component.html'
})

export class AppComponent{
  App: any = {};
  accounts:any;

  constructor(){
    console.log(context);
    let self = this;

    this.App.cable = ActionCable.createConsumer("ws://localhost:3000/cable");
    this.App.MyChannel = this.App.cable.subscriptions.create({channel: "MyChannel", context: {} }, {
      // ActionCable callbacks
      connected: function() {
        console.log("connected");
      },
      disconnected: function() {
        console.log("disconnected");
      },
      rejected: function() {
        console.log("rejected");
      },
      received: function(data) {
        console.log('Data Received from backend', data);
        if(data && data.accounts){
          self.accounts = data.accounts;
        }
      },
      doStuff: function(data){
        console.log('Doing stuff', data);
        data.context = context;
        this.perform('doStuff', data);
      }
    });
  }

}
```
What changed ? **2 things**:
1. We check if data and data,accounts on data received and if exists, we set the added 'accounts' property to thie value.

2.```let self = this;``` Because the 'receive' function is inside the App.cable.subscription.create, the 'this' there does not point to our component class anymore. Therefore we make sure to set the component reference to a different variable before so we can use it then.

Now we just need to set the list in the app.component.html as follow:
```
<header-component></header-component>
<div class="slds-grid slds-wrap">
  <div class="slds-p-around--medium">
    <button class="slds-button slds-button--destructive slds-m-right--small"
            (click)="App.MyChannel.doStuff({ data: 'Just a string' })">Do Stuff</button>
  </div>
  <div class="slds-p-horizontal--small slds-size--1-of-1">
    <ul class="slds-has-dividers--around-space" *ngIf="accounts">
      <li *ngFor="let a of accounts" class="slds-item">{{ a.Name }}</li>
    </ul>
  </div>
</div>
```
Restart your server and reload localhost:3000. Click on the doStuff button and you should see something like that:
![](https://sdotools-q-labs.s3.amazonaws.com/2017/May/Screen_Shot_2017_05_09_at_1_18_47_PM-1494332340870.png)

> You now have set up Salesforce data access from your Rails5 / Angular4 app !

In the next post, I'll show how to set up Heroku to get this all working in the cloud ! ;)

Meanwhile, you can play around Restforce capability to enhance your app. [Library link](https://github.com/ejholmes/restforce)

 #chill
