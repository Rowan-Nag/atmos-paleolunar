      SUBROUTINE SEDMNT(FSULF,USETD,frak,HCDENS,ihztype)
      INCLUDE 'PHOTOCHEM/INPUTFILES/parameters.inc'
      implicit real*8(A-H,O-Z)
      real*8 mass
      DIMENSION FSULF(NZ),TAUTRN(NZ),RHOP(NZ)
      DIMENSION TAURAN(NZ,NP),ALAM(NZ),TAUCPK(NZ,NP),ETA(NZ)
      character*8 PLANET,ISPEC
      INCLUDE 'PHOTOCHEM/DATA/INCLUDE/PHOTABLOK.inc'
      INCLUDE 'PHOTOCHEM/DATA/INCLUDE/CBLOK.inc'
      INCLUDE 'PHOTOCHEM/DATA/INCLUDE/GBLOK.inc'
      INCLUDE 'PHOTOCHEM/DATA/INCLUDE/NBLOK.inc'
      INCLUDE 'PHOTOCHEM/DATA/INCLUDE/AERBLK.inc'
      INCLUDE 'PHOTOCHEM/DATA/INCLUDE/DBLOK.inc'

      DIMENSION CUNING(NZ,NP),amass(NZ,NP),THERMSP(NZ,NP),
     2  TAURELAXC(NZ,NP),TAURELAX(NZ,NP),AFPL(NZ,NP),delta(NZ,NP),
     3  BETAF(NZ,NP)

      REAL NMON,RMON,DF,rmmax,rconmax !frachack
C- aerosol properties
      rmmax=1.90E-4 !Maximum HC radius, as to be smaller than greatest rstand for optical properties (current rstand max value 2mum)
      rconmax=6.0E-5
      If(NP.eq.2) THEN
      NPX=NP
      ELSE
      NPX=NP-1
      ENDIF


c
C
C   THIS SUBROUTINE CALCULATES FALL VELOCITIES AND ESTIMATES PARTICLE SIZE
C   BASED ON THEIR COAGULATION LIFETIMES
C
C   CONSTANTS FOR STOKES-CUNNINGHAM EQUATION (KASTEN, 1968)
C-AP      A = 1.249
C-AP      B = 0.42
C-AP      C = 0.87
C   CONSTANTS from Pruppacher and Klett page 450
          A = 1.257
          B = 0.4
          C = 1.1
C-AP
C-AP       A = 0.866
C-AP       B = 0.29
C-AP       C = 1.25
C-AP
      BK = 1.38*1.E-16
      PI = 3.14159
      NZ1 = NZ - 1
C


      if (frak.eq.1) then
C **********************************************
C-EW  IMPLEMENTATION OF FRACTAL MICROPHYSICS
C-EW  ONLY FOR HYDROCARBONS, K=3 and 4
C
C-EW  IMPLEMENTATION USES A SIZE BIN DEPENDENT FRACTAL
C-EW  DIMENSION TO PARAMETERIZE AGGREGATE RESTRUCTURING
C-EW  PERMEABILITY EFFECTS ARE NOT TREATED HERE
C
C-EW RPAR = equal mass spherical radii
C-EW RFRAC = fractal aggregate radii
C
          RMON = 50.E-7
C-EW  THIS IS THE MONOMER RADIUS [cm]
       if (ihztype.eq.0.) RMON = 50.E-7
       if (ihztype.eq.1.) RMON = 10.E-7
       if (ihztype.eq.2.) RMON = 20.E-7
       if (ihztype.eq.3.) RMON = 70.E-7
       if (ihztype.eq.4.) RMON = 10.E-6
       if (ihztype.eq.5.) RMON = 50.E-7
       if (ihztype.eq.6.) RMON = 50.E-7

         RMON = 50.E-7
      do K=3,NPX
      DO J=1,NZ
      IF(RPAR(J,K).GE.rmmax)then   !limiting RPAR size to rmmax, which has to be smaller than greatest rstand
      RPAR(J,K)=rmmax
      ENDIF
      NMON = (RPAR(J,K)/RMON)**3.
      IF (NMON .LE. 1.) THEN
        DF = 3.
      ELSE
        DF = 2.4 - 0.9*EXP(-NMON/500.)
      ENDIF
      RFRAC(J,K) = RPAR(J,K)**(3./DF)*RMON**(1.-3./DF)
      ENDDO
      enddo


