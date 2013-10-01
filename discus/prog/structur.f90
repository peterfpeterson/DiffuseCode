MODULE structur

USE errlist_mod 
!
IMPLICIT NONE
!
PUBLIC
CONTAINS
!+                                                                      
!     These routines create a new structure. The different options      
!     are (or will be soon) :                                           
!                                                                       
!       - comletely new structure                                       
!       - freestyle edited                                              
!       - generated from plane,space or non-crystallographic group      
!       - read-in structure                                             
!       - user written file                                             
!       - system catalog of standard structures                         
!                                                                       
!*****7*****************************************************************
      SUBROUTINE read_struc 
!-                                                                      
!     Main menu for read command.                                       
!+                                                                      
      USE config_mod 
      USE allocate_appl_mod
      USE crystal_mod 
      USE molecule_mod 
      USE read_internal_mod
      USE save_mod 
      USE spcgr_apply
      USE stack_rese_mod
      USE update_cr_dim_mod
!      USE interface_def
!
      USE doact_mod 
      USE learn_mod 
      USE macro_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 11) 
!                                                                       
      CHARACTER(1024) line, zeile, cpara (maxw) 
      CHARACTER(1024) strucfile 
      CHARACTER (LEN=1024)   :: string
      CHARACTER(50) prom 
      CHARACTER(5) befehl 
      INTEGER lpara (maxw), lp, length 
      INTEGER ce_natoms, lstr, i, j, k, iatom 
      INTEGER ianz, l, n, lbef 
      INTEGER    :: natoms,nscats
      LOGICAL lout 
      REAL hkl (3), u (3), xc (3), yc (3), zc (3), dist 
      REAL werte (maxw) 
      INTEGER          :: ncells
      INTEGER          :: n_gene
      INTEGER          :: n_symm
      INTEGER          :: n_mole
      INTEGER          :: n_type
      INTEGER          :: n_atom
      LOGICAL          :: need_alloc = .false.
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
!                                                                       
      CALL no_error 
!                                                                       
      blank = ' ' 
      lout = .true. 
!                                                                       
      lstr = 40 
      cr_icc (1) = 1 
      cr_icc (2) = 1 
      cr_icc (3) = 1 
!                                                                       
      prom = prompt (1:len_str (prompt) ) //'/read' 
      CALL get_cmd (line, length, befehl, lbef, zeile, lp, prom) 
!                                                                       
      IF (ier_num.ne.0) return 
      IF (line (1:1) .eq.' '.or.line (1:1) .eq.'#'.or.line.eq.char (13) &
      ) goto 9999                                                       
!                                                                       
!------ execute a macro file                                            
!                                                                       
      IF (line (1:1) .eq.'@') then 
         IF (length.ge.2) then 
            CALL file_kdo (line (2:length), length - 1) 
         ELSE 
            ier_num = - 13 
            ier_typ = ER_MAC 
         ENDIF 
!                                                                       
!------ Echo a string, just for interactive check in a macro 'echo'     
!                                                                       
      ELSEIF (str_comp (befehl, 'echo', 2, lbef, 4) ) then 
         CALL echo (zeile, lp) 
