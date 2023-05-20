######################################################################
# © 2014 Synopsys, Inc.  All rights reserved.             
#                                                                  
# This script is proprietary and confidential information of        
# Synopsys, Inc. and may be used and disclosed only as authorized   
# per your agreement with Synopsys, Inc. controlling such use and   
# disclosure.                                                       
#                                                                   
######################################################################
#
# Version 1.0: Date created 11/7/2013
#  Report DRCs in table format. 
#  Select DRCs to report by layer and/or type
#  Highlight reported DRCs by specified color 
#
# Version 1.1: Date created 11/15/2013
#  Added -ignore_type & -ignore_layer options
#
# Version 1.2: Date created 11/17/2013
#  Filter DRCs by layer_number instead of layer
#  to avoid wrong reporting due to pattern matches
#
######################################################################

proc report_drc {args} {
	set begin [clock seconds]
	parse_proc_arguments -args $args results
	
	# Find the drc_types to report
	if {[info exists results(-type)]} {
		set drc(types) $results(-type)
	} else {
		set drc(types) [list_drc_error_types]
	}

	# If -ignore_type flag is present, remove those from list
	if {[info exists results(-ignore_type)]} {
		foreach type $results(-ignore_type) {
			set remove [lsearch $drc(types) $type]
			set drc(types) [lreplace $drc(types) $remove $remove]
		}
	}
	
	# Find the routing layers to report
	if {[info exists results(-layer)]} {
		set drc(layers) $results(-layer)
	} else {
		# Convert collection of all routing layers to list
		set drc(layers) [collection_to_list -name_only -no_braces [get_layers -filter is_routing_layer]]
	}

	# If -ignore_layer flag is present, remove those from list
	if {[info exists results(-ignore_layer)]} {
		foreach layer $results(-ignore_layer) {
			set remove [lsearch $drc(layers) $layer]
			set drc(layers) [lreplace $drc(layers) $remove $remove]
		}
	}

	if {[info exists results(-add_to_highlight)] && ![info exists results(-highlight)]} {
		echo "\nWarning: add_to_highlight should be used in conjunction with highlight"
	} 

	# Default highlight color is set to red
	if {[info exists results(-color)]} { set color $results(-color)} else {set color red}

	# Default error cell is set to "Detail Route"
	if {[info exists results(-err_cell)]} { set err_cell $results(-err_cell)} else {set err_cell "Detail Route"}

	# Start the error browser and set it to highlight mode.
	if {[info exists results(-highlight)]} {
		start_gui
		gui_unload_error_cel
		gui_load_error_cel -error_cel_type $err_cell
		gui_error_browser -show
		gui_set_current_errors -data_name $err_cell
		gui_set_error_browser_option -dim true -show_mode highlighted
		# Clear the highlighted DRCs unless -add_to_highlight is specified
		if {[info exists results(-add_to_highlight)]} { } else {gui_change_error_highlight -remove -all_visible}
	}

	if {[llength $drc(types)] > 0} {
		#Initialize the array drc to 0
		set stlen 0
		foreach type $drc(types) {
			foreach layer $drc(layers) {
				set drc($type,$layer) 0
				set total($layer) 0
			}
			set total($type) 0
			if {[string length $type] > $stlen} {set stlen [string length $type]}
		}

		# Populate DRCs per layer/type
		foreach type $drc(types) {
			foreach layer $drc(layers) {
				set layer_number [get_attribute [get_layer $layer] layer_number]
				set drc_count [sizeof_collection [get_drc_error -filter "type==\"$type\" && layer_numbers=~*$layer_number*" -quiet]]
				set drc($type,$layer) $drc_count
				if {[info exists results(-highlight)]} {
					# Select the errors and then highlight selected errors, then clear selected errors
					gui_set_selected_errors -add [get_drc_error -filter "type==\"$type\" && layer_numbers=~*$layer_number*" -quiet]
					gui_change_error_highlight -add -color $color -selected
					gui_clear_selected_errors
				}
			}
		}
	
		# Find totals per type and per layer and overall total
		foreach type $drc(types) {
			set total($type) [sizeof_collection [get_drc_error -filter "type==\"$type\"" -quiet]]
		}
		foreach layer $drc(layers) {
			set layer_number [get_attribute [get_layer $layer] layer_number]
			set total($layer) [sizeof_collection [get_drc_error -filter "layer_numbers=~*$layer_number*" -quiet]]
		}
		set total(all) [sizeof_collection [get_drc_errors]]

		# Print out Layer list header
		set layer_count 0
		echo ""
		echo -n [format "%${stlen}s |" ""]
		foreach layer $drc(layers) {
			if {$total($layer) > 0} {echo -n [format "%6s" $layer]; incr layer_count}
		}
		echo [format " |%6s" "TOTAL"]
		set sep [string repeat "-" [expr $stlen + [expr [expr $layer_count + 2] * 6]]]; echo $sep

		# Print the DRC table. If any row/column totals 0, do not print
		foreach type $drc(types) {
			if {$total($type) > 0} {
			echo -n [format "%${stlen}s |" $type]  
				foreach layer $drc(layers) {
					if {$total($layer) > 0} {
						if {$drc($type,$layer) > 0} {
							echo -n [format "%6d" $drc($type,$layer)]
						} else {echo -n [format "%6s" "-"]}
					}
				}
			echo -n [format " |%6d" $total($type)]
			echo ""
			}
		}
		echo $sep
		echo -n [format "%${stlen}s |" "TOTAL"]
		foreach layer $drc(layers) {
			if {$total($layer) > 0} {
			echo -n [format "%6d" $total($layer)]
			}
		}

		# Do not report total if following flags are passed
		if {![info exists results(-type)] && ![info exists results(-layer)] && ![info exists results(-ignore_type)]  && ![info exists results(-ignore_layer)]} {
			echo [format " |%6d" $total(all)]
		} else {echo " |"}
	} else {
		echo "\n#################\nNo DRCs to report\n#################\n"
	}

	set end [clock seconds]
	echo [format "\nElapsed time : %20d Seconds" [expr $end - $begin]]
}

define_proc_attributes report_drc \
	-info "Report/Highlight routing DRCs by Layer and/or DRC_type\n" \
	-define_args {
		{-layer "Layer list on which to report DRC. eg: -layer {{M2} {M7E}} " layer list optional}
		{-type "List of DRC types to report. eg: -type {{Short} {Less than NDR width}} " type list optional}
		{-ignore_layer "Layers to ignore. eg: -ignore_layer {{M2} {M7E}} " ignore_layer list optional}
		{-ignore_type "DRCs to ignore. eg: -ignore_type {{Short} {Less than NDR width} {Macro pin connection by offset}} " ignore_type list optional}
		{-highlight "Highlight reported DRCs in the GUI" "" boolean optional}
		{-color "Highlight color. Default: red. eg: green" color string optional}
		{-add_to_highlight "Add to already highlighted DRCs in the GUI" "" boolean optional}
		{-err_cell "Err cell from which to report DRC. Default: {Detail Router}"  err_cell string optional}
	}

