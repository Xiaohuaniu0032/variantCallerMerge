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

	#if (-d "$outdir/$dir"){
	#	`rm $outdir/$dir`;
	#	`mkdir $outdir/$dir`;
	#}else{
	#	`mkdir $outdir/$dir`;
	#}

	my $vc_dir = "$report_dir/plugin_out/$dir";
	#print "$vc_dir\n";
	# get all TSVC_variants.vcf
	my @vcf = glob "$vc_dir/*/TSVC_variants.vcf";

	# if this vcf is from sars-cov-2 sample?
	# vcf contain "2019-nCoV"
	my @cov_vcf; # SARS vcf
	for my $vcf (@vcf){
		#print "$vcf\n";
		my $if_cov2_vcf = &check_if_cov2_vcf($vcf);
		if ($if_cov2_vcf eq "YES"){
			print "[SARS-CoV-2 VCF]: $vcf\n";
			push @cov_vcf, $vcf;
		}else{
			#print "[NOT SARS-CoV-2 VCF]: $vcf\n";
			next;
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
			
			my @var;
			if ($arr[4] =~ /\,/){
				# 包含>=2个alt allele
				my $gt = (split /\:/, $arr[-1])[0]; # 1/1
				my @gt = split /\//, $gt; # [1,1] => 纯合突变 OR [1,2] 双杂合突变
				my @alt = split /\,/, $arr[4]; # [CAT,CTAT]
				my $freq_tmp = (split /\;/, $arr[7])[0]; # AF=1,0
				$freq_tmp =~ s/^AF=//;
				my @freq = split /\,/, $freq_tmp;

				my $idx = 0;
				my @allele;
				push @allele, $arr[3];
				for my $v (@alt){
					push @allele, $v;
				}

				for my $gt (@gt){
					my $gt_int = int($gt);
					if ($gt_int >= 1){
						# 有效的突变
						my $alt = $allele[$gt_int];
						my $freq = $freq[$gt_int-1];
						my $var = "$arr[0]\:$arr[1]\:$arr[3]\:$alt"; # 2019-nCoV:210:G:T
						$sample_vars{$barcode}{$var} = $freq;
						my $pos = $arr[1];
						push @{$all_vars{$pos}}, $var; # 1) one pos may has diff variants; 2) may contain dup vars
					}
				}
			}else{
				my $freq_tmp = (split /\;/, $arr[7])[0]; # AF=1
				my $freq = (split /\=/, $freq_tmp)[1]; # freq is 0.98
				my $var = "$arr[0]\:$arr[1]\:$arr[3]\:$arr[4]"; # 2019-nCoV:210:G:T
				$sample_vars{$barcode}{$var} = $freq;
				my $pos = $arr[1];
				push @{$all_vars{$pos}}, $var; # 1) one pos may has diff variants; 2) may contain dup vars
			}
		}
		close VCF;
	}


	# outdir is /results/analysis/output/Home/2019-nCoV-map2hg19-exon-virus_241/plugin_out/variantCaller_out.1535
	#my $plugin_number = basename($outdir);
	my $outfile = "$outdir/$dir\.TSVC_variants.merged.vcf.xls";
	print "[Merge VCF is]: $outfile\n";
	# Chrom/Position/Ref/Variant/IonXpress_001.Freq/IonXpress_002.Freq/.../
	# 2019-nCoV/210/G/T/1/0.98/.../
	
	open O, ">$outfile" or die;
	print O "Chrom\tPosition\tRef\tVariant";

	# print sample name by barcode numbering
	my @sample_by_order;
	my %sample_tmp;
	foreach my $s (keys %sample){
		my $num = (split /\_/, $s)[1]; # 001/002
		$num =~ s/^[0+]//;
		my $barcode_str = (split /\_/, $s)[0];
		$sample_tmp{$num} = $barcode_str;
	}

	foreach my $num (sort { $a <=> $b } keys %sample_tmp){
		# check num's length
		my $barcode_str = $sample_tmp{$num}; # IonXpress
		my @num = split //, $num;
		my $new_num; # trans 1 into 001
		if (@num == 1){
			$new_num = "00".$num;
		}
		if (@num == 2){
			$new_num = "0".$num;
		}
		if (@num == 3){
			$new_num = $num;
		}

		my $new_barcode = $barcode_str."_".$new_num; # IonXpress_001
		push @sample_by_order, $new_barcode;
	}

	for my $s (@sample_by_order){
		print O "\t$s";
	}
	print O "\n";

	# sort variant by pos
	foreach my $pos (sort { $a <=> $b } keys %all_vars){
		my $var_aref = $all_vars{$pos}; # one pos may have multi var type
		my %uniq_var;
		for my $var (@{$var_aref}){
			$uniq_var{$var} = 1;
		}

		for my $var (keys %uniq_var){ # 2019-nCoV:210:G:T
			my @var = split /\:/, $var;
			print O "$var[0]\t$var[1]\t$var[2]\t$var[3]";
			for my $s (@sample_by_order){
				my $freq;
				if (exists $sample_vars{$s}{$var}){
					$freq = $sample_vars{$s}{$var};
				}else{
					$freq = "NA";
				}
				print O "\t$freq";
			}
			print O "\n";
		}
	}
	close O;
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
			next if ($vc_name =~ /variantCallerMerge/);
			# variantCaller_out.1257/
			# SARS_CoV_2_variantCaller_out.1529/
			push @vc_dirs, $vc_name;
		}
	}

	return(\@vc_dirs);
}
