MODULE domain_menu
!
CONTAINS
!*****7*****************************************************************
!                                                                       
SUBROUTINE do_domain (line, lp) 
!-                                                                      
!           This subroutine reads a domain from a file and replaces the 
!     corresponding part of the structure.                              
!     This is the new versio of the microdomain level.                  
!-                                                                      
      USE config_mod 
      USE allocate_appl_mod
      USE crystal_mod 
      USE domain_mod 
      USE micro_mod 
      USE domaindis_mod 
      USE show_menu
!
      USE doact_mod 
      USE errlist_mod 
      USE learn_mod 
      USE macro_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 9) 
!                                                                       
      CHARACTER ( * ) line 
      CHARACTER(5) befehl 
      CHARACTER(50) prom 
      CHARACTER(1024) zeile, cpara (maxw) 
      INTEGER lpara (maxw), lp 
      INTEGER i, j, ianz, laenge, lbef 
      INTEGER indxg 
      INTEGER, SAVE    :: n_clu = 0   ! current number of clusters
      LOGICAL, SAVE    :: linit = .true. ! do we need to initialize?
      LOGICAL lend
      REAL werte (maxw) 
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
!                                                                       
      lend = .false. 
!
!     Allocate the arrays in domain_mod.f90. As DISCUS cannot know the 
!     required number, of cluster types, we will just allocate a reasonable
!     amount and increase if necessary.
!
      IF ( linit ) THEN
         CALL alloc_domain ( clu_increment )
         MK_MAX_SCAT = MAX(MK_MAX_SCAT, MAXSCAT)
         MK_MAX_ATOM = MAX(MK_MAX_ATOM, NMAX)
         CALL alloc_micro  ( MK_MAX_SCAT , MK_MAX_ATOM)
         n_clu = CLU_MAX_TYPE
         linit = .false.
      ENDIF
!                                                                       
!     BEGIN OF new domain code                                          
!                                                                       
!                                                                       
      DO while (.not.lend) 
      CALL no_error 
      prom = prompt (1:len_str (prompt) ) //'/domain' 
      CALL get_cmd (line, laenge, befehl, lbef, zeile, lp, prom) 
      IF (ier_num.eq.0) then 
         IF (line.ne.' '.and.line (1:1) .ne.'#'.and.line.ne.char (13) ) &
         then                                                           
!                                                                       
!     ----search for "="                                                
!                                                                       
            indxg = index (line, '=') 
      IF (indxg.ne.0.and..not. (str_comp (befehl, 'echo', 2, lbef, 4) ) &
     &.and..not. (str_comp (befehl, 'syst', 2, lbef, 4) ) .and..not. (st&
     &r_comp (befehl, 'help', 2, lbef, 4) .or.str_comp (befehl, '?   ', &
     &2, lbef, 4) ) ) then                                              
!                                                                       
! ------evaluate an expression and assign the value to a variabble      
!                                                                       
               CALL do_math (line, indxg, laenge) 
            ELSE 
!                                                                       
!------ ----execute a macro file                                        
!                                                                       
               IF (befehl (1:1) .eq.'@') then 
                  IF (laenge.ge.2) then 
                     CALL file_kdo (line (2:laenge), laenge-1) 
                  ELSE 
                     ier_num = - 13 
                     ier_typ = ER_MAC 
                  ENDIF 
!                                                                       
!------ ----list asymmetric unit 'asym'                                 
!                                                                       
               ELSEIF (str_comp (befehl, 'asym', 2, lbef, 4) ) then 
                  CALL show_asym 
!                                                                       
!------ ----list atoms present in the crystal 'chem'                    
!                                                                       
               ELSEIF (str_comp (befehl, 'chem', 2, lbef, 4) ) then 
                  CALL show_chem 
!                                                                       
!     ----continues a macro 'continue'                                  
!                                                                       
               ELSEIF (str_comp (befehl, 'continue', 5, lbef, 8) ) then 
                  CALL macro_continue (zeile, lp) 
!                                                                       
!     ----Echo a string, just for interactive check in a macro 'echo'   
!                                                                       
               ELSEIF (str_comp (befehl, 'echo', 2, lbef, 4) ) then 
                  CALL echo (zeile, lp) 
!                                                                       
!      ---Evaluate an expression, just for interactive check 'eval'     
!                                                                       
               ELSEIF (str_comp (befehl, 'eval', 2, lbef, 4) ) then 
                  CALL do_eval (zeile, lp) 
!                                                                       
!     ----exit 'exit'                                                   
!                                                                       
               ELSEIF (str_comp (befehl, 'exit', 2, lbef, 4) ) then 
                  lend = .true. 
!                                                                       
!     ----help 'help' , '?'                                             
!                                                                       
      ELSEIF (str_comp (befehl, 'help', 1, lbef, 4) .or.str_comp (befehl&
     &, '?   ', 1, lbef, 4) ) then                                      
                  IF (str_comp (zeile, 'errors', 2, lp, 6) ) then 
                     lp = lp + 7 
                     CALL do_hel ('discus '//zeile, lp) 
                  ELSE 
                     lp = lp + 13 
                     CALL do_hel ('discus domain '//zeile, lp) 
                  ENDIF 
!                                                                       
!------- -Operating System Kommandos 'syst'                             
!                                                                       
               ELSEIF (str_comp (befehl, 'syst', 2, lbef, 4) ) then 
                  IF (zeile.ne.' '.and.zeile.ne.char (13) ) then 
                     CALL do_operating (zeile (1:lp), lp) 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!------  -----waiting for user input                                    
!                                                                       
               ELSEIF (str_comp (befehl, 'wait', 3, lbef, 4) ) then 
                  CALL do_input (zeile, lp) 
!                                                                       
!     ----Original domain commands                                      
!                                                                       
!                                                                       
!     assign properties to pseudoatoms 'assign'                         
!                                                                       
               ELSEIF (str_comp (befehl, 'assign', 1, lbef, 6) ) then 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) then 
                     IF (ianz.ge.3) then 
                        CALL do_build_name (ianz, cpara, lpara, werte,  &
                        maxw, 2)                                        
                        clu_index = 0 
                        CALL do_cap (cpara (2) ) 
                        DO i = 1, clu_number 
                        IF (str_comp (cpara (2), clu_name (i), 2, lpara &
                        (2), 4) ) then                                  
                           clu_index = i 
                        ENDIF 
                        ENDDO 
                        IF (clu_index.eq.0) then 
!
!                          If necessary increase array sizes
!
                           IF ( clu_number >= CLU_MAX_TYPE ) THEN
                              i     = CLU_MAX_TYPE + clu_increment
                              CALL alloc_domain ( i )
                              n_clu = CLU_MAX_TYPE
                           ENDIF
                           clu_number = clu_number + 1 
                           clu_index = clu_number 
                           clu_name (clu_index) = ' ' 
                           clu_name (clu_index) = cpara (2) (1:lpara(2))
                        ENDIF 
                        IF (str_comp (cpara (1) , 'character', 2, lpara &
                        (1) , 9) ) then                                 
                           IF (str_comp (cpara (3) , 'cube', 2, lpara ( &
                           3) , 4) ) then                               
                              clu_character (clu_index) = CLU_CHAR_CUBE 
                           ELSEIF (str_comp (cpara (3) , 'cylinder', 2, &
                           lpara (3) , 8) ) then                        
                              clu_character (clu_index) =               &
                              CLU_CHAR_CYLINDER                         
                           ELSEIF (str_comp (cpara (3) , 'fuzzy', 1,    &
                           lpara (3) , 5) ) then                        
                              clu_character (clu_index) =               &
                              CLU_CHAR_FUZZY                            
                           ELSEIF (str_comp (cpara (3) , 'sphere', 2,   &
                           lpara (3) , 6) ) then                        
                              clu_character (clu_index) =               &
                              CLU_CHAR_SPHERE                           
                           ENDIF 
                        ELSEIF (str_comp (cpara (1) , 'contentfile', 2, &
                        lpara (1) , 11) ) then                          
                           CALL del_params (2, ianz, cpara, lpara, maxw) 
                           IF (ier_num.eq.0) then 
                              CALL do_build_name (ianz, cpara, lpara,   &
                              werte, maxw, 1)                           
                              IF (ier_num.eq.0) then 
                                 clu_content (clu_index) = cpara (1) (1:lpara(1))
                              ENDIF 
                           ENDIF 
                        ELSEIF (str_comp (cpara (1) , 'fuzzy', 1, lpara &
                        (1) , 5) ) then                                 
                           CALL del_params (2, ianz, cpara, lpara, maxw) 
                           IF (ier_num.eq.0) then 
                              CALL ber_params (ianz, cpara, lpara,      &
                              werte, maxw)                              
                              IF (ier_num.eq.0) then 
                                 clu_fuzzy (clu_index) = werte (1) 
                              ENDIF 
                           ENDIF 
                        ELSEIF (str_comp (cpara (1) , 'orient', 1,      &
                        lpara (1) , 6) ) then                           
                           CALL del_params (2, ianz, cpara, lpara, maxw) 
                           IF (ier_num.eq.0) then 
                              CALL ber_params (ianz, cpara, lpara,      &
                              werte, maxw)                              
                              IF (ier_num.eq.0) then 
                                 i = nint (werte (1) ) 
                                 DO j = 1, 4 
                                 clu_orient (clu_index, i, j) = werte ( &
                                 j + 1)                                 
                                 ENDDO 
                              ENDIF 
                           ENDIF 
                        ELSEIF (str_comp (cpara (1) , 'shape', 1, lpara &
                        (1) , 5) ) then                                 
                           CALL del_params (2, ianz, cpara, lpara, maxw) 
                           IF (ier_num.eq.0) then 
                              CALL ber_params (ianz, cpara, lpara,      &
                              werte, maxw)                              
                              IF (ier_num.eq.0) then 
                                 i = nint (werte (1) ) 
                                 DO j = 1, 4 
                                 clu_shape (clu_index, i, j) = werte (j &
                                 + 1)                                   
                                 ENDDO 
                              ENDIF 
                           ENDIF 
                        ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ENDIF 
!                                                                       
!     ----set orientation for the current type 'orientation'            
!                                                                       
               ELSEIF (str_comp (befehl, 'orie', 1, lbef, 4) ) then 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        j = nint (werte (1) ) 
                        IF (0.lt.j.and.j.le.md_ori_n) then 
                           mv_orient = j 
                        ELSE 
                           ier_num = - 18 
                           ier_typ = ER_APPL 
                        ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!     define name of input file 'inputfile'                             
!                                                                       
               ELSEIF (str_comp (befehl, 'inputfile', 1, lbef, 9) )     &
               then                                                     
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) then 
                     CALL do_build_name (ianz, cpara, lpara, werte,     &
                     maxw, 1)                                           
                     IF (ier_num.eq.0) then 
                        clu_infile = cpara (1) (1:lpara(1))
                        clu_infile_internal = clu_infile(1:8)=='internal'
                     ENDIF 
                  ENDIF 
