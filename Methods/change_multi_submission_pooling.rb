# This is for a multiple submission only
def change_multi_submission_pooling(ean13,pool_initial_wells,mode)
  ActiveRecord::Base.transaction do
    plate = Plate.find_by_barcode(Barcode.split_barcode(ean13)[1]).stock_plate
    puts "Found stock plate #{plate.ean13_barcode} for #{ean13}"
    pool_initial_wells.each do |loc|
      first_request = plate.wells.located_at(loc).first.requests_as_source.first
      submission = first_request.submission ; pcp = first_request.pre_capture_pool
      requests = submission.requests.select {|r| r.sti_type == "Pulldown::Requests::IscLibraryRequest"}
      requests.map(&:request_metadata).map {|r| r.pre_capture_plex_level = requests.size; r.save!}
      requests.each do |request|
        puts "updating plex from #{request.pre_capture_pool.id} to #{pcp.id}"
        request.update_attributes!(:pre_capture_pool => pcp)
      end
      puts "Updating order.."
      order = requests.first.order
      order.request_options['pre_capture_plex_level'] = requests.size
      order.save!
    end
    raise "Test mode" unless mode == 'run'
  end
end