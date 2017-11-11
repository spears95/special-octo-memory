#!/usr/bin/perl
# Author: Cheol Ho Lim in MSC GmbH.

use strict;
use warnings;
use diagnostics;

use Path::Tiny;
use autodie; # die if problem reading or writing a file

#my $dir = path("C:/Users/Cheol Ho Lim/Documents/MAKE"); # ./
my $dir = path("./build"); 
my $dir_make = path("./");

my $file_rd = $dir->child("build.log");
my $file_wr = $dir_make->child("makefile");

# openr_utf8() returns an IO::File object to read from
# with a UTF-8 decoding layer
my $file_rd_handle = $file_rd->openr_utf8();

# opena_utf8() returns an IO::File object to write to 
# with a UTF-8 decoding layer
my $file_wr_handle = $file_wr->openw_utf8();

# version info.
my $version_info = "This version is v0.90 created by C.Lim\r\n";

# after this, commands will be collected and transferred to makefile.
my $line_start = "-- creating ident header for library RTE_lib\r\n";

# hyphens to distinguish command starts.
my $line_hp1 = "------------------------------------------------------------------------------\r\n";

# temporary file to store data.
my $line_temp;  

# dealing with for MAIN TARGET.
my $flag = 0; 

# commands after hyphens should be collected.
my $flag2 = 0; 

# commands transferred to makefile.
my $flag3 = 0; 

# this flag is for temporary file which should be named as a sequence.
my $tmp_file_flag = 0;

# this flag is for *.a.  
my $a_lib_flag = 0; 

# this flag is for temporary file which should be ignored.
my $tmp_cnt_flag = 0; 

# make libs list for makefile.
my @make_libs_list;

# global increment variable to keep array number.
my $global_inc_idx = 0;

