
### notes
## zebrafisch_48hpf_WM7 : 3*8bit < 2GB => use compressed MHDs
## ITKSnap reduces f64 => use f32


SHELL:= /bin/bash
GVmake=$(MAKE) #any line with $(MAKE) gets exectued even with -n, GVmake should merely be used for makefile-visualization to avoid its execution with -n


BASENAME = zebrafisch_48hpf_WM7


ITKDIR = ~/itk/simple/build_itk4_iana0


.PHONY : all clean 

all : $(BASENAME)_seg.nii.gz


% :: %.gz # try decompress-first rule https://www.gnu.org/software/make/manual/html_node/Match_002dAnything-Rules.html#Match_002dAnything-Rules  https://www.gnu.org/software/make/manual/html_node/Double_002dColon.html#Double_002dColon
	unpigz -v -k -- $<

%.gz : %
	pigz -v -- $< 



%.mhd : %.lif
	vglrun /opt/fiji/Fiji.app/ImageJ-linux64  --memory=200g --allow-multiple $<

%_RGB.nii.gz : %_r.mhd %_g.mhd %_b.mhd
	$(ITKDIR)/rgb2RGB $^ $@ 1


%_gmv+0.mhd : %.mhd
	$(ITKDIR)/gradient_mag_vec_f32 $< $@ 1 0 # not using principal components:  less "noise", more "fringes"

%_gmv+1.mhd : %.mhd
	$(ITKDIR)/gradient_mag_vec_f32 $< $@ 1 1 # use of principal components:  more "noise", less "fringes"

%_adg.mhd : %.mhd
	$(ITKDIR)/anisoDiff-grad_vec_f32 $< $@ 1 5 0.0625 2.0 # tests for 1/2^(N+1) but docs and guide say 1/2^N: https://itk.org/pipermail/insight-users/2010-February/035268.html

%_adg.nii.gz : %.nii.gz # just to test real RGB
	$(ITKDIR)/anisoDiff-grad_vec_f32 $< $@ 1 5 0.125 2.0 # tests for 1/2^(N+1) but docs and guide say 1/2^N: https://itk.org/pipermail/insight-users/2010-February/035268.html

# $(BASENAME)_seg.nii.gz : $(BASENAME).mhd $(BASENAME)_gmv+0.mhd
# 	vglrun +xcb /opt/compilation/itksnap-src_build-v3.3.0+gdWS/ITK-SNAP -g $< # load $(BASENAME)_gmv+0.mhd for gWS (not working correctly yet, loads but uses BG-image for processing)

$(BASENAME)_seg.nii.gz : $(BASENAME)_adg_gmv+0.mhd $(BASENAME).mhd
	vglrun +xcb /opt/compilation/itksnap-src_build-v3.3.0+gdWS/ITK-SNAP -g $< -o $(lastword $^) # overlay as reference

