// app/javascript/controllers/turbo_stream_actions_controller.js
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  connect() {
    console.log("Turbo Stream Actions Controller connected");
    this.element.addEventListener("turbo-stream:turbo-visit", this.turboVisit.bind(this));
    console.log("Stimulus: Listening for 'turbo-stream:turbo-visit' event.");
  }

  // This method will be called when a <turbo-stream action="turbo_visit" url="..." /> is received.
  turboVisit(event) {
    console.log("Stimulus: turboVisit method called by event.", event); // Add this
    const url = event.detail.url;
    console.log("Stimulus: Performing Turbo.visit to", url);
    Turbo.visit(url);
  }
}