# Read in line at a time
while( my $line = $file_rd_handle->getline() ) {

	if( $line eq $line_start ) {
		# remove the final 2 characters "\r\n".
		$line = substr($line, 0, -2); 
		
		# a start comment.
		$file_wr_handle->print("## A makefile for post-processing automatically generated.\r\n");
		
		# print version information.
		$file_wr_handle->print("## ");
		$file_wr_handle->print($version_info);
		
		# this 1st line should be a comment.		
		$file_wr_handle->print("## ");
		# this is not a actual start and is just to check if it is right to start.
		$file_wr_handle->print($line);
		# add "\r\n" as it is removed from above.
		$file_wr_handle->print("\r\n");
		
		# this is the flag to start the actual behaviour.
		$flag = 0xAAAA; 
	}
	
	# it checks if it is MAIN TARGET.
	if ( $flag == 0xAAAA ) { 
		# filter the string with "MAIN TARGET".
		if( $line =~ m{MAIN TARGET} ) { 
			# it should be ignored. the existing one will be used. 
			if( $line =~ m{opt_ld.inv\r\n} ) { 
				next;
			}

			# in order to avoid some situation that blank line is not inserted, in front putting "\r\n" is needed.
			$file_wr_handle->print("\r\n");
			
			# *.a needs more things to do. 
			# in order to put '.', need '\.'. 
			if( $line =~ m{\.a\r\n$} ) { 
				$a_lib_flag = 0xFFBB;
			}
			
			# remove the first characters "-- " + "MAIN TARGET: ".
			$line = substr($line, 16); 
			# remove the final 2 characters "\r\n".
			$line = substr($line, 0, -2); 
			# store line to make_libs_list
			$make_libs_list[$global_inc_idx++] = $line;
			
			$file_wr_handle->print($line);
			
			# it is added to make target in the makefile.
			$file_wr_handle->print(":\r\n");
			# the next is to collect a command for compiling, linking and post-processing.
			$flag2 = 0xBBBB; 
			next;
		}
		
		# it checks if it is a start of the command for compiling.
		if( $flag2 == 0xBBBB ) { 
			if( $line eq $line_hp1 ) {
				$flag3 = 0xCCCC;
				$flag2 = 0;
				next;
			}
		}
		
		# it collects the commands.
		if( $flag3 == 0xCCCC ) { 
		
			# firstly, needs to distinguish if it is a command. things unnecessary should be ignored.
		
			# in pkw_wle.elf, "***" is printed. need to skip. 
			$line_temp = substr($line, 0, 3);
			if( $line_temp eq "***" ) { 
				next;
			}
			
			# in pkw_wle.elf, license relevant is printed. need to skip.
			$line_temp = substr($line, 0, 6);
			if( $line_temp eq "switch" ) { 
				next;
			}
			
			# "== " needs to skip.
			$line_temp = substr($line, 0, 3);
			if( $line_temp eq "-- " ) { 
				next;
			}
			
			# "        1 file(s)" needs to skip.
			$line_temp = substr($line, 0, 17);
			if( $line_temp eq "        1 file(s)" ) { 
				next;
			}
			
			# "* " needs to skip.
			$line_temp = substr($line, 0, 2);
			if( $line_temp eq "* " ) { 
				next;
			}
			
			# "<<" needs to skip.
			$line_temp = substr($line, 0, 2);
			if( $line_temp eq "<<" ) { 
				if( $tmp_cnt_flag == 0 ) {
					$tmp_cnt_flag = 0x1111;
				}
				else {
					$tmp_cnt_flag = 0;
				}
				next;
			}
			
			# in order to avoid collecting contents of some file. 
			if( $tmp_cnt_flag == 0x1111 ) { 
				next;
			}
			
			# "ltc " needs to skip.
			$line_temp = substr($line, 0, 4);
			if( $line_temp eq "ltc " ) { 
				next;
			}
			
			# "creating" needs to skip.
			$line_temp = substr($line, 0, 8);
			if( $line_temp eq "creating" ) { 
				next;
			}
			
			# "copy_file(@ARGV)" is not required. need to skip.
			if( $line =~ m{copy_file(@ARGV)} ) { 
				next;
			}
			
			# "OPTIONS" is not required. need to skip.
			if( $line =~ m{OPTIONS} ) { 
				next;
			}
			
			# "Adress-Range" is not required. need to skip.
			if( $line =~ m{Adress-Range} ) { 
				next;
			}
			
			# "shift8toA.bat" is not requird. need to skip. 
			if( $line =~ m{shift8toA.bat} ) {
				next;
			}
			
			# only need to substitute some commands with forward slash to the one with back slash. Windows doesn't recognize forward slash. 
			# for example, /bin/perl.exe -> \bin\perl.exe
			
			# /frdcc_le_tools_ms/ivob/tesa/make/bin/perl58/bin/perl.exe
			$line =~ s{/frdcc_le_tools_ms/ivob/tesa/make/bin/perl58/bin/perl.exe}{\\frdcc_le_tools_ms\\ivob\\tesa\\make\\bin\\perl58\\bin\\perl.exe}g;
			
			# /frdcc_le_tools_ms/ivob/tools/tasking/TriCore/v4.2r2/ctc/bin/ctc.exe
			$line =~ s{/frdcc_le_tools_ms/ivob/tools/tasking/TriCore/v4.2r2/ctc/bin/ctc.exe}{\\frdcc_le_tools_ms\\ivob\\tools\\tasking\\TriCore\\v4.2r2\\ctc\\bin\\ctc.exe}g;
			
			# /frdcc_le_tools_ms/ivob/tools/tasking/TriCore/v4.2r2/ctc/bin/astc.exe
			$line =~ s{/frdcc_le_tools_ms/ivob/tools/tasking/TriCore/v4.2r2/ctc/bin/astc.exe}{\\frdcc_le_tools_ms\\ivob\\tools\\tasking\\TriCore\\v4.2r2\\ctc\\bin\\astc.exe}g;
			
			# /frdcc_le_tools_ms/ivob/tools/tasking/TriCore/v4.2r2/ctc/bin/artc.exe
			$line =~ s{/frdcc_le_tools_ms/ivob/tools/tasking/TriCore/v4.2r2/ctc/bin/artc.exe}{\\frdcc_le_tools_ms\\ivob\\tools\\tasking\\TriCore\\v4.2r2\\ctc\\bin\\artc.exe}g;
			
			#/frdcc_le_tools_ms/ivob/tools/tasking/TriCore/v4.2r2/ctc/bin/ltc.exe
			$line =~ s{/frdcc_le_tools_ms/ivob/tools/tasking/TriCore/v4.2r2/ctc/bin/ltc.exe}{\\frdcc_le_tools_ms\\ivob\\tools\\tasking\\TriCore\\v4.2r2\\ctc\\bin\\ltc.exe}g;
			
			# /frdcc_le_tools_ms/ivob/tools/converter/srecord/srec_cat.exe
			$line =~ s{/frdcc_le_tools_ms/ivob/tools/converter/srecord/srec_cat.exe}{\\frdcc_le_tools_ms\\ivob\\tools\\converter\\srecord\\srec_cat.exe}g;
			
			# /frdcc_le_tools_ms/ivob/tools/iDAS/vector/exec/canape32.exe
			$line =~ s{/frdcc_le_tools_ms/ivob/tools/iDAS/vector/exec/canape32.exe}{\\frdcc_le_tools_ms\\ivob\\tools\\iDAS\\vector\\exec\\canape32.exe}g;
			
			# %TESAMAKE_DIR_TEMP%\
			$line =~ s{%TESAMAKE_DIR_TEMP%\\}{}g;
			
			# this routine replaces make{xxxxx}.rsp with proper one from build log.
			# it is different from each build so should be able to distinguish some variants of the environment. 
			if( $line =~ m{C:\\Users\\[zZ]\d{6}\\AppData\\Local\\Temp\\make\d{5}.rsp} ) { 
				# 1st make{xxxxx}.rsp should be changed to temp_rte.rsp.
				if( $tmp_file_flag == 0) { 
					$line =~ s{C:\\Users\\[zZ]\d{6}\\AppData\\Local\\Temp\\make\d{5}.rsp}{temp_rte.rsp}g;
					$tmp_file_flag++;
				}
				# 2nd make{xxxxx}.rsp should be changed to temp_inv.rsp.
				elsif( $tmp_file_flag == 1) { 
					$line =~ s{C:\\Users\\[zZ]\d{6}\\AppData\\Local\\Temp\\make\d{5}.rsp}{temp_inv.rsp}g;
					$tmp_file_flag++;
				}
				# 3rd make{xxxxx}.rsp should be changed to temp_bsw.rsp.
				elsif( $tmp_file_flag == 2) { 
					$line =~ s{C:\\Users\\[zZ]\d{6}\\AppData\\Local\\Temp\\make\d{5}.rsp}{temp_bsw.rsp}g;
					$tmp_file_flag++;
				}
				# 4th make{xxxxx}.rsp should be changed to temp_std_arch.rsp.
				elsif( $tmp_file_flag == 3) { 
					$line =~ s{C:\\Users\\[zZ]\d{6}\\AppData\\Local\\Temp\\make\d{5}.rsp}{temp_std_arch.rsp}g;
					$tmp_file_flag++;
				}
				# 5th make{xxxxx}.rsp should be changed to temp_dff.rsp.
				elsif( $tmp_file_flag == 4) { 
					$line =~ s{C:\\Users\\[zZ]\d{6}\\AppData\\Local\\Temp\\make\d{5}.rsp}{temp_dff.rsp}g;
					$tmp_file_flag++;
				}
			}
			
			# hyphen should not be printed.
			if( $line ne $line_hp1 && $line =~ m{\\frdcc_} ) { 
				# a TAB key is required to show commands in makefile.
				$file_wr_handle->print("		");
				# note $line has "\r\n".
				$file_wr_handle->print($line);
			}

			# remove all but the first 4 characters.
			$line_temp = substr($line, 0, 4);
			# after copy command, there will be another command.			
			if( $line_temp eq "COPY" ) { 
				next; 
			}
			
			# remove all but the first 2 characters.
			$line_temp = substr($line, 0, 2); 
			# after cd command, there will be another command.
			if( $line_temp eq "CD" ) { 
				next;
			}
			
			# remove all but the first 4 characters.
			$line_temp = substr($line, 0, 4); 
			# after move command, there will be another command.
			if( $line_temp eq "MOVE" ) { 
				next;
			}
			
			# *.a has 1 more command to do.
			if( $a_lib_flag == 0xFFBB ) { 
				$a_lib_flag = 0;
				next;
			}
			
			# before hyphens it means commands continue.
			if( $line eq $line_hp1 ) {
				$flag3 = 0;
			}
			
		} # if( $flag3 == 0xCCCC )
	} # if ( $flag == 0xAAAA ) 
} # while( my $line = $file_rd_handle->getline() )

# need to insert "\r\n".
$file_wr_handle->print("\r\n");

# put below in makefile.
# a blank behind \ should not exist. 
$file_wr_handle->print("MAKE_LIBS_LIST = \\\n");

# print a target for makefile.
# a blank behind \ should not exist. 
for my $i (@make_libs_list) {
	$file_wr_handle->print("  $i \\\n");
}

# need to insert "\r\n".
$file_wr_handle->print("\r\n");

# .PHONY target is needed.
$file_wr_handle->print(".PHONY: make_libs \n");

# in order to put '$', need '\$'.
$file_wr_handle->print("make_libs: \$(MAKE_LIBS_LIST) \n");

# close file handle at the end
close $file_rd_handle;
close $file_wr_handle;