!                                                                       
!     execute command                                                   
!     help                                                              
!                                                                       
      ELSEIF (str_comp (befehl, 'help', 2, lbef, 4) .or.str_comp (befehl&
     &, '?   ', 1, lbef, 4) ) then                                      
         IF (zeile.eq.' '.or.zeile.eq.char (13) ) then 
            zeile = 'commands' 
            lp = lp + 8 
         ENDIF 
         IF (str_comp (zeile, 'errors', 2, lp, 6) ) then 
            lp = lp + 7 
            CALL do_hel ('discus '//zeile, lp) 
         ELSE 
            lp = lp + 12 
            CALL do_hel ('discus read '//zeile, lp) 
         ENDIF 
!                                                                       
!------  -----waiting for user input                                    
!                                                                       
      ELSEIF (str_comp (befehl, 'wait', 3, lbef, 4) ) then 
         CALL do_input (zeile, lp) 
!                                                                       
      ELSE 
!                                                                       
!     --all other commands                                              
!                                                                       
!     --get command parameters                                          
!                                                                       
         CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
         IF (ier_num.ne.0) then 
            RETURN 
         ENDIF 
         IF (ianz.ge.1) then 
!                                                                       
!     --Build file name                                                 
!                                                                       
            CALL do_build_name (ianz, cpara, lpara, werte, maxw, 1) 
            IF (ier_num.ne.0) then 
               RETURN 
            ENDIF 
         ENDIF 
!                                                                       
!     --reset epsilon tensors                                           
!                                                                       
         DO i = 1, 3 
         DO j = 1, 3 
         DO k = 1, 3 
         cr_eps (i, j, k) = 0.0 
         cr_reps (i, j, k) = 0.0 
         ENDDO 
         ENDDO 
         ENDDO 
!                                                                       
!     read in old cell, use space group symbol to generate cell         
!     content 'cell'                                                    
!                                                                       
         IF (str_comp (befehl, 'cell', 1, lbef, 4) .or.str_comp (befehl,&
         'lcell', 1, lbef, 5) ) then                                    
            IF (ianz.ge.1) then 
               cr_newtype = str_comp (befehl, 'cell', 1, lbef, 4) 
               CALL rese_cr 
               strucfile = cpara (1) 
               IF (ier_num.eq.0) then 
!                                                                       
!     --------if necessary get crystal size                             
!                                                                       
                  IF (ianz.gt.1) then 
                     cpara (1) = '0.0' 
                     lpara (1) = 3 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        DO i = 1, ianz - 1 
                        cr_icc (i) = nint (werte (i + 1) ) 
                        ENDDO 
                     ENDIF 
                  ENDIF 
                  IF (ier_num.eq.0) then 
internalcell:        IF ( str_comp(strucfile(1:8),'internal',8,8,8)) THEN
                        CALL readcell_internal(strucfile)
                     ELSE internalcell
                        CALL test_file ( strucfile, natoms, nscats, n_mole, n_type, &
                                         n_atom, -1 , .false.)
                        IF (ier_num /= 0) THEN
                           RETURN
                        ENDIF
                        CALL readcell (strucfile) 
                     ENDIF internalcell
!
                     IF (ier_num.eq.0) then 
!                                                                       
!     ----------check whether total number of atoms fits into available 
!     ----------space                                                   
!                                                                       
                        iatom = cr_icc (1) * cr_icc (2) * cr_icc (3)    &
                        * cr_natoms                                     
                        IF (iatom.gt.nmax) then 
                           CALL alloc_crystal ( MAXSCAT, INT(iatom * 1.1))
                           IF (ier_num < 0 ) RETURN
                        ENDIF
!
!                          ier_num = - 10 
!                          ier_typ = ER_APPL 
!                          WRITE (ier_msg (1), 3000) cr_icc (1),        &
!                          cr_icc (2), cr_icc (3)                       
!                          WRITE (ier_msg (2), 3100) cr_natoms 
!                          WRITE (ier_msg (3), 3200) iatom, nmax 
!3000 FORMAT                ('Unit cells   : ',3(i4,2x)) 
!3100 FORMAT                ('Atoms / cell : ',i10) 
!3200 FORMAT                ('Total / max  : ',i10,'/',i10) 
!                          RETURN 
!                       ENDIF 
                        ce_natoms = cr_natoms 
                        cr_ncatoms = cr_natoms 
                        cr_natoms = 0 
                        DO k = 1, cr_icc (3) 
                        DO j = 1, cr_icc (2) 
                        DO i = 1, cr_icc (1) 
                        DO n = 1, ce_natoms 
                        cr_natoms = cr_natoms + 1 
                        cr_iscat (cr_natoms) = cr_iscat (n) 
                        cr_pos (1, cr_natoms) = cr_pos (1, n) + float ( &
                        i - 1)                                          
                        cr_pos (2, cr_natoms) = cr_pos (2, n) + float ( &
                        j - 1)                                          
                        cr_pos (3, cr_natoms) = cr_pos (3, n) + float ( &
                        k - 1)                                          
                        cr_prop (cr_natoms) = cr_prop (n) 
                        ENDDO 
                        ENDDO 
                        ENDDO 
                        ENDDO 
!                                                                       
!     ----------Update crystal dimensions                               
!                                                                       
                        CALL update_cr_dim 
                        ncells = cr_icc (1) * cr_icc (2)* cr_icc (3)
!                                                                       
!     ----------If molecules were read                                  
!                                                                       
                        IF (mole_num_mole.gt.0) then 
      need_alloc = .false.
      n_gene = MAX( 1, MOLE_MAX_GENE)
      n_symm = MAX( 1, MOLE_MAX_SYMM)
      n_mole =         MOLE_MAX_MOLE
      n_type =         MOLE_MAX_TYPE
      n_atom =         MOLE_MAX_ATOM
      IF (mole_num_mole* ncells                              >= MOLE_MAX_MOLE ) THEN
         n_mole = mole_num_mole* ncells + 20
         need_alloc = .true.
      ENDIF
      IF ((mole_off(mole_num_mole)+mole_len(mole_num_mole))*ncells >= MOLE_MAX_ATOM ) THEN
         n_atom = (mole_off(mole_num_mole)+mole_len(mole_num_mole))*ncells + 200
         need_alloc = .true.
      ENDIF
      IF ( need_alloc ) THEN
         call alloc_molecule(n_gene, n_symm, n_mole, n_type, n_atom)
      ENDIF
                           IF (mole_num_mole * cr_icc (1) * cr_icc (2)  &
                           * cr_icc (3) .le.MOLE_MAX_MOLE) then         
                              mole_num_atom = mole_off (mole_num_mole)  &
                              + mole_len (mole_num_mole)                
                              l = mole_num_mole 
                              mole_num_unit = mole_num_mole 
                              DO i = 2, cr_icc (1) * cr_icc (2) *       &
                              cr_icc (3)                                
                              DO j = 1, mole_num_mole 
                              l = l + 1 
                              mole_len (l) = mole_len (j) 
                              mole_off (l) = mole_off (l -              &
                              mole_num_mole) + mole_num_atom            
                              mole_type (l) = mole_type (j) 
                              mole_char (l) = mole_char (j) 
                              mole_dens (l) = mole_dens (j) 
                              DO k = 1, mole_len (j) 
                              mole_cont (mole_off (l) + k) = mole_cont (&
                              mole_off (j) + k) + (i - 1) * ce_natoms   
                              ENDDO 
                              ENDDO 
                              ENDDO 
                              mole_num_mole = l 
                              mole_num_atom = mole_off (mole_num_mole)  &
                              + mole_len (mole_num_mole)                
                           ELSE 
                              ier_num = - 65 
                              ier_typ = ER_APPL 
                              RETURN 
                           ENDIF 
                        ENDIF 
!                                                                       
!     ----------Define initial crystal size in fractional coordinates   
!                                                                       
                        DO l = 1, 3 
                        cr_dim0 (l, 1) = float (nint (cr_dim (l, 1) ) ) 
                        cr_dim0 (l, 2) = float (nint (cr_dim (l, 2) ) ) 
                        ENDDO 
                     ENDIF 
                  ENDIF 
               ENDIF 
            ENDIF 
            IF (ier_num.eq.0) then 
!                                                                       
!     ------reset microdomain status                                    
!                                                                       
               CALL do_stack_rese 
            ENDIF 
!                                                                       
!     Free style editing of a structure 'free'                          
!                                                                       
         ELSEIF (str_comp (befehl, 'free', 1, lbef, 4) ) then 
            CALL rese_cr 
            cr_name = 'freely created structure' 
            cr_spcgr (1:1) = 'P' 
            cr_spcgr (2:2) = '1' 
      cr_spcgr (3:16)  = '              ' 
            cr_spcgrno = 1 
            cr_syst = 1 
            CALL get_symmetry_matrices 
            IF (ianz.eq.0) then 
               DO i = 1, 3 
               cr_a0 (i) = 1.0 
               cr_win (i) = 90.0 
               ENDDO 
            ELSEIF (ianz.eq.6) then 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               DO i = 1, 3 
               cr_a0 (i) = werte (i) 
               cr_win (i) = werte (i + 3) 
               ENDDO 
               IF (cr_a0 (1) .le.0.0.or.cr_a0 (2) .le.0.0.or.cr_a0 (3)  &
               .le.0.0.or.cr_win (1) .le.0.0.or.cr_win (2)              &
               .le.0.0.or.cr_win (3) .le.0.0.or.cr_win (1)              &
               .ge.180.0.or.cr_win (2) .ge.180.0.or.cr_win (3)          &
               .ge.180.0) then                                          
                  ier_num = - 93 
                  ier_typ = ER_APPL 
                  ier_msg (1) = 'Error reading unit cell parameters' 
                  RETURN 
               ENDIF 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
               RETURN 
            ENDIF 
            cr_icc (1) = 1 
            cr_icc (2) = 1 
            cr_icc (3) = 1 
            cr_natoms = 0 
            cr_ncatoms = 1 
            cr_nscat = 0 
            as_natoms = 0 
!                                                                       
!     ----reset microdomain status                                      
!                                                                       
            CALL do_stack_rese 
!                                                                       
!     read an old structure 'stru'                                      
!                                                                       
         ELSEIF (str_comp (befehl, 'stru', 1, lbef, 4) ) then 
            IF (ianz.eq.1) then 
               CALL rese_cr 
               sav_r_ncell = .false. 
               strucfile = cpara (1)
internal:      IF ( str_comp(strucfile(1:8),'internal',8,8,8)) THEN
                  CALL readstru_internal(strucfile) !, NMAX, MAXSCAT, MOLE_MAX_MOLE, &
!                       MOLE_MAX_TYPE, MOLE_MAX_ATOM )
               ELSE internal
               CALL test_file ( strucfile, natoms, nscats, n_mole, n_type, &
                             n_atom, -1 , .false.)
               IF (ier_num /= 0) THEN
                  RETURN
               ENDIF
               need_alloc = .false.
               IF(natoms > NMAX) THEN
                  natoms = MAX(INT(natoms * 1.1), natoms + 10,NMAX)
                  need_alloc = .true.
               ENDIF
               IF(nscats > MAXSCAT) THEN
                  nscats = MAX(INT(nscats * 1.1), nscats + 2, MAXSCAT)
                  need_alloc = .true.
               ENDIF
               IF ( need_alloc ) THEN
                  CALL alloc_crystal (nscats, natoms)
                  IF ( ier_num /= 0 ) RETURN
               ENDIF
               IF(n_mole>MOLE_MAX_MOLE .or. n_type>MOLE_MAX_TYPE .or.   &
                  n_atom>MOLE_MAX_ATOM                          ) THEN
                  n_mole = MAX(n_mole +20 ,MOLE_MAX_MOLE)
                  n_type = MAX(n_type +10 ,MOLE_MAX_TYPE)
                  n_atom = MAX(n_atom +200,MOLE_MAX_ATOM)
                  CALL alloc_molecule(1, 1,n_mole,n_type,n_atom)
                  IF ( ier_num /= 0 ) RETURN
               ENDIF
!
               CALL readstru (NMAX, MAXSCAT, strucfile, cr_name,        &
               cr_spcgr, cr_a0, cr_win, cr_natoms, cr_nscat, cr_dw,     &
               cr_at_lis, cr_pos, cr_iscat, cr_prop, cr_dim, as_natoms, &
               as_at_lis, as_dw, as_pos, as_iscat, as_prop, sav_ncell,  &
               sav_r_ncell, sav_ncatoms, spcgr_ianz, spcgr_para)        
               IF (ier_num.ne.0) then 
                  RETURN 
               ENDIF 
!                                                                       
!     ------Define initial crystal size in fractional coordinates       
!                                                                       
               DO l = 1, 3 
               cr_dim0 (l, 1) = float (nint (cr_dim (l, 1) ) ) 
               cr_dim0 (l, 2) = float (nint (cr_dim (l, 2) ) ) 
               ENDDO 
!                                                                       
!     ------The crystal size was read from the structure file           
!                                                                       
               IF (sav_r_ncell) then 
                  DO i = 1, 3 
                  cr_icc (i) = sav_ncell (i) 
                  ENDDO 
                  cr_ncatoms = sav_ncatoms 
               ELSE 
!                                                                       
!     ------Define initial crystal size in number of unit cells         
!                                                                       
                  DO i = 1, 3 
                  cr_icc (i) = max (1, int (cr_dim0 (i, 2) - cr_dim0 (i,&
                  1) ) )                                                
                  ENDDO 
!                                                                       
!     ------Define (average) number of atoms per unit cell              
!                                                                       
                  cr_ncatoms = cr_natoms / (cr_icc (1) * cr_icc (2)     &
                  * cr_icc (3) )                                        
               ENDIF 
               ENDIF internal
!                                                                       
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
            IF (ier_num.eq.0) then 
!                                                                       
!     ------reset microdomain status                                    
!                                                                       
               CALL do_stack_rese 
            ENDIF 
         ELSE 
            ier_num = - 6 
            ier_typ = ER_COMM 
            GOTO 9999 
         ENDIF 
         IF (ier_num.eq.0) then 
            WRITE (output_io, 1000) cr_spcgr, cr_spcgrno 
!.......calculate metric and reciprocal metric tensor,reciprocal lattice
!       constants and permutation tensors                               
            CALL setup_lattice (cr_a0, cr_ar, cr_eps, cr_gten, cr_reps, &
            cr_rten, cr_win, cr_wrez, cr_v, cr_vr, lout, cr_gmat,       &
            cr_fmat, cr_cartesian)                                      
            IF (.not. (str_comp (befehl, 'cell',  1, lbef, 4) .or.      &
                       str_comp (befehl, 'lcell', 1, lbef, 5)     ) ) then
               CALL get_symmetry_matrices 
            ENDIF
         ELSE 
            CALL errlist 
            IF (ier_sta.ne.ER_S_LIVE) then 
               IF (lmakro) then 
                  CALL macro_close 
                  prompt_status = PROMPT_ON 
               ENDIF 
               IF (lblock) then 
                  ier_num = - 11 
                  ier_typ = ER_COMM 
                  RETURN 
               ENDIF 
               CALL no_error 
            ENDIF 
         ENDIF 
      ENDIF 
!                                                                       
 9999 CONTINUE 
!                                                                       
 1000 FORMAT    (1x,a16,i5) 
      END SUBROUTINE read_struc                     
!********************************************************************** 
      SUBROUTINE readcell (strucfile) 
!-                                                                      
!           This subroutine reads a unit cell.                          
!+                                                                      
      USE config_mod 
      USE allocate_appl_mod
      USE crystal_mod 
      USE molecule_mod 
      USE save_mod 
      USE spcgr_apply
      USE wyckoff_mod
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER ist, maxw 
      PARAMETER (ist = 7, maxw = 5) 
!                                                                       
      CHARACTER ( LEN=* ), INTENT(IN) :: strucfile 
!
      CHARACTER(10) befehl 
      CHARACTER(1024) line, zeile 
      CHARACTER(80) cpara (maxw) 
      INTEGER lpara (maxw) 
      INTEGER property 
      INTEGER i, j, ibl, lbef 
      INTEGER lline 
      INTEGER     :: new_nmax
      INTEGER     :: new_nscat
      INTEGER     :: io_line
      INTEGER          :: n_gene
      INTEGER          :: n_symm
      INTEGER                          :: n_mole 
      INTEGER                          :: n_type 
      INTEGER                          :: n_atom 
      LOGICAL          :: need_alloc = .false.
      LOGICAL lread, lcell, lout 
      REAL werte (maxw), dw1 
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
      LOGICAL :: IS_IOSTAT_END
!                                                                       
      cr_natoms = 0 
      lread     = .true. 
      lcell     = .true. 
      lout      = .false. 
      CALL test_file ( strucfile, new_nmax, new_nscat, n_mole, n_type, &
                             n_atom, -1 , .not.cr_newtype)
      IF (ier_num /= 0) THEN
         CLOSE (ist)
         RETURN
      ENDIF
      IF( NMAX    < new_nmax .or. &          ! Allocate sufficient atom numbers
          MAXSCAT < new_nscat     ) THEN     ! Allocate sufficient atom types
         new_nmax = MAX(new_nmax ,NMAX)
         new_nscat= MAX(new_nscat,MAXSCAT)
         CALL alloc_crystal(new_nscat, new_nmax)
         IF ( ier_num /= 0) THEN
            CLOSE (IST)
            RETURN
         ENDIF
      ENDIF
      need_alloc = .false.
      IF ( n_mole > MOLE_MAX_MOLE  .or.  &
           n_type > MOLE_MAX_TYPE  .or.  &
           n_atom > MOLE_MAX_ATOM      ) THEN
         n_mole = MAX(n_mole,MOLE_MAX_MOLE)
         n_type = MAX(n_type,MOLE_MAX_TYPE)
         n_atom = MAX(n_atom,MOLE_MAX_ATOM)
         CALL alloc_molecule(1, 1, n_mole, n_type, n_atom)
         IF ( ier_num /= 0) THEN
            CLOSE (IST)
            RETURN
         ENDIF
      ENDIF
      CALL oeffne (ist, strucfile, 'old', lread) 
      IF (ier_num /= 0) THEN
         CLOSE (ist)
         RETURN
      ENDIF
!
      DO i = 1, 3 
         cr_dim (i, 1) =  1.e10 
         cr_dim (i, 2) = -1.e10 
      ENDDO 
!                                                                       
!     --Read header of structure file                                   
!                                                                       
         CALL stru_readheader (ist, NMAX, MAXSCAT, lcell, cr_name,      &
         cr_spcgr, cr_at_lis, cr_nscat, cr_dw, cr_a0, cr_win, sav_ncell,&
         sav_r_ncell, sav_ncatoms, spcgr_ianz, spcgr_para)              
      IF (ier_num.ne.0) THEN 
         CLOSE (ist)
         RETURN 
      ENDIF 
         CALL setup_lattice (cr_a0, cr_ar, cr_eps, cr_gten, cr_reps,    &
         cr_rten, cr_win, cr_wrez, cr_v, cr_vr, lout, cr_gmat, cr_fmat, &
         cr_cartesian)                                                  
!                                                                       
      IF (ier_num /= 0) THEN
         CLOSE (ist)
         RETURN
      ENDIF
!                                                                       
      CALL get_symmetry_matrices 
      IF( NMAX < spc_n*new_nmax .or.  &      ! Allocate sufficient atom numbers
          MAXSCAT < new_nscat       ) THEN   ! Allocate sufficient scattering types
         new_nmax  = MAX(spc_n*new_nmax + 1, NMAX)
         new_nscat = MAX(new_nscat         , MAXSCAT)
         CALL alloc_crystal(new_nscat, new_nmax)
        IF ( ier_num /= 0) THEN
            CLOSE (IST)
            RETURN
         ENDIF
      ENDIF
      need_alloc = .false.
      IF ( n_mole*spc_n > MOLE_MAX_MOLE ) THEN
         n_mole = n_mole*spc_n
         need_alloc = .true.
      ENDIF
      IF ( n_type > MOLE_MAX_TYPE ) THEN
         need_alloc = .true.
      ENDIF
      IF ( n_atom*spc_n > MOLE_MAX_ATOM ) THEN
         n_atom = n_atom*spc_n
         need_alloc = .true.
      ENDIF
      IF( need_alloc )  THEN         ! Allocate sufficient molecules
         CALL alloc_molecule(1, 1, n_mole, n_type, n_atom)
        IF ( ier_num /= 0) THEN
            CLOSE (IST)
            RETURN
         ENDIF
      ENDIF


main: DO  ! while (cr_natoms.lt.nmax)  ! end of loop via EOF in input
         ier_num = -49 
         ier_typ = ER_APPL 
         line = ' ' 
!        READ (ist, 2000, end = 2, err = 999) line 
         READ (ist, 2000, IOSTAT=io_line    ) line 
         IF(IS_IOSTAT_END(io_line)) THEN    ! Handle End Of File
            EXIT main
         ELSEIF(io_line /= 0 ) THEN         ! Handle input error
            GOTO 999
         ENDIF
         lline = len_str (line) 
!23456789 123456789 123456789 123456789 123456789 123456789 123456789 12
empty:   IF (line.ne.' '.and.line (1:1) .ne.'#'.and.line.ne.char (13)) THEN
            need_alloc = .false.
            new_nmax   = NMAX
            new_nscat  = MAXSCAT
            IF ( NMAX < cr_natoms + spc_n ) THEN     ! Allocate sufficient atom numbers
               new_nmax  = MAX(NMAX + spc_n + 1, cr_natoms + spc_n+1)
               need_alloc = .true.
            ENDIF
            IF ( MAXSCAT < cr_nscat + 1       ) THEN ! Allocate sufficient atom types
               new_nscat = MAX(MAXSCAT + 5, INT ( MAXSCAT * 1.025 ) )
               need_alloc = .true.
            ENDIF
            IF( need_alloc ) THEN
               CALL alloc_crystal(new_nscat, new_nmax)
               IF ( ier_num /= 0) THEN
                  CLOSE (IST)
                  RETURN
               ENDIF
               ier_num = -49 
               ier_typ = ER_APPL 
            ENDIF
               lbef = 10 
               befehl = ' ' 
               ibl = index (line (1:lline) , ' ') 
               IF (ibl.eq.0) THEN 
                  ibl = lline+1 
               ENDIF 
               lbef = min (ibl - 1, lbef) 
               befehl = line (1:lbef) 
typus:         IF (str_comp (befehl, 'molecule', 4, lbef, 8) .or.       &
                   str_comp (befehl, 'domain',   4, lbef, 6) .or.       &
                   str_comp (befehl, 'object',   4, lbef, 6)     ) THEN
!                                                                       
!     ----------Start/End of a molecule                                 
!                                                                       
                  CALL no_error 
                  IF (ibl.le.lline) then 
                     i = lline-ibl 
                     zeile = line (ibl + 1:lline) 
                  ELSE 
                     zeile = ' ' 
                     i = 0 
                  ENDIF 
                  CALL struc_mole_header (zeile, i, .true.) 
                  IF (ier_num.ne.0) THEN
                     CLOSE(IST)
                     RETURN 
                  ENDIF
               ELSE  typus
                  DO j = 1, MAXW 
                  werte (j) = 0.0 
                  ENDDO 
                  werte (5) = 1.0 
                  CALL read_atom_line (line, ibl, lline, as_natoms,     &
                  maxw, werte)                                          
                  IF (ier_num.ne.0.and.ier_num.ne. -49) then 
                     GOTO 999 
                  ENDIF 
                  cr_natoms = cr_natoms + 1 
                  i = cr_natoms 
                  IF (.not.mole_l_on) then 
!                                                                       
!     ------------Transform atom into first unit cell,                  
!                 if it is not inside a molecule                        
!                                                                       
                     CALL firstcell (werte, maxw) 
                  ENDIF 
!                                                                       
                  DO j = 1, 3 
                     cr_pos (j, i) = werte (j) 
                  ENDDO 
                  dw1 = werte (4) 
                  cr_prop (i) = nint (werte (5) ) 
!                                                                       
                  IF (line (1:4) .ne.'    ') then 
                     ibl = ibl - 1 
                     CALL do_cap (line (1:ibl) ) 
!                                                                       
!------ ----------- New option determines whether all atoms in          
!------ ----------- asymmetric unit are considered different atom       
!------ ----------- types ..                                            
!                                                                       
                     IF (.not.cr_newtype) then 
                        DO j = 0, cr_nscat 
                        IF (line (1:ibl) .eq.cr_at_lis (j)              &
                        .and.dw1.eq.cr_dw (j) ) then                    
                           cr_iscat (i) = j 
                           CALL symmetry 
                           IF (ier_num.ne.0) then 
                              CLOSE (IST)
                              RETURN 
                           ENDIF 
                           GOTO 22 
                        ENDIF 
                        ENDDO 
                     ENDIF 
!                                                                       
!------ ----------- end new code                                        
!                                                                       
                     IF (cr_nscat.lt.maxscat) then 
                        cr_nscat = cr_nscat + 1 
                        cr_iscat (i) = cr_nscat 
                        cr_at_lis (cr_nscat) = line (1:ibl) 
                        cr_dw (cr_nscat) = dw1 
!                                                                       
                        as_natoms = as_natoms + 1 
                        as_at_lis (cr_nscat) = cr_at_lis (cr_nscat) 
                        as_iscat (as_natoms) = cr_iscat (i) 
                        as_dw (as_natoms) = cr_dw (cr_nscat) 
                        DO j = 1, 3 
                        as_pos (j, as_natoms) = cr_pos (j, i) 
                        ENDDO 
                        as_prop (as_natoms) = cr_prop (i) 
                        CALL symmetry 
                        IF (ier_num.ne.0) then 
                           CLOSE(IST)
                           RETURN 
                        ENDIF 
                     ELSE 
                        ier_num = -26 
                        ier_typ = ER_APPL 
                        GOTO 2 
                     ENDIF 
   22                CONTINUE 
                  ENDIF 
               ENDIF  typus
            ENDIF empty
      ENDDO main 
!                                                                       
    2    CONTINUE 
         IF (ier_num.eq. -49) then 
            CALL no_error 
!                                                                       
!       move first unit cell into lower left corner of crystal          
!                                                                       
            DO i = 1, cr_natoms 
            DO j = 1, 3 
            cr_pos (j, i) = cr_pos (j, i) - int ( (cr_icc (j) ) / 2) 
!             cr_pos(j,i)=cr_pos(j,i) - int((cr_icc(j)-0.1)/2)          
            cr_dim (j, 1) = amin1 (cr_dim (j, 1), cr_pos (j, i) ) 
            cr_dim (j, 2) = amax1 (cr_dim (j, 2), cr_pos (j, i) ) 
            ENDDO 
            ENDDO 
         ENDIF 
!                                                                       
!     ENDIF 
!                                                                       
  999 CONTINUE 
      CLOSE (ist) 
      IF (ier_num.eq. - 49) then 
         WRITE (ier_msg (1), 3000) as_natoms + 1 
 3000 FORMAT      ('At atom number = ',i8) 
      ENDIF 
!                                                                       
 2000 FORMAT    (a) 
 2010 FORMAT    (a16) 
      END SUBROUTINE readcell                       
!********************************************************************** 
      SUBROUTINE read_atom_line (line, ibl, length, cr_natoms, maxw,    &
      werte)                                                            
!-                                                                      
!     reads a line from the cell file/structure file                    
!+                                                                      
      USE prop_para_mod 
      IMPLICIT none 
!                                                                       
                                                                        
!                                                                       
      CHARACTER ( * ) line 
      INTEGER ibl 
      INTEGER length 
      INTEGER cr_natoms 
      INTEGER maxw 
      REAL werte (maxw) 
!                                                                       
      CHARACTER(1024) cpara (maxw) 
      CHARACTER(1024) string 
      INTEGER lpara (maxw) 
      INTEGER j 
      INTEGER ianz 
!                                                                       
      werte (5) = 1.0 
      CALL get_params (line (ibl:length), ianz, cpara, lpara, maxw,     &
      length - ibl + 1)                                                 
params: IF(IANZ.eq.1) THEN
!                                                                       
!-----      Deal with old four respectively old five column style       
!                                                                       
         READ (line (ibl:length), *, end = 999, err = 850) (werte (j),  &
         j = 1, 4)                                                      
!                                                                       
!       got four columns, try to read column five                       
!                                                                       
         READ (line (ibl:length), *, end = 800, err = 850) (werte (j),  &
         j = 1, 5)                                                      
  800    CONTINUE 
         CALL no_error 
         GOTO 900 
  850    CONTINUE
      ELSE params
!                                                                       
got_params: IF (ier_num.eq.0) THEN 
         IF (ianz.eq.4.or.ianz.eq.5) then 
            DO j = 1, ianz 
               string = '(1.0*'//cpara (j) (1:lpara (j) ) //')' 
               cpara (j) = string 
               lpara (j) = lpara (j) + 6 
            ENDDO 
            CALL ber_params (ianz, cpara, lpara, werte, maxw) 
            IF (ier_num.ne.0) then 
               ier_msg (1)  = 'Error calculating atom  ' 
               ier_msg (2) = 'coordinates for atom '//line (1:ibl) 
               WRITE (ier_msg (3), 2000) cr_natoms + 1 
               RETURN 
            ENDIF 
            CALL no_error 
         ELSE 
            ier_num = - 6 
            ier_typ = ER_COMM 
            ier_msg (1) = 'Missing coordinates for ' 
            ier_msg (2) = 'atom '//line (1:ibl) 
            ier_msg (3) = ' ' 
            RETURN 
         ENDIF 
      ELSE  got_params
         ier_msg (1) = 'Error reading parameters for' 
         ier_msg (2) = 'coordinates for atom '//line (1:ibl) 
         WRITE (ier_msg (3), 2000) cr_natoms + 1 
         RETURN 
         ENDIF  got_params
      ENDIF params
      RETURN 
!                                                                       
  900 CONTINUE 
!                                                                       
!-----      Basic error checks TO FOLLOW                                
!                                                                       
      IF (nint (werte (5) ) < 0              .or.  &
          2**(MAXPROP+1)-1  < nint (werte (5)    )  )THEN
         ier_num = - 102 
         ier_typ = ER_APPL 
      ENDIF 
!                                                                       
  999 CONTINUE 
!                                                                       
 2000 FORMAT    ('Atom Nr. ',i4) 
      END SUBROUTINE read_atom_line                 
!********************************************************************** 
      SUBROUTINE struc_mole_header (zeile, lp, lcell) 
!-                                                                      
!     interprets the 'molecule' lines of a structure file               
!+                                                                      
                                                                        
      USE allocate_appl_mod
      USE config_mod 
      USE crystal_mod 
      USE molecule_mod 
      USE spcgr_apply
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 21) 
!                                                                       
      CHARACTER ( * ) zeile 
      CHARACTER(1024) cpara (maxw) 
      INTEGER j, ianz 
      INTEGER lpara (maxw), lp 
      REAL werte (maxw) 
      LOGICAL lcell 
      INTEGER          :: n_gene
      INTEGER          :: n_symm
      INTEGER          :: n_mole
      INTEGER          :: n_type
      INTEGER          :: n_atom
      LOGICAL          :: need_alloc = .false.