!                                                                       
!     define interpretation of input file 'mode'                        
!                                                                       
               ELSEIF (str_comp (befehl, 'mode', 1, lbef, 4) ) then 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) then 
                     IF (str_comp (cpara (1) , 'domain', 1, lbef, 7) )  &
                     then                                               
                        clu_mode = CLU_IN_CLUSTER 
                     ELSEIF (str_comp (cpara (1) , 'pseudo', 1, lbef, 6)&
                     ) then                                             
                        clu_mode = CLU_IN_PSEUDO 
                     ENDIF 
                  ENDIF 
!                                                                       
!     ----Start the distribution of domains 'run'                       
!                                                                       
               ELSEIF (str_comp (befehl, 'run ', 2, lbef, 4) ) then 
                  CALL micro_filereading 
!                                                                       
!     ----Reset the number of domain definitions 'rese'                 
!                                                                       
               ELSEIF (str_comp (befehl, 'rese', 2, lbef, 4) ) then 
                  clu_number = 0 
!                                                                       
!     ----define various surface related settings 'set'                 
!                                                                       
               ELSEIF (str_comp (befehl, 'set', 2, lbef, 3) ) then 
                  CALL domain_do_set (zeile, lp) 
!                                                                       
!     ----show current settings 'show'                                  
!                                                                       
               ELSEIF (str_comp (befehl, 'show', 3, lbef, 4) ) then 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) then 
                     IF (ianz.eq.0.or.ianz.eq.1) then 
                        CALL show_domain 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!     ----unknown command                                               
!                                                                       
               ELSE 
                  ier_num = - 8 
                  ier_typ = ER_COMM 
               ENDIF 
            ENDIF 
         ENDIF 
      ENDIF 
!                                                                       
!     --Goto_s and jumps are terrible, yet FORTRTAN does not            
!       have a break                                                    
!     --Jump here if an error occured                                   
!                                                                       
      IF (ier_num.ne.0) then 
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
      ENDDO 
!                                                                       
      END SUBROUTINE do_domain                      
!*****7*****************************************************************
      SUBROUTINE show_domain 
!-                                                                      
!     Displays the current parameters for domain distributions          
!+                                                                      
      USE config_mod 
      USE allocate_appl_mod 
      USE crystal_mod 
      USE domain_mod 
      USE surface_mod 
      USE errlist_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      CHARACTER(9) char_type ( - 4:0) 
      CHARACTER(12) char_mode (0:1) 
      INTEGER i, ii, j 
      INTEGER              :: new_nscat ! DUMMY for allocation
!                                                                       
      INTEGER len_str 
!                                                                       
      DATA char_mode / 'domain     ', 'pseudoatoms' / 
      DATA char_type / 'fuzzy    ', 'sphere   ', 'cylinder ', 'cube     &
     &', 'undefined' /                                                  
!                                                                       
      IF (cr_nscat == MAXSCAT) then 
         new_nscat = MAX(MAXSCAT + 5, INT ( MAXSCAT * 1.025 ))
         CALL alloc_crystal(new_nscat, NMAX)
         CALL alloc_surf   (new_nscat)
      ENDIF 
      IF (MAXSCAT  > ubound(surf_in_dist,1)) THEN
         new_nscat = MAXSCAT
         CALL alloc_surf   (new_nscat)
      ENDIF 
      i = 0 
      i = len_str (clu_infile) 
!                                                                       
      WRITE (output_io, 3000) 
      WRITE (output_io, 3100) char_mode (clu_mode) 
      IF (i.gt.0) then 
         WRITE (output_io, 3200) clu_infile (1:i) 
      ELSE 
         WRITE (output_io, 3250) 
      ENDIF 
!                                                                       
      IF (clu_mode.eq.CLU_IN_PSEUDO) then 
         WRITE (output_io, 4000) 
         DO i = 1, clu_number 
         WRITE (output_io, 4100) clu_name (i) 
         WRITE (output_io, 4200) char_type (clu_character (i) ) 
         j = 0 
         j = len_str (clu_content (i) ) 
         IF (j.gt.0) then 
            WRITE (output_io, 4300) clu_content (i) (1:j) 
         ELSE 
            WRITE (output_io, 4350) 
         ENDIF 
         IF( clu_fuzzy(i) > 0 ) THEN
            WRITE (output_io, 4400) clu_fuzzy (i) 
         ELSE
            WRITE (output_io, 4410) 
         ENDIF
         DO ii = 1, 3 
         WRITE (output_io, 4500) (clu_shape (i, ii, j), j = 1, 4) 
         ENDDO 
         WRITE (output_io, * ) 
         DO ii = 1, 3 
         WRITE (output_io, 4600) (clu_orient (i, ii, j), j = 1, 4) 
         ENDDO 
         ENDDO 
      ENDIF 
      IF (SURF_MAXSCAT==0) THEN
        WRITE(output_io,*) ' No distances to surfaces have been defined yet'
        WRITE(output_io,*) ' Set distances within surface menu first'
        RETURN
      ENDIF
      WRITE (output_io, * ) 
      WRITE (output_io, 5100) 
      WRITE (output_io, * ) 
      DO i = 0, cr_nscat 
      WRITE (output_io, 5010) cr_at_lis (i), surf_in_dist (i) 
      ENDDO 
      IF (cr_nscat.lt.SURF_MAXSCAT) then 
         WRITE (output_io, 5010) 'new', surf_in_dist (SURF_MAXSCAT) 
      ENDIF 
!                                                                       
      WRITE (output_io, * ) 
!                                                                       
 3000 FORMAT(/'****************************************************'//  &
     &        ' Characterisation of domain distribution'/)              
 3100 FORMAT(' Inputfile contains     : ',a11) 
 3200 FORMAT(' Inputfile name         : ',a) 
 3250 FORMAT(' Inputfile name         : ','undefined') 
 4000 FORMAT(' Pseudoatom definitions : ',a) 
 4100 FORMAT(/,'     Pseudoatom name    : ',a4) 
 4200 FORMAT('     domain type        : ',a9) 
 4300 FORMAT('     content in file    : ',a) 
 4350 FORMAT('     content in file    : ','undefined') 
 4400 FORMAT('     fuzzy separation   : ',f15.7,' A') 
 4410 FORMAT('     fuzzy separation   : ','switched OFF old atoms are not removed')
 4500 FORMAT('     shape orientation  : ','(',3(f9.4,2x),2x,f9.4,')') 
 4600 FORMAT('     atom orientation   : ','(',3(f9.4,2x),2x,f9.4,')') 
 5100 FORMAT (' Distances between atom types and an internal surface') 
 5010 FORMAT (' Atom type   ',a4,' at ',f8.3,' Angstroem') 
      END SUBROUTINE show_domain                    
!*****7*****************************************************************
      SUBROUTINE micro_filereading 
