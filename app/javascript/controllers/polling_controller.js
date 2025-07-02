import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="polling"
export default class extends Controller {
  // Define values that can be passed from HTML data attributes
  static values = {
    url: String,      // The URL to poll (e.g., /hotspot/payment_status?transaction_id=...)
    interval: Number  // The polling interval in milliseconds (e.g., 3000 for 3 seconds)
  }

  connect() {
    console.log("Polling controller connected.", { url: this.urlValue, interval: this.intervalValue });
    // Immediately fetch the status on connect
    this.fetchStatus();
    // Start polling interval
    this.interval = setInterval(() => this.fetchStatus(), this.intervalValue);
  }

  disconnect() {
    console.log("Polling controller disconnected.");
    // Clear the interval when the controller is removed from the DOM
    clearInterval(this.interval);
  }

  fetchStatus() {
    // Only poll if we're on the page and the redirect hasn't happened yet
    // Check if the redirection_target div has any content (meaning the redirect script has been inserted)
    if (document.getElementById('redirection_target')?.hasChildNodes()) {
      console.log("Redirect script detected, stopping polling.");
      this.disconnect(); // Stop polling if redirect is already initiated
      return;
    }

    console.log("Polling for payment status...");
    fetch(this.urlValue, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html' // Crucial: Tell server we expect Turbo Stream
      }
    })
    .then(response => {
      // If the response is a Turbo Stream, render it
      if (response.headers.get('Content-Type')?.includes('text/vnd.turbo-stream.html')) {
        return response.text();
      }
      // Otherwise, log error or handle unexpected response
      console.error("Expected Turbo Stream, but received:", response.headers.get('Content-Type'));
      throw new Error("Unexpected content type from polling endpoint.");
    })
    .then(html => {
      console.log("html", { html });
      // Use Turbo.Stream.render to process the Turbo Stream response
      // This will update 'payment_status' or 'redirection_target' as defined in your controller
      Turbo.renderStreamMessage(html);


      // After rendering, check again if the redirect script has been inserted
      if (document.getElementById('redirection_target')?.hasChildNodes()) {
        console.log("Redirect script rendered, polling stopped.");
        this.disconnect(); // Stop polling once the redirect is handled
      }
    })
    .catch(error => {
      console.error("Polling fetch error:", error);
      // Optional: Implement exponential backoff or retry logic here
    });
  }
}