!                                                                       
      LOGICAL str_comp 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                                                                        
      IF (ier_num.eq.0) then 
         IF (ianz.eq.0) then 
!                                                                       
!     --No parameters, start a new Molekule                             
!                                                                       
      need_alloc = .false.
      n_gene = MAX( 1, MOLE_MAX_GENE)
      n_symm = MAX( 1, MOLE_MAX_SYMM)
      n_mole =         MOLE_MAX_MOLE
      n_type =         MOLE_MAX_TYPE
      n_atom =         MOLE_MAX_ATOM
      IF (mole_num_mole >= MOLE_MAX_MOLE ) THEN
         n_mole = mole_num_mole + 20
         need_alloc = .true.
      ENDIF
      IF ( need_alloc ) THEN
         call alloc_molecule(n_gene, n_symm, n_mole, n_type, n_atom)
      ENDIF
            IF (mole_num_mole.lt.MOLE_MAX_MOLE) then 
               IF (mole_num_type.lt.MOLE_MAX_TYPE) then 
                  mole_l_on = .true. 
                  mole_l_first = .true. 
                  mole_num_atom = mole_off (mole_num_mole) + mole_len ( &
                  mole_num_mole)                                        
                  mole_num_mole = mole_num_mole+1 
                  mole_num_curr = mole_num_mole 
                  mole_num_type = mole_num_type+1 
                  mole_off (mole_num_mole) = mole_num_atom 
                  mole_type (mole_num_mole) = mole_num_type 
                  mole_gene_n = 0 
                  mole_symm_n = 0 
               ELSE 
                  ier_num = - 66 
                  ier_typ = ER_APPL 
                  RETURN 
               ENDIF 
            ELSE 
               ier_num = - 65 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
         ELSE 
!                                                                       
!     --Parameters, interpret parameters                                
!                                                                       
            IF (str_comp (cpara (1) , 'end', 3, lpara (1) , 3) ) then 
!                                                                       
!     ----Turn off molecule                                             
!                                                                       
               IF (lcell) call mole_firstcell 
               mole_l_on = .false. 
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'character', 3, lpara (1) , 9)&
            ) then                                                      
!                                                                       
!     ------Define whether this is a molecule or an object              
!                                                                       
               IF (str_comp (cpara (2) , 'atoms', 2, lpara (2) , 5) )   &
               then                                                     
                  mole_char (mole_num_mole) = MOLE_ATOM 
               ELSEIF (str_comp (cpara (2) , 'cube', 2, lpara (2) , 4) )&
               then                                                     
                  mole_char (mole_num_mole) = MOLE_CUBE 
               ELSEIF (str_comp (cpara (2) , 'cylinder', 2, lpara (2) , &
               8) ) then                                                
                  mole_char (mole_num_mole) = MOLE_CYLINDER 
               ELSEIF (str_comp (cpara (2) , 'sphere', 2, lpara (2) , 6)&
               ) then                                                   
                  mole_char (mole_num_mole) = MOLE_SPHERE 
               ELSEIF (str_comp (cpara (2) , 'edge', 2, lpara (2) , 4) )&
               then                                                     
                  mole_char (mole_num_mole) = MOLE_EDGE 
               ELSEIF (str_comp (cpara (2) , 'domain_cube', 9, lpara (2)&
               , 11) ) then                                             
                  mole_char (mole_num_mole) = MOLE_DOM_CUBE 
               ELSEIF (str_comp (cpara (2) , 'domain_cylinder', 9,      &
               lpara (2) , 15) ) then                                   
                  mole_char (mole_num_mole) = MOLE_DOM_CYLINDER 
               ELSEIF (str_comp (cpara (2) , 'domain_sphere', 9, lpara (&
               2) , 13) ) then                                          
                  mole_char (mole_num_mole) = MOLE_DOM_SPHERE 
               ELSEIF (str_comp (cpara (2) , 'domain_fuzzy', 9, lpara ( &
               2) , 12) ) then                                          
                  mole_char (mole_num_mole) = MOLE_DOM_FUZZY 
               ELSE 
                  ier_num = - 82 
                  ier_typ = ER_APPL 
               ENDIF 
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'file', 3, lpara (1) , 4) )   &
            then                                                        
               mole_file (mole_num_mole) = cpara (2) 
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'density', 3, lpara (1) , 6) )&
            then                                                        
!                                                                       
!     ------Define the scattering density of an object                  
!                                                                       
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.2) then 
                     mole_dens (mole_num_mole) = werte (2) 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'fuzzy', 3, lpara (1) , 5) )  &
            then                                                        
!                                                                       
!     ------Define the minimum distance between atoms in a domain       
!             and the host                                              
!                                                                       
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.2) then 
                     mole_fuzzy (mole_num_mole) = werte (2) 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'generator', 3, lpara (1) , 9)&
            ) then                                                      
!                                                                       
!     ------Define which generators create atoms within the             
!           same molecule                                               
!           Obsolete statement, is done automatically!!! RBN            
!                                                                       
               ier_num = + 2 
               ier_typ = ER_APPL 
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'symmetry', 4, lpara (1) , 8) &
            ) then                                                      
!                                                                       
!     ------Define which symmetries  create atoms within the            
!           same molecule                                               
!           Obsolete statement, is done automatically!!! RBN            
!                                                                       
               ier_num = + 2 
               ier_typ = ER_APPL 
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'type', 3, lpara (1) , 4) )   &
            then                                                        
!                                                                       
!     ------Define the molecule type, if less than current highest      
!     ------type number diminuish type number by one                    
!                                                                       
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.2) then 
                     IF (nint (werte (2) ) .lt.mole_num_type) then 
                        mole_num_type = mole_num_type-1 
                        mole_type (mole_num_mole) = nint (werte (2) ) 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
            ELSEIF (str_comp (cpara (1) , 'content', 4, lpara (1) , 7) )&
            then                                                        
