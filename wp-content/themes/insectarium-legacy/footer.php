<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
?>
	</div><!-- /.main-wrap -->

	<div class="footer-wrap">
		<div class="footer">
			<div class="wsite-elements wsite-footer">
				<div class="wsite-search-element-outer">
					<div class="wsite-search-element-align-center" style="padding: 10px 0 10px 0">
						<form class="wsite-search-element-form" action="<?php echo esc_url( home_url( '/' ) ); ?>" method="get">
							<div class="wsite-search-element">
								<input class="wsite-input wsite-search-element-input" type="text" name="s" placeholder="Search" autocomplete="off" aria-label="Search" />
								<button class="wsite-search-element-submit" title="Search" type="submit"></button>
							</div>
						</form>
					</div>
				</div>
				<div class="paragraph" style="text-align:center;">
					<span style="color:rgb(42, 42, 42); font-weight:400">&#8203;&copy;2018 Portland Insectarium</span>
				</div>
			</div>
		</div>
	</div>

	<div id="navMobile" class="nav mobile-nav">
		<a class="hamburger" aria-label="Menu" href="#"><span></span></a>
		<?php require get_template_directory() . '/template-parts/site-nav.php'; ?>
	</div>

</div><!-- /.wrapper -->

<script src="https://fareharbor.com/embeds/api/v1/?autolightframe=yes"></script>
<?php wp_footer(); ?>
</body>
</html>
