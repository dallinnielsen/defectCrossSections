program TMEmain
  use TMEmod
  
  implicit none

  
  call mpiInitialization('TME')
    !! Initialize MPI

  call getCommandLineArguments()
    !! * Get the number of pools from the command line

  if((overlapOnly .and. intraK) .or. .not. capture) nPools = 1

  call setUpPools()
    !! * Split up processors between pools and generate MPI
    !!   communicators for pools
  
  if(ionode) call cpu_time(t0)


  call readInputParams(iBandLBra, iBandHBra, iBandLKet, iBandHKet, ibBra, ikBra, ibKet, ikKet, ibShift_braket, &
          ispSelect, nPairs, order, phononModeJ, baselineDir, braExportDir, ketExportDir, dqFName, energyTableDir, &
          optimalPairsDir, outputDir, capture, dqOnly, intraK, lineUpBands, overlapOnly, readOptimalPairs, subtractBaseline)
    !! Read input, initialize, check that required variables were set, and
    !! distribute across processes
    

  nSys = 2

  call setUpSystemArray(nSys, braExportDir, ketExportDir, crystalSystem)
    ! This is not really needed for only 2 crystal systems. We don't actually
    ! need it right now because for scattering we plan to only read from 2 exports.
    ! However, it is possible that you could read from multiple exports for the
    ! different k-points, so I am going to leave this here just in case.


  call completePreliminarySetup(nSys, order, phononModeJ, capture, intraK, dqFName, mill_local, nGVecsGlobal, nGVecsLocal, &
        nKPoints, nSpins, dq_j, recipLattVec, volume, Ylm, crystalSystem, pot)

  
  if(capture) then
    call getAndWriteCaptureMatrixElements(nPairs, ibShift_braket, ibKet, ibBra(1), ispSelect, nGVecsLocal, nSpins, dq_j, volume, &
          dqOnly, crystalSystem(1), crystalSystem(2), pot)
  else if(overlapOnly .and. .not. intraK) then
    call getAndWriteInterKOnlyOverlaps(iBandLBra, iBandHBra, iBandLKet, iBandHKet, nPairs, ibShift_braket, ibBra, ibKet, &
            ispSelect, nGVecsLocal, nSpins, volume, lineUpBands, readOptimalPairs, optimalPairsDir, crystalSystem(1), &
            crystalSystem(2), pot)
  else
    call getAndWriteScatterMatrixElementsOrOverlaps(nPairs, ibShift_braket, ibKet, ikKet, ibBra, ikBra, ispSelect, nGVecsLocal, nSpins, &
            volume, overlapOnly, readOptimalPairs, optimalPairsDir, crystalSystem(1), crystalSystem(2), pot)
  endif 


  call MPI_BARRIER(worldComm, ierr)

  
  call finalizeCalculation(nSys, crystalSystem, pot)

  deallocate(crystalSystem)
  
  call MPI_FINALIZE(ierr)
  
end program TMEmain
