/* Insectarium Legacy — minimal nav behaviour. Weebly's main.js is not loaded. */
(function () {
	'use strict';

	// Mobile: hamburger toggles the slide-in menu.
	document.addEventListener('click', function (e) {
		var burger = e.target.closest('.hamburger');
		if (burger) {
			e.preventDefault();
			document.body.classList.toggle('mobile-nav-open');
			return;
		}
		// Touch / no-hover: tapping a parent item with a submenu opens it
		// instead of navigating (parent <a> has no href).
		var parentLink = e.target.closest('.mobile-nav .wsite-menu-item, .mobile-nav .wsite-menu-subitem');
		if (parentLink && parentLink.parentNode.querySelector('.wsite-menu-wrap')) {
			if (!parentLink.getAttribute('href')) {
				e.preventDefault();
				parentLink.parentNode.classList.toggle('open');
			}
		}
	});

	// Close mobile menu on resize up to desktop.
	var mq = window.matchMedia('(min-width: 768px)');
	mq.addEventListener('change', function (ev) {
		if (ev.matches) { document.body.classList.remove('mobile-nav-open'); }
	});
})();
