use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

my ($report_dir,$outdir) = @ARGV;

# SARS_CoV_2_variantCaller_out.1613/
# variantCaller_out.1629/


# first get all variantCaller_out.* dir
my $vc_dirs_aref = &get_vc_dir_by_run_time($report_dir);

# for each variantCaller_out.*, creat a new dir
for my $dir (@{$vc_dirs_aref}){
	# mkdir
	print "creating $outdir/$dir\n";
	`mkdir $outdir/$dir`;

	#if (-d "$outdir/$dir"){
	#	`rm $outdir/$dir`;
	#	`mkdir $outdir/$dir`;
	#}else{
	#	`mkdir $outdir/$dir`;
	#}

	my $vc_dir = "$report_dir/$dir";
	# get all TSVC_variants.vcf
	my @vcf = glob "$vc_dir/*/TSVC_variants.vcf";

	# if this vcf is from cov-2 sample?
	# vcf contain "2019-nCoV"
	my @cov_vcf;
	for my $vcf (@vcf){
		my $if_cov2_vcf = &check_if_cov2_vcf();
		if ($if_cov2_vcf eq "YES"){
			push @cov_vcf, $vcf;
		}else{
			print "[NOT SARS-CoV-2 VCF]: $vcf\n";
		}
	}

	my %sample_vars;
	my %all_vars;
	my %sample;
	for my $vcf (@cov_vcf){
		my $base_dir = dirname($vcf);
		my $barcode = basename($base_dir);
		$sample{$barcode} = 1; # barcode [IonXpress_001]

		open VCF, "$vcf" or die;
		while (<VCF>){
			chomp;
			next if (/^\#/); #skip # line
			my @arr = split /\t/;
			if ($arr[0] ne "2019-nCoV"){
				next; # skip
			}
			my $var = "$arr[0]\:$arr[1]\:$arr[3]\:$arr[4]"; # 2019-nCoV:210:G:T
			my $freq_tmp = (split /\;/, $arr[7])[0]; # AF=1
			my $freq = (split /\=/, $freq_tmp)[1]; # freq is 0.98

			$sample_vars{$barcode}{$var} = $freq;

			my $pos = $arr[1];
			push @{$all_vars{$pos}}, $var;
		}
		close VCF;
	}
}




sub check_if_cov2_vcf{
	my $vcf = $_[0];
	my $flag = 0;
	open IN, "$vcf" or die;
	while (<IN>){
		chomp;
		next if (/^\#/);
		my @arr = split /\t/;
		if ($arr[0] eq "2019-nCoV"){
			$flag += 1;
		}
	}
	close IN;

	my $res;
	if ($flag == 0){
		$res = "NO";
	}else{
		$res = "YES";
	}

	return($res);
}



sub get_vc_dir_by_run_time{
	my ($dir) = @_;
	my @startplugin_json = glob "$dir/plugin_out/*/startplugin.json"; # /results/analysis/output/Home/2019-nCoV-map2hg19-exon-virus_241/plugin_out/variantCaller_out.1257/startplugin.json
	my @vc_dirs;
	for my $json (@startplugin_json){
		my $basedir = dirname($json);
		my $vc_name = basename($basedir);
		if ($vc_name =~ /variantCaller/){
			next if ($vc_name =~ /variantCallerMerge/); # skip self outdir. if this plugin run many times.
			# variantCaller_out.1257/
			# SARS_CoV_2_variantCaller_out.1529/
			push @vc_dirs, $vc_name;
		}
	}

	return(\@vc_dirs);
}
