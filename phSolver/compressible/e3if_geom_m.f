      module e3if_geom_m
c
        use mpi_def_m
        use e3if_defs_m
        use hierarchic_m
c
        implicit none
c
      contains
c
        subroutine malloc_e3if_geom
c
          allocate(xl0(npro,nenl0,nsd))
          allocate(xl1(npro,nenl1,nsd))
          allocate(area(npro))
          allocate(WdetJif0(npro),WdetJif1(npro))
          allocate(if_normal_l0(npro,nshl0,nsd+1))
          allocate(if_normal_l1(npro,nshl1,nsd+1))
          allocate(if_kappa_l0(npro,nshl0,nsd+1))
          allocate(if_kappa_l1(npro,nshl1,nsd+1))
          allocate(nv0(npro,nsd))
          allocate(nv1(npro,nsd))
          allocate(shp0(npro,nshl0))
          allocate(shp1(npro,nshl1))
          allocate(shgl0(npro,nsd,nshl0))
          allocate(shgl1(npro,nsd,nshl1))
          allocate(sgn0(npro,nshl0))
          allocate(sgn1(npro,nshl1))
c
        end subroutine malloc_e3if_geom
c
        subroutine mfree_e3if_geom
c
          deallocate(xl0,xl1)
          deallocate(area)
          deallocate(WdetJif0,WdetJif1)
          deallocate(if_normal_l0,if_normal_l1)
          deallocate(if_kappa_l0,if_kappa_l1)
          deallocate(nv0,nv1)
          deallocate(shp0,shp1)
          deallocate(shgl0,shgl1)
          deallocate(sgn0,sgn1)
c
        end subroutine mfree_e3if_geom
c
        subroutine calc_if_normals(xl0,xl1,shpif0,shpif1,shgif0,shgif1,qwtif0,qwtif1)
c
          real*8,  dimension(:,:,:), pointer, intent(in) :: xl0, xl1 
          real*8, dimension(nshl0,nqpt),intent(in)   :: shpif0
          real*8, dimension(nshl1,nqpt),intent(in)   :: shpif1
          real*8, dimension(nsd,nshl0,nqpt), intent(in) :: shgif0
          real*8, dimension(nsd,nshl1,nqpt), intent(in) :: shgif1
          real*8, dimension(nqpt), intent(in) :: qwtif0, qwtif1
c
          integer :: intp
c
          do intp = 1, nqpt
c
c... calculate normal vectors at the integration point...
c
            call calc_normal_vectors(nv0,area,WdetJif0,xl0,qwtif0,lcsyst0,intp,npro)
            call calc_normal_vectors(nv1,area,WdetJif1,xl1,qwtif1,lcsyst1,intp,npro)
c
            call  getshp(shp0, shgl0, shpif0, shgif0, sgn0, npro, nsd, nshl0, nqpt, nenl0, intp, ipord)
            call  getshp(shp1, shgl1, shpif1, shgif1, sgn1, npro, nsd, nshl1, nqpt, nenl1, intp, ipord)
c
c... distribute the weighted vectors from integration points to nodes
c
            call collect_weighted_normals(if_normal_l0,nv0,shp0,WdetJif0,nshl0)
            call collect_weighted_normals(if_normal_l1,nv1,shp1,WdetJif1,nshl1)
c
          enddo
c
        end subroutine calc_if_normals
c
        subroutine collect_weighted_normals(if_normal_l,nv,shp,WdetJif,nshl)
c
          real*8, dimension(:,:,:), intent(inout) :: if_normal_l
          real*8, dimension(:,:), intent(in) :: nv
          real*8, dimension(:,:),   intent(in)    :: shp
          real*8, dimension(:),     intent(in)    :: WdetJif
          integer, intent(in) :: nshl
c
          integer :: n,isd
c
          do n = 1,nshl
            do isd = 1,nsd
              if_normal_l(:,n,isd) = if_normal_l(:,n,isd) 
     &                               + shp(:,n)*nv(:,isd)*area(:)
c     &                               + shp(:,n)*nv(:,isd)*WdetJif(:)
            enddo
          enddo
c
        end subroutine collect_weighted_normals
c
        subroutine calc_normal_vectors(nv,area,WdetJ,xl,qwt,lcsyst,intp,npro)
c
          real*8, dimension(:,:), pointer, intent(out) :: nv
          real*8, dimension(:),   pointer, intent(out) :: area, WdetJ
          real*8, dimension(:,:,:), pointer, intent(in) :: xl
          real*8, dimension(nqpt),           intent(in) :: qwt
          integer, intent(in) :: lcsyst,intp,npro
c
          real*8 :: temp_len(npro)
          real*8, dimension(npro, nsd) :: v1, v2, temp_normal
          integer :: isd, iel
          character(len=8) :: err_msg
