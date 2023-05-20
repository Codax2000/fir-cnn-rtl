
template : core_ring_vdd(hlay,vlay,rw,os) {
   side : horizontal {
      layer : @hlay
      width : @rw     #power ring width
      offset : @os    #power ring clearance+width+space
   }
   side : vertical {
      layer : @vlay
      width : @rw
      offset : @os
   }
}
template : core_ring_vss(hlay,vlay,rw,os) {
   side : horizontal {
      layer : @hlay
      width : @rw     #power ring width
      offset : @os    #power ring clearance
   }
   side : vertical {
      layer : @vlay
      width : @rw
      offset : @os
   }
}
