def update_lib_creation_requests_for_x10_mx_tubes_and_place_in_inbox(barcode_of_lib_pcr_xp_plate)
  ActiveRecord::Base.transaction do
    Plate.find_by_barcode(barcode_of_lib_pcr_xp_plate).wells.map(&:requests).flatten.map(&:target_asset).map {|mx| mx.transition_to('started'); mx.transition_to('passed'); mx.location_id = 2; mx.save!}
  end
end

update_lib_creation_requests_for_x10_mx_tubes_and_place_in_inbox(