!                                                                       
!     ------start reading a molecule content                            
!                                                                       
               cpara (1) = '0' 
               lpara (1) = 1 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.2.or.ianz.eq.3) then 
                     IF (mole_num_mole.lt.MOLE_MAX_MOLE) then 
                        IF (werte (2) .lt.MOLE_MAX_TYPE) then 
                           IF (mole_l_on) then 
                              mole_type (mole_num_mole) = int (werte (2)&
                              )                                         
                              mole_num_type = max (mole_num_type-1, int &
                              (werte (2) ) )                            
                           ELSE 
                              mole_num_atom = mole_off (mole_num_mole)  &
                              + mole_len (mole_num_mole)                
                              mole_num_mole = mole_num_mole+1 
                              mole_num_curr = mole_num_mole 
                              mole_type (mole_num_mole) = int (werte (2)&
                              )                                         
                              mole_off (mole_num_mole) = mole_num_atom 
                              mole_len (mole_num_mole) = 0 
                              mole_num_type = max (mole_num_type, int ( &
                              werte (2) ) )                             
                              mole_gene_n = 0 
                              mole_symm_n = 0 
                              mole_l_on = .true. 
                           ENDIF 
                        ELSE 
                           ier_num = - 64 
                           ier_typ = ER_APPL 
      ier_msg (1)  = 'First characters of wrong line' 
                           ier_msg (2) = zeile (1:40) 
                           ier_msg (3) = zeile (41:80) 
                        ENDIF 
                     ELSE 
                        ier_num = - 65 
                        ier_typ = ER_APPL 
                        ier_msg (1) = 'First characters of wrong line' 
                        ier_msg (2) = zeile (1:40) 
                        ier_msg (3) = zeile (41:80) 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                     ier_msg (1) = 'First characters of wrong line' 
                     ier_msg (2) = zeile (1:40) 
                     ier_msg (3) = zeile (41:80) 
                  ENDIF 
               ELSE 
                  ier_msg (1) = 'First characters of wrong line' 
                  ier_msg (2) = zeile (1:40) 
                  ier_msg (3) = zeile (41:80) 
               ENDIF 
            ELSEIF (str_comp (cpara (1) , 'atoms', 4, lpara (1) , 5) )  &
            then                                                        
!                                                                       
!     ------read a molecule content                                     
!                                                                       
               IF (mole_l_on) then 
                  cpara (1) = '0' 
                  lpara (1) = 1 
                  CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  IF (ier_num.eq.0) then 
                     DO j = 2, ianz 
                     mole_len (mole_num_mole) = mole_len (mole_num_mole)&
                     + 1                                                
                     mole_cont (mole_off (mole_num_mole) + mole_len (   &
                     mole_num_mole) ) = int (werte (j) )                
                     ENDDO 
                  ELSE 
                     ier_msg (1) = 'First characters of wrong line' 
                     ier_msg (2) = zeile (1:40) 
                     ier_msg (3) = zeile (41:80) 
                  ENDIF 
               ELSE 
                  ier_num = - 65 
                  ier_typ = ER_APPL 
               ENDIF 
            ELSE 
               ier_num = - 84 
               ier_typ = ER_APPL 
               ier_msg (1) = 'First characters of wrong line' 
               ier_msg (2) = zeile (1:40) 
               ier_msg (3) = zeile (41:80) 
            ENDIF 
         ENDIF 
      ENDIF 
!                                                                       
      END SUBROUTINE struc_mole_header              
!********************************************************************** 
      SUBROUTINE readstru (NMAX, MAXSCAT, strucfile, cr_name, cr_spcgr, &
      cr_a0, cr_win, cr_natoms, cr_nscat, cr_dw, cr_at_lis, cr_pos,     &
      cr_iscat, cr_prop, cr_dim, as_natoms, as_at_lis, as_dw, as_pos,   &
      as_iscat, as_prop, sav_ncell, sav_r_ncell, sav_ncatoms,           &
      spcgr_ianz, spcgr_para)                                           
!-                                                                      
!           this subroutine reads an old structur.                      
!+                                                                      
      IMPLICIT none 
!                                                                       
      INTEGER NMAX 
      INTEGER MAXSCAT 
!                                                                       
!
      INTEGER,                       INTENT(INOUT)  :: cr_natoms
      INTEGER, DIMENSION(1:NMAX),    INTENT(INOUT)  :: cr_iscat
      INTEGER, DIMENSION(1:NMAX),    INTENT(INOUT)  :: cr_prop
      REAL   , DIMENSION(1:3,1:NMAX),INTENT(INOUT)  :: cr_pos
!                                                                       
      INTEGER sav_ncell (3) 
      INTEGER sav_ncatoms 
      LOGICAL sav_r_ncell 
      LOGICAL lcell 
!                                                                       
      INTEGER ist 
      PARAMETER (ist = 7) 
!                                                                       
      CHARACTER ( * ) strucfile 
      CHARACTER(80) cr_name 
      CHARACTER(16) cr_spcgr 
      CHARACTER(4) cr_at_lis (0:MAXSCAT) 
      CHARACTER(4) as_at_lis (0:MAXSCAT) 
!                                                                       
      INTEGER cr_nscat 
      INTEGER as_natoms 
      INTEGER as_prop (MAXSCAT) 
      INTEGER as_iscat (MAXSCAT) 
!                                                                       
      INTEGER spcgr_ianz 
      INTEGER spcgr_para 
!                                                                       
      REAL cr_a0 (3) 
      REAL cr_win (3) 
      REAL cr_dw (0:MAXSCAT) 
      REAL cr_dim (3, 2) 
      REAL as_pos (3, MAXSCAT) 
      REAL as_dw (0:MAXSCAT) 
!                                                                       
      INTEGER i 
      LOGICAL lread 
!                                                                       
      cr_natoms = 0 
      lread = .true. 
      lcell = .false. 
      CALL oeffne (ist, strucfile, 'old', lread) 
      IF (ier_num.eq.0) then 
         DO i = 1, 3 
         cr_dim (i, 1) = 1.e10 
         cr_dim (i, 2) = - 1.e10 
         ENDDO 
!                                                                       
!     --Read header of structure file                                   
!                                                                       
         CALL stru_readheader (ist, NMAX, MAXSCAT, lcell, cr_name,      &
         cr_spcgr, cr_at_lis, cr_nscat, cr_dw, cr_a0, cr_win, sav_ncell,&
         sav_r_ncell, sav_ncatoms, spcgr_ianz, spcgr_para)              
!                                                                       
         IF (ier_num.eq.0) then 
!                                                                       
            CALL struc_read_atoms (NMAX, MAXSCAT, cr_natoms, cr_nscat,  &
            cr_dw, cr_at_lis, cr_pos, cr_iscat, cr_prop, cr_dim,        &
            as_natoms, as_at_lis, as_dw, as_pos, as_iscat, as_prop)     
         ENDIF 
      ENDIF 
!                                                                       
  999 CONTINUE 
      CLOSE (ist) 
      IF (ier_num.eq. - 49) then 
         WRITE (ier_msg (1), 3000) cr_natoms + 1 
 3000 FORMAT      ('At atom number = ',i8) 
      ENDIF 
!                                                                       
 2000 FORMAT    (a) 
 2010 FORMAT    (a16) 
      END SUBROUTINE readstru                       
!********************************************************************** 
      SUBROUTINE stru_readheader (ist, HD_NMAX, HD_MAXSCAT, lcell, cr_name,   &
      cr_spcgr, cr_at_lis, cr_nscat, cr_dw, cr_a0, cr_win, sav_ncell,   &
      sav_r_ncell, sav_ncatoms, spcgr_ianz, spcgr_para)                 
!-                                                                      
!     This subroutine reads the header of a structure file              
!+                                                                      
      USE gen_add_mod 
      USE sym_add_mod 
      IMPLICIT none 
!                                                                       
      INTEGER HD_NMAX 
      INTEGER HD_MAXSCAT 
!                                                                       
!                                                                       
      CHARACTER(80) cr_name 
      CHARACTER(16) cr_spcgr 
      CHARACTER(4) cr_at_lis (0:HD_MAXSCAT) 
!                                                                       
      INTEGER cr_nscat 
!                                                                       
      INTEGER spcgr_ianz 
      INTEGER spcgr_para 
!                                                                       
      REAL cr_a0 (3) 
      REAL cr_win (3) 
      REAL cr_dw (0:HD_MAXSCAT) 
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 13) 
!                                                                       
      CHARACTER(1024) line, cpara (maxw) 
      CHARACTER(1024) zeile 
      CHARACTER(6) befehl 
      INTEGER ist, i, ll, j, islash 
      INTEGER ianz 
!DBG      integer             spcgr_ianz                                
      INTEGER lpara (maxw), lp 
      INTEGER lbef, indxb 
      INTEGER xx_nscat, xx_nadp 
      INTEGER sav_ncell (3) 
      INTEGER sav_ncatoms 
      LOGICAL sav_r_ncell 
      LOGICAL lcell 
      LOGICAL lend 
!DBG      real            spcgr_para                                    
      REAL werte (maxw) 
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
!
      xx_nscat = 0 
      xx_nadp = 0 
!                                                                       
      ier_num = - 46 
      ier_typ = ER_APPL 
      READ (ist, 2000, end = 999, err = 999) cr_name 
!                                                                       
!     This construction is needed as long a the old cell file format    
!     must be supported.                                                
!                                                                       
!                                                                       
!     The maximum number of significant characters depends on the       
!     length of the character constant befehl.                          
!                                                                       
      lbef = len (befehl) 
      befehl = '    ' 
      indxb = index (cr_name, ' ') 
      lbef = min (indxb - 1, lbef) 
      befehl = cr_name (1:lbef) 
      lbef = len_str (befehl) 
      befehl = cr_name (1:lbef) 
      IF (str_comp (befehl, 'title', 1, lbef, 5) ) then 
!                                                                       
!     Read new header                                                   
!                                                                       
!                                                                       
!     --remove title string from cr_name                                
!                                                                       
         ll = len (cr_name) 
         ll = len_str (cr_name) 
         line = ' ' 
         IF (0.lt.indxb.and.indxb + 1.le.ll) then 
            line (1:ll - indxb) = cr_name (indxb + 1:ll) 
         ELSE 
            line = ' ' 
         ENDIF 
         cr_name = line 
!                                                                       
         CALL no_error 
         DO while (.not.str_comp (befehl, 'atoms', 1, lbef, 5) ) 
         READ (ist, 2000, end = 999, err = 999) line 
         ll = 200 
         ll = len_str (line) 
!                                                                       
!     ----The maximum number of significant characters depends on the   
!     ----length of the character constant befehl.                      
!                                                                       
         lbef = len (befehl) 
      befehl = '    ' 
         indxb = index (line, ' ') 
         lbef = min (indxb - 1, lbef) 
         befehl = line (1:lbef) 
         lbef = len_str (befehl) 
         befehl = line (1:lbef) 
!                                                                       
!     ----command parameters start at the first character following     
!------ ----the blank                                                   
!                                                                       
         zeile = ' ' 
         lp = 0 
         IF (indxb + 1.le.ll) then 
            zeile = line (indxb + 1:ll) 
            lp = ll - indxb 
         ENDIF 
!                                                                       
!     ----Commentary                                                    
!                                                                       
                                                                        
         IF (line.eq.' '.or.line (1:1) .eq.'#'.or.line.eq.char (13) )   &
         then                                                           
            CONTINUE 
!                                                                       
!     ----Space group symbol                                            
!                                                                       
         ELSEIF (str_comp (befehl, 'spcgr', 1, lbef, 5) ) then 
            CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
            IF (ianz.lt.1) then 
               ier_num = - 100 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
            islash = index (cpara (1) (1:lpara (1) ) , 'S') 
            DO while (islash.ne.0) 
            cpara (1) (islash:islash) = '/' 
            islash = index (cpara (1) (1:lpara (1) ) , 'S') 
            ENDDO 
            cr_spcgr = cpara (1) 
            spcgr_ianz = ianz - 1 
            ianz = ianz - 1 
            spcgr_para = 1 
            IF (ianz.eq.1) then 
               cpara (1) = cpara (2) 
               lpara (1) = lpara (2) 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               spcgr_para = nint (werte (1) ) 
            ENDIF 
            IF (ier_num.ne.0) then 
               ier_num = - 47 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
!                                                                       
!     ----Cell constants                                                
!                                                                       
         ELSEIF (str_comp (befehl, 'cell', 1, lbef, 4) ) then 
            CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
            IF (ier_num.eq.0) then 
               IF (ianz.eq.6) then 
!     --------New style, kommata included                               
                  CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  IF (ier_num.eq.0) then 
                     DO i = 1, 3 
                     cr_a0 (i) = werte (i) 
                     cr_win (i) = werte (i + 3) 
                     ENDDO 
                  ELSE 
                     ier_msg (1) = 'Error reading unit cell parameters' 
                     RETURN 
                  ENDIF 
               ELSE 
!     --------Old style, no kommata included                            
                  ier_num = - 48 
                  ier_typ = ER_APPL 
                  READ (zeile, *, end = 999, err = 999) (cr_a0 (i),     &
                  i = 1, 3), (cr_win (i), i = 1, 3)                     
                  CALL no_error 
               ENDIF 
            ELSE 
               ier_msg (1) = 'Error reading unit cell parameters' 
               RETURN 
            ENDIF 
            IF (cr_a0 (1) .le.0.0.or.cr_a0 (2) .le.0.0.or.cr_a0 (3)     &
            .le.0.0.or.cr_win (1) .le.0.0.or.cr_win (2)                 &
            .le.0.0.or.cr_win (3) .le.0.0.or.cr_win (1)                 &
            .ge.180.0.or.cr_win (2) .ge.180.0.or.cr_win (3) .ge.180.0)  &
            then                                                        
               ier_num = - 93 
               ier_typ = ER_APPL 
               ier_msg (1) = 'Error reading unit cell parameters' 
               RETURN 
            ENDIF 
