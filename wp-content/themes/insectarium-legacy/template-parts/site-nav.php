<?php
/**
 * Version A primary navigation — hardcoded, matches the export's index.html.
 * Shared by header.php (desktop) and footer.php (#navMobile).
 */
if ( ! defined( 'ABSPATH' ) ) { exit; }
$home = esc_url( home_url( '/' ) );
?>
<ul class="wsite-menu-default">
	<li class="wsite-menu-item-wrap"><a href="<?php echo $home; ?>" class="wsite-menu-item">Home</a></li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Info</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>about-us" class="wsite-menu-subitem"><span class="wsite-menu-title">About us</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>faq-about-the-insectarium" class="wsite-menu-subitem"><span class="wsite-menu-title">FAQ about the insectarium</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>faq-about-bugs" class="wsite-menu-subitem"><span class="wsite-menu-title">FAQ about bugs</span></a></li>
		</ul></div>
	</li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Visit</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>calendar" class="wsite-menu-subitem"><span class="wsite-menu-title">Calendar</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>admission" class="wsite-menu-subitem"><span class="wsite-menu-title">Admission</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>hourslocation" class="wsite-menu-subitem"><span class="wsite-menu-title">Hours/Location</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>summer-camp" class="wsite-menu-subitem"><span class="wsite-menu-title">Summer Camp</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>memberships" class="wsite-menu-subitem"><span class="wsite-menu-title">Memberships</span></a></li>
		</ul></div>
	</li>

	<li class="wsite-menu-item-wrap"><a href="<?php echo $home; ?>public-events" class="wsite-menu-item">Public Events</a></li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Private Events and Field Trips</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>private-events" class="wsite-menu-subitem"><span class="wsite-menu-title">Events at the Insectarium</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>off-site-events" class="wsite-menu-subitem"><span class="wsite-menu-title">Off-site events</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>photo-shoots" class="wsite-menu-subitem"><span class="wsite-menu-title">Photo shoots</span></a></li>
		</ul></div>
	</li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Get involved</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>bug-club" class="wsite-menu-subitem"><span class="wsite-menu-title">Bug Club</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>community" class="wsite-menu-subitem"><span class="wsite-menu-title">Community</span></a></li>
		</ul></div>
	</li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Other</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>shop" class="wsite-menu-subitem"><span class="wsite-menu-title">Shop</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>services" class="wsite-menu-subitem"><span class="wsite-menu-title">Services</span></a></li>
			<li class="wsite-menu-subitem-wrap">
				<a href="<?php echo $home; ?>care-sheets" class="wsite-menu-subitem"><span class="wsite-menu-title">Care Sheets</span><span class="wsite-menu-arrow">&gt;</span></a>
				<div class="wsite-menu-wrap"><ul class="wsite-menu">
					<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>care-sheets/jumping-spiders" class="wsite-menu-subitem"><span class="wsite-menu-title">Jumping Spiders</span></a></li>
					<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>care-sheets/ghost-mantis" class="wsite-menu-subitem"><span class="wsite-menu-title">Ghost Mantis</span></a></li>
					<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>care-sheets/isopods" class="wsite-menu-subitem"><span class="wsite-menu-title">Isopods</span></a></li>
				</ul></div>
			</li>
		</ul></div>
	</li>
</ul>
