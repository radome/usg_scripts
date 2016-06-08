#!ruby

class UpdateTubesWGS

  def is_valid_pcr_xp_qc_complete?(plate)
    (plate.state == "qc_complete") && (plate.plate_purpose.name == 'Lib PCR-XP')
  end

  def is_tube_in_qc_complete?(tube)
    tube.state=="qc_complete"
  end


  def pass_and_complete_tube(tube, user)
    if is_tube_in_qc_complete?(tube)
      puts "Tube: #{tube.id} was already in qc_complete state"
      return false
    else
      puts "Tube #{tube.purpose.name}: #{tube.id}, State: passed"
      StateChange.create(:user => user, :target => tube, :target_state => "passed")
      puts "Tube #{tube.purpose.name}: #{tube.id}, State: qc_complete"
      StateChange.create(:user => user, :target => tube, :target_state => "qc_complete")
      return true
    end
  end

  def create_lib_pool_norm_tube(tube, user)
    puts "Creating with transfer_template #{transfer_template.name} for user #{user.name} and source #{tube.uuid}"
    transfer = transfer_template.create!(
      :user   => user,
      :source => tube
    )
    destination_tube = transfer.destination
    puts "Tube #{destination_tube.purpose.name} created #{destination_tube.id}, #{destination_tube.uuid}"
    puts destination_tube
    destination_tube
  end

  def transfer_template
    TransferTemplate.find_by_name("Transfer from tube to tube by submission")
  end

  def user_by_login(login)
    User.find_by_login(login)
  end

  def find_plate_by_barcode(barcode)
    Plate.find_by_barcode(barcode)
  end

  def lib_pool_tubes(plate)
    plate.wells.map(&:requests).flatten.select do |r|
      r.request_type.key=='Illumina_Lib_PCR_XP_Lib_Pool'
    end.map(&:target_asset).uniq
  end

  def process_barcode(plate_barcode, user)
    ActiveRecord::Base.transaction do |t|
      plate = find_plate_by_barcode(plate_barcode)
      if is_valid_pcr_xp_qc_complete?(plate)

        lib_pool_tubes(plate).each do |lib_pool_tube|
          if (pass_and_complete_tube(lib_pool_tube, user))
            # We only create lib pool norm if the lib pool tube was not already qc_completed before
            lib_pool_norm_tube = create_lib_pool_norm_tube(lib_pool_tube, user)
            pass_and_complete_tube(lib_pool_norm_tube, user)
          end
        end
      end
    end
  end

  def process_barcodes(barcodes, login)
    barcodes.each{|barcode| process_barcode(barcode, user_by_login(login)) }
  end

end
