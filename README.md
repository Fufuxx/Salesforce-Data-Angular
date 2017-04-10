## Where we left off

If you didn't go through it, I would recommend to follow the first tutorial to get you base app running, as I'll use it as a starting point for this tuto: [Get Started with rails 5 & Angular](https://q-labs.herokuapp.com/2016/10/28/get-started-angular2-rails5/)

###### Updating the all thing

As you know in software, everything evolves quite rapidly, so since the last post on getting started on rails 5 and Angular, Angular came up with a brand new Version ! **4.0.0**

So let's go ahead and update our Angular version as well as setting action-cable.js library for our WebSocket.

Open up ```package.json``` in you app root directory and update its content

```
{
  "name": "rails-ng2",
  "version": "0.0.1",
  "scripts": {
    "tsc": "tsc",
    "tsc:w": "tsc -w",
    "typings": "typings",
    "postinstall": "typings install"
  },
  "repository": {
    "type": "git",
    "url": ""
  },
  "license": "ISC",
  "dependencies": {
    "@angular/animations": "^4.0.0",
    "@angular/common": "^4.0.0",
    "@angular/compiler": "^4.0.0",
    "@angular/compiler-cli": "^4.0.0",
    "@angular/core": "^4.0.0",
    "@angular/forms": "^4.0.0",
    "@angular/http": "^4.0.0",
    "@angular/platform-browser": "^4.0.0",
    "@angular/platform-browser-dynamic": "^4.0.0",
    "@angular/platform-server": "^4.0.0",
    "@angular/platform-webworker": "^4.0.0",
    "@angular/router": "^4.0.0",
    "@angular/upgrade": "^4.0.0",
    "actioncable-js": "5.0.0-rc2",
    "es6-shim": "^0.35.0",
    "reflect-metadata": "^0.1.3",
    "rxjs": "^5.0.1",
    "systemjs": "0.19.41",
    "time-ago-pipe": "^1.1.1",
    "typescript": "^2.2.2",
    "zone.js": "^0.8.4"
  },
  "engines": {
    "node": ">= 5.4.1 < 7"
  },
  "devDependencies": {
    "typescript": "^2.0.10",
    "typings": "^2.0.0"
  }
}
```
Then, open up your terminal, go to your root directory, and type the command ```npm install```

Ok, now we need to delete the old ```node_modules``` folder in ```public/``` directory and replace it with the new one just generated in the app root directory.

One last thing...
Go to tsconfig.json in your app root directory and make sure you have the ```compileOnSave``` property set up.

We have noticed that some IDE didn't generate js and map.js file automatically without it.

```
{
  "compileOnSave": true,
  "compilerOptions": {
    "target": "es5",
    "module": "system",
    "moduleResolution": "node",
    "sourceMap": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "removeComments": false,
    "noImplicitAny": false,
    "rootDir":"public"
  },
  "exclude": [
    "node_modules",
    "typings/main",
    "typings/main.d.ts"
  ]
}
```

Once that done, run ```foreman start -p 3000``` in your command line and go to ```localhost:3000``` in your favorite browser.

> You should still see the original app running. It has now been updated ! Woooo...

###### Setting up ActionCable - Backend

In you app root directory, go to ```app/views/layouts/application.html.erb``` and make sure you have the action-cable.js script set up
![](https://sdotools-q-labs.s3.amazonaws.com/2017/Apr/Screen_Shot_2017_04_10_at_12_54_25_PM-1491825301767.png)

Now, in ```app/channels``` directory, create a new file called **my_channel.rb**, which contains

```
class MyChannel < ApplicationCable::Channel
  def subscribed
    p "Setting Stream"
    stream_from "MyStream"
  end

  def doStuff(data)
    p "Doing stuff"
    p data
    ActionCable.server.broadcast "MyStream",
      { :method => 'doStuff', :status => 'success',
        :data => { :message => 'Stuff done !' } }
  end
end
```
ActionCable will create a general channel for us. From there, we can initiate a Stream that we'll be able to subscribe to.
Once Subscribed, we'll be able to receive notifications from the Stream (broadcast method above).

> That is our Backend set up for ActionCable. Pretty fast and easy.

###### Setting up ActionCable - Frontend

Now it's time to hook up Angular into this, and in order to do so, we are going to use the action-cable.js library.

In the ```/public/app/app.component.ts```, let's set up our connection

```
import {Component} from '@angular/core'

declare let ActionCable:any

@Component({
  selector: 'app',
  templateUrl: '/app/app.component.html'
})

export class AppComponent{
  App: any = {};

  constructor(){
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
      }
    });
  }

}

```
**What changed ?**

1 - ```declare let ActionCable:any;```
If the class used by action-cable javascript library is not declared, Angular will reject it as undefined. So we simply define it for Angular so we can use it from there.

2 - We are calling ```ActionCable.createConsumer``` method to create a connection to our channel from Angular, to be able to call methods from here (such as ```doStuff```) and receive broadcast responses ```received: function(data){}``` method.

Go to your terminal, stop the server if running (cmd+c or ctrl+c) and rerun ```foreman start -p 3000```

reload your app and you should get something like that in your browser console:
![Logs](https://sdotools-q-labs.s3.amazonaws.com/2017/Apr/Screen_Shot_2017_04_10_at_11_53_26_AM-1491821740610.png)

> You have now connected your Angular front end to rails ActionCable backend !

How about we try out calling our doStuff() method ? So we see how this all thing works.

Go back to your ```/public/app/app.component.html``` and set this:

```
<div class="slds-grid slds-wrap">
  <div class="slds-p-around--medium">
    <button class="slds-button slds-button--destructive slds-m-right--small"
            (click)="App.MyChannel.doStuff({ data: 'Just a sting' })">Do Stuff</button>
  </div>
</div>

```
Here we simply added a button to our app component and on click, we are calling a method doStuff() on our App.MyChannel that we set up in the constructor of our class.

> Yes ! See, we can do that ! 'App' is a property (type 'any' so we can use it as an object) of your app.component.ts class (check it), so we can refer to it anywhere in the class, but also in our template.

We now need to set up this method on the App.MyChannel in the app component class ```app.component.ts```
So open up the class, and add the doStuff method to the App.MyChannel (after the receive method) as follow:
```
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
      },
      doStuff: function(data){
        console.log('Doing stuff', data);
        this.perform('doStuff', data);
      }
    });
```
Ok. So our button click calls doStuff method of App.MyChannel.

Inside the doStuff method, you can see ```this.perform('doStuff', data)```
This is calling our channel method 'doStuff' in our backend ! And it's even passing arguments (our data).

So let's see it all in action.
Reload your application (or run it using ```foreman start -p 3000``` if not running)
1 - You should see what we've already seen before, connected printed in the javascript console.
And on the command line interface, you should see this
![](https://sdotools-q-labs.s3.amazonaws.com/2017/Apr/Screen_Shot_2017_04_10_at_12_12_38_PM-1491822785779.png)
2 - After clicking on the button, you should see this in your browser console
![](https://sdotools-q-labs.s3.amazonaws.com/2017/Apr/Screen_Shot_2017_04_10_at_12_13_43_PM-1491822860496.png)
And this on your command line interface
![](https://sdotools-q-labs.s3.amazonaws.com/2017/Apr/Screen_Shot_2017_04_10_at_12_15_02_PM-1491822922668.png)

So on click, Angular ran the doStuff method of the App.Channel property, which called a this.perform('doStuff', data). The perform here is used to actually called the backend method in the MyChannel class.

The backend method ran and at the end broadcasted the result that was received by Angular through App.MyChannel again -> received method.

> Congratulations ! You now successfully linked Angular and rails5 ActionCable together to access backend method through WebSocket.

######Important note

You might have noticed the ```context: {} ``` variable passed in the ```this.App.MyChannel = this.App.cable.subscriptions.create({channel: "MyChannel", context: {} }, {...```

**WebSockets need a context**

Let's say you and I are using this app at the same time. Now, you are clicking the button. We'll both receive a notification 'Data received...' because we both subscribed to the same stream that broadcasts the response.

**But I didn't do anything, you did... So I shouldn't get notified right ?**

It doesn't matter much here, but what if you were retrieving some sensitive information ?  I would receive it too.

What are the options then ?
1 - Make the stream linked to the logged-in user Id so each User has his own stream.
2 - If you need more context, you can simply pass it from Angular to Rails and back and check it (hence the context variable).

###### A bit of Angular to finish up

I thought I would try to show some Angular stuff quickly on the way.
So I want to show how externalize a component on Angular. It's quite basic but important as you can then organize your app better.

Let's create a new folder called structure containing a header-component component. ```/public/app/structure/header-component.ts```:

```
import {Component} from '@angular/core'

@Component({
  selector: 'header-component',
  templateUrl: '/app/structure/header-component.html'
})

export class HeaderComponent{}
```
Note the selector. This is what we'll use to inject the component. Try to not use selector names like 'header' or 'article' as those are standard html already existing element tags and can lead to conflicts.

Then let's create the template by copy/pasting the header html code from the app.component.html:
 ```/public/app/structure/header-component.html ```

```
<div class="slds-page-header" role="banner">
  <div class="slds-media slds-media--center">
    <div class="slds-media__figure">
      <svg aria-hidden="true" class="slds-icon slds-icon-standard-quotes">
        <use xlink:href="/css/assets/icons/standard-sprite/svg/symbols.svg#endorsement"></use>
      </svg>
    </div>
    <div class="slds-media__body">
      <p class="slds-page-header__title slds-truncate slds-align-middle" title="My App">This is a Header</p>
      <p class="slds-text-body--small page-header__info">Testing SLDS with Angular Final and Rails 5</p>
    </div>
  </div>
</div>
```

And replace this code in app.component.html using the new header-component selector:```<header-component></header-component>```

Last thing we need to do it's to add the new component to the overall app module.

In ``` /public/app/app.module.ts ```, Import the new component:

```
import {HeaderComponent} from './structure/header-component.ts'
```
And add it up to @NgModule Declarations:
```
@NgModule({
  imports: [
    BrowserModule
  ],
    declarations: [
      AppComponent,
      HeaderComponent
  ],
  bootstrap: [ AppComponent ]
})
```
Et Voilà !!
You should still have your header as follow:
![](https://sdotools-q-labs.s3.amazonaws.com/2017/Apr/Screen_Shot_2017_04_10_at_12_43_38_PM-1491824664380.png)

You can now organize your code as you'd like by externalizing any component.

There are lots of other things I'd like to show but I am not going to write a book right now so stay tuned for the next post(s).

 #chill
