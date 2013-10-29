# This is for a single submission only
# Will write something when the next multiple submission repooling request pops up
def change_pooling(ean13,mode)
  ActiveRecord::Base.transaction do
    plate = Plate.find_by_barcode(Barcode.split_barcode(ean13)[1])
    puts "Found plate #{plate.ean13_barcode}"
    requests = plate.stock_plate.wells.map {|w| w.requests.first}.compact
    raise "Error: Multiple submission" unless requests.map(&:submission_id).uniq.count == 1
    puts "#{requests.size} requests"
    pcp = requests.first.pre_capture_pool
    puts "Updating requests..."
    requests.each do |request|
      puts "updating plex from #{request.pre_capture_pool.id} to #{pcp.id}"
      request.update_attributes!(:pre_capture_pool => pcp)
    end
    order = requests.first.order
    puts "Updating order.."
    order.request_options['pre_capture_plex_level'] = requests.size
    order.save!
    raise "Test mode" unless mode == 'run'
  end
end
