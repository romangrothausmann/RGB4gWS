
### setting default paths of external programs
ITK?=/opt/ITK-CLIs/
ITKSNAP?=/opt/itksnap/

VGLRUN?=vglrun


### notes
## zebrafisch_48hpf_WM7 : 3*8bit < 2GB => use compressed MHDs
## ITKSnap reduces f64 => use f32


SHELL:= /bin/bash
GVmake=$(MAKE) #any line with $(MAKE) gets exectued even with -n, GVmake should merely be used for makefile-visualization to avoid its execution with -n


export PATH:= $(ITK)/bin:$(PATH)
export PATH:= $(ITKSNAP)/bin:$(PATH)


### check existance of external programs
## http://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#25668869
EXECUTABLES = $(VGLRUN) extract_subimage anisoDiff-grad_f32 anisoDiff-curv_f32 itksnap
K:= $(foreach exec,$(EXECUTABLES),\
	$(if $(shell PATH=$(PATH) which $(exec)),some string,$(error "No $(exec) in PATH: $(PATH)")))



BASENAME = zebrafisch_48hpf_WM7



.PHONY : all clean 

all : $(BASENAME)_ROI_adc+150+0.2_gmv+0_seg.nii.gz


% :: %.gz # try decompress-first rule https://www.gnu.org/software/make/manual/html_node/Match_002dAnything-Rules.html#Match_002dAnything-Rules  https://www.gnu.org/software/make/manual/html_node/Double_002dColon.html#Double_002dColon
	unpigz -v -k -- $<

%.gz : %
	pigz -v -- $< 



%.mhd : %.lif
	$(VGLRUN) /opt/fiji/Fiji.app/ImageJ-linux64  --memory=200g --allow-multiple $<

%_RGB.nii.gz : %_r.mhd %_g.mhd %_b.mhd
	rgb2RGB $^ $@ 1


%_ROI.mhd : %.mhd
	extract_subimage $< $@  260 190 1  530 630 130

%_rsi+1+4.0.mhd : %.mhd
	resample $< $@ 1 1 4.0 4.0 4.0


%_gmv+0.mhd : %.mhd
	gradient_mag_vec_f32 $< $@ 1 0 # not using principal components:  less "noise", more "fringes"

%_gmv+1.mhd : %.mhd
	gradient_mag_vec_f32 $< $@ 1 1 # use of principal components:  more "noise", less "fringes"

%_adg+50+2.mhd : %.mhd
	anisoDiff-grad_f32 $< $@ 1 50 0.0625 2.0 # tests for 1/2^(N+1) but docs and guide say 1/2^N: https://itk.org/pipermail/insight-users/2010-February/035268.html

%_adg+15+2.mhd : %.mhd
	anisoDiff-grad_f32 $< $@ 1 15 0.0625 2.0

%_adc+15+2.mhd : %.mhd
	anisoDiff-curv_f32 $< $@ 1 15 0.0625 2.0

%_adc+150+2.mhd : %.mhd
	anisoDiff-curv_f32 $< $@ 1 150 0.0625 2.0

%_adc+150+0.2.mhd : %.mhd
	anisoDiff-curv_f32 $< $@ 1 150 0.0625 0.2

%_adg+5+10.mhd : %.mhd
	anisoDiff-grad_f32 $< $@ 1 5 0.0625 10.0


%_adg.nii.gz : %.nii.gz # just to test real RGB
	anisoDiff-grad_f32 $< $@ 1 5 0.125 2.0 # tests for 1/2^(N+1) but docs and guide say 1/2^N: https://itk.org/pipermail/insight-users/2010-February/035268.html

# $(BASENAME)_seg.nii.gz : $(BASENAME).mhd $(BASENAME)_gmv+0.mhd
# 	$(VGLRUN) itksnap -g $< # load $(BASENAME)_gmv+0.mhd for gWS (not working correctly yet, loads but uses BG-image for processing)

%_seg.nii.gz : %.mhd $(BASENAME)_ROI.mhd
	 $(VGLRUN) itksnap -g $< -o $(lastword $^) # overlay as reference

#prevent removal of any intermediate files http://stackoverflow.com/questions/5426934/why-this-makefile-removes-my-goal https://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.SECONDARY: 