!                                                                       
      USE config_mod 
      USE crystal_mod 
      USE domain_mod 
      USE domaindis_mod 
      USE micro_mod 
      USE read_internal_mod
      USE save_mod 
      USE structur, ONLY: stru_readheader
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER imd 
      PARAMETER (imd = 45) 
!                                                                       
      CHARACTER(1024) infile 
      LOGICAL lend 
      LOGICAL lread 
      LOGICAL lmetric 
      REAL mc_dimen (4, 4) 
      REAL mc_idimen (4, 4) 
      REAL mc_matrix (4, 4) 
      integer natoms_old
      real    shortest
      real    vv(3)
!
      clu_remove_end = cr_natoms    ! Initially remove only atoms in original crystal
!                                                                       
      lread = .true. 
      IF ( clu_infile_internal ) THEN
         CALL stru_readheader_internal (clu_infile, MK_MAX_SCAT, mk_name,   &
         mk_spcgr, mk_at_lis, mk_nscat, mk_dw, mk_a0, mk_win,         &
         sav_ncell, sav_r_ncell, sav_ncatoms, spcgr_ianz, spcgr_para, &
         mk_GEN_ADD_MAX, mk_gen_add_n, mk_gen_add_power, mk_gen_add,  &
         mk_SYM_ADD_MAX, mk_sym_add_n, mk_sym_add_power, mk_sym_add )
         clu_iatom = 0
      ELSE
         CALL oeffne (imd, clu_infile, 'old') 
         IF (ier_num.ne.0) return 
!                                                                       
!     Read the input file header                                        
!                                                                       
         CALL stru_readheader (imd, MK_MAX_SCAT, mk_name,     &
         mk_spcgr, mk_at_lis, mk_nscat, mk_dw, mk_a0, mk_win, sav_ncell,   &
         sav_r_ncell, sav_ncatoms, mk_spcgr_ianz, mk_spcgr_para)           
      ENDIF
      IF (ier_num.ne.0) return 
!                                                                       
!------ Here we should include comparison of the unit cell              
!       space group etc.                                                
!                                                                       
      lmetric = abs (mk_a0 (1) - cr_a0 (1) ) .lt.0.0001.and.abs (mk_a0 (&
      2) - cr_a0 (2) ) .lt.0.0001.and.abs (mk_a0 (3) - cr_a0 (3) )      &
      .lt.0.0001.and.abs (mk_win (1) - cr_win (1) ) .lt.0.001.and.abs ( &
      mk_win (2) - cr_win (2) ) .lt.0.001.and.abs (mk_win (3) - cr_win (&
      3) ) .lt.0.001                                                    
      IF (.not.lmetric) then 
         ier_num = - 87 
         ier_typ = ER_APPL 
         ier_msg (1) = 'The lattice constants in the domain' 
         ier_msg (2) = 'file differ from those of the host' 
         CLOSE (imd) 
         RETURN 
      ENDIF 
      IF (mk_spcgr (1:1) .ne.cr_spcgr (1:1) ) then 
         ier_num = - 88 
         ier_typ = ER_APPL 
         ier_msg (1) = 'between microdomain and host' 
         CLOSE (imd) 
         RETURN 
      ENDIF 
!                                                                       
      IF (clu_mode.eq.CLU_IN_PSEUDO) then 
         CALL micro_read_simple (imd, lend, infile, mc_dimen, mc_idimen,&
         mc_matrix, MK_MAX_SCAT, mk_at_lis)                                                     
         IF (ier_num.ne.0) return 
!                                                                       
         DO while (.not.lend) 
         IF (mc_type  .lt.0) then 
            CALL micro_read_atoms (infile, mc_idimen,         &
            mc_matrix)                                                  
         ENDIF 
         IF (ier_num.ne.0) return 
         CALL micro_read_simple (imd, lend, infile, mc_dimen, mc_idimen,&
         mc_matrix, MK_MAX_SCAT, mk_at_lis)                                                     
         IF (ier_num.ne.0) return 
         ENDDO 
!
!        if the user trusts that no domains overlap among each other, then
!        old atoms are removed only here at the end
!
         IF ( clu_remove_mode == CLU_REMOVE_TRUST ) THEN
            mk_dim       = 0.
            natoms_old   = clu_remove_end
            mk_natoms    = cr_natoms - natoms_old 
            md_sep_fuz   = clu_remove_dist
            vv           = 0.0
            shortest     = 0.0
            mc_type      = MD_DOMAIN_FUZZY
            IF(md_sep_fuz > 0.0 ) THEN
               CALL micro_fuzzy_rem (mk_dim, natoms_old, mk_natoms, md_sep_fuz,  &
               vv, shortest, mc_type, MD_DOMAIN_FUZZY)                                                     
            ENDIF
         ENDIF
!                                                                       
      ELSE 
         CALL micro_read_micro (imd, lend, infile, mc_dimen, mc_idimen, &
         mc_matrix)                                                     
         IF (ier_num.ne.0) return 
!                                                                       
         DO while (.not.lend) 
         IF (mc_type  .lt.0) then 
            CALL micro_read_atoms (infile, mc_idimen,         &
            mc_matrix)                                                  
         ENDIF 
         IF (ier_num.ne.0) return 
         CALL micro_read_micro (imd, lend, infile, mc_dimen, mc_idimen, &
         mc_matrix)                                                     
         IF (ier_num.ne.0) return 
         ENDDO 
      ENDIF 
      IF ( .not. clu_infile_internal ) THEN
         CLOSE (imd) 
      ENDIF 
!                                                                       
      END SUBROUTINE micro_filereading              
!*****7*****************************************************************
      SUBROUTINE micro_read_micro (imd, lend, infile, mc_dimen,         &
      mc_idimen, mc_matrix)                                             
!                                                                       
      USE config_mod 
      USE domaindis_mod 
      USE tensors_mod
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 4) 
!                                                                       
      CHARACTER (LEN=* ), INTENT(OUT) :: infile 
      INTEGER           , INTENT(IN)  :: imd 
      LOGICAL           , INTENT(OUT) :: lend 
      REAL              , INTENT(OUT) :: mc_dimen (4, 4) 
      REAL              , INTENT(OUT) :: mc_idimen (4, 4) 
      REAL              , INTENT(OUT) :: mc_matrix (4, 4) 
!                                                                       
      CHARACTER(10) befehl 
      CHARACTER(1024) line, zeile 
      CHARACTER(1024) cpara (maxw) 
      CHARACTER(1024) mc_strufile 
      INTEGER i, j, ibl, lbef 
      INTEGER lline 
      INTEGER lp, ianz 
      INTEGER lpara (maxw) 
      REAL werte (maxw) 
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
!                                                                       
      ier_num = - 49 
      ier_typ = ER_APPL 
      DO i = 1, 4 
      DO j = 1, 4 
      mc_matrix (i, j) = 0.0 
      mc_dimen (i, j) = 0.0 
      ENDDO 
      mc_matrix (i, i) = 1.0 
      mc_dimen (i, i) = 1.0 
      ENDDO 
      line = ' ' 
      READ (imd, 2000, end = 2, err = 999) line 
      lline = len_str (line) 
      DO while (line.eq.' '.or.line (1:1) .eq.'#'.or.line.eq.char (13) ) 
      READ (imd, 2000, end = 2, err = 999) line 
      lline = len_str (line) 
      ENDDO 
      ibl = index (line (1:lline) , ' ') + 1 
      lbef = 10 
      befehl = ' ' 
      ibl = index (line, ' ') 
      lbef = min (ibl - 1, lbef) 
      befehl = line (1:lbef) 
      lbef = len_str (befehl) 
      befehl = line (1:lbef) 
      IF (str_comp (befehl, 'domain', 4, lbef, 6) ) then 
!                                                                       
!     --Start/End of a microdomain descriptor                           
!                                                                       
         CALL no_error 
         zeile = line (ibl:lline) 
         lp = lline-ibl + 1 
         CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
         IF (ier_num.eq.0) then 
            IF (ianz.eq.0) then 
 1000          CONTINUE 
               READ (imd, 2000, end = 998, err = 999) line 
               lline = len_str (line) 
               ibl = index (line (1:lline) , ' ') + 1 
               lbef = 10 
               befehl = ' ' 
               ibl = index (line, ' ') 
               lbef = min (ibl - 1, lbef) 
               befehl = line (1:lbef) 
               lbef = len_str (befehl) 
               befehl = line (1:lbef) 
               CALL do_cap (befehl) 
               CALL no_error 
               zeile = line (ibl:lline) 
               lp = lline-ibl + 1 
