// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Register the custom Turbo Stream action
// This makes <turbo-stream action="turbo_visit" url="some_path" /> work

console.log("application.js loaded"); // Add this

Turbo.StreamActions.turbo_visit = function() {
  console.log("Turbo.StreamActions.turbo_visit function called."); // Add this
  const url = this.getAttribute("url");
  if (url) {
    console.log("URL from turbo-stream tag:", url); // Add this
    this.element.dispatchEvent(new CustomEvent("turbo-stream:turbo-visit", {
      bubbles: true,
      cancelable: true,
      detail: { url: url }
    }));
    console.log("Custom event 'turbo-stream:turbo-visit' dispatched."); // Add this
  } else {
    console.warn("Turbo Stream: 'turbo_visit' action received without a 'url' attribute."); // Add this
  }
};