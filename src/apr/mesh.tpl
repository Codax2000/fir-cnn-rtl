
template : core_mesh(m12os,num_m1m2_straps) {
   layer : metal6 {
      direction : horizontal
      width : 0.22
      spacing : interleaving
      pitch : 2.8
      offset_type : centerline
      offset_start: boundary
      offset : 0
      trim_strap : true
   }
   layer : metal5 {
      direction : vertical
      width : 0.22
      spacing : interleaving
      pitch : 2.8
      offset_type : centerline
      offset_start: boundary
      offset : 0
      trim_strap : true
   }
   layer : metal4 {
      direction : horizontal
      width : 0.22
      spacing : interleaving
      pitch : 2.8
      offset_type : centerline
      offset_start: boundary
      offset : 0
      trim_strap : true
   }
   layer : metal3 {
      direction : vertical
      width : 0.22
      spacing : interleaving
      pitch : 2.8
      offset_type : centerline
      offset_start: boundary
      offset : 0
      trim_strap : true
   }
   layer : metal2 {
      direction : horizontal
      width : 0.17
      spacing : interleaving
      pitch : 2.8
      offset_type : centerline
      offset_start: boundary
      offset : @m12os
      trim_strap : false
      number: @num_m1m2_straps
   }
   layer : metal1 {
      direction : horizontal
      width : 0.17
      spacing : interleaving
      pitch : 2.8
      offset_type : centerline
      offset_start: boundary
      offset : @m12os
      trim_strap : false
      number: @num_m1m2_straps
   }
   advanced_rule : on {
      honor_advanced_via_rule : on
      stack_vias: adjacent
   }
}

