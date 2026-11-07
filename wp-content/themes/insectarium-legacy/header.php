<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<meta name="description" content="Portland's first zoo and museum dedicated entirely to insects and arachnids!" />
	<meta name="keywords" content="insects, museum, travel, bugs, arachnids, spiders, beetles, bug zoo, crawlers, flies, wings, tentacles, ants, butterflies, moths, caterpillar" />
	<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<div class="wrapper">
	<div class="cento-header">
		<div class="nav-wrap">
			<div class="container">
				<a class="hamburger" aria-label="Menu" href="#"><span></span></a>
				<div class="logo">
					<span class="wsite-logo">
						<a href="<?php echo esc_url( home_url( '/' ) ); ?>">
							<img src="<?php echo esc_url( il_asset( 'assets/img/insectarium-logo-1.png' ) ); ?>" alt="PORTLAND INSECTARIUM" />
						</a>
					</span>
				</div>
				<div class="nav desktop-nav">
					<div class="container">
						<?php require get_template_directory() . '/template-parts/site-nav.php'; ?>
					</div>
				</div>
			</div>
		</div>
	</div>
	<div class="main-wrap">
