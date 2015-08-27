use Module::Build;
my $build = Module::Build->new
	(
	module_name => 'cworld::crane_nature2015',
	license  => 'perl',
	requires => {
				'perl'          => '5.6.1',
				},
	dist_author => 'Bryan R. Lajoie <bryan.lajoie@umassmed.edu>',
	);
$build->create_build_script;
