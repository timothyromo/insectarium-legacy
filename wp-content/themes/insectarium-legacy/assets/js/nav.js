/* Insectarium Legacy — minimal nav behaviour. Weebly's main.js is not loaded. */
(function () {
	'use strict';

	document.addEventListener('click', function (e) {
		// Mobile: hamburger toggles the slide-in menu.
		var burger = e.target.closest('.hamburger');
		if (burger) {
			e.preventDefault();
			document.body.classList.toggle('mobile-nav-open');
			return;
		}

		// Mobile: a tapped item that owns a submenu.
		//   - group header WITHOUT an href: first tap opens, next tap closes it.
		//   - item WITH an href (e.g. "Care Sheets"): first tap opens the submenu
		//     so its children are reachable; a second tap (submenu already open)
		//     follows the href.
		var link = e.target.closest('.mobile-nav .wsite-menu-item, .mobile-nav .wsite-menu-subitem');
		if (!link) { return; }
		var li = link.parentNode;
		var submenu = li && li.querySelector('.wsite-menu-wrap');
		if (!submenu) { return; }  // leaf link — navigate normally

		if (!li.classList.contains('open')) {
			e.preventDefault();          // first tap: reveal children instead of navigating
			li.classList.add('open');
		} else if (!link.getAttribute('href')) {
			e.preventDefault();          // open group header, no href: second tap closes
			li.classList.remove('open');
		}
		// else: submenu already open and link has an href — let the tap navigate.
	});

	// Close mobile menu on resize up to desktop.
	var mq = window.matchMedia('(min-width: 768px)');
	mq.addEventListener('change', function (ev) {
		if (ev.matches) { document.body.classList.remove('mobile-nav-open'); }
	});
})();
