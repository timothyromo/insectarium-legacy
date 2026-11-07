<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
get_header();
?>
<div id="wsite-content" class="wsite-elements wsite-not-footer">
	<div class="wsite-section-wrap">
		<div class="wsite-section wsite-body-section">
			<div class="wsite-section-content"><div class="container"><div class="wsite-section-elements">
				<div class="paragraph" style="text-align:center;">
					<h2>Page not found</h2>
					<p>Try the menu above, or <a href="<?php echo esc_url( home_url( '/' ) ); ?>">return to the home page</a>.</p>
				</div>
			</div></div></div>
		</div>
	</div>
</div>
<?php
get_footer();