!                                                                       
!     ----Additional symmetry generators 'generator'                    
!                                                                       
         ELSEIF (str_comp (befehl, 'gene', 1, lbef, 4) ) then 
            IF (gen_add_n.lt.GEN_ADD_MAX) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.12.or.ianz.eq.13) then 
                     CALL ber_params (ianz, cpara, lpara, werte,     &
                     maxw)                                           
                     IF (ier_num.eq.0) then 
                        gen_add_n = gen_add_n + 1 
                        DO j = 1, 4 
                        gen_add (1, j, gen_add_n) = werte (j) 
                        gen_add (2, j, gen_add_n) = werte (j + 4) 
                        gen_add (3, j, gen_add_n) = werte (j + 8) 
                        ENDDO 
                        IF (ianz.eq.13) then 
                           gen_add_power (gen_add_n) = nint (werte ( &
                           13) )                                     
                        ELSE 
                           gen_add_power (gen_add_n) = 1 
                        ENDIF 
                     ENDIF 
                  ELSEIF (ianz.eq.1) then 
                     lend = .true. 
                     READ (zeile, *, end = 8000) (werte (j), j = 1,  &
                     13)                                             
                     lend = .false. 
                     gen_add_n = gen_add_n + 1 
                     DO j = 1, 4 
                     gen_add (1, j, gen_add_n) = werte (j) 
                     gen_add (2, j, gen_add_n) = werte (j + 4) 
                     gen_add (3, j, gen_add_n) = werte (j + 8) 
                     ENDDO 
                     gen_add_power (gen_add_n) = nint (werte (13) ) 
 8000                CONTINUE 
                     IF (lend) then 
                        ier_num = - 92 
                        ier_typ = ER_APPL 
                        RETURN 
                     ENDIF 
                  ELSE 
                     ier_num = - 92 
                     ier_typ = ER_APPL 
                  ENDIF 
               ENDIF 
            ELSE 
               ier_num = - 61 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
!                                                                       
!     ----Names of atoms to setup specific sequence of scattering curves
!                                                               'scat'  
!                                                                       
         ELSEIF (str_comp (befehl, 'scat', 2, lbef, 4) ) then 
            CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
            IF (ier_num.eq.0) then 
               IF (xx_nscat + ianz.le.HD_MAXSCAT) then 
                  DO i = 1, ianz 
                  CALL do_cap (cpara (i) (1:lpara (i) ) ) 
                  cr_at_lis (xx_nscat + i) = cpara (i) 
                  ENDDO 
                  xx_nscat = xx_nscat + ianz 
                  cr_nscat = max (cr_nscat, xx_nscat) 
               ELSE 
                  ier_num = -26 
                  ier_typ = ER_APPL 
               ENDIF 
            ELSE 
               ier_num = -111
               ier_typ = ER_COMM 
            ENDIF 
!                                                                       
!     ----Displacement parameters to setup specific sequence of         
!                                    scattering curves 'adp'            
!                                                                       
         ELSEIF (str_comp (befehl, 'adp', 2, lbef, 3) ) then 
            CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
            IF (ier_num.eq.0) then 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  IF (xx_nadp + ianz.le.HD_MAXSCAT) then 
                     DO i = 1, ianz 
                     cr_dw (xx_nadp + i) = werte (i) 
                     ENDDO 
                     xx_nadp = xx_nadp + ianz 
                     cr_nscat = max (cr_nscat, xx_nadp) 
                  ELSE 
                     ier_num = - 26 
                     ier_typ = ER_APPL 
                  ENDIF 
               ENDIF 
            ELSE 
               ier_num = -112
               ier_typ = ER_COMM 
            ENDIF 
!                                                                       
!     ----Crystal dimensions and number of atoms per unit cell 'ncell'  
!                                                                       
         ELSEIF (str_comp (befehl, 'ncell', 1, lbef, 5) ) then 
            CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
            IF (ier_num.eq.0) then 
               IF (ianz.eq.4) then 
                  CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                  IF (ier_num.eq.0) then 
                     DO j = 1, 3 
                     sav_ncell (j) = werte (j) 
                     ENDDO 
                     sav_ncatoms = werte (4) 
                     sav_r_ncell = .true. 
                  ENDIF 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
            ENDIF 
!                                                                       
!     ----Additional symmetry operations 'symmetry'                     
!                                                                       
         ELSEIF (str_comp (befehl, 'symm', 2, lbef, 4) ) then 
            IF (sym_add_n.lt.SYM_ADD_MAX) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.12.or.ianz.eq.13) then 
                     CALL ber_params (ianz, cpara, lpara, werte,     &
                     maxw)                                           
                     IF (ier_num.eq.0) then 
                        sym_add_n = sym_add_n + 1 
                        DO j = 1, 4 
                        sym_add (1, j, sym_add_n) = werte (j) 
                        sym_add (2, j, sym_add_n) = werte (j + 4) 
                        sym_add (3, j, sym_add_n) = werte (j + 8) 
                        ENDDO 
                        IF (ianz.eq.13) then 
                           sym_add_power (sym_add_n) = nint (werte ( &
                           13) )                                     
                        ELSE 
                           sym_add_power (sym_add_n) = 1 
                        ENDIF 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
            ELSE 
               ier_num = - 62 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
!                                                                       
         ELSEIF (str_comp (befehl, 'atoms', 2, lbef, 5) ) then 
            CONTINUE 
         ELSE 
            ier_num = - 89 
            ier_typ = ER_APPL 
         ENDIF 
         IF (ier_num.ne.0) then 
            RETURN 
         ENDIF 
         ENDDO 
!                                                                       
         CALL no_error 
!                                                                       
!     --Determine space group number                                    
!                                                                       
         werte (1) = spcgr_para 
         CALL spcgr_no (spcgr_ianz, maxw, werte) 
      ELSE 
!                                                                       
!     Read old header                                                   
!                                                                       
         ier_num = - 47 
         ier_typ = ER_APPL 
         READ (ist, 2010, end = 999, err = 999) line 
         lp = len_str (line) 
         CALL get_params (line, ianz, cpara, lpara, maxw, lp) 
         cr_spcgr = cpara (1) 
         ianz = ianz - 1 
         IF (ianz.eq.1) then 
            cpara (1) = cpara (2) 
            lpara (1) = lpara (2) 
            CALL ber_params (ianz, cpara, lpara, werte, maxw) 
         ENDIF 
         IF (ier_num.eq.0) then 
            ier_num = - 48 
            ier_typ = ER_APPL 
            READ (ist, *, end = 999, err = 999) (cr_a0 (i), i = 1, 3),  &
            (cr_win (i), i = 1, 3)                                      
            CALL no_error 
            CALL spcgr_no (ianz, maxw, werte) 
         ENDIF 
      ENDIF 
!                                                                       
  999 CONTINUE 
!
!                                                                       
 2000 FORMAT    (a) 
 2010 FORMAT    (a16) 
      END SUBROUTINE stru_readheader                
!********************************************************************** 
      SUBROUTINE struc_read_atoms (NMAX, MAXSCAT, cr_natoms, cr_nscat,  &
      cr_dw, cr_at_lis, cr_pos, cr_iscat, cr_prop, cr_dim, as_natoms,   &
      as_at_lis, as_dw, as_pos, as_iscat, as_prop)                      
!-                                                                      
!           This subroutine reads the list of atoms into the            
!       crystal array                                                   
!+                                                                      
      USE allocate_appl_mod , ONLY: alloc_molecule
      USE molecule_mod 
      USE spcgr_apply
      IMPLICIT none 
!                                                                       
      INTEGER NMAX 
      INTEGER MAXSCAT 
!                                                                       
!
      INTEGER,                       INTENT(INOUT)  :: cr_natoms
      INTEGER, DIMENSION(1:NMAX),    INTENT(INOUT)  :: cr_iscat
      INTEGER, DIMENSION(1:NMAX),    INTENT(INOUT)  :: cr_prop
      REAL   , DIMENSION(1:3,1:NMAX),INTENT(INOUT)  :: cr_pos
!                                                                       
      INTEGER ist, maxw 
      PARAMETER (ist = 7, maxw = 5) 
!                                                                       
      CHARACTER(4) cr_at_lis (0:MAXSCAT) 
      CHARACTER(4) as_at_lis (0:MAXSCAT) 
!                                                                       
      INTEGER cr_nscat 
      INTEGER as_natoms 
      INTEGER as_iscat (MAXSCAT) 
      INTEGER as_prop (MAXSCAT) 
!                                                                       
      REAL cr_a0 (3) 
      REAL cr_win (3) 
      REAL cr_dim (3, 2) 
      REAL cr_dw (0:MAXSCAT) 
      REAL as_pos (3, MAXSCAT) 
      REAL as_dw (0:MAXSCAT) 
!                                                                       
      CHARACTER(10) befehl 
      CHARACTER(80) cpara (maxw) 
      CHARACTER(1024) line, zeile 
      INTEGER lpara (maxw) 
      INTEGER ianz 
      INTEGER i, j, ibl, lbef 
      INTEGER lline 
      INTEGER          :: n_gene
      INTEGER          :: n_symm
      INTEGER          :: n_mole
      INTEGER          :: n_type
      INTEGER          :: n_atom
      LOGICAL          :: need_alloc = .false.
      REAL, PARAMETER  :: eps = 1e-6
      REAL werte (maxw), dw1 
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
!                                                                       
 1000 CONTINUE 
      ier_num = - 49 
      ier_typ = ER_APPL 
      line = ' ' 
      READ (ist, 2000, end = 2, err = 999) line 
      lline = len_str (line) 
      IF (line.ne.' '.and.line (1:1) .ne.'#'.and.line.ne.char (13) )    &
      then                                                              
         ibl = index (line (1:lline) , ' ') + 1 
         lbef = 10 
         befehl = ' ' 
         ibl = index (line (1:lline) , ' ') 
         IF (ibl.eq.0) then 
            ibl = lline+1 
         ENDIF 
         lbef = min (ibl - 1, lbef) 
         befehl = line (1:lbef) 
         IF (str_comp (befehl, 'molecule', 4, lbef, 8) .or.str_comp (   &
         befehl, 'domain', 4, lbef, 6) .or.str_comp (befehl, 'object',  &
         4, lbef, 6) ) then                                             
!                                                                       
!     ------Start/End of a molecule                                     
!                                                                       
            CALL no_error 
            IF (ibl.le.lline) then 
               zeile = line (ibl:lline) 
               i = lline-ibl + 1 
            ELSE 
               zeile = ' ' 
               i = 0 
            ENDIF 
            CALL struc_mole_header (zeile, i, .false.) 
            IF (ier_num.ne.0) return 
         ELSE 
!                                                                       
!        --Make sure we have enough space for molecule atoms
!                                                                       
            need_alloc = .false.
            n_gene = MAX( 1, MOLE_MAX_GENE)
            n_symm = MAX( 1, MOLE_MAX_SYMM)
            n_mole =         MOLE_MAX_MOLE
            n_type =         MOLE_MAX_TYPE
            n_atom =         MOLE_MAX_ATOM
            IF ((mole_off(mole_num_mole)+mole_len(mole_num_mole)) >= MOLE_MAX_ATOM ) THEN
               n_atom = (mole_off(mole_num_mole)+mole_len(mole_num_mole)) + 200
               need_alloc = .true.
            ENDIF
            IF ( need_alloc ) THEN
               call alloc_molecule(n_gene, n_symm, n_mole, n_type, n_atom)
            ENDIF
            CALL read_atom_line (line, ibl, lline, as_natoms, maxw,     &
            werte)                                                      
            IF (ier_num.ne.0.and.ier_num.ne. - 49) then 
               GOTO 999 
            ENDIF 
            IF (cr_natoms.eq.nmax) then 
!                                                                       
!     --------Too many atoms in the structure file                      
!                                                                       
               ier_num = - 10 
               ier_typ = ER_APPL 
               RETURN 
            ENDIF 
            cr_natoms = cr_natoms + 1 
            i = cr_natoms 
            DO j = 1, 3 
            cr_pos (j, i) = werte (j) 
            cr_dim (j, 1) = amin1 (cr_dim (j, 1), cr_pos (j, i) ) 
            cr_dim (j, 2) = amax1 (cr_dim (j, 2), cr_pos (j, i) ) 
            ENDDO 
            dw1 = werte (4) 
            cr_prop (i) = nint (werte (5) ) 
      IF (line (1:4) .ne.'    ') then 
               ibl = ibl - 1 
               CALL do_cap (line (1:ibl) ) 
               DO j = 0, cr_nscat 
                  IF (line (1:ibl) .eq.cr_at_lis (j) .and. &
                      ABS(dw1-cr_dw(j)).lt.eps               ) THEN
                     cr_iscat (i) = j 
                     GOTO 11 
                  ENDIF 
               ENDDO 
               IF (cr_nscat.eq.MAXSCAT) then 
!                                                                       
!     --------  Too many atom types in the structure file               
!                                                                       
                  ier_num = -72 
                  ier_typ = ER_APPL 
                  RETURN 
               ENDIF 
               cr_nscat = cr_nscat + 1 
               cr_iscat (i) = cr_nscat 
               cr_at_lis (cr_nscat) = line (1:ibl) 
               cr_dw (cr_nscat) = dw1 
!                                                                       
               IF (0.0.le.cr_pos (1, i) .and.cr_pos (1, i)              &
               .lt.1.and.0.0.le.cr_pos (2, i) .and.cr_pos (2, i)        &
               .lt.1.and.0.0.le.cr_pos (3, i) .and.cr_pos (3, i) .lt.1) &
               then                                                     
                  as_natoms = as_natoms + 1 
                  as_at_lis (cr_nscat) = cr_at_lis (cr_nscat) 
                  as_iscat (as_natoms) = cr_iscat (i) 
                  as_dw (as_natoms) = cr_dw (cr_nscat) 
                  DO j = 1, 3 
                  as_pos (j, as_natoms) = cr_pos (j, i) 
                  ENDDO 
                  as_prop (as_natoms) = cr_prop (i) 
               ENDIF 
   11          CONTINUE 