C-EW *******************************************
C
      endif

      DO J=1,NZ
      ALAM(J) = 1.63E14/DEN(J)
      ETA(J)=ABS((1.718 + 0.0049*(T(J)-273.) - 1.2
     & *(1.E-5)*(T(J)-273.)*(T(J)-273.))*1.E-4)
      ENDDO


      DO 10 K=1,NPX
C   (1 = SULFATE, 2 = S8, 3 = HYDROCARBON, 4=HCAER2)
        LL=NQ-NP+K

       L = LSO4AER  !so using the sulfate aersol for all particles?

        if(usetd.eq.1) then !Jim's code with particles in tri-diag uses H2SO4 rather than the aerosol
          L = LH2SO4  !using h2so4 for all particles? (sure why not - it's infinite rainout...)
        endif

C
C-AP ESTIMATION OF THE AEROSOL FREE PATH LENGTH
      DO J = 1,NZ
      IF(K.GE.3 .AND. frak.eq.1) THEN  !ACK hardcoded particle number (getting HCAER and HCAER2)
C-EW  HYDROCARBONS: USE FRACTAL MICROPHYSICS
       ALPH = A + B*EXP(-C*RFRAC(J,K)/ALAM(J)) !giada - related to particle diffusion I think
       CUNING(J,K) = 1 + ALPH*ALAM(J)/RFRAC(J,K)
C-AP Here we assume that the density of aerosol is 1 g/cm3
C-Giada: actually, density of hc aerosols should be 0.63 g/cm3
C        see Trainer et al (2006)
C-AP Notation is similar Fusch 1964
C THERMSP = thermal velocity of molecule
c       adensity = 0.64
       amass(J,K) = (4./3.)*PI*RPAR(J,K)**3*HCDENS
       THERMSP(J,K) = SQRT((8*BK*T(J))/(pi*amass(J,K))) !giada - thermal velocity
       TAURELAXC(J,K)=2*RPAR(J,K)**3/(9*ETA(J)*RFRAC(J,K))
       TAURELAX(J,K) = TAURELAXC(J,K)*CUNING(J,K)
       AFPL(J,K) = THERMSP(J,K)*TAURELAX(J,K) !giada - this is particle mean free path?
       delta(J,K) = (((2*RFRAC(J,K)+AFPL(J,K))**3 - (4* !giada - delta is mean distance from ctr of sphere
     & RFRAC(J,K)*RFRAC(J,K)+AFPL(J,K)*AFPL(J,K))**1.5)/!reached by particle leaving the surface and traveling distance
     & (6*RFRAC(J,K)*AFPL(J,K)) - 2*RFRAC(J,K))*SQRT(2.)!equal to the mean free path (AFPL)
      ELSE
C-EW  S8,SO4,HC if frak=0: USE SPHERICAL MICROPHYSICS
       ALPH = A + B*EXP(-C*RPAR(J,K)/ALAM(J))
       CUNING(J,K) = 1 + ALPH*ALAM(J)/RPAR(J,K)
C-AP Here we assume that the density of aerosol is 1 g/cm3
C-AP Notation is similar Fusch 1964

C assign density
       if (LL.EQ.LS8AER) then
         adensity = 2.07
       elseif (LL.EQ.LSO4AER) then
         adensity = 1. + 0.8*FSULF(J)
       else
       adensity = HCDENS
       endif

       amass(J,K) = (4./3.)*PI*RPAR(J,K)**3*adensity
       THERMSP(J,K) = SQRT((8*BK*T(J))/(pi*amass(J,K)))
       TAURELAXC(J,K)=2*RPAR(J,K)*RPAR(J,K)/(9*ETA(J))
       TAURELAX(J,K) = TAURELAXC(J,K)*CUNING(J,K)
       AFPL(J,K) = THERMSP(J,K)*TAURELAX(J,K)
       delta(J,K) = (((2*RPAR(J,K)+AFPL(J,K))**3 - (4*
     & RPAR(J,K)*RPAR(J,K)+AFPL(J,K)*AFPL(J,K))**1.5)/
     & (6*RPAR(J,K)*AFPL(J,K)) - 2*RPAR(J,K))*SQRT(2.)
      ENDIF !end frak loop
      ENDDO

C-AP Calculation of the correction to the coagulation kernel
      DO J = 1,NZ
      IF(K.GE.3 .AND. frak.eq.1) THEN    !get HCAER and HCAER2
C-EW  HYDROCARBONS: USE FRACTAL MICROPHYSICS - giada: betaf is effective radii?
       BETAF(J,K) = 1/(RFRAC(J,K)/(RFRAC(J,K)+delta(J,K)/2)
     & +PI*AFPL(J,K)/(2*SQRT(2.)*RFRAC(J,K)))
      ELSE
C-EW  S8,SO4,HC if frak=0: USE SPHERICAL MICROPHYSICS
       BETAF(J,K) = 1/(RPAR(J,K)/(RPAR(J,K)+delta(J,K)/2)
     & +PI*AFPL(J,K)/(2*SQRT(2.)*RPAR(J,K)))
      ENDIF
      ENDDO
C-AP ******************************************************



C   ESTIMATE COAGULATION AND SEDIMENTATION LIFETIMES (TOON AND FARLOW, 1981
      DO I=1,NZ
c this commented one was from Toon and Farlow 1981; giada-new methodology from Pavlov 2001
c     TAUC(I,K) = 1.E6/(AERSOL(I,K)*SQRT(RPAR(I,K)))      !T&F (81) p.41 - e-folding lifetime against coagulation
                                                          ! 1/tauc = 1/N DN/DT

c recompute tauc using new methodology (giada- from Pavlov 2001)
      TAUCPK(I,K) = 3*ETA(I)/(4*AERSOL(I,K)*BK*
     & T(I)*CUNING(I,K))
      TAUC(I,K)=TAUCPK(I,K)/BETAF(I,K)  !ok for fractals as BETAF has new effective radii if frak=1

      TAURAN(I,K) = 1./(RAINGC(L,I) + 1.E-20)    ! this is really wrong for S8 !!  !where does this come from?

!it looks like I never completly fixed the rainout thing.  TAURAN is using LSO4AER for both.  but isn't RAINGC really small for S8?

                                                 ! what is this? rainout lifetime, i presume. should check magnitude

      TAUSED(I,K) = HSCALE(I)/WFALL(I,K)
      enddo
C
C   FIND MINIMUM OF DIFFUSION AND SEDIMENTATION LIFETIMES, THEN SCALE PRTICLE SIZES
      e_minus_5 = 1.E-5
      e_hc=1.3E-7
      DO  I=1,NZ
      TAUTRN(I) = min(TAUSED(I,K),TAUEDD(I))                  !find the minimum of the three destruction timescales
      TAUTRN(I) = min(TAUTRN(I),TAURAN(I,K))                  !lifetime against eddy diffusion is H*H/K
                                                              !where K is eddy diffusion coefficient, H is scale height
      RPAR(I,K) = RPAR(I,K) * (TAUTRN(I)/TAUC(I,K))**0.25     !particle growth depends on
      if (K.GE.3) then
       RPAR(I,K) = max(RPAR(I,K),e_hc)  !largest HC particles are smaller?
        IF(RPAR(I,K).GE.rmmax)then   !limiting RPAR size to rmmax, which has to be smaller than greatest rstand
        RPAR(I,K)=rmmax
        ENDIF
      else
       RPAR(I,K) = max(RPAR(I,K),e_minus_5)                    !largest particles are 1 micron
      endif
      ENDDO
C
C   DON'T ALLOW PARTICLES TO DECREASE IN SIZE AT LOW ALTITUDES
      DO I=1,NZ1
      J = NZ - I
      RPAR(J,K) = max(RPAR(J,K),RPAR(J+1,K))
      ENDDO

      if(K.eq.3) then
      Do J= I, NZ
       RPAR(J,4)=RPAR(J,3)
      enddo
      endif

C
C   COMPUTE PARTICLE-TO-GAS CONVERSION FACTORS AND DENSITIES
c - it would nice to document where these come from - the 1989 sulfur/UV paper, I imagine.
c- no hints in Shawn's code
      do I=1,nz
        R = RPAR(I,K)
        LL=NQ-NP+K  !ACK - assuming particles are last LL elements
        if (USETD.EQ.1) LL=K+NQ  !particles in tri-diag

       if (LL.EQ.LS8AER) then
         RHOP(I) = 2.07
         factor=2.03E7
       endif

       if (LL.EQ.LSO4AER) then
         RHOP(I) = 1. + 0.8*FSULF(I)
         factor = 4.6E7*FSULF(I)
       endif

       if (LL.EQ.LHCAER .OR. LL.EQ.LHCAER2) then
c         RHOP(I) = 1.4
c         RHOP(I) = 1.0  !from feng's code
          RHOP(I) = HCDENS
c         factor=7.06E7 !giada - this was computed using 1.4 g/cm3
          IF (LL.eq.LHCAER) then
             gpermolec = 2*1.66e-24+12*4*1.66e-24 !grams per molecule for HCAER
          endif

             gpermolechcaer2 = 4*1.66e-24+12*5*1.66e-24 !grams per molecule for HCAER2

           factorhcaer2=(4./3.)*PI*(1.E-5)**3*HCDENS/gpermolechcaer2

       endif
          CONVER(I,K) = factor * (R/1.E-5)**3
          IF (K.eq.3) then
          CONVER(I,4) = factorhcaer2 * (R/1.E-5)**3
          endif


c - giada - factor is the NUMBER OF MOLECULES PER 0.1UM SPHERE (don't know why .1um was chosen, but that is how it is...)

!rho_p is particle density (g/cm3)
!factor is related to density somehow (jim's words) (giada - yeah, this was all I had to go off of to figue
!out the mysterious 'factor'...)

!conver is the number of molecules/particle, so that main calcuations are done in molecule space
!conver is used in the main code to calculate aersol (= number density of aerosols)!


      enddo

C   NOW COMPUTE FALL VELOCITIES
      DO  J=1,NZ
cccccccccc
      IF(K.GE.3 .AND. frak.eq.1) THEN
      NMON = (RPAR(J,K)/RMON)**3.
      IF (NMON .LE. 1.) THEN
        DF = 3.
      ELSE
        DF = 2.4 - 0.9*EXP(-NMON/500.)
      ENDIF
      RFRAC(J,K) = RPAR(J,K)**(3./DF)*RMON**(1.-3./DF)
cccccccccc
C-EW  HYDROCARBONS: USE FRACTAL MICROPHYSICS
       R = RPAR(J,K)
       RF = RFRAC(J,K)
       F1 = 2./9. * RHOP(J)*R*R*R*GZ(J)/ETA(J)/RF !from stokes law F1 - settling velocity
       !giada -  it's computing terminal velocity  when frictional and buoyant forces
       !are equal to gravitational force
       ALPH = A + B*EXP(-C*RF/ALAM(J)) ! I think this is related to particle resistance to motion
       WFALL(J,K) = F1*(1. + ALAM(J)*ALPH/RF) !wfall = fall velocity
       IF (K.eq.3) THEN
       WFALL(J,4) =WFALL(J,3)
       ENDIF
                             !this term (alam*alph/rf) is particle diffusion?  maybe?
      ELSE
C-EW  S8, SO4,HC if frak=0: USE SPHERICAL MICROPHYSICS
       R = RPAR(J,K)
C-AP      ETA = 1.77E-4 * SQRT(T(J)/288.)
C-AP  From Prupacher & Klett
       F1 = 2./9. * RHOP(J)*R*R*GZ(J)/ETA(J)
       ALPH = A + B*EXP(-C*R/ALAM(J))
       WFALL(J,K) = F1*(1. + ALAM(J)*ALPH/R)
       IF (K.eq.3) THEN
       WFALL(J,4) =WFALL(J,3)
       ENDIF
      ENDIF
      enddo


  10  CONTINUE

C


c      print *, 'stopping in Sedmnt', GZ(1)
c      stop
      RETURN
      END