!                                                                       
               IF (str_comp (befehl, 'DOMAIN', 4, lbef, 6) ) then 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) then 
                     IF (str_comp (cpara (1) , 'character', 2, lpara (1)&
                     , 9) ) then                                        
                        IF (str_comp (cpara (2) , 'domain_sphere', 9,   &
                        lpara (2) , 13) ) then                          
                           mc_type = MD_DOMAIN_SPHERE 
                        ELSEIF (str_comp (cpara (2) , 'domain_cube', 10,&
                        lpara (2) , 11) ) then                          
                           mc_type = MD_DOMAIN_CUBE 
                        ELSEIF (str_comp (cpara (2) , 'domain_cylinder',&
                        10, lpara (2) , 15) ) then                      
                           mc_type = MD_DOMAIN_CYLINDER 
                        ELSEIF (str_comp (cpara (2) , 'domain_fuzzy',   &
                        10, lpara (2) , 12) ) then                      
                           mc_type = MD_DOMAIN_FUZZY 
                        ENDIF 
                     ELSEIF (str_comp (cpara (1) , 'content', 2, lpara (&
                     1) , 7) ) then                                     
                        CONTINUE 
                     ELSEIF (str_comp (cpara (1) , 'file', 2, lpara (1) &
                     , 4) ) then                                        
                        mc_strufile = cpara (2) (1:lpara (2) ) 
                        infile = cpara (2) (1:lpara (2) ) 
                     ELSEIF (str_comp (cpara (1) , 'fuzzy', 2, lpara (1)&
                     , 5) ) then                                        
                        CALL del_params (1, ianz, cpara, lpara, maxw) 
                        CALL ber_params (ianz, cpara, lpara, werte,     &
                        maxw)                                           
                        IF (ier_num.eq.0) then 
                           md_sep_fuz = werte (1) 
                        ELSE 
                           RETURN 
                        ENDIF 
                     ELSEIF (str_comp (cpara (1) , 'end', 3, lpara (1) ,&
                     3) ) then                                          
                        DO i = 1, 3 
                        DO j = 1, 3 
                        mc_matrix (i, j) = mc_matrix (i, j) - mc_matrix &
                        (j, 4)                                          
                        mc_dimen (i, j) = mc_dimen (i, j) - mc_dimen (j,&
                        4)                                              
                        ENDDO 
                        ENDDO 
                        DO i = 1, 4 
                        DO j = 1, 4 
                        mc_idimen (i, j) = mc_dimen (i, j) 
                        ENDDO 
                        ENDDO 
                        CALL invmat4 (mc_idimen) 
                        lend = .false. 
                        CALL no_error 
                        RETURN 
                     ELSE 
                        ier_num = - 94 
                        ier_typ = ER_APPL 
                        ier_msg (1) = 'Error while reading' 
                        ier_msg (2) = 'the domain input file' 
                     ENDIF 
                  ELSE 
                     RETURN 
                  ENDIF 
               ELSEIF (str_comp (befehl, 'POSI', 4, lbef, 8) ) then 
                  READ (zeile, * ) (mc_matrix (i, 4), i = 1, 3) 
               ELSEIF (str_comp (befehl, 'XAXI', 4, lbef, 8) ) then 
                  READ (zeile, * ) (mc_matrix (1, i), i = 1, 3) 
               ELSEIF (str_comp (befehl, 'YAXI', 4, lbef, 8) ) then 
                  READ (zeile, * ) (mc_matrix (2, i), i = 1, 3) 
               ELSEIF (str_comp (befehl, 'ZAXI', 4, lbef, 8) ) then 
                  READ (zeile, * ) (mc_matrix (3, i), i = 1, 3) 
               ELSEIF (str_comp (befehl, 'CENT', 4, lbef, 8) ) then 
                  READ (zeile, * ) (mc_dimen (i, 4), i = 1, 3) 
               ELSEIF (str_comp (befehl, 'XDIM', 4, lbef, 8) ) then 
                  READ (zeile, * ) (mc_dimen (1, i), i = 1, 3) 
               ELSEIF (str_comp (befehl, 'YDIM', 4, lbef, 8) ) then 
                  READ (zeile, * ) (mc_dimen (2, i), i = 1, 3) 
               ELSEIF (str_comp (befehl, 'ZDIM', 4, lbef, 8) ) then 
                  READ (zeile, * ) (mc_dimen (3, i), i = 1, 3) 
               ELSE 
                  ier_num = - 96 
                  ier_typ = ER_APPL 
                  ier_msg (1) = 'Error while reading' 
                  ier_msg (2) = 'the domain input file' 
               ENDIF 
!                                                                       
               GOTO 1000 
            ELSE 
               ier_num = - 95 
               ier_typ = ER_APPL 
               ier_msg (1) = 'Error while reading' 
               ier_msg (2) = 'the domain input file' 
            ENDIF 
         ELSE 
            RETURN 
         ENDIF 
      ELSE 
         ier_num = - 96 
         ier_typ = ER_APPL 
         ier_msg (1) = 'Error while reading' 
         ier_msg (2) = 'the domain input file' 
         RETURN 
      ENDIF 
      line = ' ' 
!                                                                       
    2 CONTINUE 
      lend = .true. 
      CALL no_error 
      RETURN 
!                                                                       
      line = ' ' 
  998 CONTINUE 
  999 CONTINUE 
      line = ' ' 
!                                                                       
 2000 FORMAT    (a) 
!                                                                       
      END SUBROUTINE micro_read_micro               
!*****7*****************************************************************
      SUBROUTINE micro_read_atoms (infile, mc_idimen,         &
      mc_matrix)                                                        
!                                                                       
      USE config_mod 
      USE crystal_mod 
      USE metric_mod
      USE micro_mod 
      USE read_internal_mod 
      USE save_mod 
      USE structur, ONLY: stru_readheader
      USE trafo_mod
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      CHARACTER ( * ) infile 
      REAL mc_idimen (4, 4) 
      REAL mc_matrix (4, 4) 
!                                                                       
      INTEGER ist 
      PARAMETER (ist = 46) 
!                                                                       
      LOGICAL lread 
!                                                                       
      lread = .true. 
      IF(infile(1:8)=='internal') THEN
         mk_infile_internal = .true.
         CALL stru_readheader_internal (infile, MK_MAX_SCAT, mk_name,   &
         mk_spcgr, mk_at_lis, mk_nscat, mk_dw, mk_a0, mk_win,         &
         sav_ncell, sav_r_ncell, sav_ncatoms, spcgr_ianz, spcgr_para, &
         mk_GEN_ADD_MAX, mk_gen_add_n, mk_gen_add_power, mk_gen_add,  &
         mk_SYM_ADD_MAX, mk_sym_add_n, mk_sym_add_power, mk_sym_add )
         mk_iatom = 0
      ELSE
         CALL oeffne (ist, infile, 'unknown') 
         IF (ier_num.ne.0) return 
!                                                                       
!     Read the input file header                                        
!                                                                       
         CALL stru_readheader (ist, MK_MAX_SCAT, mk_name,     &
         mk_spcgr, mk_at_lis, mk_nscat, mk_dw, mk_a0, mk_win, sav_ncell,   &
         sav_r_ncell, sav_ncatoms, mk_spcgr_ianz, mk_spcgr_para)           
      ENDIF
!                                                                       
      CALL micro_read_atom (ist, infile, mc_idimen, mc_matrix) 
      IF(.not.(infile(1:8)=='internal')) THEN
         CLOSE (ist) 
      ENDIF
!                                                                       
      END SUBROUTINE micro_read_atoms               
!*****7*****************************************************************
      SUBROUTINE micro_remove_old (mc_idimen) 
!                                                                       
!     This routine will become obsolete if the "fuzzy" property is      
!     always used.                                                      
!                                                                       
      USE config_mod 
      USE crystal_mod 
      USE domaindis_mod 
      USE micro_mod 
      USE metric_mod
      USE prop_para_mod 
      USE trafo_mod
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      REAL mc_idimen (4, 4) 
!                                                                       
      INTEGER idim 
      PARAMETER (idim = 4) 
!                                                                       
      INTEGER i, j 
      LOGICAL lspace 
      REAL d 
      REAL u (3), v (3) 
      REAL u4 (4), v4 (4) 
      REAL radius (3) 
      REAL NULL (3) 
!                                                                       
!     REAL do_blen 
!                                                                       
      DATA NULL / 0.0, 0.0, 0.0 / 
!                                                                       
      IF (mc_type .eq.MD_DOMAIN_FUZZY) then 
         RETURN 
      ENDIF 
!                                                                       
      lspace = .true. 
      v (1) = 0.0 
      v (2) = 0.0 
      v (3) = 0.0 
      DO i = 1, 3 
      DO j = 1, 3 
      u (1) = 0.0 
      u (2) = 0.0 
      u (3) = 0.0 
      ENDDO 
      u (i) = 1.0 
      radius (i) = do_blen (lspace, u, v) 
      ENDDO 