!                                                                       
!     --------If we are reading a molecule insert atom into current     
!                                                                       
               IF (mole_l_on) then 
                  CALL mole_insert_current (cr_natoms, mole_num_curr) 
                  IF (ier_num.lt.0.and.ier_num.ne. - 49) then 
                     GOTO 999 
                  ENDIF 
               ENDIF 
            ENDIF 
         ENDIF 
      ENDIF 
      GOTO 1000 
!                                                                       
    2 CONTINUE 
      IF (ier_num.eq. - 49) then 
         CALL no_error 
      ENDIF 
!
!                                                                       
  999 CONTINUE 
      CLOSE (ist) 
!                                                                       
 2000 FORMAT    (a) 
      END SUBROUTINE struc_read_atoms               
!********************************************************************** 
!********************************************************************** 
      SUBROUTINE spcgr_no (ianz, maxw, werte) 
!-                                                                      
!     Interprets the space group symbol. Returns the space group no.    
!+                                                                      
      USE config_mod 
      USE crystal_mod 
      USE spcgr_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      CHARACTER(1024) cpara 
      INTEGER lpara 
      INTEGER ianz, maxw, ii, i 
      REAL werte (maxw) 
      REAL rpara 
!                                                                       
      INTEGER len_str 
!                                                                       
      CALL no_error 
      ii = 1 
      IF (ianz.eq.1) then 
         ii = nint (werte (1) ) 
      ENDIF 
!                                                                       
!     Distinguish between trigonal and rhombohedral settings            
!                                                                       
      IF (cr_spcgr (1:1) .eq.'R') then 
         IF (cr_a0 (1) .eq.cr_a0 (2) .and.cr_win (1) .eq.90..and.cr_win &
         (2) .eq.90.0.and.cr_win (3) .eq.120.0) then                    
            ii = 1 
         ELSEIF (cr_a0 (1) .eq.cr_a0 (2) .and.cr_a0 (1) .eq.cr_a0 (3)   &
         .and.cr_win (1) .eq.cr_win (2) .and.cr_win (1) .eq.cr_win (3) )&
         then                                                           
            ii = 2 
         ELSE 
            ier_num = - 7 
            ier_typ = ER_APPL 
         ENDIF 
      ENDIF 
!                                                                       
      IF (ii.lt.1.or.2.lt.ii) then 
         ier_num = - 7 
         ier_typ = ER_APPL 
         RETURN 
      ENDIF 
!                                                                       
      cr_spcgrno = 0 
      cr_syst = 0 
      ier_num = - 7 
      ier_typ = ER_APPL 
!                                                                       
      DO i = 1, SPCGR_MAX 
      IF (cr_spcgr.eq.spcgr_name (i) ) then 
         cr_spcgrno = spcgr_num (i, ii) 
         cr_syst = spcgr_syst (cr_spcgrno) 
         CALL no_error 
         GOTO 10 
      ENDIF 
      ENDDO 
!                                                                       
      CALL no_error 
      cpara = cr_spcgr 
      lpara = len_str (cpara) 
      CALL ber_params (1, cpara, lpara, rpara, 1) 
      IF (ier_num.eq.0) then 
         cr_spcgrno = nint (rpara) 
         cr_syst = spcgr_syst (cr_spcgrno) 
         cr_spcgr = spcgr_name (cr_spcgrno) 
      ELSE 
         ier_num = - 7 
         ier_typ = ER_APPL 
      ENDIF 
!                                                                       
   10 CONTINUE 
!                                                                       
      IF (ier_num.eq.0) then 
         ier_num = - 14 
         ier_typ = ER_APPL 
         IF (cr_syst.eq.1) then 
            CALL no_error 
         ELSEIF (cr_syst.eq.2) then 
            IF (cr_win (1) .eq.90.0.and.cr_win (3) .eq.90.0) then 
               CALL no_error 
            ENDIF 
         ELSEIF (cr_syst.eq.3) then 
            IF (cr_win (1) .eq.90.0.and.cr_win (2) .eq.90.0) then 
               CALL no_error 
            ENDIF 
         ELSEIF (cr_syst.eq.4) then 
            IF (cr_win (1) .eq.90.0.and.cr_win (2) .eq.90.0.and.cr_win (&
            3) .eq.90.0) then                                           
               CALL no_error 
            ENDIF 
         ELSEIF (cr_syst.eq.5) then 
            IF (cr_a0 (1) .eq.cr_a0 (2) .and.cr_win (1)                 &
            .eq.90.0.and.cr_win (2) .eq.90.0.and.cr_win (3) .eq.90.0)   &
            then                                                        
               CALL no_error 
            ENDIF 
         ELSEIF (cr_syst.eq.6.or.cr_syst.eq.8) then 
            IF (cr_a0 (1) .eq.cr_a0 (2) .and.cr_win (1)                 &
            .eq.90.0.and.cr_win (2) .eq.90.0.and.cr_win (3) .eq.120.0)  &
            then                                                        
               CALL no_error 
            ENDIF 
         ELSEIF (cr_syst.eq.7) then 
            IF (cr_a0 (1) .eq.cr_a0 (2) .and.cr_a0 (1) .eq.cr_a0 (3)    &
            .and.cr_win (1) .eq.cr_win (2) .and.cr_win (2) .eq.cr_win ( &
            3) ) then                                                   
               CALL no_error 
            ENDIF 
         ELSEIF (cr_syst.eq.9) then 
            IF (cr_a0 (1) .eq.cr_a0 (2) .and.cr_a0 (1) .eq.cr_a0 (3)    &
            .and.cr_win (1) .eq.90.0.and.cr_win (2) .eq.90.0.and.cr_win &
            (3) .eq.90.0) then                                          
               CALL no_error 
            ENDIF 
         ENDIF 
      ENDIF 
      END SUBROUTINE spcgr_no                       
!********************************************************************** 
!********************************************************************** 
      SUBROUTINE rese_cr 
!                                                                       
!     resets the crystal structure to empty                             
!                                                                       
      USE config_mod 
      USE crystal_mod 
      USE gen_add_mod 
      USE molecule_mod 
      USE sym_add_mod 
      USE save_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER i 
!                                                                       
      cr_natoms = 0 
      as_natoms = 0 
      cr_ncatoms = 1 
      cr_nscat = 0 
      cr_icc       = 1
      cr_cartesian = .false. 
      cr_scat_int (0) = .true. 
      cr_delf_int (0) = .true. 
      cr_scat_equ (0) = .false. 
      cr_sel_prop (0) = 0 
      cr_sel_prop (1) = 0 
      DO i = 1, maxscat 
      cr_at_lis (i) = ' ' 
      cr_at_equ (i) = ' ' 
      as_at_lis (i) = ' ' 
      cr_scat_int (i) = .true. 
      cr_delf_int (i) = .true. 
      cr_scat_equ (i) = .false. 
      ENDDO 
      DO i = 1, 3 
      cr_dim (i, 1) = 0.0 
      cr_dim (i, 2) = 0.0 
      ENDDO 
!                                                                       
      DO i = 0, MOLE_MAX_MOLE 
      mole_len (i) = 0 
      mole_off (i) = 0 
      ENDDO 
      mole_l_on = .false. 
      mole_num_mole = 0 
      mole_num_curr = 0 
      mole_num_act = 0 
      mole_num_type = 0 
      mole_gene_n = 0 
      mole_symm_n = 0 
!                                                                       
      sym_add_n = 0 
      gen_add_n = 0 
!                                                                       
      sav_r_ncell = .false. 
!                                                                       
      END SUBROUTINE rese_cr                        
!*****7**************************************************************** 
      SUBROUTINE do_import (zeile, lp) 
!-                                                                      
!     imports a file into discus.cell format                            
!+                                                                      
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (MAXW = 5) 
!                                                                       
      CHARACTER ( * ) zeile 
      INTEGER lp 
!                                                                       
      CHARACTER(1024) cpara (MAXW) 
      INTEGER lpara (MAXW) 
      INTEGER ianz 
!                                                                       
      LOGICAL str_comp 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, MAXW, lp) 
      IF (ier_num.ne.0) then 
         RETURN 
      ENDIF 
!                                                                       
      IF (ianz.ge.1) then 
         IF (str_comp (cpara (1) , 'shelx', 2, lpara (1) , 5) ) then 
            IF (ianz.eq.2) then 
               CALL del_params (1, ianz, cpara, lpara, maxw) 
               IF (ier_num.ne.0) return 
               CALL ins2discus (ianz, cpara, lpara, MAXW) 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSEIF (str_comp (cpara (1) , 'cmaker', 2, lpara (1) , 6) ) then 
            IF (ianz.eq.2) then 
               CALL del_params (1, ianz, cpara, lpara, maxw) 
               IF (ier_num.ne.0) return 
               CALL cmaker2discus (ianz, cpara, lpara, MAXW) 
            ELSE 
               ier_num = - 6 
               ier_typ = ER_COMM 
            ENDIF 
         ELSE 
            ier_num = - 86 
            ier_typ = ER_APPL 
         ENDIF 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
!                                                                       
      END SUBROUTINE do_import                      
!*****7**************************************************************** 
      SUBROUTINE ins2discus (ianz, cpara, lpara, MAXW) 
!-                                                                      
!     converts a SHELXL "ins" or "res" file to DISCUS                   
!+                                                                      
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER                             , INTENT(IN)    :: ianz 
      INTEGER                             , INTENT(IN)    :: MAXW 
      CHARACTER (LEN= * ), DIMENSION(MAXW), INTENT(INOUT) :: cpara ! (MAXW) 
      INTEGER            , DIMENSION(MAXW), INTENT(INOUT) :: lpara ! (MAXW) 
!                                                                       
      INTEGER NFV 
      PARAMETER (NFV = 50) 
!                                                                       
      REAL werte (3) 
!                                                                       
      INTEGER shelx_num 
      PARAMETER (shelx_num = 62) 
      CHARACTER(4) shelx_ign (1:shelx_num) 
      CHARACTER(2) c_atom (20) 
      CHARACTER(4) command 
      CHARACTER(80) line1 
      CHARACTER(80) line2 
      CHARACTER(160) line 
      CHARACTER(1024) infile 
      CHARACTER(1024) ofile 
      INTEGER ird, iwr 
      INTEGER i, j, ii, jj 
      INTEGER ix, iy, iz, idot 
      INTEGER ntyp , ntyp_prev
      INTEGER length, length1, length2, lp 
      INTEGER icont 
      INTEGER centering 
      INTEGER ityp 
      INTEGER ifv 
      LOGICAL lread 
      LOGICAL lwrite 
      LOGICAL lmole, lmole_wr 
      LOGICAL lcontinue 
      REAL z, latt (6) 
      REAL xyz (3) 
      REAL sof 
      REAL uiso, uij (6) 
      REAL gen (3, 4) 
      REAL fv (NFV) 
!
      INTEGER                               :: iianz      ! Dummy number of parameters
      INTEGER, PARAMETER                    :: MAXP  = 11 ! Dummy number of parameters
      CHARACTER (LEN=1024), DIMENSION(MAXP) :: ccpara     ! Parameter needed for SFAC analysis
      INTEGER             , DIMENSION(MAXP) :: llpara
      REAL                , DIMENSION(MAXP) :: wwerte
!                                                                       
      INTEGER len_str 
!                                                                       
      DATA shelx_ign / 'ACTA', 'AFIX', 'ANIS', 'BASF', 'BIND', 'BLOC',  &
      'BOND', 'BUMP', 'CGLS', 'CHIV', 'CONF', 'CONN', 'DAMP', 'DANG',   &
      'DEFS', 'DELU', 'DFIX', 'DISP', 'EADP', 'EQIV', 'EXTI', 'EXYZ',   &
      'FEND', 'FLAT', 'FMAP', 'FRAG', 'FREE', 'GRID', 'HFIX', 'HOPE',   &
      'HTAB', 'ISOR', 'L.S.', 'LAUE', 'LIST', 'MERG', 'MORE', 'MOVE',   &
      'MPLA', 'NCSY', 'OMIT', 'PART', 'PLAN', 'REM ', 'RESI', 'RTAB',   &
      'SADI', 'SAME', 'SHEL', 'SIMU', 'SIZE', 'SPEC', 'SUMP', 'STIR',   &
      'SWAT', 'TEMP', 'TIME', 'TWIN', 'UNIT', 'WGHT', 'WPDB', 'ZERR' /  
!                                                                       
      DO i = 1, NFV 
         fv (i) = 0.0 
      ENDDO 
!                                                                       
      lmole    = .false. 
      lmole_wr = .true. 
!
      ntyp      = 0
      ntyp_prev = 0
!                                                                       
      CALL do_build_name (ianz, cpara, lpara, werte, maxw, 1) 
      IF (ier_num.ne.0) then 
         RETURN 
      ENDIF 
      infile = cpara (1) 
      i = index (infile, '.') 
      IF (i.eq.0) then 
         infile = cpara (1) (1:lpara (1) ) //'.ins' 
         ofile = cpara (1) (1:lpara (1) ) //'.cell' 
      ELSE 
         ofile = cpara (1) (1:i) //'cell' 
      ENDIF 
      lread = .true. 
      lwrite = .false. 
      ird = 34 
      iwr = 35 
      CALL oeffne (ird, infile, 'old', lread) 
      IF (ier_num.ne.0) then 
         RETURN 
      ENDIF 
      CALL oeffne (iwr, ofile, 'unknown', lwrite) 
      IF (ier_num.ne.0) then 
         RETURN 
      ENDIF 
