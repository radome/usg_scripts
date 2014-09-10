def update_lib_creation_requests_for_x10_mx_tubes(barcode)
  ActiveRecord::Base.transaction do
    Plate.find_by_barcode(barcode).wells.map(&:requests).flatten.map(&:target_asset).map {|mx| mx.transition_to('started'); mx.transition_to('passed')}
  end
end
