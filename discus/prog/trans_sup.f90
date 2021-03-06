MODULE trans_sup_mod
!
CONTAINS
!*****7*****************************************************************
      SUBROUTINE tran_ca (usym, matrix, lscreen) 
!-                                                                      
!     Performs the transformation symmetry operation for a single       
!     atom or reciprocal vector.                                        
!+                                                                      
      USE config_mod 
      USE trafo_mod
!
      USE errlist_mod 
      USE param_mod 
      USE prompt_mod 
!
      IMPLICIT none 
!                                                                       
!                                                                       
      INTEGER j 
!                                                                       
      LOGICAL lscreen 
!                                                                       
      REAL usym (4), ures (4) 
      REAL matrix (4, 4) 
!                                                                       
!-----      Apply symmetry operation                                    
!                                                                       
      CALL trans (usym, matrix, ures, 4) 
!                                                                       
!     Replace original vector and store result                          
!                                                                       
      DO j = 1, 3 
      res_para (j) = ures (j) 
      usym (j) = ures (j) 
      ENDDO 
!                                                                       
      res_para (0) = 3 
      IF (lscreen) then 
         WRITE (output_io, 3000) (res_para (j), j = 1, 3) 
      ENDIF 
!                                                                       
 3000 FORMAT    (' Result    : ',3(2x,f9.4)) 
      END SUBROUTINE tran_ca                        
END MODULE trans_sup_mod
