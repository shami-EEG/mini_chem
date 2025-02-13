program mini_chem_main
  use mini_ch_precision
  use mini_ch_class, only: g_sp
  use mini_ch_read_reac_list, only : read_react_list
  use mini_ch_i_radau5, only : mini_ch_radau5
  implicit none

  integer :: n, n_step, u_nml
  real(dp) :: T_in
  real(dp) :: P_in
  real(dp) :: t_step, t_now
  integer :: n_sp
  real(dp), allocatable, dimension(:) :: VMR, VMR_IC
  character(len=200) :: data_file, sp_file, network,  net_dir, met

  logical :: CE_IC
  character(len=200) :: IC_file

  integer :: u
  character(len=200) :: integrator

  namelist /mini_chem/ T_in, P_in, t_step, n_step, n_sp, data_file, sp_file, network,  net_dir, met
  namelist /mini_chem_VMR/ CE_IC, IC_file, VMR_IC

  ! Input Temperature [K], pressure [Pa] and stepping variables
  !! Read input variables from namelist
  open(newunit=u_nml, file='mini_chem.nml', status='old', action='read')
  read(u_nml, nml=mini_chem)
  !! Read VMRs from namelist
  allocate(VMR(n_sp),VMR_IC(n_sp))
  read(u_nml, nml=mini_chem_VMR)
  close(u_nml)

  print*, 'T [K], P [bar], t_step, n_step, n_sp :'
  print*, T_in, P_in/1e5_dp, t_step, n_step, n_sp

  ! Initial time
  t_now = 0.0_dp

  ! Read the reaction and species list
  call read_react_list(data_file, sp_file, net_dir, met)

  ! Save the inital conditions to file
  ! Rescale IC to 1
  VMR_IC(:) = VMR_IC(:)/sum(VMR_IC(:))
  print*, 'integrator: ', g_sp(:)%c, 'VMR sum'
  print*, 'IC: ', VMR_IC(:), sum(VMR_IC(:))

  integrator = 'radau5'
  open(newunit=u,file='outputs_radau5/'//trim(integrator)//'.txt',action='readwrite')
  write(u,*) 'n', 'time', g_sp(:)%c
  write(u,*) 0, 0.0, VMR_IC(:)

  ! Give intial conditions to VMR array
  VMR(:) = VMR_IC(:)
 
  !! Do time marching loop
  ! - this loop emulates what a call to the model is like in the GCM
  do n = 1, n_step

    ! Update time
    t_now = t_now + t_step

    ! Time now
    print*, n, n_step, t_now

    !! Scale VMR to 1
    VMR(:) = VMR(:)/sum(VMR(:))

    ! Call radau5 - implicit Runge-Kutta method of order 5
    call mini_ch_radau5(T_in, P_in, t_step, VMR(:), network)
    print*, 'radau5: ', VMR(:), sum(VMR(:))
    write(u,*) n, t_now, VMR(:)

    !! Scale VMR to 1
    VMR(:) = VMR(:)/sum(VMR(:))

  end do

end program mini_chem_main
