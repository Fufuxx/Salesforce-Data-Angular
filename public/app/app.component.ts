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
      },
      doStuff: function(data){
        console.log('Doing stuff', data);
        this.perform('doStuff', data);
      }
    });
  }

}