!                                                                       
      DO i = 1, cr_natoms 
      DO j = 1, 3 
      u4 (j) = cr_pos (j, i) 
      ENDDO 
      u4 (4) = 1.0 
      CALL trans (u4, mc_idimen, v4, idim) 
      DO j = 1, 3 
      v (j) = v4 (j) 
      ENDDO 
      IF (mc_type  .eq.MD_DOMAIN_SPHERE) then 
         d = do_blen (lspace, v, NULL) 
         IF (d.lt.radius (2) ) then 
            cr_iscat (i) = 0 
            cr_prop (i) = IBCLR (cr_prop (i), PROP_NORMAL) 
            cr_prop (i) = IBSET (cr_prop (i), PROP_DOMAIN) 
         ENDIF 
      ELSEIF (mc_type  .eq.MD_DOMAIN_CUBE) then 
         IF (abs (v (1) ) .le.1.and.abs (v (2) ) .le.1.and.abs (v (3) ) &
         .le.1) then                                                    
            cr_iscat (i) = 0 
            cr_prop (i) = IBCLR (cr_prop (i), PROP_NORMAL) 
            cr_prop (i) = IBSET (cr_prop (i), PROP_DOMAIN) 
         ENDIF 
      ELSEIF (mc_type  .eq.MD_DOMAIN_CYLINDER) then 
         IF (abs (v (3) ) .le.1) then 
            v (3) = 0.0 
            d = do_blen (lspace, v, NULL) 
            IF (d.lt.radius (2) ) then 
               cr_iscat (i) = 0 
               cr_prop (i) = IBCLR (cr_prop (i), PROP_NORMAL) 
               cr_prop (i) = IBSET (cr_prop (i), PROP_DOMAIN) 
            ENDIF 
         ENDIF 
      ENDIF 
      ENDDO 
!                                                                       
      END SUBROUTINE micro_remove_old               
!*****7*****************************************************************
      SUBROUTINE micro_read_atom (ist, infile, mc_idimen, mc_matrix) 
!                                                                       
      USE config_mod 
      USE allocate_appl_mod 
      USE crystal_mod 
      USE domain_mod 
      USE domaindis_mod 
      USE metric_mod
      USE micro_mod 
      USE molecule_mod 
      USE prop_para_mod 
      USE read_internal_mod
      USE structur, ONLY: struc_mole_header
      USE spcgr_apply, ONLY: mole_insert_current
      USE trafo_mod
      USE surface_mod 
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER ist 
      CHARACTER (LEN = *), INTENT(IN) :: infile
      REAL mc_idimen (4, 4) 
      REAL mc_matrix (4, 4) 
!                                                                       
      INTEGER idim4 
      PARAMETER (idim4 = 4) 
      INTEGER maxw 
      PARAMETER (maxw = 4) 
!                                                                       
      CHARACTER(10) befehl 
      CHARACTER(1024) line, zeile 
      INTEGER i, j, k, ii, ibl, lbef 
      INTEGER natoms_old 
      INTEGER i_count 
      INTEGER              :: new_nscat ! DUMMY for allocation
      INTEGER              :: new_nmax  ! DUMMY for allocation
      LOGICAL lspace 
      LOGICAL linside
      REAL d 
      REAL u (4), v (4), w (4) 
      REAL vv (3) 
      REAL radius (3) 
      REAL werte (maxw), dw1 
      REAL NULL (3) 
      REAL shortest 
      REAL, DIMENSION(3)  :: xyz ! Atom position
      INTEGER             :: dummy_iscat ! Atom type
      INTEGER             :: dummy_prop ! Atom property
      INTEGER             :: natoms ! Number of molecules
      INTEGER             :: nscat  ! Number of molecule types
      INTEGER             :: TEMP_MAX_MOLE ! Number of molecules
      INTEGER             :: TEMP_MAX_TYPE ! Number of molecule types
      INTEGER             :: TEMP_MAX_ATOM ! Number of atoms in molecules
      INTEGER             :: temp_num_mole ! Number of molecules
      INTEGER             :: temp_num_type ! Number of molecule types
      INTEGER             :: temp_num_atom ! Number of atoms in molecules
      INTEGER             :: istatus! Number of atoms in molecules
      INTEGER, DIMENSION(:), ALLOCATABLE :: temp_mole_len
      INTEGER, DIMENSION(:), ALLOCATABLE :: temp_mole_off
      INTEGER, DIMENSION(:), ALLOCATABLE :: temp_mole_type
      INTEGER, DIMENSION(:), ALLOCATABLE :: temp_mole_char
      CHARACTER (LEN=200), DIMENSION(:), ALLOCATABLE :: temp_mole_file
      REAL   , DIMENSION(:), ALLOCATABLE :: temp_mole_dens
      REAL   , DIMENSION(:), ALLOCATABLE :: temp_mole_fuzzy
      INTEGER, DIMENSION(:), ALLOCATABLE :: temp_mole_cont
      LOGICAL, DIMENSION(:), ALLOCATABLE :: temp_present
      INTEGER, DIMENSION(:), ALLOCATABLE :: temp_in_crystal
      INTEGER, DIMENSION(:), ALLOCATABLE :: temp_in_mole
      INTEGER             :: n_mole
      INTEGER             :: n_type
      INTEGER             :: n_atom
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
!     REAL do_blen 
!                                                                       
      DATA NULL / 0.0, 0.0, 0.0 / 
!                                                                       
      lspace = .true.
      linside = .false.
      v (1) = 0.0 
      v (2) = 0.0 
      v (3) = 0.0 
      DO i = 1, 3 
         u (1) = 0.0 
         u (2) = 0.0 
         u (3) = 0.0 
         u (i) = 1.0 
         radius (i) = do_blen (lspace, u, v) 
      ENDDO 
      i_count = 0 
!                                                                       
      DO i = 1, 3 
         mk_dim (i, 1) = mc_matrix (i, 4) 
         mk_dim (i, 2) = mc_matrix (i, 4) 
      ENDDO 
!
!     Does the user want to remove existing atoms at insertion of each domain
!     which includes atoms inserted by other domains in this run or
!     only the atoms that existed previous to the 'run' command
!
      IF (     clu_remove_mode ==  CLU_REMOVE_STRICT  ) THEN
         natoms_old = cr_natoms 
      ELSE
         natoms_old = clu_remove_end
      ENDIF 
!                                                                       
      IF(mk_infile_internal) THEN
         mk_iatom = 0
         ALLOCATE ( temp_present   (0:MK_MAX_ATOM), STAT = istatus )
         ALLOCATE ( temp_in_crystal(0:MK_MAX_ATOM), STAT = istatus )
         ALLOCATE ( temp_in_mole   (0:MK_MAX_ATOM), STAT = istatus )
         temp_present    = .false.
         temp_in_crystal = 0
         temp_in_mole    = 0
      ENDIF
 1000 CONTINUE 
      ier_num = - 49 
      ier_typ = ER_APPL 
      line = ' ' 
      IF(mk_infile_internal) THEN
         mk_iatom =  mk_iatom + 1   ! Increment internal atom number
         CALL struc_read_one_atom_internal(infile,  mk_iatom,  &
              xyz, dummy_iscat, dummy_prop )
         IF( ier_num == -105 ) THEN  ! read "end_of_file" 
            ier_num = 0
            ier_typ = ER_NONE
             mk_iatom =  mk_iatom - 1   ! Increment internal atom number
            GOTO 2
         ENDIF
         WRITE(line, 3000) mk_at_lis(dummy_iscat), xyz, mk_dw(dummy_iscat) ! copy into line
      ELSE
         READ (ist, 2000, end = 2, err = 999) line 
      ENDIF
blank1: IF (line.ne.' '.and.line (1:1) .ne.'#'.and.line.ne.char (13) ) then
         i_count = i_count + 1 
         ibl = index (line, ' ') + 1 
         lbef = 10 
         befehl = ' ' 
         ibl = index (line, ' ') 
         lbef = min (ibl - 1, lbef) 
         befehl = line (1:lbef) 
         lbef = len_str (befehl) 
         befehl = line (1:lbef) 
is_mole: IF (str_comp (befehl, 'molecule', 4, lbef, 8) .or. &
             str_comp (befehl, 'domain',   4, lbef, 6) .or. &
             str_comp (befehl, 'object',   4, lbef, 6)      ) then                                             
