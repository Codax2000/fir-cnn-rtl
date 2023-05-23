TOPLEVEL=zyNet
SYN_DIR=sapr/syn
APR_DIR=sapr/apr

.PHONY: syn apr apr-to-floorplan

syn:
	cd $(SYN_DIR) && dc_shell -f syn.tcl

syn-link:
	cd $(SYN_DIR) && dc_shell -f syn_link.tcl

apr:
	cd $(APR_DIR) && icc_shell -shared_license -f apr.tcl

apr-to-floorplan:
	cd $(APR_DIR) && icc_shell -shared_license -f apr_to_floorplan.tcl

clean-general:
	-rm -r alib-52
	-rm -r reports
	-rm -r results
	-rm -r tmp
	-rm -r design_lib
	-rm *.log
	-rm icc_output.txt
	-rm set_pad_attributes_on_cell_zyNet.tcl
	-rm pin_placement.tcl
	
clean-syn:
	$(MAKE) clean-general -C sapr/syn

clean-apr:
	$(MAKE) clean-general -C sapr/apr

clean:
	$(MAKE) clean-syn
	$(MAKE) clean-apr