!                                                                       
      lcontinue = .false. 
      READ (ird, 1000, end = 900, err = 900) line1 
      length1 = len_str (line1) 
      IF (length1.gt.0) then 
         icont = index (line1, '=') 
         IF (icont.gt.0) then 
            READ (ird, 1000, end = 900, err = 900) line2 
            length2 = len_str (line2) 
            line = line1 (1:icont - 1) //' '//line2 (1:length2) 
         ELSE 
            line = line1 
         ENDIF 
      ELSE 
         line = line1 
      ENDIF 
      length = len_str (line) 
      IF (length.gt.0) then 
         command = line (1:4) 
      ELSE 
      command = '    ' 
      ENDIF 
      DO i = 1, shelx_num 
      lcontinue = lcontinue.or.command.eq.shelx_ign (i) 
      ENDDO 
!                                                                       
      DO while (command.ne.'FVAR'.and.command.ne.'MOLE') 
      IF (lcontinue) then 
         CONTINUE 
      ELSEIF (command.eq.'TITL') then 
         WRITE (iwr, 2000) line (6:length) 
         WRITE (iwr, 2100) 
      ELSEIF (command.eq.'CELL') then 
         READ (line (6:length), * ) z, latt 
         WRITE (iwr, 2200) latt 
      ELSEIF (command.eq.'LATT') then 
         READ (line (6:length), * ) centering 
         IF (abs (centering) .eq.1) then 
            CONTINUE 
         ELSEIF (abs (centering) .eq.2) then 
            WRITE (iwr, 2320) 
         ELSEIF (abs (centering) .eq.3) then 
            WRITE (iwr, 2330) 
         ELSEIF (abs (centering) .eq.4) then 
            WRITE (iwr, 2340) 
            WRITE (iwr, 2341) 
         ELSEIF (abs (centering) .eq.5) then 
            WRITE (iwr, 2350) 
         ELSEIF (abs (centering) .eq.6) then 
            WRITE (iwr, 2360) 
         ELSEIF (abs (centering) .eq.7) then 
            WRITE (iwr, 2370) 
         ENDIF 
         IF (centering.gt.0) then 
            WRITE (iwr, 2400) 
         ENDIF 
      ELSEIF (command.eq.'SFAC') then 
         j = 5 
         atom_search: DO while (j.lt.length) 
            j = j + 1 
            DO while (j.lt.length.and.line (j:j) .eq.' ') 
               j = j + 1 
            ENDDO 
            IF (j.le.length) then 
               ntyp = ntyp + 1 
               c_atom (ntyp) = ' ' 
               i = 0 
               DO while (j.le.length.and.line (j:j) .ne.' ') 
                  i = i + 1 
                  c_atom (ntyp) (i:i) = line (j:j) 
                  j = j + 1 
               ENDDO 
               IF(ntyp == ntyp_prev + 2) THEN
!
!                 This is the second parameter, test if this is a numerical
!                 value. If so only the first parameter is an atom name rest is
!                 the numerical form factor, which we ignore
                  ccpara(1) = c_atom(ntyp)
                  llpara(1) = i
                  iianz     = 1
                  CALL ber_params (iianz, ccpara, llpara, wwerte, MAXP) 
                  IF(ier_num==0) THEN
                     ntyp = ntyp - 1
                     EXIT atom_search
                  ENDIF
                  ier_num = 0
                  ier_typ = ER_NONE
               ENDIF
            ENDIF 
         ENDDO atom_search
!        WRITE (iwr, 2500) (c_atom (i) , ',', i = 1, ntyp - 1) , c_atom &
!        (ntyp)                                                         
      ELSEIF (command.eq.'SYMM') then 
         lp = length - 5 
         CALL get_params (line (6:length), ianz, cpara, lpara, maxw, lp) 
         IF (ianz.eq.3) then 
            DO i = 1, 3 
            DO jj = 1, 4 
            gen (i, jj) = 0.0 
            ENDDO 
            ix = index (cpara (i) , 'X') 
            IF (ix.gt.0) then 
               gen (i, 1) = 1.0 
               IF (ix.gt.1.and.cpara (i) (ix - 1:ix - 1) .eq.'-') then 
                  gen (i, 1) = - 1.0 
                  cpara (i) (ix - 1:ix - 1) = ' ' 
               ELSEIF (ix.gt.1.and.cpara (i) (ix - 1:ix - 1) .eq.'+')   &
               then                                                     
                  gen (i, 1) = 1.0 
                  cpara (i) (ix - 1:ix - 1) = ' ' 
               ENDIF 
               cpara (i) (ix:ix) = ' ' 
            ENDIF 
            iy = index (cpara (i) , 'Y') 
            IF (iy.gt.0) then 
               gen (i, 2) = 1.0 
               IF (iy.gt.1.and.cpara (i) (iy - 1:iy - 1) .eq.'-') then 
                  gen (i, 2) = - 1.0 
                  cpara (i) (iy - 1:iy - 1) = ' ' 
               ELSEIF (iy.gt.1.and.cpara (i) (iy - 1:iy - 1) .eq.'+')   &
               then                                                     
                  gen (i, 2) = 1.0 
                  cpara (i) (iy - 1:iy - 1) = ' ' 
               ENDIF 
               cpara (i) (iy:iy) = ' ' 
            ENDIF 
            iz = index (cpara (i) , 'Z') 
            IF (iz.gt.0) then 
               gen (i, 3) = 1.0 
               IF (iz.gt.1.and.cpara (i) (iz - 1:iz - 1) .eq.'-') then 
                  gen (i, 3) = - 1.0 
                  cpara (i) (iz - 1:iz - 1) = ' ' 
               ELSEIF (iz.gt.1.and.cpara (i) (iz - 1:iz - 1) .eq.'+')   &
               then                                                     
                  gen (i, 3) = 1.0 
                  cpara (i) (iz - 1:iz - 1) = ' ' 
               ENDIF 
               cpara (i) (iz:iz) = ' ' 
            ENDIF 
            ENDDO 
            DO i = 1, 3 
            idot = index (cpara (i) , '.') 
            IF (idot.eq.0) then 
               cpara (i) (lpara (i) + 1:lpara (i) + 1) = '.' 
               cpara (i) (lpara (i) + 2:lpara (i) + 2) = '0' 
               lpara (i) = lpara (i) + 2 
            ENDIF 
            CALL rem_bl (cpara (i), lpara (i) ) 
            ENDDO 
            CALL ber_params (ianz, cpara, lpara, werte, maxw) 
            gen (1, 4) = werte (1) 
            gen (2, 4) = werte (2) 
            gen (3, 4) = werte (3) 
            WRITE (iwr, 2600) ( (gen (i, j), j = 1, 4), i = 1, 3) 
         ENDIF 
      ENDIF 
!                                                                       
      lcontinue = .false. 
      READ (ird, 1000, end = 900, err = 900) line1 
      length1 = len_str (line1) 
      IF (length1.gt.0) then 
         icont = index (line1, '=') 
         IF (icont.gt.0) then 
            READ (ird, 1000, end = 900, err = 900) line2 
            length2 = len_str (line2) 
            line = line1 (1:icont - 1) //' '//line2 (1:length2) 
         ELSE 
            line = line1 
         ENDIF 
      ELSE 
         line = line1 
      ENDIF 
      length = len_str (line) 
      IF (length.gt.0) then 
         command = line (1:4) 
      ELSE 
      command = '    ' 
      ENDIF 
      DO i = 1, shelx_num 
      lcontinue = lcontinue.or.command.eq.shelx_ign (i) 
      ENDDO 
      ENDDO 
!                                                                       
      WRITE (iwr, 3000) 
!                                                                       
      DO while (command.ne.'HKLF') 
      IF (lcontinue) then 
         CONTINUE 
      ELSEIF (command.eq.'FVAR') then 
         READ (line (6:length), *, end = 800) (fv (i), i = 1, NFV) 
  800    CONTINUE 
      ELSEIF (command.eq.'MOLE') then 
         IF (lmole) then 
            WRITE (iwr, 4000) 'molecule end' 
            lmole_wr = .true. 
         ELSE 
            lmole = .true. 
            lmole_wr = .true. 
         ENDIF 
         CONTINUE 
      ELSE 
         IF (lmole.and.lmole_wr) then 
            WRITE (iwr, 4000) 'molecule' 
            lmole_wr = .false. 
         ENDIF 
!
!        This is an atom, get the parameters from the input line
!
         iianz  = 0
         j      = 5 
         ccpara = ' '
         llpara = 0
         atom_para: DO while (j.lt.length) 
            j = j + 1 
            DO while (j.lt.length.and.line (j:j) .eq.' ') 
               j = j + 1 
            ENDDO 
            IF (j.le.length) then 
               iianz = iianz + 1 
               ccpara (iianz) = ' ' 
               i = 0 
               DO while (j.le.length.and.line (j:j) .ne.' ') 
                  i = i + 1 
                  ccpara (iianz) (i:i) = line (j:j) 
                  j = j + 1 
               ENDDO 
               llpara(iianz) = i
            ENDIF 
         ENDDO atom_para
         READ (ccpara(1)(1:llpara(1)),*) ityp
         READ (ccpara(2)(1:llpara(2)),*) xyz(1)
         READ (ccpara(3)(1:llpara(3)),*) xyz(2)
         READ (ccpara(4)(1:llpara(4)),*) xyz(3)
         DO i=1,iianz - 5
            READ (ccpara(5+i)(1:llpara(5+i)),*) uij(i)
         ENDDO
!        READ (line (6:length), *, end = 850) ityp, xyz, sof, (uij (i), &
!        i = 1, 6)                                                      
! 850    CONTINUE 
         IF (iianz == 6) then 
            uiso = uij (1) 
         ELSE 
            uiso = (uij (1) + uij (2) + uij (3) ) / 3. 
         ENDIF 
         DO i = 1, 3 
         ifv = nint (xyz (i) / 10.) 
         IF (ifv.eq.1) then 
            xyz (i) = xyz (i) - 10. 
         ELSEIF (ifv.gt.1) then 
            xyz (i) = (xyz (i) - ifv * 10) * fv (ifv) 
         ELSEIF (ifv.lt. - 1) then 
            xyz (i) = (abs (xyz (i) ) + ifv * 10) * (1. - fv (iabs (ifv)&
            ) )                                                         
         ENDIF 
         ENDDO 
!         write(iwr,3100) c_atom(ityp),xyz,float(ityp)                  
         WRITE (iwr, 3100) c_atom (ityp), xyz, uiso 
      ENDIF 
!                                                                       
      lcontinue = .false. 
      READ (ird, 1000, end = 900, err = 900) line1 
      length1 = len_str (line1) 
      IF (length1.gt.0) then 
         icont = index (line1, '=') 
         IF (icont.gt.0) then 
            READ (ird, 1000, end = 900, err = 900) line2 
            length2 = len_str (line2) 
            line = line1 (1:icont - 1) //' '//line2 (1:length2) 
         ELSE 
            line = line1 
         ENDIF 
      ELSE 
         line = line1 
      ENDIF 
      length = len_str (line) 
      IF (length.gt.0) then 
         command = line (1:4) 
      ELSE 
      command = '    ' 
      ENDIF 
      DO i = 1, shelx_num 
      lcontinue = lcontinue.or.command.eq.shelx_ign (i) 
      ENDDO 
      ENDDO 
!                                                                       
  900 CONTINUE 
!                                                                       
      IF (lmole) then 
         WRITE (iwr, 4000) 'molecule end' 
      ENDIF 
!                                                                       
      CLOSE (ird) 
      CLOSE (iwr) 
!                                                                       
 1000 FORMAT    (a) 
 2000 FORMAT    ('title ',a) 
 2100 FORMAT    ('spcgr P1') 
 2200 FORMAT    ('cell ',5(2x,f9.4,','),2x,f9.4) 
 2320 FORMAT    ('gener  1.0, 0.0, 0.0, 0.5,',                          &
     &                     '    0.0, 1.0, 0.0, 0.5,',                   &
     &                     '    0.0, 0.0, 1.0, 0.5,  1')                
 2330 FORMAT    ('gener  1.0, 0.0, 0.0, 0.66666667,',                   &
     &                     '    0.0, 1.0, 0.0, 0.33333333,',            &
     &                     '    0.0, 0.0, 1.0, 0.33333333,   2')        
 2340 FORMAT    ('gener  1.0, 0.0, 0.0, 0.0,',                          &
     &                     '    0.0, 1.0, 0.0, 0.5,',                   &
     &                     '    0.0, 0.0, 1.0, 0.5,   1')               
 2341 FORMAT    ('gener  1.0, 0.0, 0.0, 0.5,',                          &
     &                     '    0.0, 1.0, 0.0, 0.0,',                   &
     &                     '    0.0, 0.0, 1.0, 0.5,   1')               
 2350 FORMAT    ('gener  1.0, 0.0, 0.0, 0.0,',                          &
     &                     '    0.0, 1.0, 0.0, 0.5,',                   &
     &                     '    0.0, 0.0, 1.0, 0.5,   1')               
 2360 FORMAT    ('gener  1.0, 0.0, 0.0, 0.5,',                          &
     &                     '    0.0, 1.0, 0.0, 0.0,',                   &
     &                     '    0.0, 0.0, 1.0, 0.5,   1')               
 2370 FORMAT    ('gener  1.0, 0.0, 0.0, 0.5,',                          &
     &                     '    0.0, 1.0, 0.0, 0.5,',                   &
     &                     '    0.0, 0.0, 1.0, 0.0,  1')                
 2400 FORMAT    ('gener -1.0, 0.0, 0.0, 0.0,',                          &
     &                     '    0.0,-1.0, 0.0, 0.0,',                   &
     &                     '    0.0, 0.0,-1.0, 0.0,  1')                
 2500 FORMAT    ('scat ',20(a4,a1)) 
 2600 FORMAT    ('gener',3(2X,4(1x,f12.8,',')),' 1.') 
