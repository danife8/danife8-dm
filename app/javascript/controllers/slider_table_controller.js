import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="slider-table"
export default class extends Controller {
  static targets = [
    "sliderContainer",
    "paginationContainer",
    "prevButton",
    "nextButton",
  ];

  connect() {
    new window.Swiper(this.sliderContainerTarget, {
      modules: [window.SwiperNavigation, window.SwiperPagination],
      navigation: {
        prevEl: this.prevButtonTarget,
        nextEl: this.nextButtonTarget,
      },
      pagination: {
        el: this.paginationContainerTarget,
        clickable: true,
      },
      autoHeight: true,
    });
  }
}
