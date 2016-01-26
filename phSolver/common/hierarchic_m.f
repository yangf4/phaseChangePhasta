      module hierarchic_m
c
        implicit none
c
      contains
c
        subroutine getsgn(ien, sgn, nshl, nenl)
c
          implicit none
c
          integer, dimension(:,:), pointer, intent(out) :: sgn
          integer, dimension(:,:), pointer, intent(in)  :: ien
          integer, intent(in) :: nshl, nenl
c
          integer :: i
c
          do i = nenl+1,nshl
            where (ien(:,i) < 0)
              sgn(:,i) = -1 
            elsewhere
              sgn(:,i) = +1
            endwhere
          enddo
c
          return
c
        end subroutine getsgn
c
      subroutine getshp(shp_qpt,shg_qpt,shp,shg,sgn,npro,nsd,nshl,nqpt,nenl,intp,ipord)
c
        implicit none
c
        integer, intent(in) :: npro,nshl,nsd,nqpt,nenl,intp, ipord
        real*8, dimension(nshl,nqpt), intent(in) :: shp
        real*8, dimension(nsd,nshl,nqpt), intent(in) :: shg
        integer, dimension(:,:), pointer, intent(in) :: sgn
        real*8, dimension(:,:), pointer, intent(out) :: shp_qpt
        real*8, dimension(:,:,:), pointer, intent(out) :: shg_qpt
c
        integer :: i,j
c
        do i = 1,nenl
          shp_qpt(1:npro,i) = shp(i,intp)
          do j = 1,3
            shg_qpt(1:npro,j,i) = shg(j,i,intp)
          enddo
        enddo
        if (ipord > 1) then
          do i = nenl+1,nshl
            shp_qpt(1:npro,i) = sgn(1:npro,i) * shp(i,intp)
            do j = 1,3
              shg_qpt(1:npro,j,i) = sgn(1:npro,i) * shg(j,i,intp)
            enddo
          enddo
        endif
c
      end subroutine getshp
c
      subroutine getshp_if(shpq0,shpq1,shgq0,shgq1,shp0,shp1,shg0,shg1,xl0,xl1,npro,nsd,nshl,nqpt,nenl,intp)
c
c...NOTE: 
c   This routine uses geometirc tolerances to match the interface nodes.
c   Do not use this (it only has been used for DEBUG)
c
        implicit none
c
        integer, intent(in) :: npro,nsd,nshl,nqpt,nenl,intp
        real*8, dimension(nshl,nqpt), intent(in) :: shp0,shp1
        real*8, dimension(nsd,nshl,nqpt), intent(in) :: shg0,shg1
        real*8, dimension(:,:,:), pointer, intent(in) :: xl0,xl1
        real*8, dimension(:,:), pointer, intent(out) :: shpq0,shpq1
        real*8, dimension(:,:,:), pointer, intent(out) :: shgq0,shgq1
c
        integer :: i,j,iel,isd,jsd
        real*8 :: d,tol
c
        tol = 1.e-10
c
        do iel = 1,npro
          do i = 1,3
            shpq0(iel,i) = shp0(i,intp)
            do isd = 1,nsd
              shgq0(iel,isd,i) = shg0(isd,i,intp)
            enddo
            do j = 1,3
              d = sqrt(sum((xl0(iel,i,:)-xl1(iel,j,:))**2))
              if (d <= tol) then
                shpq1(iel,i) = shp1(j,intp)
                do jsd = 1,nsd
                  shgq1(iel,jsd,i) = shg1(jsd,j,intp)
                enddo
              endif
            enddo
          enddo
          shpq0(iel,4) = shp0(4,intp)
          shpq1(iel,4) = shp1(4,intp)
          shgq0(iel,:,4) = shg0(:,4,intp)
          shgq1(iel,:,4) = shg1(:,4,intp)
        enddo
c
      end subroutine getshp_if
c
      end module hierarchic_m
