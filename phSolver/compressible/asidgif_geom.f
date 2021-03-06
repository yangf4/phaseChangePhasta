      subroutine asidgif_geom 
     & (
     &  if_normals,if_kappa,
     &  x,shpif0,shpif1,shgif0,shgif1,
     &  qwtif0, qwtif1,
     &  ienif0, ienif1
     & )
c
        use hierarchic_m
        use local_m
        use e3if_geom_m
c
        implicit none
c
        real*8, pointer, intent(inout) :: if_normals(:,:), if_kappa(:,:)
        real*8, intent(in) :: x(nshg,nsd)
        real*8, dimension(nshl0,nqpt),intent(in)   :: shpif0
        real*8, dimension(nshl1,nqpt),intent(in)   :: shpif1
        real*8, dimension(nsd,nshl0,nqpt), intent(in) :: shgif0
        real*8, dimension(nsd,nshl1,nqpt), intent(in) :: shgif1
        real*8, intent(in) :: qwtif0(nqpt), qwtif1(nqpt)
        integer, dimension(:,:), pointer, intent(in)   :: ienif0, ienif1
c
      integer :: iel,inode,n
c
        call malloc_e3if_geom
c
        if (ipord .gt. 1) then
          call getsgn(ienif0,sgn0,nshl0,nenl0)
          call getsgn(ienif1,sgn1,nshl1,nenl1)
        endif
c
        call localx(x, xl0,  ienif0, nsd, 'gather  ', nshg, nenl0, npro, gbytes)
        call localx(x, xl1,  ienif1, nsd, 'gather  ', nshg, nenl1, npro, gbytes)
c
        call calc_if_normals(xl0,xl1,shpif0,shpif1,shgif0,shgif1,qwtif0,qwtif1)
c
        call local (if_normals, if_normal_l0, ienif0, nsd, 'scatter ', nshg, nshl0,npro,ipord,sbytes,flops)
        call local (if_normals, if_normal_l1, ienif1, nsd, 'scatter ', nshg, nshl1,npro,ipord,sbytes,flops)
c
        call calc_mean_curvature(if_kappa_l0,xl0,ienif0)
        call calc_mean_curvature(if_kappa_l1,xl1,ienif1)
c
        call local (if_kappa, if_kappa_l0, ienif0, nsd+1, 'scatter ', nshg, nshl0,npro,ipord,sbytes,flops)
        call local (if_kappa, if_kappa_l1, ienif1, nsd+1, 'scatter ', nshg, nshl1,npro,ipord,sbytes,flops)
c
        call mfree_e3if_geom
c
      end subroutine asidgif_geom
