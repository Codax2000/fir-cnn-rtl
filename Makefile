TOPLEVEL=zyNet
SYN_DIR=sapr/syn
APR_DIR=sapr/apr

.PHONY: syn apr apr-to-floorplan clean-syn clean-apr

syn:
	cd $(SYN_DIR) && dc_shell -f syn.tcl

apr:
	cd $(APR_DIR) && icc_shell -shared_license -f apr.tcl

apr-to-floorplan:
	cd $(APR_DIR) && icc_shell -sharef_license -f apr_to_floorplan.tcl


clean-syn:

clean-apr:

clean: clean-syn clean-apr
	