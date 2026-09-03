<?php get_header(); ?>
<div class="main-wrap">
	<div id="wsite-content" class="wsite-elements wsite-not-footer">
		<?php while ( have_posts() ) : the_post(); the_content(); endwhile; ?>
	</div>
</div>
<?php get_footer();