!                                                                       
 3000 FORMAT    ('atoms') 
 3100 FORMAT    (a2,2x,4(2x,f9.5)) 
!                                                                       
 4000 FORMAT    (a) 
!                                                                       
      END SUBROUTINE ins2discus                     
!*****7**************************************************************** 
      SUBROUTINE cmaker2discus (ianz, cpara, lpara, MAXW) 
!-                                                                      
!     converts a CrystalMaker "xyz" file to DISCUS                   
!+                                                                      
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER          , INTENT(IN)                    :: ianz 
      INTEGER          , INTENT(IN)                    :: MAXW 
      CHARACTER (LEN=*), DIMENSION(1:MAXW), INTENT(IN) :: cpara
      INTEGER          , DIMENSION(1:MAXW), INTENT(IN) :: lpara
!                                                                       
!                                                                       
      REAL   , DIMENSION(3) :: werte
!                                                                       
      CHARACTER(LEN=87)     :: line 
      CHARACTER(LEN=1024)   :: infile 
      CHARACTER(LEN=1024)   :: ofile 
      INTEGER               :: ird, iwr 
      INTEGER               :: i
      INTEGER               :: indx1, indx2
      INTEGER               :: iostatus
      INTEGER               :: natoms
      LOGICAL               :: lread
      LOGICAL               :: lwrite
      INTEGER               :: nline
      INTEGER               :: length
      REAL   , DIMENSION(6) :: latt (6) 
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp
!                                                                       
!     Create input / output file name
!
      CALL do_build_name (ianz, cpara, lpara, werte, maxw, 1) 
      IF (ier_num.ne.0) then 
         RETURN 
      ENDIF 
      infile = cpara (1) 
      i = index (infile, '.') 
      IF (i.eq.0) then 
         infile = cpara (1) (1:lpara (1) ) //'.txt' 
         ofile  = cpara (1) (1:lpara (1) ) //'.cell' 
      ELSE 
         ofile  = cpara (1) (1:i) //'cell' 
      ENDIF 
      lread  = .true. 
      lwrite = .false. 
      ird = 34 
      iwr = 35 
      CALL oeffne (ird, infile, 'old', lread) 
      IF (ier_num.ne.0) then 
         RETURN 
      ENDIF 
      CALL oeffne (iwr, ofile, 'unknown', lwrite) 
      IF (ier_num.ne.0) then 
         RETURN 
      ENDIF 
!                                                                       
      nline     = 1
header: DO
         READ (ird, 1000, iostat=iostatus) line
         IF(iostatus /= 0) THEN
            CLOSE(ird)
            CLOSE(iwr)
            ier_msg(1) = 'Error reading CrystalMaker file'
            WRITE(ier_msg(2),5000) nline
            RETURN
         ENDIF
         length = len_str (line) 
zero_o:  IF (length.gt.0) then 
cmd:        IF(str_comp(line(1:4),'Unit', 4, length, 4)) THEN
               READ (ird, 1000, iostat=iostatus) line
               nline = nline + 1
               IF(iostatus /= 0) THEN
                  CLOSE(ird)
                  CLOSE(iwr)
                  ier_msg(1) = 'Error reading CrystalMakere file'
                  WRITE(ier_msg(2),5000) nline
                  RETURN
               ENDIF
               length = len_str (line) 
               READ(line,1500), latt(1),latt(2),latt(3)
               nline = nline + 1
               IF(iostatus /= 0) THEN
                  CLOSE(ird)
                  CLOSE(iwr)
                  ier_msg(1) = 'Error reading CrystalMakere file'
                  WRITE(ier_msg(2),5000) nline
                  RETURN
               ENDIF
               length = len_str (line) 
               READ(line,1500), latt(1),latt(2),latt(3)
            ELSEIF(str_comp(line(1:4),'List', 4, length, 4)) THEN
               indx1 = INDEX(line,'all')
               indx2 = INDEX(line,'atoms')
               READ(line(indx1+3:indx2-1),*,iostat=iostatus) natoms
               IF(iostatus /= 0) THEN
                  CLOSE(ird)
                  CLOSE(iwr)
                  ier_num    = -3
                  ier_typ    = ER_IO
                  ier_msg(1) = 'Error reading CrystalMaker file'
                  WRITE(ier_msg(2),5000) nline
                  RETURN
               ENDIF
            ELSEIF(str_comp(line(1:4),'Elmt', 4, length, 4)) THEN
               EXIT header
            ENDIF cmd
         ENDIF zero_o
      ENDDO header
      READ (ird, 1000, iostat=iostatus) line
      nline = nline + 1
!
      WRITE (iwr, 2000)         ! Write 'title' line
      WRITE (iwr, 2100)         ! Write 'spcgr P1' line
      WRITE (iwr, 2200) latt    ! Write lattice constants
      WRITE (iwr, 2300)         ! Write 'atoms' line
!
      DO i=1,natoms             ! Loop over all atoms expected in input
         READ (ird, 1000, iostat=iostatus) line
         nline = nline + 1
         IF(iostatus /= 0) THEN
            CLOSE(ird)
            CLOSE(iwr)
            ier_msg(1) = 'Error reading CrystalMaker file'
            WRITE(ier_msg(2),5000) nline
            RETURN
         ENDIF
         WRITE(iwr,3000) line(1:2),line(13:24),line(25:36),line(37:48)
      ENDDO
      CLOSE(ird)
      CLOSE(iwr)
!                                                                       
 1000 FORMAT (a) 
 1500 FORMAT (7x,F10.7,8x,f10.7,9x,f10.7)
 2000 FORMAT ('title ') 
 2100 FORMAT ('spcgr P1') 
 2200 FORMAT ('cell ',5(2x,f9.4,','),2x,f9.4) 
 2300 FORMAT ('atoms') 
 3000 FORMAT (a2,4x,a13,',',a13,',',a13,',  0.100000,   1')
 5000 FORMAT ('Line ',i10)
!                                                                       
!                                                                       
      END SUBROUTINE cmaker2discus                     
!
      SUBROUTINE test_file ( strucfile, natoms, ntypes, n_mole, n_type, &
                             n_atom, init, lcell)
!
!     Determines the number of atoms and atom types in strucfile
!
      USE charact_mod
      IMPLICIT NONE
!

!
      CHARACTER (LEN=*), INTENT(IN)    :: strucfile
      INTEGER          , INTENT(INOUT) :: natoms
      INTEGER          , INTENT(INOUT) :: ntypes
      INTEGER          , INTENT(INOUT) :: n_mole 
      INTEGER          , INTENT(INOUT) :: n_type 
      INTEGER          , INTENT(INOUT) :: n_atom 
      INTEGER          , INTENT(IN)    :: init
      LOGICAL          , INTENT(IN)    :: lcell
!
      INTEGER, PARAMETER                    :: MAXW = 13 
      CHARACTER(LEN=1024), DIMENSION(MAXW)  :: cpara (MAXW) 
      INTEGER            , DIMENSION(MAXW)  :: lpara (MAXW) 
      REAL               , DIMENSION(MAXW)  :: werte (MAXW) 
!
      REAL, PARAMETER                       :: eps = 1e-6
      CHARACTER (LEN=1024)                  :: line
      CHARACTER (LEN=1024)                  :: zeile
      CHARACTER (LEN=  20)                  :: bef
      CHARACTER (LEN=   4), DIMENSION(1024), SAVE :: names
      REAL                , DIMENSION(1024), SAVE :: bvals
      INTEGER                               :: ios
      INTEGER                               :: i
      INTEGER                               :: ianz   ! no of arguments
      INTEGER                               :: laenge ! length of input line
      INTEGER                               :: lp     ! length of parameter string
      INTEGER                               :: nscattypes ! no of SCAT arguments 
      INTEGER                               :: nadptypes  ! no of ADP  arguments 
      INTEGER                               :: indxt      ! Pos of a TAB in input
      INTEGER                               :: indxb      ! Pos of a BLANK in input
      INTEGER                               :: lbef       ! Length of command string
      LOGICAL                               :: in_mole    ! Currently within a molecule
      LOGICAL                               :: l_type     ! RFound molecule type command
      LOGICAL                               :: new
      REAL                                  :: xc,yc,zc,bval
!
      INTEGER, EXTERNAL :: len_str
      LOGICAL, EXTERNAL :: str_comp
      LOGICAL           :: IS_IOSTAT_END
!
      natoms     = 0
      nscattypes = 0
      nadptypes  = 0
      IF ( init == -1 ) then
        names  = ' '
        bvals  = 0.0
        ntypes = 0
        n_mole     = 0
        n_type     = 0
        n_atom     = 0
      ENDIF
      in_mole = .false.
!
      CALL oeffne ( 99, strucfile, 'old', .true. )
      IF ( ier_num /= 0) THEN
          CLOSE ( 99 )
          RETURN
      ENDIF
header: DO
        READ (99,1000, IOSTAT=ios) line
        IF ( ios /= 0 ) THEN
           ier_num = -6
           ier_typ = ER_IO
           CLOSE ( 99 )
           RETURN
        ENDIF
        CALL do_cap (line)
        laenge = len_str(line)
        IF ( laenge .gt. 4 ) then
           zeile = line(5:laenge)
           lp    = laenge - 4
        ELSE
           zeile = ' '
           lp    = 1
        ENDIF
        IF (line(1:4) == 'SCAT' ) then 
            CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
            IF (ier_num.eq.0) then 
               DO i = 1,ianz
                   names(ntypes+i) = cpara(i)(1:lpara(i))
               ENDDO
               nscattypes = ianz
            ELSE
               ier_num = -111
               ier_typ = ER_APPL
               CLOSE(99)
               RETURN
            ENDIF
        ELSEIF (line(1:3) == 'ADP' ) then 
            CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
            IF (ier_num.eq.0) then 
               CALL ber_params (ianz, cpara, lpara, werte, maxw) 
               IF (ier_num.eq.0) then 
                  DO i = 1,ianz
                      bvals(ntypes+i) = werte(i)
                  ENDDO
                  nadptypes = ianz
               ELSE
                  ier_num = -111
                  ier_typ = ER_APPL
                  CLOSE(99)
                  RETURN
               ENDIF
            ELSE
               ier_num = -111
               ier_typ = ER_APPL
               CLOSE(99)
               RETURN
            ENDIF
        ENDIF
        IF (line(1:4) == 'ATOM') EXIT header
      ENDDO header
!
      IF (nscattypes /= nadptypes) THEN
         ier_num = -115
         ier_typ = ER_APPL
         CLOSE(99)
         RETURN
      ENDIF
!
      ntypes = MAX(ntypes,nscattypes)
!
main: DO
        READ (99,1000, IOSTAT=ios) line
        IF ( IS_IOSTAT_END(ios) ) EXIT main
        CALL do_cap (line)
        laenge = len_str(line)
!
        bef   = '    '
        indxt = INDEX (line, tab)       ! find a tabulator
        IF(indxt==0) indxt = laenge + 1
        indxb = index (line, ' ')       ! find a blank
        IF(indxb==0) indxb = laenge + 1
        indxb = MIN(indxb,indxt)
        lbef = min (indxb - 1, 5)
        bef  = line (1:lbef)
!
ismole: IF ( str_comp(line, 'MOLECULE', 3, lbef, 8) .or. &
             str_comp(line, 'DOMAIN'  , 3, lbef, 6) .or. &
             str_comp(line, 'OBJECT'  , 3, lbef, 6)     ) THEN
           IF ( indxb+1 >= laenge) THEN   ! No parameter => start
              IF ( .not. in_mole) THEN
                 in_mole = .true.
                 n_mole  = n_mole + 1
                 l_type  = .false.
              ENDIF
           ELSEIF ( str_comp(line(indxb+1: laenge), 'END',3, laenge-indxb,3)) THEN
              IF ( in_mole) THEN
                 in_mole = .false.
                 IF(.not.l_type) THEN
                    n_type = n_type + 1
                 ENDIF
                 l_type  = .false.
              ENDIF
           ELSEIF ( str_comp(line(indxb+1: laenge), 'TYPE',3, laenge-indxb,4)) THEN
              zeile  = line(indxb+1: laenge)
              laenge = laenge-indxb
              CALL get_params (zeile, ianz, cpara, lpara, maxw, laenge)
              cpara(1) = '0' 
              lpara(1) = 1
              CALL ber_params (ianz, cpara, lpara, werte, maxw)
              n_type = MAX(n_type, NINT(werte(2)))
              l_type = .true.
           ELSE
           ENDIF
        ELSE ismole
           READ (line(5:len_str(line)), *, IOSTAT = ios) xc,yc,zc,bval
isatom:    IF ( ios == 0 ) THEN
              natoms = natoms + 1
              IF ( in_mole ) THEN
                 n_atom = n_atom + 1
              ENDIF
              new = .true.
types:        DO i=1,ntypes
                 IF ( LINE(1:4) == names(i) ) THEN
                    IF ( lcell ) THEN
                       new = .false.
                       EXIT types
                    ELSEIF ( abs(abs(bval)-abs(bvals(i))) < eps ) THEN
                       new = .false.
                       EXIT types
                    ENDIF
                 ENDIF
              ENDDO types
              IF ( new ) THEN
                 ntypes = ntypes + 1
                 names(ntypes) = line(1:4)
                 bvals(ntypes) = bval
              ENDIF
           ENDIF isatom
        ENDIF ismole
      ENDDO main
!
      CLOSE (99)
!
!
1000  FORMAT(a)
!
      END SUBROUTINE test_file
!*******************************************************************************
END MODULE structur
