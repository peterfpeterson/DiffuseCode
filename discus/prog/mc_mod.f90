MODULE mc_mod
!+
!
!     Variables for MONTE-CARLO level
!-
!
      USE config_mod
!
      SAVE
!
      INTEGER, PARAMETER  ::  MC_NONE     = 0
      INTEGER, PARAMETER  ::  MC_OCC      = 1
      INTEGER, PARAMETER  ::  MC_DISP     = 2
      INTEGER, PARAMETER  ::  MC_SPRING   = 3
      INTEGER, PARAMETER  ::  MC_ANGLE    = 4
      INTEGER, PARAMETER  ::  MC_VECTOR   = 5
      INTEGER, PARAMETER  ::  MC_BLEN     = 6
      INTEGER, PARAMETER  ::  MC_LENNARD  = 7
      INTEGER, PARAMETER  ::  MC_BUCKING  = 8
      INTEGER, PARAMETER  ::  MC_REPULSIVE= 9
!
      CHARACTER(LEN=200)  ::  mo_atom(3)
!
      INTEGER             ::  mo_energy
      INTEGER             ::  mo_mode,mo_local
      INTEGER             ::  mo_cyc,mo_feed
!
      REAL                ::  mo_target_corr(CHEM_MAX_COR)
      REAL                ::  mo_ach_corr(CHEM_MAX_COR)
      REAL                ::  mo_const(0:CHEM_MAX_COR)
      REAL                ::  mo_cfac(0:CHEM_MAX_COR)
      REAL                ::  mo_disp(CHEM_MAX_COR,0:DEF_MAXSCAT,0:DEF_MAXSCAT)
      REAL                ::  mo_maxmove(3,0:DEF_MAXSCAT)
      REAL                ::  mo_kt
      LOGICAL             ::  mo_sel_atom
!
END MODULE mc_mod
