# This is for a single submission only
# Will write something when the next repooling request pops up
def change_pooling(ean13)
  ActiveRecord::Base.transaction do
    ean13 = 1234567890123
    plate = Plate.find_by_barcode(Barcode.split_barcode(ean13)[1])
    requests = plate.stock_plate.wells.map {|w| w.requests.first}.compact
    pcp = requests.first.pre_capture_pool
    requests.each do |request|
      request.update_attributes!(:pre_capture_pool => pcp)
    end
    order = requests.first.order
    order.request_options['pre_capture_plex_level'] = requests.size
    order.save!
    raise "Test mode" unless mode == 'run'
  end
