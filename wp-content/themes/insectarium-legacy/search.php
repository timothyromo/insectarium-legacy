<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
get_header();
?>
<div id="wsite-content" class="wsite-elements wsite-not-footer">
	<div class="wsite-section-wrap"><div class="wsite-section wsite-body-section">
	<div class="wsite-section-content"><div class="container"><div class="wsite-section-elements">
		<h2 class="wsite-content-title">Search results for &ldquo;<?php echo esc_html( get_search_query() ); ?>&rdquo;</h2>
		<?php if ( have_posts() ) : ?>
			<ul class="il-search-results">
			<?php while ( have_posts() ) : the_post(); ?>
				<li><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
				<div class="paragraph"><?php echo esc_html( wp_trim_words( wp_strip_all_tags( get_the_content() ), 40 ) ); ?></div></li>
			<?php endwhile; ?>
			</ul>
		<?php else : ?>
			<div class="paragraph"><p>No pages matched. Try the menu above, or <a href="<?php echo esc_url( home_url( '/' ) ); ?>">return home</a>.</p></div>
		<?php endif; ?>
	</div></div></div>
	</div></div>
</div>
<?php
get_footer();
