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
