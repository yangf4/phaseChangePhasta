      module e3if_vi_m
c
        use e3if_defs_m
c
        implicit none
c
      contains
c
      subroutine calc_vi(p,n)
c
        real*8, pointer, intent(in) :: p(:), n(:,:)
c
        real*8, parameter :: alpha = 1.d0
        real*8, parameter :: beta  = 1.d-6
c
        integer :: isd
        integer :: vmag
c
        do isd = 1,nsd
c
c          vmag = beta * p**alpha
          vmag = 0.0d0
          vi(:,isd) = vmag*n(:,isd)
c
        enddo
c
      end subroutine calc_vi
c
      subroutine calc_vi_area_node(sum_vi_area_l,shp,WdetJif,nshl)
c
        real*8, dimension(:,:,:), intent(inout) :: sum_vi_area_l
        real*8, dimension(:,:),   intent(in)    :: shp
        real*8, dimension(:),     intent(in)    :: WdetJif
        integer, intent(in) :: nshl
c
        integer :: n,isd
c
        do n = 1,nshl
          do isd = 1,nsd
            sum_vi_area_l(:,n,isd) = sum_vi_area_l(:,n,isd) 
     &                             + shp(:,n)*vi(:,isd)*area(:)
c     &                             + shp(:,n)*vi(:,isd)*WdetJif(:)
          enddo
          sum_vi_area_l(:,n,nsd+1) = sum_vi_area_l(:,n,nsd+1) + shp(:,n)*area(:)
c          sum_vi_area_l(:,n,nsd+1) = sum_vi_area_l(:,n,nsd+1) + shp(:,n)*WdetJif(:)
        enddo
c
      end subroutine calc_vi_area_node
c
      end module e3if_vi_m
