<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
get_header();
?>
<div id="wsite-content" class="wsite-elements wsite-not-footer">
	<?php
	while ( have_posts() ) :
		the_post();
		the_content();
	endwhile;
	?>
</div>
<?php
get_footer();
