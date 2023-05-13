
# Unpack the bbox coordinates into the provided variables
proc get_macro_coordinates {macro_name llx_var lly_var urx_var ury_var} {
   upvar $llx_var m_bbox_llx
   upvar $lly_var m_bbox_lly
   upvar $urx_var m_bbox_urx
   upvar $ury_var m_bbox_ury
   set m_bbox [join [get_attribute [get_cells $macro_name] bbox]]
   set m_bbox_llx [lindex $m_bbox 0]
   set m_bbox_lly [lindex $m_bbox 1]
   set m_bbox_urx [lindex $m_bbox 2]
   set m_bbox_ury [lindex $m_bbox 3]
}

# Returns the 4 rectangle coordinates in polygon order
proc get_rectangle_polygon {llx lly urx ury} {
   set tl [list $llx $ury]
   set tr [list $urx $ury]
   set br [list $urx $lly]
   set bl [list $llx $lly]
   return [list $tl $tr $br $bl]
}

# Return the bbox of the given macro
proc get_macro_bbox {macro_name} {
   set llx [get_attr -c cell $macro_name bbox_llx]
   set lly [get_attr -c cell $macro_name bbox_lly]
   set urx [get_attr -c cell $macro_name bbox_urx]
   set ury [get_attr -c cell $macro_name bbox_ury]
   return [list $llx $lly $urx $ury]
}