c
c      write(*,*) 'In calc_normal_vectors...'
c
c.... compute the normal to the boundary. This is achieved by taking
c     the cross product of two vectors in the plane of the 2-d 
c     boundary face.
c
          do isd = 1,nsd
            v1(:,isd) = xl(:,2,isd) - xl(:,1,isd)
            v2(:,isd) = xl(:,3,isd) - xl(:,1,isd)
          enddo
c
          select case (lcsyst)
          case (1)
c
            temp_normal(:,1) = + v1(:,2)*v2(:,3) - v1(:,3)*v2(:,2)
            temp_normal(:,2) = - v1(:,1)*v2(:,3) + v1(:,3)*v2(:,1)
            temp_normal(:,3) = + v1(:,1)*v2(:,2) - v1(:,2)*v2(:,1)
c
            area = pt50 * sqrt(temp_normal(:,1)*temp_normal(:,1)
     &                       + temp_normal(:,2)*temp_normal(:,2)
     &                       + temp_normal(:,3)*temp_normal(:,3))
c
          case default
c            write(err_msg,'(a,i1)') 'lcsyst ',lcsyst
            call error ('calc_normal_vectors ', err_msg, 0)
          end select
c
          do iel = 1,npro
            temp_len(iel) = sqrt(dot_product(temp_normal(iel,1:3),temp_normal(iel,1:3)))
            nv(iel,1:nsd) = temp_normal(iel,1:nsd) / temp_len(iel)
          enddo
c
c... also calculate WdetJ here...
c
          select case (lcsyst)
          case (1)
            WdetJ = qwt(intp) * temp_len * pt25
          case default
            write(err_msg,'(a,i1)') 'lcsyst ',lcsyst
            call error ('calc WdetJif ', err_msg, 0)
          end select
c
        end subroutine calc_normal_vectors
c
        subroutine calc_mean_curvature(if_kappa_l,xl0,ienif0)
c
          real*8, dimension(:,:,:), pointer, intent(inout) :: if_kappa_l
          real*8, dimension(:,:,:), pointer, intent(in) :: xl0
          integer, dimension(:,:), pointer, intent(in) :: ienif0
c
          integer,parameter :: nnode = 3 ! ONLY WORKS ON THE TRIAGLES
          integer :: iel,i,j,k,inode
          real*8 :: v1(3),v2(3),v3(3),v(3),area,l1sq,l2sq,l3sq,n(3)
          real*8, dimension(nnode) :: cot0(3),cot1(3)
          logical :: obtuse
c
          do iel = 1,npro
c
            v1 = xl0(iel,2,:)-xl0(iel,1,:)
            v2 = xl0(iel,3,:)-xl0(iel,2,:)
            v3 = xl0(iel,1,:)-xl0(iel,3,:)
c
            call cross(v,v1,v2)
            area = pt5*norm2(v)
c
            l1sq = dot_product(v1,v1)
            l2sq = dot_product(v2,v2)
            l3sq = dot_product(v3,v3)
c
            cot0(1) = cotan(v1,-v3)
            cot0(2) = cotan(v2,-v1)
            cot0(3) = cotan(v3,-v2)
c
            if_kappa_l(iel,1,1:nsd) = pt5*(cot0(2)*v3-cot0(3)*v1)
            if_kappa_l(iel,2,1:nsd) = pt5*(cot0(3)*v1-cot0(1)*v2)
            if_kappa_l(iel,3,1:nsd) = pt5*(cot0(1)*v2-cot0(2)*v3)
c
            obtuse = any(cot0(:) < zero)
      obtuse = .false.
c
            if (.not. obtuse) then
              if_kappa_l(iel,1,nsd+1) = pt125*(cot0(3)*l1sq+cot0(2)*l3sq)
              if_kappa_l(iel,2,nsd+1) = pt125*(cot0(1)*l2sq+cot0(3)*l1sq)
              if_kappa_l(iel,3,nsd+1) = pt125*(cot0(2)*l3sq+cot0(1)*l2sq)
            else
              do i = 1,nsd
                if (cot0(i) < zero) then
                  if_kappa_l(iel,i,nsd+1) = if_kappa_l(iel,i,nsd+1) + pt5*area
                else
                  if_kappa_l(iel,i,nsd+1) = if_kappa_l(iel,i,nsd+1) + pt25*area
                endif
              enddo
            endif
c
          enddo
c
        end subroutine calc_mean_curvature
c
        subroutine cross(v,v1,v2)
          real*8, dimension(nsd), intent(out) :: v
          real*8, dimension(nsd), intent(in) :: v1,v2
          v(1) = v1(2)*v2(3) - v1(3)*v2(2)
          v(2) = v1(3)*v2(1) - v1(1)*v2(3)
          v(3) = v1(1)*v2(2) - v1(2)*v2(1)
        end subroutine cross
c
        real*8 function cotan(v1,v2)
          real*8, dimension(nsd) :: v1,v2,v
          real*8 n2
          call cross(v,v1,v2)
          n2 = norm2(v)
          if (n2 == zero) call error('cotan','norm2=0',0)
          cotan = dot_product(v1,v2)/n2
        end function cotan
c
      end module e3if_geom_m
