
### notes
## zebrafisch_48hpf_WM7 : 3*8bit < 2GB => use compressed MHDs
## ITKSnap reduces f64 => use f32


SHELL:= /bin/bash
GVmake=$(MAKE) #any line with $(MAKE) gets exectued even with -n, GVmake should merely be used for makefile-visualization to avoid its execution with -n


BASENAME = zebrafisch_48hpf_WM7


ITKDIR = ~/itk/simple/build_itk4_iana0


.PHONY : all clean 

all : $(BASENAME)_seg.nii.gz $(BASENAME)_gmv+0.mhd $(BASENAME).mhd


% :: %.gz # try decompress-first rule https://www.gnu.org/software/make/manual/html_node/Match_002dAnything-Rules.html#Match_002dAnything-Rules  https://www.gnu.org/software/make/manual/html_node/Double_002dColon.html#Double_002dColon
	unpigz -v -k -- $<

%.gz : %
	pigz -v -- $< 



%.mhd : %.lif
	vglrun /opt/fiji/Fiji.app/ImageJ-linux64  --memory=200g --allow-multiple $<

%_gmv+0.mhd : %.mhd
	$(ITKDIR)/gradient_mag_vec_f32 $< $@ 1 0 # not using principal components:  less "noise", more "fringes"

%_gmv+1.mhd : %.mhd
	$(ITKDIR)/gradient_mag_vec_f32 $< $@ 1 1 # use of principal components:  more "noise", less "fringes"

# $(BASENAME)_seg.nii.gz : $(BASENAME).mhd $(BASENAME)_gmv+0.mhd
# 	vglrun +xcb /opt/compilation/itksnap-src_build-v3.3.0+gdWS/ITK-SNAP -g $< # load $(BASENAME)_gmv+0.mhd for gWS (not working correctly yet, loads but uses BG-image for processing)

$(BASENAME)_seg.nii.gz : $(BASENAME)_gmv+0.mhd $(BASENAME).mhd
	vglrun +xcb /opt/compilation/itksnap-src_build-v3.3.0+gdWS/ITK-SNAP -g $< -o $(lastword $^) # overlay as reference