!                                                                       
!     ------Start/End of a molecule                                     
!                                                                       
            CALL no_error 
            zeile = line (ibl:200) 
            i = 200 - ibl 
            i = len_str (zeile) 
            CALL struc_mole_header (zeile, i, .false.) 
            IF (ier_num.ne.0) return 
         ELSE is_mole
            READ (line (ibl:80), *, end = 999, err = 999) (werte (j),   &
            j = 1, 4)                                                   
            DO j = 1, 3 
            u (j) = werte (j) 
            ENDDO 
            u (4) = 1.0 
            CALL trans (u, mc_matrix, v, idim4) 
            CALL trans (v, mc_idimen, w, idim4) 
            DO j = 1, 3 
            vv (j) = w (j) 
            mk_dim (j, 1) = min (mk_dim (j, 1), v (j) ) 
            mk_dim (j, 2) = max (mk_dim (j, 2), v (j) ) 
            ENDDO 
            IF (mc_type  .eq.MD_DOMAIN_SPHERE) then 
               d = do_blen (lspace, vv, NULL) 
               linside = (d.lt.radius (2) ) 
            ELSEIF (mc_type  .eq.MD_DOMAIN_CUBE) then 
               linside = abs (vv (1) ) .le.1.and.abs (vv (2) )          &
               .le.1.and.abs (vv (3) ) .le.1                            
            ELSEIF (mc_type  .eq.MD_DOMAIN_CYLINDER) then 
               linside = .false. 
               IF (abs (vv (3) ) .le.1) then 
                  vv (3) = 0.0 
                  d = do_blen (lspace, vv, NULL) 
                  linside = d.lt.radius (2) 
               ENDIF 
            ELSEIF (mc_type  .eq.MD_DOMAIN_FUZZY) then 
               linside = .true. 
            ENDIF 
inside:     IF (linside) then 
               IF (cr_natoms.eq.nmax) then 
                  new_nmax = int( nmax*1.1 )
                  CALL alloc_crystal(MAXSCAT, new_nmax)
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
               cr_pos (j, i) = v (j)
               cr_dim (j, 1) = amin1 (cr_dim (j, 1), cr_pos (j, i) ) 
               cr_dim (j, 2) = amax1 (cr_dim (j, 2), cr_pos (j, i) ) 
               ENDDO 
               dw1 = werte (4) 
noblank:      IF (line (1:4) .ne.'    ') then 
                  ibl = ibl - 1 
                  CALL do_cap (line (1:ibl) ) 
                  DO j = 0, cr_nscat 
                  IF (line (1:ibl) .eq.cr_at_lis (j) .and.dw1.eq.cr_dw (&
                  j) ) then                                             
                     cr_iscat (i) = j 
                     cr_prop (i) = 0 
                     cr_prop (i) = ibset (cr_prop (i), PROP_NORMAL) 
                     cr_prop (i) = ibset (cr_prop (i), PROP_DOMAIN) 
                     GOTO 11 
                  ENDIF 
                  ENDDO 
                  IF (cr_nscat == MAXSCAT) then 
                     new_nscat = MAX(MAXSCAT + 5, INT ( MAXSCAT * 1.025 ))
                     CALL alloc_crystal(new_nscat, NMAX)
                     CALL alloc_surf   (new_nscat)
                  ENDIF 
                  IF (MAXSCAT  > ubound(surf_in_dist,1)) THEN
                     new_nscat = MAXSCAT
                     CALL alloc_surf   (new_nscat)
                  ENDIF 
                  IF (cr_nscat.eq.MAXSCAT) then 
!                                                                       
!     --------  Too many atom types in the structure file               
!                                                                       
                     ier_num = - 72 
                     ier_typ = ER_APPL 
                     RETURN 
                  ENDIF 
                  cr_nscat = cr_nscat + 1 
                  cr_iscat (i) = cr_nscat 
                  cr_prop (i) = 0 
                  cr_prop (i) = ibset (cr_prop (i), PROP_NORMAL) 
                  cr_prop (i) = ibset (cr_prop (i), PROP_DOMAIN) 
                  cr_at_lis (cr_nscat) = line (1:ibl) 
                  cr_dw (cr_nscat) = dw1 
!                                                                       
                  IF (0.0.le.cr_pos (1, i) .and.cr_pos (1, i)           &
                  .lt.1.and.0.0.le.cr_pos (2, i) .and.cr_pos (2, i)     &
                  .lt.1.and.0.0.le.cr_pos (3, i) .and.cr_pos (3, i)     &
                  .lt.1) then                                           
                     as_natoms = as_natoms + 1 
                     as_at_lis (cr_nscat) = cr_at_lis (cr_nscat) 
                     as_iscat (as_natoms) = cr_iscat (i) 
                     as_prop (as_natoms) = cr_prop (i) 
                     as_dw (as_natoms) = cr_dw (cr_nscat) 
                     DO j = 1, 3 
                     as_pos (j, as_natoms) = cr_pos (j, i) 
                     ENDDO 
                  ENDIF 
   11             CONTINUE 
                  IF(mk_infile_internal) THEN
                     temp_present   (mk_iatom) = .true.
                     temp_in_crystal(mk_iatom) = i
                  ENDIF
!                                                                       
!     --------If we are reading a molecule insert atom into current     
                  IF (mole_l_on) then 
                     CALL mole_insert_current (cr_natoms, mole_num_curr) 
                     IF (ier_num.lt.0.and.ier_num.ne. - 49) then 
                        GOTO 999 
                     ENDIF 
                  ENDIF 
               ENDIF  noblank
            ENDIF inside
         ENDIF is_mole
      ENDIF blank1
      GOTO 1000 
!                                                                       
    2 CONTINUE 
!
!   If the file was read from internal storage, we need to assign the molecules
!
mole_int: IF(mk_infile_internal) THEN
       CALL testfile_internal (infile, natoms, &        ! Get size of internal structure
              nscat, TEMP_MAX_MOLE, TEMP_MAX_TYPE, TEMP_MAX_ATOM)
       temp_num_mole = TEMP_MAX_MOLE
       temp_num_type = TEMP_MAX_TYPE
       temp_num_atom = TEMP_MAX_ATOM
       ALLOCATE ( temp_mole_len  (0:temp_num_mole), STAT = istatus) ! Allocate temporary
       ALLOCATE ( temp_mole_off  (0:temp_num_mole), STAT = istatus) ! molecule arrays
       ALLOCATE ( temp_mole_type (0:temp_num_mole), STAT = istatus)
       ALLOCATE ( temp_mole_char (0:temp_num_mole), STAT = istatus)
       ALLOCATE ( temp_mole_file (0:temp_num_mole), STAT = istatus)
       ALLOCATE ( temp_mole_dens (0:temp_num_mole), STAT = istatus)
       ALLOCATE ( temp_mole_fuzzy(0:temp_num_mole), STAT = istatus)
       ALLOCATE ( temp_mole_cont (0:temp_num_atom), STAT = istatus)
       CALL stru_internal_molecules(infile, TEMP_MAX_MOLE,                & ! Read domain 
              TEMP_MAX_ATOM, temp_num_mole, temp_num_type, & ! molecules
              temp_num_atom, temp_mole_len, temp_mole_off, temp_mole_type,& ! into temp
              temp_mole_char,    &
              temp_mole_file, temp_mole_dens, temp_mole_fuzzy, temp_mole_cont)
       IF(MOLE_MAX_MOLE < mole_num_mole + temp_num_mole .or.  &    ! If necessary increase
          MOLE_MAX_TYPE < mole_num_type + temp_num_type .or.  &    ! size of crystal molecule
          MOLE_MAX_ATOM < mole_num_atom + temp_num_atom     ) THEN ! arrays
          n_mole = MAX(MOLE_MAX_MOLE , mole_num_mole + temp_num_mole)
          n_type = MAX(MOLE_MAX_TYPE , mole_num_type + temp_num_type)
          n_atom = MAX(MOLE_MAX_ATOM , mole_num_atom + temp_num_atom)
          call alloc_molecule( MOLE_MAX_GENE, MOLE_MAX_SYMM, n_mole, n_type, n_atom )
       ENDIF
       DO i=1, temp_num_mole ! Create a lookup table, atom is in molecule
          DO j=1, temp_mole_len(i)
             k = temp_mole_cont(temp_mole_off(i)+j)
             temp_in_mole(k) = i
          ENDDO
       ENDDO
       DO i=1, temp_num_mole ! Create content of all molecules
          k  = mole_off(mole_num_mole) + mole_len(mole_num_mole) ! Offset of next molecule
          ii = 0
          DO j=1,mk_iatom    ! test all domain atoms
             IF(temp_present(j)) THEN  ! Domain atom is within the crystal
                IF(temp_in_mole(j)==i) THEN ! Domain atom is inside this molecule
                   ii = ii + 1         ! Increment no of atoms in this molecule
                   mole_len  (mole_num_mole+1) = mole_len  (mole_num_mole+1) + 1    ! Adjust length
                   mole_cont (k + mole_len  (mole_num_mole+1)) = temp_in_crystal(j) ! Set content
                   cr_prop (temp_in_crystal(j)) = IBSET (cr_prop (temp_in_crystal(j)), PROP_MOLECULE) 
                ENDIF
             ENDIF
          ENDDO
          IF(ii> 0) THEN ! If any atom is inside current molecule, then set all parameters
             mole_num_mole             = mole_num_mole + 1
             mole_off  (mole_num_mole) = k
             mole_type (mole_num_mole) = temp_mole_type (i)
             mole_char (mole_num_mole) = temp_mole_char (i)
             mole_file (mole_num_mole) = temp_mole_file (i)
             mole_dens (mole_num_mole) = temp_mole_dens (i)
             mole_fuzzy(mole_num_mole) = temp_mole_fuzzy(i)
          ENDIF
       ENDDO
       mole_num_atom = mole_off(mole_num_mole) + mole_len(mole_num_mole) ! set total no of atoms in the molecules
