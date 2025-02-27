// Entry point for the build script in your package.json
import * as bootstrap from "bootstrap";
import "@hotwired/turbo-rails";
import sortable from "html5sortable/dist/html5sortable.es";
import Swiper from "swiper";
import { Navigation, Pagination } from "swiper/modules";
import stimulusApp from "./stimulus";

// Global variables used to make libraries accessible across different scripts
window.bootstrap = bootstrap;
window.sortable = sortable;
window.Swiper = Swiper; // Core functionality
window.SwiperNavigation = Navigation; // Additional module
window.SwiperPagination = Pagination; // Additional module
window.Stimulus = stimulusApp;
