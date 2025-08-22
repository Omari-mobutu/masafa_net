import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="multi-step-form"

export default class extends Controller {
  static targets = ["step"]

  connect() {
    this.showStep(1); // Initially show the first step
  }

  showStep(stepNumber) {
    this.stepTargets.forEach(element => {
      if (parseInt(element.dataset.step) === stepNumber) {
        element.classList.remove("hidden");
        // Focus on the first input in the new step for better UX
        const firstInput = element.querySelector('input, select, textarea');
        if (firstInput) {
          firstInput.focus();
        }
      } else {
        element.classList.add("hidden");
      }
    });
  }

  nextStep() {
    this.showStep(2);
  }

  previousStep() {
    this.showStep(1);
  }
}