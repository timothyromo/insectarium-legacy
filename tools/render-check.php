<?php
/**
 * Task 9 Part 2 - portable-PHP template render smoke test.
 *
 * Minimal WordPress function stubs, then include the theme's page.php with
 * the_content() echoing a page fragment passed as argv[1]. Lets us render the
 * real header.php / template-parts/site-nav.php / page.php / footer.php chain
 * without a WordPress install.
 *
 *   php tools/render-check.php scripts/pages/home.html   > rendered.html
 *
 * All errors/warnings/notices are routed to stderr (error_reporting(E_ALL)).
 */

error_reporting( E_ALL );
ini_set( 'display_errors', 'stderr' );

$FRAG = $argv[1] ?? '';
if ( $FRAG === '' || ! is_file( $FRAG ) ) {
	fwrite( STDERR, "usage: php tools/render-check.php <fragment.html>\n" );
	exit( 2 );
}

define( 'ABSPATH', dirname( __DIR__ ) . '/' );
$THEME = dirname( __DIR__ ) . '/wp-content/themes/insectarium-legacy';
$GLOBALS['__il_frag'] = file_get_contents( $FRAG );

// ---- minimal WP shims ----------------------------------------------------
function language_attributes() { echo 'lang="en-US"'; }
function bloginfo( $key ) { echo $key === 'charset' ? 'UTF-8' : ''; }
function wp_head() {}
function wp_footer() {}
function wp_body_open() {}
function body_class() { echo 'class="page"'; }
function esc_url( $u ) { return $u; }
function home_url( $path = '' ) { return 'https://example.test/' . ltrim( $path, '/' ); }
function get_template_directory() { global $THEME; return $THEME; }
function get_template_directory_uri() { return 'https://example.test/wp-content/themes/insectarium-legacy'; }
function il_asset( $rel ) { return get_template_directory_uri() . '/' . ltrim( $rel, '/' ); }
function have_posts() { static $n = 0; return $n++ < 1; }
function the_post() {}
function the_content() { echo $GLOBALS['__il_frag']; }
function get_header() { include get_template_directory() . '/header.php'; }
function get_footer() { include get_template_directory() . '/footer.php'; }

include $THEME . '/page.php';
