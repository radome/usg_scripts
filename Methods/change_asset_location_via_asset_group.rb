def change_asset_location(asset_group, location_id)
  ActiveRecord::Base.transaction do
    AssetGroup.find(asset_group).assets.each {|a| a.location_id = location_id; a.save!}
  end
end

def change_asset_location(asset_groups, location_id)
  ActiveRecord::Base.transaction do
    asset_groups.each do |asset_group|
      AssetGroup.find(asset_group).assets.each {|a| a.location_id = location_id; a.save!}
    end
  end
end

# For a list of freezer locations
# pp Location.all