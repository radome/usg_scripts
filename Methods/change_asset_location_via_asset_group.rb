def change_asset_location(asset_groups,location_id)
  ActiveRecord::Base.transaction do
    asset_groups.each do |asset_group|
      AssetGroup.find_by_name(asset_group).assets.each {|a| a.location_id = location_id; a.save!}
    end
  end
end
pp Location.all

change_asset_location(asset_groups,location_id)