!
!      Deallocate temporary arrays
!
       DEALLOCATE ( temp_mole_len  , STAT = istatus)
       DEALLOCATE ( temp_mole_off  , STAT = istatus)
       DEALLOCATE ( temp_mole_type , STAT = istatus)
       DEALLOCATE ( temp_mole_char , STAT = istatus)
       DEALLOCATE ( temp_mole_file , STAT = istatus)
       DEALLOCATE ( temp_mole_dens , STAT = istatus)
       DEALLOCATE ( temp_mole_fuzzy, STAT = istatus)
       DEALLOCATE ( temp_mole_cont , STAT = istatus)
       DEALLOCATE ( temp_present   , STAT = istatus)
       DEALLOCATE ( temp_in_crystal, STAT = istatus)
       DEALLOCATE ( temp_in_mole   , STAT = istatus)
    ENDIF mole_int
!                                                                       
!     --Remove old atoms inside micromdomain if microdomain is fuzzy    
!DBG_RBN      This should becom standard for all domains!!!!!!!!!!!!    
!     -- Removal is only performed, if md_sep_fuz is > 0
!                                                                       
!DBG      if(mc_type.eq.MD_DOMAIN_FUZZY) then                   
      remove_strict: IF ( clu_remove_mode /= CLU_REMOVE_TRUST ) THEN
         IF ( md_sep_fuz > 0.00 ) THEN   ! Separation is > 0, remove atoms
            DO i = 1, 3 
               mk_dim (i, 1) = mk_dim (i, 1) - mc_matrix (i, 4) 
               mk_dim (i, 2) = mk_dim (i, 2) - mc_matrix (i, 4) 
            ENDDO 
!                                                                       
            mk_natoms = cr_natoms - natoms_old 
            vv (1) = mc_matrix (1, 4) 
            vv (2) = mc_matrix (2, 4) 
            vv (3) = mc_matrix (3, 4) 
            IF (MAXSCAT  > ubound(surf_in_dist,1)) THEN
               new_nscat = MAXSCAT
               CALL alloc_surf   (new_nscat)
            ENDIF 
            CALL micro_fuzzy_rem (mk_dim, natoms_old, mk_natoms, md_sep_fuz,  &
            vv, shortest, mc_type, MD_DOMAIN_FUZZY)                                                     
            IF (shortest.gt.1.5 * md_sep_fuz) then 
               ier_num = + 1 
               ier_typ = ER_APPL 
               WRITE (ier_msg (2), 3100) shortest 
               WRITE (ier_msg (3), 3200) md_sep_fuz 
               CALL errlist 
            ENDIF 
         ENDIF 
      ELSE  remove_strict
         clu_remove_dist = MAX(clu_remove_dist, md_sep_fuz)
      ENDIF remove_strict
!
      IF (ier_num.eq. - 49) then 
         CALL no_error 
      ENDIF 
!                                                                       
  999 CONTINUE 
      CLOSE (ist) 
!                                                                       
 2000 FORMAT    (a) 
 3000 FORMAT    (a4, 4(f16.8))
 3100 FORMAT    ('Shortest Distance to host ',f12.4) 
 3200 FORMAT    ('Intended fuzzy distance   ',f12.4) 
      END SUBROUTINE micro_read_atom                
!*****7*****************************************************************
      SUBROUTINE micro_read_simple (imd, lend, infile, mc_dimen,        &
      mc_idimen, mc_matrix, MK_MAX_SCAT,mk_at_lis)                                             
!
!     Reads a single line from the input file. This should contain a 
!     pseudo atom that is interpreted as cluster type
!                                                                       
      USE config_mod 
      USE domain_mod 
      USE domaindis_mod 
      USE read_internal_mod 
      USE tensors_mod
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      CHARACTER ( * ) infile 
      INTEGER imd 
      LOGICAL lend 
      REAL mc_dimen (4, 4) 
      REAL mc_idimen (4, 4) 
      REAL mc_matrix (4, 4) 
      INTEGER, INTENT(IN)                                   :: MK_MAX_SCAT
      CHARACTER (LEN=*), DIMENSION(0:MK_MAX_SCAT), INTENT(IN) :: mk_at_lis
!                                                                       
      CHARACTER(1024) line
!                                                                       
      INTEGER i, j, ii 
      REAL xyz (3) 
      INTEGER  :: dummy_iscat
      INTEGER  :: dummy_prop
!                                                                       
      LOGICAL str_comp 
!                                                                       
!     do i=1,4                                                          
!       do j=1,4                                                        
!         mc_dimen (i,j) = 0.0                                          
!         mc_idimen(i,j) = 0.0                                          
!         mc_matrix(i,j) = 0.0                                          
!       ENDDO                                                           
!       mc_dimen (i,i) = 1.0                                            
!       mc_idimen(i,i) = 1.0                                            
!       mc_matrix(i,i) = 1.0                                            
!     ENDDO                                                             
!                                                                       
      IF(clu_infile_internal) THEN   ! Read pseudo atom from internal storage
         clu_iatom = clu_iatom + 1   ! Increment internal atom number
         CALL struc_read_one_atom_internal(clu_infile, clu_iatom,  &
              xyz, dummy_iscat, dummy_prop )
         IF( ier_num == -105 ) THEN  ! read "end_of_file" 
            lend    = .true.
            ier_num = 0
            ier_typ = ER_NONE
            RETURN
         ENDIF
         WRITE(line, 1000) mk_at_lis(dummy_iscat), xyz ! copy into line
      ELSE
        READ (imd, '(a)', end = 999) line 
      ENDIF
      IF (line.ne.' '.and.line (1:1) .ne.'#'.and.line.ne.char (13) )    &
      then                                                              
         ii = 0 
         DO i = 1, clu_number 
         IF (str_comp (line (1:4), clu_name (i), 2, 4, 4) ) then 
            ii = i 
         ENDIF 
         ENDDO 
!                                                                       
         IF (ii.eq.0) then 
            ier_num = - 91 
            ier_typ = ER_APPL 
            RETURN 
         ENDIF 
!                                                                       
         infile = clu_content (ii) 
         mc_type    = clu_character (ii) 
         md_sep_fuz = clu_fuzzy (ii) 
         READ (line (5:52), * ) xyz 
!                                                                       
         DO i = 1, 3 
         DO j = 1, 4 
         mc_dimen (i, j) = clu_shape (ii, i, j) 
         mc_idimen (i, j) = clu_shape (ii, i, j) 
         mc_matrix (i, j) = clu_orient (ii, i, j) 
         ENDDO 
         mc_dimen (i, 4) = clu_shape (ii, i, 4) + xyz (i) 
         mc_idimen (i, 4) = clu_shape (ii, i, 4) + xyz (i) 
         mc_matrix (i, 4) = clu_orient (ii, i, 4) + xyz (i) 
         mc_dimen (4, i) = 0.0 
         mc_idimen (4, i) = 0.0 
         mc_matrix (4, i) = 0.0 
         ENDDO 
         mc_dimen (4, i) = 1.0 
         mc_idimen (4, i) = 1.0 
         mc_matrix (4, i) = 1.0 
         CALL invmat4 (mc_idimen) 
         lend = .false. 
      ENDIF 
!DBG                                                                    
!DBG      do i=1,4                                                      
!DBG      write(*,2222) 'MC_DIMEN  ',(mc_dimen (i,j),j=1,4)             
!DBG      ENDDO                                                         
!DBG      do i=1,4                                                      
!DBG      write(*,2222) 'MC_IDIMEN ',(mc_idimen(i,j),j=1,4)             
!DBG      ENDDO                                                         
!DBG      do i=1,4                                                      
!DBG      write(*,2222) 'MC_MATRIX ',(mc_matrix(i,j),j=1,4)             
!DBG      ENDDO                                                         
!DBG2222      format(a10,3(f8.3,2x),2x,f8.3)                            
      RETURN 
!                                                                       
  999 CONTINUE 
      lend = .true. 
!
1000  FORMAT(a4, 3(f16.8))
!                                                                       
      END SUBROUTINE micro_read_simple              
!*****7*****************************************************************
      SUBROUTINE micro_fuzzy_rem (mk_dim, natoms_old, mk_natoms,        &
      md_sep_fuz, w, shortest, mc_type, MD_DOMAIN_FUZZY)                                          
!-                                                                      
!     Removes all atoms up to number natoms_old that are inside         
!     the microdomain of fuzzy boundary type                            
!+                                                                      
      USE config_mod 
      USE crystal_mod 
      USE metric_mod
      USE molecule_mod 
      USE prop_para_mod 
      USE surface_mod 
      IMPLICIT none 
