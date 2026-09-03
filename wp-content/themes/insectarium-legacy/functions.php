<?php
/**
 * Insectarium Legacy — temporary Weebly replica theme.
 *
 * Loads the vendored Weebly base CSS + this site's theme CSS, then our small
 * chrome layer. No menus, widgets, or comments. Content is pre-formatted HTML,
 * so wpautop/wptexturize are disabled to keep it byte-exact.
 */

if ( ! defined( 'ABSPATH' ) ) { exit; }

if ( ! isset( $content_width ) ) {
	$content_width = 1140;
}

function il_asset( $rel ) {
	return get_template_directory_uri() . '/' . ltrim( $rel, '/' );
}

function il_theme_setup() {
	add_theme_support( 'title-tag' );
	add_theme_support( 'automatic-feed-links' );
	// Deliberately NOT adding: post-thumbnails UI, custom-logo, editor-styles,
	// align-wide, responsive-embeds. This theme renders raw imported HTML.
}
add_action( 'after_setup_theme', 'il_theme_setup' );

function il_enqueue_assets() {
	$ver = wp_get_theme()->get( 'Version' );

	wp_enqueue_style( 'il-fonts',      il_asset( 'assets/vendor/fonts/amaranth/font.css' ),   array(), $ver );
	wp_enqueue_style( 'il-fonts-mont', il_asset( 'assets/vendor/fonts/montserrat/font.css' ), array(), $ver );
	wp_enqueue_style( 'il-fonts-gent', il_asset( 'assets/vendor/fonts/gentium-basic/font.css' ), array(), $ver );
	wp_enqueue_style( 'il-fonts-os',   il_asset( 'assets/vendor/fonts/open-sans/font.css' ),  array(), $ver );

	wp_enqueue_style( 'il-sites',      il_asset( 'assets/vendor/sites.css' ),      array( 'il-fonts' ), $ver );
	wp_enqueue_style( 'il-main-style', il_asset( 'assets/vendor/main_style.css' ), array( 'il-sites' ), $ver );
	wp_enqueue_style( 'il-fh-kit',     il_asset( 'assets/vendor/fh-kit.css' ),     array( 'il-main-style' ), $ver );
	wp_enqueue_style( 'il-theme',      il_asset( 'theme.css' ),                    array( 'il-fh-kit' ), $ver );

	wp_enqueue_script( 'il-nav', il_asset( 'assets/js/nav.js' ), array(), $ver, true );
}
add_action( 'wp_enqueue_scripts', 'il_enqueue_assets' );

// Content is imported, pre-formatted HTML — emit it unchanged.
remove_filter( 'the_content', 'wpautop' );
remove_filter( 'the_content', 'wptexturize' );
remove_filter( 'the_excerpt', 'wpautop' );

// Kill block-library front-end CSS (this is a classic theme; imported content
// carries its own styles).
function il_dequeue_block_css() {
	wp_dequeue_style( 'wp-block-library' );
	wp_dequeue_style( 'wp-block-library-theme' );
	wp_dequeue_style( 'global-styles' );
	wp_dequeue_style( 'classic-theme-styles' );
}
add_action( 'wp_enqueue_scripts', 'il_dequeue_block_css', 100 );

// Document title: "<Page> - PORTLAND INSECTARIUM" (matches the export).
function il_document_title( $parts ) {
	if ( is_front_page() ) {
		$parts['title'] = 'Portland Insectarium';
	}
	$parts['site']    = 'PORTLAND INSECTARIUM';
	$parts['tagline'] = '';
	return $parts;
}
add_filter( 'document_title_parts', 'il_document_title' );
add_filter( 'document_title_separator', function () { return '-'; } );

// All site content is Pages, so make the front-end search query them
// (WordPress core searches only the `post` type by default). Keeps the
// footer search box functional, matching the live Weebly site's search.
function il_search_pages( $query ) {
	if ( ! is_admin() && $query->is_main_query() && $query->is_search() ) {
		$query->set( 'post_type', 'page' );
	}
}
add_action( 'pre_get_posts', 'il_search_pages' );
