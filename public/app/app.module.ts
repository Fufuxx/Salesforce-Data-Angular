import {NgModule} from '@angular/core'
import {BrowserModule} from '@angular/platform-browser'
import {AppComponent} from './app.component'
import {HeaderComponent} from './structure/header-component'


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

export class AppModule {
  constructor(){
    console.log('App Module');
  }
}