!                                                                       
      REAL, DIMENSION(3,2), INTENT(IN) ::  mk_dim
      INTEGER             , INTENT(in) ::  natoms_old
      INTEGER             , INTENT(IN) ::  mk_natoms 
      REAL                , INTENT(IN) ::  md_sep_fuz 
      REAL, DIMENSION(3)  , INTENT(IN) ::  w
      REAL                , INTENT(OUT)::  shortest 
      INTEGER             , INTENT(IN) ::  mc_type
      INTEGER             , INTENT(IN) ::  MD_DOMAIN_FUZZY
       
!                                                                       
      INTEGER i, j, k 
      LOGICAL lspace 
      REAL u (3), v (3)
      REAL a, b, c 
      REAL distance 
      REAL separation
!                                                                       
!     REAL do_blen 
!                                                                       
      shortest = 1.0e03 
      separation = 1.0e03
      lspace = .true. 
!
      type_fuzzy: IF(mc_type.eq.MD_DOMAIN_FUZZY) THEN  !This is a fuzzy domain do fast loop
         fuzzy_main: DO i = 1, natoms_old 
            separation = 1.0e03 
            fuzzy_is_void: IF (cr_iscat (i) .ne.0) then 
               DO k = 1, 3 
                  u (k) = cr_pos (k, i) 
               ENDDO 
               fuzzy_inner: DO j = cr_natoms - mk_natoms + 1, cr_natoms 
            DO k = 1, 3 
            v (k) = cr_pos (k, j) 
            ENDDO 
            distance = do_blen (lspace, u, v) 
            IF (distance.le.md_sep_fuz) then 
!                                                                       
!     ----------Atom is too close to microdomain atom, remove.          
!                                                                       
               cr_iscat (i) = 0 
               cr_prop (i) = IBCLR (cr_prop (i), PROP_NORMAL) 
               cr_prop (i) = IBSET (cr_prop (i), PROP_DOMAIN) 
               shortest = distance 
            ELSE 
               shortest = min (shortest, distance) 
               separation = min (separation, distance) 
            ENDIF 
               ENDDO fuzzy_inner
            ENDIF fuzzy_is_void
         ENDDO fuzzy_main
         IF (separation.lt.surf_in_dist (cr_iscat (i) ) ) then 
            IF (BTEST (cr_prop (i), PROP_NORMAL) ) then 
               cr_prop (i) = IBSET (cr_prop (i), PROP_SURFACE_INT) 
            ENDIF 
         ENDIF 
      ELSE type_fuzzy ! Other domain types (Should probalbly changed as well...)
!                                                                       
!     Set up extra space around microdomain to allow for outside        
!     influence of separation                                           
!                                                                       
      a = 1.5 * md_sep_fuz / cr_a0 (1) 
      b = 1.5 * md_sep_fuz / cr_a0 (2) 
      c = 1.5 * md_sep_fuz / cr_a0 (3) 
!                                                                       
!     Loop over all atoms previously inside the crystal                 
!                                                                       
      DO i = 1, natoms_old 
      separation = 1.0e03 
      IF (cr_iscat (i) .ne.0) then 
!                                                                       
!     ----Check if the atom is inside a domain or object,               
!         keep atom if inside a domain or object                        
         DO j = 1, mole_num_mole 
         IF (mole_char (j) .lt.MOLE_ATOM) then 
            DO k = 1, mole_len (j) 
            IF (mole_cont (mole_off (j) + k) .eq.i) then 
               GOTO 999 
            ENDIF 
            ENDDO 
         ENDIF 
         ENDDO 
         DO k = 1, 3 
         u (k) = cr_pos (k, i) 
         ENDDO 
         IF (mk_dim (1, 1) + w (1) - a.le.cr_pos (1, i)             .and. &
             cr_pos (1,  i)           .le.mk_dim (1, 2) + w (1) + a .and. &
             mk_dim (2, 1) + w (2) - b.le.cr_pos (2, i)             .and. &
             cr_pos (2, i)            .le.mk_dim (2, 2) + w (2) + b .and. &
             mk_dim (3, 1) + w (3) - c.le.cr_pos (3, i)             .and. &
             cr_pos (3, i)            .le.mk_dim (3, 2) + w (3) + c) then         
            DO j = cr_natoms - mk_natoms + 1, cr_natoms 
            DO k = 1, 3 
            v (k) = cr_pos (k, j) 
            ENDDO 
            distance = do_blen (lspace, u, v) 
            IF (distance.le.md_sep_fuz) then 
!                                                                       
!     ----------Atom is too close to microdomain atom, remove.          
!                                                                       
               cr_iscat (i) = 0 
               cr_prop (i) = IBCLR (cr_prop (i), PROP_NORMAL) 
               cr_prop (i) = IBSET (cr_prop (i), PROP_DOMAIN) 
               shortest = distance 
            ELSE 
               shortest = min (shortest, distance) 
               separation = min (separation, distance) 
            ENDIF 
            ENDDO 
         ENDIF 
      ENDIF 
  999 CONTINUE 
      IF (separation.lt.surf_in_dist (cr_iscat (i) ) ) then 
         IF (BTEST (cr_prop (i), PROP_NORMAL) ) then 
            cr_prop (i) = IBSET (cr_prop (i), PROP_SURFACE_INT) 
         ENDIF 
      ENDIF 
      ENDDO 
!
      ENDIF type_fuzzy
!                                                                       
!     DO j = cr_natoms - mk_natoms + 1, cr_natoms 
!     DO k = 1, 3 
!     v (k) = cr_pos (k, j) 
!     ENDDO 
!     separation = 1.0e03 
!     DO i = 1, natoms_old 
!     IF (cr_iscat (i) .ne.0) then 
!        IF (mk_dim (1, 1) + w (1) - a.le.cr_pos (1, i) .and.cr_pos (1, &
!        i) .le.mk_dim (1, 2) + w (1) + a.and.mk_dim (2, 1) + w (2)     &
!        - b.le.cr_pos (2, i) .and.cr_pos (2, i) .le.mk_dim (2, 2)      &
!        + w (2) + b.and.mk_dim (3, 1) + w (3) - c.le.cr_pos (3, i)     &
!        .and.cr_pos (3, i) .le.mk_dim (3, 2) + w (3) + c) then         
!           DO k = 1, 3 
!           u (k) = cr_pos (k, i) 
!           ENDDO 
!           distance = do_blen (lspace, u, v) 
!           separation = min (separation, distance) 
!        ENDIF 
!     ENDIF 
!     ENDDO 
!     IF (separation.lt.surf_in_dist (cr_iscat (j) ) ) then 
!        IF (BTEST (cr_prop (j), PROP_NORMAL) ) then 
!           cr_prop (j) = IBSET (cr_prop (j), PROP_SURFACE_INT) 
!        ENDIF 
!     ENDIF 
!     ENDDO 
                                                                        
!                                                                       
      END SUBROUTINE micro_fuzzy_rem                
!*****7*****************************************************************
      SUBROUTINE domain_do_set (zeile, length) 
!+                                                                      
!     This subroutine sets various parameters                           
!-                                                                      
      USE config_mod 
      USE domain_mod
      USE modify_mod
      USE errlist_mod 
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER maxw 
      PARAMETER (maxw = 20) 
!                                                                       
      CHARACTER ( * ) zeile 
      INTEGER length 
!                                                                       
      CHARACTER(1024) cpara (maxw) 
      INTEGER lpara (maxw) 
      INTEGER ianz 
      REAL werte (maxw) 
!                                                                       
      LOGICAL str_comp 
!                                                                       
      CALL get_params (zeile, ianz, cpara, lpara, maxw, length) 
      IF (ier_num.ne.0) return 
      IF (ianz.le.0) return 
!                                                                       
      IF (str_comp (cpara (1) , 'distance', 2, lpara (1) , 8) ) then 
         CALL del_params (1, ianz, cpara, lpara, maxw) 
         CALL surf_set_fuzzy (ianz, cpara, lpara, werte, maxw, 1) 
      ELSEIF(str_comp (cpara (1) , 'remove', 2, lpara (1) , 2) ) then
         IF    (str_comp (cpara (2) , 'initial', 2, lpara (2) , 6) ) then
            clu_remove_mode = CLU_REMOVE_INITIAL
         ELSEIF(str_comp (cpara (2) , 'strict', 2, lpara (2) , 6) ) then
            clu_remove_mode = CLU_REMOVE_STRICT
         ELSEIF(str_comp (cpara (2) , 'trust', 2, lpara (2) , 5) ) then
            clu_remove_mode = CLU_REMOVE_TRUST
         ELSE 
            ier_num = - 6 
            ier_typ = ER_COMM 
         ENDIF 
      ELSE 
         ier_num = - 6 
         ier_typ = ER_COMM 
      ENDIF 
!                                                                       
      END SUBROUTINE domain_do_set                  
END MODULE domain_menu
